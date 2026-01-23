surface.CreateFont("SkillTree_Title", { font = "Roboto", size = 24, weight = 800 })
surface.CreateFont("SkillTree_Sub", { font = "Roboto", size = 16, weight = 400 })

local frame, layout, lastCategory, scroll

-- This function clears the layout and shows categories
local function ShowCategories()
    if not IsValid(layout) then return end
    layout:Clear()
    if IsValid(frame.backBtn) then frame.backBtn:SetVisible(false) end


    layout:GetParent():InvalidateLayout(true)

    local wide = layout:GetWide()
    if wide < 100 then
        wide = frame:GetWide() - 40
    else
        wide = wide - 20
    end

    -- Loop through the top-level keys (Combat, Utility, etc.)
    for catName, catData in pairs(SkillTrees.Tree) do
        -- Access Check
        if catData.Teams and not table.HasValue(catData.Teams, LocalPlayer():Team()) then continue end

        local catBtn = layout:Add("DButton")
        catBtn:SetSize(wide , 60)
        catBtn:SetText("")
        catBtn.Paint = function(self, w, h)
            local col = self:IsHovered() and Color(60, 60, 70) or Color(40, 40, 50)
            draw.RoundedBox(4, 0, 0, w, h, col)
            draw.SimpleText(catName:upper(), "SkillTree_Sub", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        -- When clicked, pass the WHOLE catData table to the next function
        catBtn.DoClick = function() 
            surface.PlaySound("buttons/lightswitch2.wav")
            ShowSkills(catName, catData.Skills) 
        end
    end
    lastCategory = nil
end

-- This function clears the layout and shows skills
function ShowSkills(catName, skillsTable)
    if not IsValid(layout) or not IsValid(scroll) then return end
    lastCategory = catName
    layout:Clear()
    if IsValid(frame.backBtn) then 
        frame.backBtn:SetVisible(true) 
        frame.backBtn:MoveToFront()
    end

    local totalWide = layout:GetWide()
    if totalWide < 100 then totalWide = frame:GetWide() - 40 end

    local cardWide = (totalWide - 20) / 2
    local scrollPos = scroll:GetVBar():GetScroll()
    layout:Clear()

    -- Now we loop through the specific skills we passed in
    for skillID, info in pairs(skillsTable) do
        local card = layout:Add("DButton")
        card:SetSize(cardWide, 80)
        card:SetText("")
        
        card.Paint = function(self, w, h)            
            local plyData = LocalPlayer().SkillData
            local curLevel = (plyData and plyData.skills[skillID]) or 0

            local isLocked=  false 
            local reqName = ""

            if info.requiremnet then
                local reqInfo = SkillTrees:GetSkill(info.requirement)
                local palyerReqlevel = plyData.skills[info.requirement] or 0
                local targetMax = (reqInfo and reqInfo.maxLevel) or 1
                
                reqName = reqInfo and reqInfo.name or info.requirement

                if playerReqLevle < targetMax then
                    isLocked = true 
                end
            end

            local bGColor = isLocked and Color(30,30,30) or Color(45,45,50)
            local titleColor = isLocked and Color(120,120,120) or Color(255,255,255)

            if self:IsHovered() and not isLocked then
                bGColor = Color(60,60,65)
            end

            draw.RoundedBox(4, 0, 0, w, h, bGColor)  
            draw.SimpleText(info.name, "SkillTree_Sub", 10, 10, titleColor)

            if isLocked then
                draw.SimpleText("LOCKED: MAX " .. reqName, "DermaDefault", 12, 32, Color(200,50,50))
            else
                draw.SimpleText(info.description, "DermaDefault", 10, 35, Color(180, 180, 180))
            end
            draw.SimpleText("Lvl ".. curLevel .. "/" .. (info.maxLevel or 1), "DermaDefault", 12, h-18, Color(120,120,120))
            draw.SimpleText(info.price .. " PTS", "DermaDefault", w-12, h-18, Color(120,120,120),TEXT_ALIGN_RIGHT)
        end
        
        card.DoClick = function()
            local plyData = LocalPlayer().SkillData or {skills = {}}
            local curLevel = plyData.skills[skillID] or 0
            local maxLevel = info.maxLevel or 1
            local cost = info.price or 1
            local currentPoints = plyData.points or 0

            if curLevel >= maxLevel then
                surface.PlaySound("buttons/button10.wav")
                return 
            end
            if cost > currentPoints then
                surface.PlaySound("buttons/button10.wav")
                chat.AddText(Color(255,50,50),"[Skills] You need" .. (cost-currentPoints) .. "more points")
                return 
            end
            if info.requirement then
                local reqInfo = SkillTrees:GetSkill(info.requirement)
                if reqInfo then
                    local playerReqLevel = plyData.skills[info.requirement] or 0
                    local targetMax = (reqInfo and reqInfo.maxLevel) or 1
                    if info.requirement and playerReqLevel < targetMax then
                        surface.PlaySound("buttons/button10.wav")
                        chat.AddText(Color(255,50,50), "You must max out ".. reqInfo.name .. " first!")
                        return 
                    end
                end
            end         

            surface.PlaySound("buttons/button14.wav")
            net.Start("vtx_skills_purchase")
                net.WriteString(skillID)
            net.SendToServer()
        end
    end
    scroll:GetVBar():SetScroll(scrollPos)
    lastCategory = catName
end

local function OpenSkillMenu()
    local lp = LocalPlayer() 

    frame = vgui.Create("DFrame")
    frame:SetSize(ScrW() * 0.6, ScrH() * 0.7)
    frame:SetTitle("")
    frame:Center()
    frame:MakePopup()

    frame:ShowCloseButton(false)
    frame:SetDraggable(true)

    frame.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(20, 20, 25, 255))
        -- Header Bar
        draw.RoundedBoxEx(8, 0, 0, w, 50, Color(35, 35, 40, 255), true, true, false, false)
        draw.SimpleText("SKILL PROGRESSION", "SkillTree_Title", 20, 30, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        local data = lp.SkillData
        local plyPoints = (data and data.points) or 0
        draw.SimpleText("POINTS: " .. plyPoints, "SkillTree_Sub", w - 60, 30, Color(100, 255, 100), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    local closeBtn = vgui.Create("DButton", frame)
    closeBtn:SetSize(40, 40)
    closeBtn:SetPos(frame:GetWide() - 45, 10)
    closeBtn:SetText("")
    closeBtn.Paint = function(self, w,h)
        if self:IsHovered() then
            draw.RoundedBox(4,0,0,w,h,Color(200,50,50))
        end
        draw.SimpleText("X","SkillTree_Title",w/2,h/2, Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    end
    closeBtn.DoClick = function() frame:Close() end

    frame.backBtn = vgui.Create("DButton", frame)
    frame.backBtn:SetSize(80, 26)
    frame.backBtn:SetPos((frame:GetWide() /2) -40, 12)
    frame.backBtn:SetText("")
    frame.backBtn:SetVisible(false)
    frame.backBtn.Paint = function(self, w, h)
        local col = self:IsHovered() and Color(80,80,100) or Color(50,50,60)
        draw.RoundedBox(4, 0, 0, w, h, col)
        draw.SimpleText("< BACK", "DermaDefaultBold", w/2, h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    frame.backBtn.DoClick = function()
        ShowCategories()
        frame.backBtn:SetVisible(false)
    end

    scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    scroll:DockMargin(20, 60, 20, 20)

    layout = vgui.Create("DIconLayout", scroll)
    layout:Dock(TOP)
    layout:SetSpaceY(10)
    layout:SetSpaceX(15)
    layout:InvalidateParent()
    scroll:InvalidateLayout()

    ShowCategories()
end

concommand.Add("vtx_skills_menu", OpenSkillMenu)

net.Receive("vtx_skills_sync", function()
    local data = net.ReadTable()
    LocalPlayer().SkillData = data
    if IsValid(frame) then
        if lastCategory then
            ShowSkills(lastCategory, SkillTrees.Tree[lastCategory].Skills)
        else
            ShowCatagories()
        end
    end
    print("[Vortex] UI Refreshed")
end)