surface.CreateFont("SkillTree_Title", { font = "Roboto", size = 24, weight = 800 })
surface.CreateFont("SkillTree_Sub", { font = "Roboto", size = 16, weight = 400 })

-- We define these variables outside so all functions can see them
local frame, layout

local function ShowCategories()
    if not IsValid(layout) then return end
    layout:Clear()
    
    local categories = {}
    for _, info in pairs(SkillTrees.Skills) do
        if info.category and not table.HasValue(categories, info.category) then
            table.insert(categories, info.category)
        end
    end

    for _, cat in ipairs(categories) do
        local catBtn = layout:Add("DButton")
        catBtn:SetSize(layout:GetWide(), 50)
        catBtn:SetText("")
        catBtn.Paint = function(self, w, h)
            local col = self:IsHovered() and Color(80, 80, 90) or Color(50, 50, 60)
            draw.RoundedBox(4, 0, 0, w, h, col)
            draw.SimpleText(cat:upper(), "SkillTree_Sub", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        catBtn.DoClick = function() 
            surface.PlaySound("buttons/lightswitch2.wav")
            ShowSkills(cat) 
        end
    end
end

-- We use a regular "function" name here to avoid the '<name> expected' error
function ShowSkills(catName)
    if not IsValid(layout) then return end
    layout:Clear()

    local lp = LocalPlayer()
    local skillData = lp.SkillData or {skills = {}}

    for id, info in pairs(SkillTrees.Skills) do
        if info.category ~= catName then continue end

        local card = layout:Add("DButton")
        card:SetSize(layout:GetWide() / 2 - 5, 80)
        card:SetText("")

        card.Paint = function(self, w, h)
            local bgColor = Color(45, 45, 50)
            if self:IsHovered() then bgColor = Color(60, 60, 70) end
            
            -- Check Requirements
            local ownedReq = skillData.skills[info.requirement or ""] or 0
            local isLocked = info.requirement and ownedReq <= 0

            draw.RoundedBox(4, 0, 0, w, h, bgColor)
            
            local nameCol = isLocked and Color(150, 150, 150) or Color(255, 255, 100)
            draw.SimpleText(info.name, "SkillTree_Sub", 10, 10, nameCol)
            draw.SimpleText(info.description, "DermaDefault", 10, 30, Color(200, 200, 200))

            if isLocked then
                draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, 150))
                draw.SimpleText("LOCKED", "SkillTree_Sub", w - 10, h - 10, Color(255, 50, 50), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
            end
        end

        card.DoClick = function()
            RunConsoleCommand("vtx_buy_skill", id)
            surface.PlaySound("buttons/button14.wav")
        end
    end

    -- Back Button
    local back = layout:Add("DButton")
    back:SetSize(layout:GetWide(), 30)
    back:SetText("BACK TO CATEGORIES")
    back.DoClick = function() ShowCategories() end
end

local function OpenSkillMenu()
    local lp = LocalPlayer()
    local plyPoints = (lp.SkillData and lp.SkillData.points) or 0

    frame = vgui.Create("DFrame")
    frame:SetSize(ScrW() * 0.4, ScrH() * 0.6)
    frame:SetTitle("")
    frame:Center()
    frame:MakePopup()
    
    frame.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(30, 30, 35, 250))
        draw.SimpleText("SKILL PROGRESSION", "SkillTree_Title", 15, 25, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        
        -- Fixed Points alignment (lower and right-aligned)
        draw.SimpleText("POINTS: " .. plyPoints, "SkillTree_Sub", w - 15, 25, Color(100, 255, 100), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    scroll:DockMargin(10, 40, 10, 10)

    layout = vgui.Create("DIconLayout", scroll)
    layout:Dock(FILL)
    layout:SetSpaceX(10)
    layout:SetSpaceY(10)

    ShowCategories()
end

concommand.Add("vtx_skills_menu", OpenSkillMenu)