-- One skill icon in a tree. Reads everything live from the owning menu each frame,
-- so it never needs rebuilding when data changes.
local UI = SkillTrees.UI
local NODE = {}

local BADGE_H = 14

function NODE:Init()
    self:SetText("")
    self.FlashUntil = 0
end

function NODE:Setup(menu, skillID, treeColor, interactive)
    self.Menu = menu
    self.SkillID = skillID
    self.Info = SkillTrees:GetSkill(skillID)
    self.TreeColor = treeColor
    self.Interactive = interactive
    self.IconMat = UI.SkillIcon(self.Info)
    self.LastRank = menu:GetSkills()[skillID] or 0
end

-- Size of the icon square; the rank badge hangs below it
function NODE:IconSize()
    return self:GetWide()
end

function NODE:GetState()
    local skills = self.Menu:GetSkills()
    local status, cur, max = SkillTrees:GetSkillStatus(skills, self.SkillID)
    local saved = self.Menu:GetSaved()[self.SkillID] or 0
    local canAdd = self.Interactive and SkillTrees:CanAddLevel(LocalPlayer(), skills, self.Menu:GetPoints(), self.SkillID)
    return status, cur, max, cur - saved, canAdd
end

function NODE:Think()
    local rank = self.Menu:GetSkills()[self.SkillID] or 0
    if rank > self.LastRank then self.FlashUntil = RealTime() + 0.45 end
    self.LastRank = rank
end

function NODE:Paint(w)
    local s = self:IconSize()
    local status, cur, max, staged, canAdd = self:GetState()
    local col = self.TreeColor
    local hovered = self:IsHovered()
    local locked = status == "locked"

    local edge
    if status == "maxed" then edge = UI.Col.gold
    elseif locked then edge = UI.Col.locked
    else edge = col end

    -- Glow: pulses on nodes you can put a point into right now
    if canAdd then
        local pulse = 0.5 + 0.5 * math.sin(RealTime() * 4)
        draw.RoundedBox(6, 0, 0, s, s, UI.Alpha(col, 30 + 50 * pulse))
    end

    -- Frame and face
    draw.RoundedBox(4, 2, 2, s - 4, s - 4, UI.Alpha(edge, hovered and 255 or (locked and 140 or 210)))
    draw.RoundedBox(3, 4, 4, s - 8, s - 8, locked and Color(14, 18, 22) or Color(18, 28, 38))

    surface.SetMaterial(UI.Mat.gradDown)
    surface.SetDrawColor(col.r, col.g, col.b, locked and 10 or (hovered and 70 or 40))
    surface.DrawTexturedRect(4, 4, s - 8, s - 8)

    -- Icon (or initials when there's no icon)
    local inset = math.floor(s * 0.22)
    if self.IconMat then
        surface.SetMaterial(self.IconMat)
        surface.SetDrawColor(locked and Color(90, 90, 90, 120) or Color(255, 255, 255))
        surface.DrawTexturedRect(inset, inset, s - inset * 2, s - inset * 2)
    else
        draw.SimpleText(UI.Initials(self.Info.name), "VTX_Initial", s / 2, s / 2, locked and UI.Col.textFaint or UI.Col.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- Rank-up flash
    local flash = self.FlashUntil - RealTime()
    if flash > 0 then
        draw.RoundedBox(4, 2, 2, s - 4, s - 4, Color(255, 255, 255, 200 * flash / 0.45))
    end

    -- Rank badge "cur/max" centred under the icon, like SWTOR
    local rankCol = UI.Col.textDim
    if staged > 0 then rankCol = UI.Col.staged
    elseif status == "maxed" then rankCol = UI.Col.gold
    elseif cur > 0 then rankCol = UI.Col.green
    elseif locked then rankCol = UI.Col.textFaint end

    local text = cur .. "/" .. max
    surface.SetFont("VTX_Rank")
    local tw = surface.GetTextSize(text)
    local bw = tw + 10
    local bx, by = (w - bw) / 2, s - BADGE_H / 2 - 2
    draw.RoundedBox(3, bx, by, bw, BADGE_H, Color(4, 8, 12, 245))
    UI.Outline(bx, by, bw, BADGE_H, UI.Alpha(staged > 0 and UI.Col.staged or edge, 160))
    draw.SimpleText(text, "VTX_Rank", w / 2, by + BADGE_H / 2, rankCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    return true
end

function NODE:OnCursorEntered()
    self.Menu:ShowTooltip(self)
end

function NODE:OnCursorExited()
    self.Menu:HideTooltip(self)
end

function NODE:DoClick()
    if self.Interactive then self.Menu:Stage(self.SkillID) end
end

function NODE:DoRightClick()
    if self.Interactive then self.Menu:Unstage(self.SkillID) end
end

vgui.Register("VTX_SkillNode", NODE, "DButton")

SkillTrees.UI.NODE_BADGE_H = BADGE_H
