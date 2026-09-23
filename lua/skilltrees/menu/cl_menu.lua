-- Opening and closing the skill window. The window remembers the last tree you looked at.

function SkillTrees:OpenMenu()
    if IsValid(self.MenuPanel) then
        self.MenuPanel:MakePopup()
        return
    end

    local w = math.min(math.Clamp(ScrW() * 0.9, 900, 1280), ScrW() - 20)
    local h = math.min(math.Clamp(ScrH() * 0.85, 600, 820), ScrH() - 20)

    local menu = vgui.Create("VTX_SkillMenu")
    menu:SetSize(w, h)
    menu:Center()
    menu:MakePopup()
    menu:SelectTree(menu:DefaultTree(self.UI.LastTree))

    self.MenuPanel = menu
end

function SkillTrees:CloseMenu()
    if IsValid(self.MenuPanel) then self.MenuPanel:Remove() end
end

-- Old global entry point, kept for anything that still calls it
function OpenSkillMenu()
    SkillTrees:OpenMenu()
end
