-- One column of the SWTOR-style window: a unit's base tree (interactive grid of skills) or a
-- specialisation (the same grid once it has skills, a "coming soon" placeholder until then). Built
-- once per tree selection; live data is read in Paint so it never rebuilds on sync.
local UI = SkillTrees.UI
local TREE = {}

local FOOTER_H = 30
local PAD_X    = 14
local PAD_TOP  = 18

-- Placeholder silhouette for unreleased specialisations: nodes per row
local GHOST_ROWS = { 2, 4, 3 }

function TREE:Init()
    self.Nodes = {}
end

-- kind: "base" or "spec". For "spec", `spec` is its config table and `specName` its key.
function TREE:Setup(menu, treeName, kind, spec, specName)
    self.Menu = menu
    self.TreeName = treeName
    self.Tree = SkillTrees.Tree[treeName]
    self.Color = self.Tree.Color or Color(155, 155, 165)
    self.Kind = kind
    self.Spec = spec
    self.SpecName = specName

    -- A specialisation with no skills yet stays a placeholder
    self.Live = kind == "base" or SkillTrees:SpecIsLive(treeName, specName)
    if not self.Live then return end

    local interactive = SkillTrees:CanAccessTree(LocalPlayer(), treeName)
    for id in pairs(SkillTrees:GetGroupSkills(treeName, specName)) do
        local node = vgui.Create("VTX_SkillNode", self)
        node:Setup(menu, id, self.Color, interactive)
        self.Nodes[id] = node
    end
end

function TREE:GridRect()
    return PAD_X, PAD_TOP, self:GetWide() - PAD_X * 2, self:GetTall() - PAD_TOP - FOOTER_H - 10
end

function TREE:CellCenter(row, col)
    local gx, gy, gw, gh = self:GridRect()
    local cw = gw / SkillTrees.TREE_COLS
    local rh = gh / SkillTrees.TREE_ROWS
    return gx + (col - 0.5) * cw, gy + (row - 0.5) * rh
end

function TREE:NodeSize()
    local _, _, gw, gh = self:GridRect()
    local cw = gw / SkillTrees.TREE_COLS
    local rh = gh / SkillTrees.TREE_ROWS
    return math.floor(math.Clamp(math.min(cw * 0.62, rh * 0.52), 34, 64))
end

function TREE:PerformLayout()
    local size = self:NodeSize()
    for id, node in pairs(self.Nodes) do
        local info = node.Info
        local cx, cy = self:CellCenter(info.row or 1, info.col or 1)
        node:SetSize(size, size + 6)
        node:SetPos(math.floor(cx - size / 2), math.floor(cy - size / 2))
    end
end

-- Elbow connector from the bottom of `from` to the top of `to`
local function connector(x1, y1, x2, y2, col)
    surface.SetDrawColor(col)
    if math.abs(y1 - y2) < 4 then
        UI.Rect(math.min(x1, x2), y1 - 1, math.abs(x2 - x1), 3)
        return
    end
    local midY = math.floor((y1 + y2) / 2)
    UI.Rect(x1 - 1, y1, 3, midY - y1)
    UI.Rect(math.min(x1, x2) - 1, midY - 1, math.abs(x2 - x1) + 3, 3)
    UI.Rect(x2 - 1, midY, 3, y2 - midY)
end

