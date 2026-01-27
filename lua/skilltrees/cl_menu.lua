surface.CreateFont("SkillTree_Title", { font = "Roboto", size = 22, weight = 800 })
surface.CreateFont("SkillTree_Sub", { font = "Roboto", size = 14, weight = 400 })

local MainMenu, layout, lastCategory, scroll

-- This function clears the layout and shows categories
local function ShowCategories()
    if not IsValid(MainMenu) or not IsValid(layout) then return end
    layout:Clear()
    if IsValid(MainMenu.backBtn) then MainMenu.backBtn:SetVisible(false) end
    
    layout:GetParent():InvalidateLayout(true)
    local wide = layout:GetWide()
    if wide <= 100 then wide = MainMenu:GetWide() - 40 else wide = wide - 20 end

    -- Local variables for comparison
    local myTeam = LocalPlayer():Team()
    local myJobName = team.GetName(myTeam)
    local myJobTable = LocalPlayer():getJobTable()
    local myCategory = myJobTable and myJobTable.category or "Unknown"
    local myRank = LocalPlayer():GetUserGroup()
    local myID = LocalPlayer():SteamID()
    

    -- Ensure the base table exists before looping
    if not SkillTrees or not SkillTrees.Tree then return end

    for catName, catData in pairs(SkillTrees.Tree) do
        -- 1. Default Access (If no Teams table is defined, everyone sees it)
        local isDefaultTree = (catData.Teams == nil)
        local hasAccess = false

        -- 2. Team Access (Manual Loop to avoid table.HasValue crash)
        if catData.Teams and istable(catData.Teams) then
            for _, val in pairs(catData.Teams) do
                -- Checks for BOTH the Team ID number and the Job Name string
                if val == myTeam or val == myJobName then
                    hasAccess = true
                    break
                end
            end
        end
        if catData.MRSGroup and MRS then 
            local myMRSGroup = MRS.GetNWdata(LocalPlayer(), "Group")
            if myMRSGroup == catData.MRSGroup then
                hasAccess = true
            end
        end

        -- 3. Category Access
        local hasCategoryAccess = (catName == myCategory)
        
        -- 4. Rank Access (Safe Manual Loop)
        if catData.Ranks and istable(catData.Ranks) then
            for _, r in pairs(catData.Ranks) do
                if r == myRank then hasAccess = true break end
            end
        end

        -- 5. Direct SteamID Access (Safe Manual Loop)
        if catData.SteamIDs and istable(catData.SteamIDs) then
            for _, id in pairs(catData.SteamIDs) do
                if id == myID then hasAccess = true break end
            end
        end

        -- Final Logic Gate: If user fails ALL checks, skip this category
        if not (isDefaultTree or hasAccess) then 
            continue 
        end

        -- Create the UI Button
        local catBtn = layout:Add("DButton")
        catBtn:SetSize(wide, 60)
        catBtn:SetText("")
        catBtn.Paint = function(self, w, h)
            local col = self:IsHovered() and Color(60, 60, 70) or Color(40, 40, 50)
            draw.RoundedBox(4, 0, 0, w, h, col)
            
            local textColor = catData.Color or Color(255, 255, 255)
            draw.SimpleText(catName:upper(), "SkillTree_Sub", w/2, h/2, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        catBtn.DoClick = function() 
            surface.PlaySound("buttons/lightswitch2.wav")
            -- Pass an empty table if Skills is nil to prevent the next menu from crashing
            ShowSkills(catName, catData.Skills or {}) 
        end
    end
    lastCategory = nil
end

-- This function clears the layout and shows skills
function ShowSkills(catName, skillsTable)
    if not IsValid(layout) or not IsValid(scroll) then return end
    lastCategory = catName
    layout:Clear()
    if IsValid(MainMenu.backBtn) then 
        MainMenu.backBtn:SetVisible(true) 
        MainMenu.backBtn:MoveToFront()
    end

    local totalWide = layout:GetWide()
    if totalWide < 100 then totalWide = MainMenu:GetWide() - 40 end

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
                chat.AddText(Color(255,50,50),"[Skills] You need " .. (cost-currentPoints) .. " more point(s)")
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

function OpenSkillMenu()
    local lp = LocalPlayer()
    local sd = LocalPlayer().SkillData or {}
    local curLvl = sd.level or 1
    local reqXP = math.floor(100 * math.pow(curLvl, 1.5)) 

    if IsValid(MainMenu) then MainMenu:Remove() end

    MainMenu = vgui.Create("DFrame")
    MainMenu:SetSize(ScrW() * 0.6, ScrH() * 0.7)
    MainMenu:SetTitle("")
    MainMenu:Center()
    MainMenu:MakePopup()

    MainMenu:ShowCloseButton(false)
    MainMenu:SetDraggable(true)

    MainMenu.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(20, 20, 25, 255))
        -- Header Bar
        draw.RoundedBoxEx(8, 0, 0, w, 50, Color(35, 35, 40, 255), true, true, false, false)
        draw.SimpleText("SKILL PROGRESSION", "SkillTree_Title", 20, 30, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        local data = lp.SkillData
        local plyPoints = (data and data.points) or 0
        local curXP = sd.xp or 0
        local boxW, boxH = 240, 70
        local posX, posY = w - boxW -20, h - boxH -20
        draw.RoundedBox(8, posX, posY, boxW, boxH, Color(30,30,35,200))
        surface.SetDrawColor(60, 60, 65, 255)
        surface.DrawOutlinedRect(posX,posY,boxW,boxH)
        draw.SimpleText("POINTS: " .. plyPoints, "SkillTree_Sub", w - 60, 30, Color(100, 255, 100), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        draw.SimpleText("LEVEL " .. curLvl, "SkillTree_Title", posX + 15, posY +15, Color(150,150,150), TEXT_ALIGN_LEFT)
        local xpText = curXP .. " / " .. reqXP .. "XP"
        draw.SimpleText(xpText, "SkillTree_Title", posX + boxW - 15, posY + 15, Color(200,200,200),TEXT_ALIGN_RIGHT)
        local barY = posY + 35

        local barW, barH = boxW -30, 12
        local barX, barY = posX + 15, posY + boxH -22
        local progress = math.Clamp(curXP / reqXP, 0, 1)
        draw.RoundedBox(4, barX, barY, barW, barH, Color(0,0,0,150))
        draw.RoundedBox(4, barX, barY, barW * progress, barH, Color(155,89,182))
    end

    local closeBtn = vgui.Create("DButton", MainMenu)
    closeBtn:SetSize(40, 40)
    closeBtn:SetPos(MainMenu:GetWide() - 45, 10)
    closeBtn:SetText("")
    closeBtn.Paint = function(self, w,h)
        if self:IsHovered() then
            draw.RoundedBox(4,0,0,w,h,Color(200,50,50))
        end
        draw.SimpleText("X","SkillTree_Title",w/2,h/2, Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    end
    closeBtn.DoClick = function(self) 
       MainMenu:Close() 
    end

    MainMenu.backBtn = vgui.Create("DButton", MainMenu)
    MainMenu.backBtn:SetSize(80, 26)
    MainMenu.backBtn:SetPos((MainMenu:GetWide() /2) -40, 12)
    MainMenu.backBtn:SetText("")
    MainMenu.backBtn:SetVisible(false)
    MainMenu.backBtn.Paint = function(self, w, h)
        local col = self:IsHovered() and Color(80,80,100) or Color(50,50,60)
        draw.RoundedBox(4, 0, 0, w, h, col)
        draw.SimpleText("< BACK", "DermaDefaultBold", w/2, h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    MainMenu.backBtn.DoClick = function()
        MainMenu.backBtn:SetVisible(false)
        ShowCategories()
    end

    scroll = vgui.Create("DScrollPanel", MainMenu)
    scroll:Dock(FILL)
    scroll:DockMargin(20, 60, 20, 20)

    layout = vgui.Create("DIconLayout", scroll)
    layout:Dock(TOP)
    layout:SetSpaceY(10)
    layout:SetSpaceX(15)
    layout:InvalidateParent()
    scroll:InvalidateLayout()

    local resetBtn = vgui.Create("DButton", MainMenu)
    resetBtn:SetSize(100,25)
    resetBtn:SetPos(10, MainMenu:GetTall()-35)
    resetBtn:SetText("")

    resetBtn.Paint = function(self, w, h)
        local col = self:IsHovered() and Color(150, 50, 50) or Color(100, 30, 30)
        draw.RoundedBox(4, 0, 0, w, h, col)
        draw.SimpleText("RESET SKILLS", "DermaDefault", w/2, h/2, Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    end

    resetBtn.DoClick = function ()
        Derma_Query(
            "Are you sure you want to reset all skills?",
            "Reset Confirmation",
            "Yes, Reset", function()
                net.Start("vtx_skills_reset")
                net.SendToServer()
            end,
            "No, Cancel", function() end
        )        
    end

    ShowCategories()
end

net.Receive("vtx_skills_menu", function()
    if IsValid(MainMenu) and MainMenu:IsVisible() then return end
    OpenSkillMenu()
end)

net.Receive("vtx_skills_sync", function()
    local data = net.ReadTable()
    LocalPlayer().SkillData = data
    if IsValid(MainMenu) then
        if lastCategory then
            ShowSkills(lastCategory, SkillTrees.Tree[lastCategory].Skills)
        else
            ShowCatagories()
        end
    end
    print("[Vortex] UI Refreshed")
end)