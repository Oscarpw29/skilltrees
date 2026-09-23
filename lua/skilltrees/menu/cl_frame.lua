-- The skill window. Owns the staged (unsaved) allocation; child panels ask it for the
-- effective skills/points and repaint from that every frame. Server syncs never rebuild it.
local UI = SkillTrees.UI
local MENU = {}

local TITLE_H  = 40
local TABS_H   = 30
local BOTTOM_H = 58
local PAD      = 12
local MAX_PIPS = 40

function MENU:Init()
    self:SetTitle("")
    self:ShowCloseButton(false)
    self:SetDraggable(true)
    self:SetSizable(false)
    self:DockPadding(0, 0, 0, 0)

    self.Staged = {}
    self.Saving = false
    self.XPShown = 0
    self.ToastText, self.ToastUntil = nil, 0

    local close = UI.Button(self, "X", function() self:RequestClose() end)
    close.Accent = UI.Col.red
    self.CloseBtn = close

    self.Body = vgui.Create("DPanel", self)
    self.Body.Paint = nil

    self.UndoBtn = UI.Button(self, "UNDO", function() self:Undo() end)
    self.RespecBtn = UI.Button(self, "RESPEC", function() self:ConfirmRespec() end)
    self.RespecBtn.Accent = UI.Col.red
    self.SaveBtn = UI.Button(self, "SAVE", function() self:Save() end)
    self.SaveBtn.Accent = UI.Col.gold

    self.Tooltip = vgui.Create("VTX_SkillTooltip", self)
    self.Tooltip:SetVisible(false)

    hook.Add("SkillTrees_DataUpdated", self, function(pnl) pnl:OnDataUpdated() end)

    self:BuildTabs()
    self:Recompute()
end

-- State

function MENU:GetSaved()
    local sd = LocalPlayer().SkillData
    return sd and sd.skills or {}
end

function MENU:GetSavedPoints()
    local sd = LocalPlayer().SkillData
    return sd and sd.points or 0
end

-- Saved + staged; what every panel displays
function MENU:GetSkills() return self.Effective end
function MENU:GetPoints() return self.EffectivePoints end

function MENU:StagedCount()
    local n = 0
    for _, v in pairs(self.Staged) do n = n + v end
    return n
end

function MENU:Recompute()
    local skills = table.Copy(self:GetSaved())
    local points = self:GetSavedPoints()
    for id, n in pairs(self.Staged) do
        skills[id] = (skills[id] or 0) + n
        points = points - (SkillTrees:GetSkill(id).price or 1) * n
    end
    self.Effective, self.EffectivePoints = skills, points
end

function MENU:Stage(id)
    if self.Saving then return end
    local ok, reason = SkillTrees:CanAddLevel(LocalPlayer(), self.Effective, self.EffectivePoints, id)
    if not ok then return self:Toast(reason) end

    self.Staged[id] = (self.Staged[id] or 0) + 1
    self:Recompute()
    surface.PlaySound("buttons/button14.wav")
end

function MENU:Unstage(id)
    if self.Saving then return end
    local ok, reason = SkillTrees:CanRemoveLevel(self.Effective, id, self:GetSaved()[id] or 0)
    if not ok then return self:Toast(reason) end

    self.Staged[id] = self.Staged[id] - 1
    if self.Staged[id] <= 0 then self.Staged[id] = nil end
    self:Recompute()
    surface.PlaySound("buttons/button15.wav")
end

function MENU:Undo()
    self.Staged = {}
    self:Recompute()
end

function MENU:Save()
    if self.Saving or not SkillTrees:SendCommit(self.Staged) then return end
    self:SetSaving()
end

-- Waiting for the server's sync; released by OnDataUpdated or, if no reply comes, a timeout
function MENU:SetSaving()
    self.Saving = true
    self.SavingUntil = RealTime() + 3
end

function MENU:ConfirmRespec()
    Derma_Query("Refund every saved skill rank? Unsaved changes are discarded too.", "Respec",
        "Respec", function()
            if not IsValid(self) then return end
            self.Staged = {}
            self:SetSaving()
            self:Recompute()
            SkillTrees:SendReset()
        end,
        "Cancel", function() end)
end

function MENU:RequestClose()
    local n = self:StagedCount()
    if n == 0 then return self:Remove() end
    Derma_Query("Discard " .. n .. " unsaved skill rank(s)?", "Unsaved changes",
        "Discard", function() if IsValid(self) then self:Remove() end end,
        "Keep editing", function() end)
end

function MENU:OnDataUpdated()
    if self.Saving then
        -- Reply to our save/respec: saved data now contains (or rejected) what we staged
        self.Staged = {}
        self.Saving = false
    elseif next(self.Staged) then
        -- Someone else changed our data (XP, admin): keep whatever staged ranks still fit
        local sd = LocalPlayer().SkillData
        local _, _, applied, leftover = SkillTrees:ApplyLevels(LocalPlayer(), sd.skills, sd.points, self.Staged)
        self.Staged = applied
        if leftover > 0 then self:Toast("Some unsaved ranks no longer fit and were removed.") end
    end
    self:Recompute()