function TREE:PaintRows(w)
    local gx, gy, gw, gh = self:GridRect()
    local rh = gh / SkillTrees.TREE_ROWS
    local skills = self.Menu:GetSkills()

    for row = 2, SkillTrees.TREE_ROWS do
        local y = math.floor(gy + (row - 1) * rh)
        local need = SkillTrees:GetRowGate(row, self.TreeName, self.SpecName) - SkillTrees:SpentBelowRow(skills, self.TreeName, row, self.SpecName)
        local open = need <= 0

        surface.SetDrawColor(self.Color.r, self.Color.g, self.Color.b, open and 50 or 25)
        for x = gx, gx + gw, 8 do UI.Rect(x, y, 4, 1) end

        if not open then
            surface.SetDrawColor(0, 0, 0, 90)
            UI.Rect(gx - 4, y + 1, gw + 8, rh - 1)
            draw.SimpleText(need .. " MORE PT" .. (need == 1 and "" or "S"), "VTX_Rank", gx + gw, y + 8, UI.Col.gold, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end
end

function TREE:PaintConnectors()
    local skills = self.Menu:GetSkills()
    for id, node in pairs(self.Nodes) do
        local req = node.Info.requirement
        local parent = req and self.Nodes[req]
        if parent then
            local reqInfo = parent.Info
            local met = (skills[req] or 0) >= (reqInfo.maxLevel or 1)
            local px, py = parent:GetPos()
            local cx, cy = node:GetPos()
            local ps, cs = parent:IconSize(), node:IconSize()

            local x1, y1 = px + ps / 2, py + ps + 6
            local x2, y2 = cx + cs / 2, cy
            if (reqInfo.row or 1) == (node.Info.row or 1) then
                -- Same row: link the facing sides
                y1, y2 = py + ps / 2, cy + cs / 2
                if px < cx then x1, x2 = px + ps, cx else x1, x2 = px, cx + cs end
            end

            connector(x1, y1, x2, y2, met and self.Color or UI.Col.locked)
        end
    end
end

function TREE:PaintGhost(w, h)
    local _, gy, _, gh = self:GridRect()
    local size = self:NodeSize()
    for r, n in ipairs(GHOST_ROWS) do
        local _, cy = self:CellCenter(r, 1)
        local startCol = (SkillTrees.TREE_COLS - n) / 2
        for i = 1, n do
            local cx = self:CellCenter(r, startCol + i)
            UI.RoundBox(cx - size / 2, cy - size / 2, size, size, 6, Color(20, 26, 32), Color(40, 48, 56))
        end
    end

    -- Centre card
    local spec = self.Spec
    local level = (LocalPlayer().SkillData or {}).level or 1
    local unlock = spec.unlockLevel or SkillTrees.MaxLevel
    local cardW, cardH = math.min(w - 40, 240), 104
    local x, y = (w - cardW) / 2, gy + (gh - cardH) / 2
    UI.RoundBox(x, y, cardW, cardH, 8, Color(6, 10, 14), UI.Alpha(self.Color, 90))

    draw.SimpleText(string.upper(spec.name or "?"), "VTX_Heading", w / 2, y + 20, UI.Alpha(self.Color, 230), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    local lines = UI.Wrap(spec.description or "", "VTX_Small", cardW - 20)
    for i = 1, math.min(#lines, 2) do
        draw.SimpleText(lines[i], "VTX_Small", w / 2, y + 36 + (i - 1) * 14, UI.Col.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    local unlockText = level >= unlock and "UNLOCKED AT LEVEL " .. unlock or ("UNLOCKS AT LEVEL " .. unlock)
    draw.SimpleText(unlockText, "VTX_Rank", w / 2, y + 72, level >= unlock and UI.Col.green or UI.Col.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    if spec.comingSoon then
        draw.SimpleText("COMING SOON", "VTX_Rank", w / 2, y + 90, UI.Col.gold, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

function TREE:PaintFooter(w, h)
    local spent = 0
    local title, subtitle
    if self.Kind == "base" then
        spent = SkillTrees:GetTreeProgress(self.Menu:GetSkills(), self.TreeName)
        title, subtitle = self.TreeName, "Base Training"
    else
        if self.Live then spent = SkillTrees:GetTreeProgress(self.Menu:GetSkills(), self.TreeName, self.SpecName) end
        title, subtitle = self.Spec.name or "?", "Specialisation"
    end

    local y = h - FOOTER_H
    draw.RoundedBoxEx(UI.Radius - 1, 1, y, w - 2, FOOTER_H - 1, Color(0, 0, 0, 120), false, false, true, true)

    local box = 26
    UI.RoundBox(10, y + (FOOTER_H - 18) / 2, box, 18, 4, Color(4, 8, 12), UI.Alpha(self.Color, 150))
    draw.SimpleText(tostring(spent), "VTX_Rank", 10 + box / 2, y + FOOTER_H / 2, UI.Col.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    draw.SimpleText(title, "VTX_Heading", 44, y + FOOTER_H / 2, self.Kind == "base" and UI.Col.text or UI.Col.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    surface.SetFont("VTX_Heading")
    local tw = surface.GetTextSize(title)
    draw.SimpleText("(" .. subtitle .. ")", "VTX_Small", 44 + tw + 6, y + FOOTER_H / 2 + 1, UI.Col.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

-- What stops the player taking this specialisation right now (nil = it's open to them):
-- "chosen", the name of the other specialisation they committed to, or "level", the level it needs.
function TREE:SpecBlock()
    if self.Kind ~= "spec" or not self.Live then return nil end

    local held = SkillTrees:HeldSpec(self.Menu:GetSkills(), self.TreeName)
    if held and held ~= self.SpecName then return "chosen", held end

    local level = (LocalPlayer().SkillData or {}).level or 1
    local unlock = self.Spec.unlockLevel
    if unlock and level < unlock then return "level", unlock end
    return nil
end

function TREE:Paint(w, h)
    local isBase = self.Kind == "base"
    local live = self.Live
    UI.Panel(w, h, self.Color, UI.Alpha(self.Color, live and 140 or 60), live and 70 or 22)

    if live then
        self:PaintRows(w)
        self:PaintConnectors()
        if not isBase then
            local held = SkillTrees:HeldSpec(self.Menu:GetSkills(), self.TreeName)
            local tag = held == self.SpecName and "YOUR SPECIALISATION" or "SPECIALISATION - CHOOSE ONE"
            draw.SimpleText(tag, "VTX_Small", w / 2, 8, held == self.SpecName and UI.Col.gold or UI.Col.textFaint, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    else
        self:PaintGhost(w, h)
    end

    self:PaintFooter(w, h)
end

-- Drawn over the nodes: dims a specialisation that's closed to the player and says why. It's only
-- paint, so the nodes underneath still show their tooltips.
function TREE:PaintOver(w, h)
    local block, detail = self:SpecBlock()
    if not block then return end

    local _, gy, _, gh = self:GridRect()
    local cardW, cardH = math.min(w - 40, 220), 56
    local x, y = (w - cardW) / 2, gy + (gh - cardH) / 2

    surface.SetDrawColor(0, 0, 0, 150)
    UI.Rect(2, 2, w - 4, h - FOOTER_H - 4)

    UI.RoundBox(x, y, cardW, cardH, 8, Color(6, 10, 14), UI.Alpha(block == "chosen" and UI.Col.red or self.Color, 160))
    if block == "chosen" then
        draw.SimpleText("LOCKED", "VTX_Heading", w / 2, y + 17, UI.Col.red, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("You chose " .. detail, "VTX_Small", w / 2, y + 36, UI.Col.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    else
        draw.SimpleText("UNLOCKS AT LEVEL " .. detail, "VTX_Heading", w / 2, y + 17, UI.Col.gold, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Pick one specialisation", "VTX_Small", w / 2, y + 36, UI.Col.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

vgui.Register("VTX_SkillTree", TREE, "DPanel")
