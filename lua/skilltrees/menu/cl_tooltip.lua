-- Hover card for a skill node. Content is rebuilt every frame from live data so it stays
-- correct while you stage points with the cursor still on the node.
local UI = SkillTrees.UI
local TIP = {}

local WIDTH = 280
local PAD   = 12

function TIP:Init()
    self:SetWide(WIDTH)
    self:SetMouseInputEnabled(false)
    self:SetDrawOnTop(true)
    self.Rows = {}
end

function TIP:SetNode(node)
    self.Node = node
    self:Rebuild()
    self:Reposition()
end

local function effectText(info, level)
    local parts = {}
    for stat, amount in SortedPairs(info.buffs or {}) do
        local def = SkillTrees.StatLabels[stat]
        table.insert(parts, (def and def.label or stat) .. " " .. SkillTrees:FormatStat(stat, amount * level))
    end
    return table.concat(parts, ", ")
end

-- Rows are { text, font, color, gap? }; wrapped and measured here, drawn in Paint
function TIP:Rebuild()
    local node = self.Node
    if not IsValid(node) then return end

    local info = node.Info
    local menu = node.Menu
    local status, cur, max, staged = node:GetState()
    local rows = {}
    local function add(text, font, col, gap)
        for i, line in ipairs(UI.Wrap(text, font, WIDTH - PAD * 2)) do
            table.insert(rows, { line, font, col, i == 1 and gap or 0 })
        end
    end

    local rankText = "Rank " .. cur .. "/" .. max
    if staged > 0 then rankText = rankText .. "  (+" .. staged .. " unsaved)" end
    self.Title = info.name
    self.Rank = rankText
    self.Status = status

    add(info.description or "", "VTX_Body", UI.Col.text, 8)

    if info.buffs and next(info.buffs) then
        if cur > 0 then add("Current: " .. effectText(info, cur), "VTX_Small", UI.Col.green, 8) end
        if cur < max then add("Next rank: " .. effectText(info, cur + 1), "VTX_Small", UI.Col.staged, cur > 0 and 2 or 8) end
    end

    for i, att in ipairs(info.unlocks or {}) do
        local atttbl = ArcCW and ArcCW.AttachmentTable and ArcCW.AttachmentTable[att]
        add("Unlocks attachment: " .. (atttbl and atttbl.PrintName or att), "VTX_Small", UI.Col.gold, i == 1 and 8 or 2)
    end

    local price = info.price or 1
    add("Cost: " .. price .. " point" .. (price == 1 and "" or "s") .. " per rank", "VTX_Small", UI.Col.textDim, 8)

    if node.Interactive then
        if status ~= "maxed" then
            local ok, reason = SkillTrees:CanAddLevel(LocalPlayer(), menu:GetSkills(), menu:GetPoints(), node.SkillID)
            if not ok then add(reason, "VTX_Small", UI.Col.red, 6) end
        end
        add("Left-click: add rank   Right-click: remove unsaved rank", "VTX_Small", UI.Col.textFaint, 8)
    else
        add("Preview only - your unit can't learn this tree.", "VTX_Small", UI.Col.red, 6)
    end

    self.Rows = rows

    local h = PAD + 20 + 16
    for _, r in ipairs(rows) do h = h + r[4] + draw.GetFontHeight(r[2]) end
    self:SetTall(h + PAD)
end

-- Beside the node, flipped/clamped to stay inside the menu
function TIP:Reposition()
    local node, parent = self.Node, self:GetParent()
    if not IsValid(node) or not IsValid(parent) then return end

    local nx, ny = parent:ScreenToLocal(node:LocalToScreen(0, 0))
    local x = nx + node:GetWide() + 12
    if x + self:GetWide() > parent:GetWide() - 8 then x = nx - self:GetWide() - 12 end
    local y = math.Clamp(ny - 10, 8, parent:GetTall() - self:GetTall() - 8)
    self:SetPos(x, y)
end

function TIP:Think()
    if not IsValid(self.Node) then self:SetVisible(false) return end
    self:Rebuild()
    self:Reposition()
end

function TIP:Paint(w, h)
    local node = self.Node
    if not IsValid(node) then return end
    local col = node.TreeColor

    draw.RoundedBox(4, 0, 0, w, h, Color(6, 12, 18, 250))
    UI.Outline(0, 0, w, h, UI.Alpha(col, 200))
    surface.SetDrawColor(col)
    surface.DrawRect(0, 0, w, 3)

    local statusCol = ({ maxed = UI.Col.gold, partial = UI.Col.green, available = col, locked = UI.Col.textDim })[self.Status]
    draw.SimpleText(self.Title, "VTX_Heading", PAD, PAD, col)
    draw.SimpleText(self.Rank, "VTX_Small", PAD, PAD + 20, UI.Col.textDim)
    draw.SimpleText(string.upper(self.Status or ""), "VTX_Rank", w - PAD, PAD + 3, statusCol, TEXT_ALIGN_RIGHT)

    local y = PAD + 36
    for _, r in ipairs(self.Rows) do
        y = y + r[4]
        draw.SimpleText(r[1], r[2], PAD, y, r[3])
        y = y + draw.GetFontHeight(r[2])
    end
end

vgui.Register("VTX_SkillTooltip", TIP, "DPanel")