end

function MENU:Toast(text)
    self.ToastText = text
    self.ToastUntil = RealTime() + 3
    surface.PlaySound("buttons/button10.wav")
end

-- Tooltip

function MENU:ShowTooltip(node)
    self.Tooltip:SetNode(node)
    self.Tooltip:SetVisible(true)
    self.Tooltip:MoveToFront()
end

function MENU:HideTooltip(node)
    if self.Tooltip.Node == node then self.Tooltip:SetVisible(false) end
end

-- Trees & tabs

function MENU:BuildTabs()
    local lp = LocalPlayer()
    self.Visible = {}
    for _, name in ipairs(SkillTrees.TreeOrder) do
        if SkillTrees:CanAccessTree(lp, name) then
            table.insert(self.Visible, { name = name })
        elseif lp:IsSuperAdmin() then
            table.insert(self.Visible, { name = name, preview = true })
        end
    end

    self.Tabs = {}
    if #self.Visible < 2 then return end

    for _, entry in ipairs(self.Visible) do
        local tab = vgui.Create("DButton", self)
        tab:SetText("")
        tab.DoClick = function() self:SelectTree(entry.name) end
        tab.Paint = function(pnl, w, h)
            local col = SkillTrees.Tree[entry.name].Color or UI.Col.frameEdge
            local active = self.TreeName == entry.name
            surface.SetDrawColor(active and UI.Alpha(col, 60) or (pnl:IsHovered() and UI.Alpha(col, 30) or Color(0, 0, 0, 0)))
            surface.DrawRect(0, 0, w, h)
            if active then
                surface.SetDrawColor(col)
                surface.DrawRect(0, h - 2, w, 2)
            end
            local label = string.upper(entry.name) .. (entry.preview and "  (PREVIEW)" or "")
            draw.SimpleText(label, "VTX_Rank", w / 2, h / 2, active and UI.Col.text or UI.Col.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        surface.SetFont("VTX_Rank")
        local tw = surface.GetTextSize(string.upper(entry.name) .. (entry.preview and "  (PREVIEW)" or ""))
        tab:SetWide(tw + 28)
        table.insert(self.Tabs, tab)
    end
end

function MENU:DefaultTree(preferred)
    for _, e in ipairs(self.Visible) do
        if e.name == preferred then return e.name end
    end
    for _, e in ipairs(self.Visible) do
        if not e.preview then return e.name end
    end
    return self.Visible[1] and self.Visible[1].name
end

function MENU:SelectTree(name)
    if not name or name == self.TreeName then return end
    self.TreeName = name
    SkillTrees.UI.LastTree = name
    self.Tooltip:SetVisible(false)

    self.Body:Clear()
    self.Columns = {}

    local base = vgui.Create("VTX_SkillTree", self.Body)
    base:Setup(self, name, "base")
    table.insert(self.Columns, base)

    local specs = SkillTrees.Tree[name].Specializations or {}
    for _, spec in SortedPairs(specs) do
        local col = vgui.Create("VTX_SkillTree", self.Body)
        col:Setup(self, name, "spec", spec)
        table.insert(self.Columns, col)
    end

    self:InvalidateLayout(true)
end

-- Layout

function MENU:PerformLayout(w, h)
    self.CloseBtn:SetSize(26, 24)
    self.CloseBtn:SetPos(w - 26 - 8, (TITLE_H - 24) / 2)

    local top = TITLE_H + 6
    if #self.Tabs > 0 then
        local x = PAD
        for _, tab in ipairs(self.Tabs) do
            tab:SetTall(TABS_H - 4)
            tab:SetPos(x, top)
            x = x + tab:GetWide() + 4
        end
        top = top + TABS_H
    end

    local bodyH = h - top - BOTTOM_H - PAD
    self.Body:SetPos(PAD, top)
    self.Body:SetSize(w - PAD * 2, bodyH)

    local cols = self.Columns or {}
    local gap = 10
    if #cols == 1 then
        local cw = math.min(self.Body:GetWide(), 480)
        cols[1]:SetPos((self.Body:GetWide() - cw) / 2, 0)
        cols[1]:SetSize(cw, bodyH)
    else
        local cw = (self.Body:GetWide() - gap * (#cols - 1)) / #cols
        for i, col in ipairs(cols) do
            col:SetPos(math.floor((i - 1) * (cw + gap)), 0)
            col:SetSize(math.floor(cw), bodyH)
        end
    end

    local by = h - BOTTOM_H + (BOTTOM_H - 26) / 2
    local bw = 78
    self.SaveBtn:SetSize(bw, 26)   self.SaveBtn:SetPos(w - PAD - bw - 6, by)
    self.RespecBtn:SetSize(bw, 26) self.RespecBtn:SetPos(w - PAD - bw * 2 - 12, by)
    self.UndoBtn:SetSize(bw, 26)   self.UndoBtn:SetPos(w - PAD - bw * 3 - 18, by)
end

-- Painting

function MENU:PaintBottomBar(w, h)
    local y = h - BOTTOM_H
    local sd = LocalPlayer().SkillData or {}

    surface.SetDrawColor(4, 10, 16, 255)
    surface.DrawRect(PAD, y + 6, w - PAD * 2, BOTTOM_H - 12)
    UI.Outline(PAD, y + 6, w - PAD * 2, BOTTOM_H - 12, UI.Col.edgeDim)
    local cy = y + BOTTOM_H / 2

    -- Level + XP
    local level = sd.level or 1
    local maxed = level >= SkillTrees.MaxLevel
    local progress = maxed and 1 or math.Clamp((sd.xp or 0) / SkillTrees:GetRequiredXP(level), 0, 1)
    self.XPShown = Lerp(FrameTime() * 6, self.XPShown, progress)

    draw.SimpleText("LVL " .. level, "VTX_Heading", PAD + 14, cy - 7, UI.Col.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    local xpX, xpW = PAD + 14, 150
    surface.SetDrawColor(20, 30, 40)
    surface.DrawRect(xpX, cy + 6, xpW, 6)
    surface.SetDrawColor(140, 90, 230)
    surface.DrawRect(xpX, cy + 6, math.floor(xpW * self.XPShown), 6)
    local xpText = maxed and "MAX LEVEL" or ((sd.xp or 0) .. " / " .. SkillTrees:GetRequiredXP(level) .. " XP")
    draw.SimpleText(xpText, "VTX_Small", xpX + xpW, cy - 7, UI.Col.textDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

    -- Training points + pips
    local saved, available = self:GetSavedPoints(), self:GetPoints()
    local px = xpX + xpW + 34
    draw.SimpleText("TRAINING POINTS AVAILABLE", "VTX_Rank", px, cy, UI.Col.gold, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    surface.SetFont("VTX_Rank")
    px = px + surface.GetTextSize("TRAINING POINTS AVAILABLE") + 10

    draw.RoundedBox(3, px, cy - 10, 30, 20, Color(4, 8, 12))
    UI.Outline(px, cy - 10, 30, 20, UI.Col.gold)
    draw.SimpleText(tostring(available), "VTX_Rank", px + 15, cy, UI.Col.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    px = px + 40

    local pipsRight = self.UndoBtn:GetPos() - 14
    local pipW, pipGap = 7, 3
    local fits = math.floor((pipsRight - px) / (pipW + pipGap))
    local shown = math.min(saved, MAX_PIPS, fits)
    for i = 1, shown do
        local x = px + (i - 1) * (pipW + pipGap)
        if i <= available then
            surface.SetDrawColor(UI.Col.gold)
            surface.DrawRect(x, cy - 8, pipW, 16)
        else
            UI.Outline(x, cy - 8, pipW, 16, UI.Col.staged)
        end
    end

    -- Toast
    local t = self.ToastUntil - RealTime()
    if self.ToastText and t > 0 then
        local a = math.Clamp(t, 0, 1) * 255
        draw.SimpleText(self.ToastText, "VTX_Body", w / 2, y - 6, Color(UI.Col.red.r, UI.Col.red.g, UI.Col.red.b, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
    end
end

-- Runs from Paint rather than Think: overriding Think would replace DFrame's own
-- Think, which handles dragging.
function MENU:UpdateButtons()
    if self.Saving and RealTime() > self.SavingUntil then self.Saving = false end

    local staged = next(self.Staged) ~= nil
    self.SaveBtn:SetDisabled(self.Saving or not staged)
    self.UndoBtn:SetDisabled(self.Saving or not staged)
    self.RespecBtn:SetDisabled(self.Saving)
    self.SaveBtn.Label = self.Saving and "SAVING..." or "SAVE"
end

function MENU:Paint(w, h)
    self:UpdateButtons()

    -- Outer frame
    surface.SetDrawColor(UI.Col.bg)
    surface.DrawRect(0, 0, w, h)
    UI.Outline(0, 0, w, h, UI.Col.frameEdge, 2)

    -- Title bar
    surface.SetDrawColor(UI.Col.titleBar)
    surface.DrawRect(2, 2, w - 4, TITLE_H - 2)
    surface.SetMaterial(UI.Mat.gradDown)
    surface.SetDrawColor(UI.Alpha(UI.Col.frameEdge, 60))
    surface.DrawTexturedRect(2, 2, w - 4, TITLE_H - 2)
    surface.SetDrawColor(UI.Col.frameEdge)
    surface.DrawRect(0, TITLE_H, w, 1)

    local title = "SKILL TREE"
    if self.TreeName then title = title .. " - " .. string.upper(self.TreeName) end
    draw.SimpleText(title, "VTX_Title", w / 2, TITLE_H / 2, UI.Col.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    if not self.TreeName then
        draw.SimpleText("No skill trees are available for your unit.", "VTX_Body", w / 2, h / 2, UI.Col.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    self:PaintBottomBar(w, h)
    return true
end

vgui.Register("VTX_SkillMenu", MENU, "DFrame")
