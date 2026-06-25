surface.CreateFont("VTX_Title",    { font = "Roboto", size = 22, weight = 800 })
surface.CreateFont("VTX_Sub",      { font = "Roboto", size = 14, weight = 500 })
surface.CreateFont("VTX_NodeName", { font = "Roboto", size = 13, weight = 700 })
surface.CreateFont("VTX_Small",    { font = "Roboto", size = 11, weight = 400 })
surface.CreateFont("VTX_Tiny",     { font = "Roboto", size = 10, weight = 600 })

local MainMenu
local NODE_W, NODE_H  = 142, 72
local COL_GAP, ROW_GAP = 68, 14
local TREE_PAD         = 24

-- Shared hover state written by node buttons, read by canvas Paint
local treeHover = {}

local COLS = {
    locked    = { bg = Color(22,22,27),   edge = Color(48,48,55),   text = Color(75,75,82),   bar = Color(48,48,55)    },
    available = { bg = Color(20,30,52),   edge = Color(52,96,178),  text = Color(170,205,255), bar = Color(52,96,178)   },
    partial   = { bg = Color(20,40,28),   edge = Color(50,148,76),  text = Color(155,238,175), bar = Color(50,148,76)   },
    maxed     = { bg = Color(26,50,22),   edge = Color(65,185,85),  text = Color(95,250,115),  bar = Color(65,185,85)   },
}

local function Trunc(s, n)
    if #s > n then return s:sub(1, n - 2) .. ".." end
    return s
end

local function GetSkillStatus(skillID, info, plyData)
    local skills = (plyData and plyData.skills) or {}
    local cur    = skills[skillID] or 0
    local max    = info.maxLevel or 1
    if info.requirement then
        local ri   = SkillTrees:GetSkill(info.requirement)
        local rmax = ri and ri.maxLevel or 1
        if (skills[info.requirement] or 0) < rmax then
            return "locked", cur, max
        end
    end
    if cur >= max then return "maxed",     cur, max end
    if cur  > 0  then return "partial",   cur, max end
    return "available", cur, max
end

local function BuildLayout(skillsTable)
    local parentOf, childrenOf = {}, {}
    for id, info in pairs(skillsTable) do
        local req = info.requirement
        if req and skillsTable[req] then
            parentOf[id] = req
            childrenOf[req] = childrenOf[req] or {}
            table.insert(childrenOf[req], id)
        end
    end

    -- BFS depth assignment
    local depth, queue = {}, {}
    for id in pairs(skillsTable) do
        if not parentOf[id] then
            depth[id] = 0
            table.insert(queue, id)
        end
    end
    local qi = 1
    while qi <= #queue do
        local id = queue[qi]
        for _, child in ipairs(childrenOf[id] or {}) do
            if not depth[child] then
                depth[child] = depth[id] + 1
                table.insert(queue, child)
            end
        end
        qi = qi + 1
    end

    -- Group by column, sort for stable layout
    local cols, maxDepth = {}, 0
    for id, d in pairs(depth) do
        cols[d] = cols[d] or {}
        table.insert(cols[d], id)
        if d > maxDepth then maxDepth = d end
    end
    for d = 0, maxDepth do
        if cols[d] then table.sort(cols[d]) end
    end

    -- Assign pixel positions (top-left of each node)
    local positions = {}
    local cW, cH   = 0, 0
    for d = 0, maxDepth do
        local col = cols[d] or {}
        local cx  = TREE_PAD + d * (NODE_W + COL_GAP)
        for row, id in ipairs(col) do
            local cy = TREE_PAD + (row - 1) * (NODE_H + ROW_GAP)
            positions[id] = { x = cx, y = cy }
            cW = math.max(cW, cx + NODE_W)
            cH = math.max(cH, cy + NODE_H)
        end
    end

    local connections = {}
    for id, info in pairs(skillsTable) do
        if info.requirement and positions[info.requirement] and positions[id] then
            table.insert(connections, { from = info.requirement, to = id })
        end
    end

    return positions, connections, cW + TREE_PAD, cH + TREE_PAD
end

local function ShowTree(catName, catData, container)
    container:Clear()
    treeHover = {}

    local skills                        = catData.Skills or {}
    local positions, connections, cW, cH = BuildLayout(skills)

    -- Scroll area (leaves room for detail strip)
    local DETAIL_H = 72
    local scroll   = vgui.Create("DScrollPanel", container)
    scroll:SetPos(0, 0)
    scroll:SetSize(container:GetWide(), container:GetTall() - DETAIL_H - 1)

    local vbar = scroll:GetVBar()
    vbar:SetWide(5)
    vbar.Paint         = function(_, w, h) draw.RoundedBox(0, 0, 0, w, h, Color(18, 18, 22)) end
    vbar.btnUp.Paint   = function() end
    vbar.btnDown.Paint = function() end
    vbar.btnGrip.Paint = function(_, w, h) draw.RoundedBox(3, 1, 1, w - 2, h - 2, Color(55, 55, 70)) end

    -- Canvas that holds drawing + invisible node buttons
    local canvas = vgui.Create("DPanel", scroll)
    canvas:SetSize(math.max(cW, scroll:GetWide()), math.max(cH, scroll:GetTall()))
    canvas.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(15, 15, 19))

        local pd = LocalPlayer().SkillData or {}

        -- Connections
        for _, conn in ipairs(connections) do
            local fp, tp = positions[conn.from], positions[conn.to]
            if not fp or not tp then continue end
            local fromSt  = GetSkillStatus(conn.from, skills[conn.from], pd)
            local unlocked = (fromSt == "maxed")
            local col      = unlocked and Color(55, 148, 76, 210) or Color(42, 42, 50, 200)
            surface.SetDrawColor(col)
            local x1 = fp.x + NODE_W
            local y1 = fp.y + NODE_H / 2
            local x2 = tp.x
            local y2 = tp.y + NODE_H / 2
            local mx = math.floor((x1 + x2) / 2)
            surface.DrawLine(x1, y1, mx, y1)
            surface.DrawLine(mx, y1, mx, y2)
            surface.DrawLine(mx, y2, x2, y2)
            -- Arrow tip
            surface.DrawLine(x2, y2, x2 - 7, y2 - 4)
            surface.DrawLine(x2, y2, x2 - 7, y2 + 4)
        end

        -- Nodes
        for id, pos in pairs(positions) do
            local info = skills[id]
            if not info then continue end
            local st, cur, max = GetSkillStatus(id, info, pd)
            local c     = COLS[st]
            local hov   = treeHover[id]
            local x, y  = pos.x, pos.y

            -- Border (1px via slightly larger background box)
            local ec = c.edge
            draw.RoundedBox(8, x - 1, y - 1, NODE_W + 2, NODE_H + 2, hov and Color(ec.r, ec.g, ec.b, 255) or Color(ec.r, ec.g, ec.b, 160))
            -- Shadow
            draw.RoundedBox(8, x + 2, y + 3, NODE_W, NODE_H, Color(0, 0, 0, 55))
            -- Background
            local bg = c.bg
            draw.RoundedBox(8, x, y, NODE_W, NODE_H, hov and Color(bg.r + 10, bg.g + 10, bg.b + 10) or bg)

            -- Name
            draw.SimpleText(info.name, "VTX_NodeName", x + NODE_W / 2, y + 14, c.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            -- Description (truncated)
            local descCol = Color(c.text.r, c.text.g, c.text.b, 130)
            draw.SimpleText(Trunc(info.description, 26), "VTX_Tiny", x + NODE_W / 2, y + 30, descCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            -- XP bar
            local bx, by, bw, bh2 = x + 8, y + NODE_H - 18, NODE_W - 16, 4
            draw.RoundedBox(2, bx, by, bw, bh2, Color(0, 0, 0, 100))
            local prog = max > 0 and math.Clamp(cur / max, 0, 1) or 0
            if prog > 0 then
                draw.RoundedBox(2, bx, by, math.floor(bw * prog), bh2, c.bar)
            end

            -- Bottom-left: level
            local lvlStr = st == "locked" and "LOCKED" or ("Lv " .. cur .. "/" .. max)
            local lvlCol = st == "locked" and Color(58, 58, 64) or Color(c.bar.r, c.bar.g, c.bar.b, 200)
            draw.SimpleText(lvlStr, "VTX_Tiny", x + 7, y + NODE_H - 28, lvlCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            -- Top-right: cost or MAX badge
            if st == "maxed" then
                draw.SimpleText("MAX", "VTX_Tiny", x + NODE_W - 6, y + 6, Color(65, 185, 85, 220), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
            else
                draw.SimpleText((info.price or 1) .. "pt", "VTX_Tiny", x + NODE_W - 6, y + 6, Color(95, 95, 108), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
            end
        end
    end

    -- Invisible DButton overlays for each node (hover + click)
    for id, pos in pairs(positions) do
        local info = skills[id]
        if not info then continue end

        local btn = vgui.Create("DButton", canvas)
        btn:SetPos(pos.x, pos.y)
        btn:SetSize(NODE_W, NODE_H)
        btn:SetText("")
        btn.Paint = function() end

        local sid = id
        btn.OnCursorEntered = function() treeHover[sid] = true end
        btn.OnCursorExited  = function() treeHover[sid] = nil  end
        btn.DoClick = function()
            local pd   = LocalPlayer().SkillData or { skills = {}, points = 0 }
            local st, cur, max = GetSkillStatus(sid, info, pd)
            local cost = info.price or 1
            local pts  = pd.points or 0

            if st == "locked" then
                surface.PlaySound("buttons/button10.wav")
                local ri = SkillTrees:GetSkill(info.requirement)
                chat.AddText(Color(255, 80, 80), "[Skills] Requires " .. (ri and ri.name or info.requirement) .. " at max level")
                return
            end
            if st == "maxed" then surface.PlaySound("buttons/button10.wav") return end
            if cost > pts then
                surface.PlaySound("buttons/button10.wav")
                chat.AddText(Color(255, 80, 80), "[Skills] Need " .. (cost - pts) .. " more point(s)")
                return
            end

            surface.PlaySound("buttons/button14.wav")
            net.Start("vtx_skills_purchase")
                net.WriteString(sid)
            net.SendToServer()
        end
    end

    -- Detail strip at the bottom of the content panel
    local detail = vgui.Create("DPanel", container)
    detail:SetPos(0, container:GetTall() - DETAIL_H)
    detail:SetSize(container:GetWide(), DETAIL_H)
    detail.Paint = function(self, w, h)
        surface.SetDrawColor(30, 30, 38)
        surface.DrawLine(0, 0, w, 0)
        draw.RoundedBoxEx(0, 0, 1, w, h - 1, Color(18, 18, 23))

        -- Find which skill is hovered
        local hid, hinfo
        for sid in pairs(treeHover) do
            hid   = sid
            hinfo = skills[sid]
            break
        end

        if hinfo then
            local pd    = LocalPlayer().SkillData or {}
            local st, cur, max = GetSkillStatus(hid, hinfo, pd)
            local c     = COLS[st]
            -- Colour accent strip on left
            draw.RoundedBox(0, 0, 0, 3, h, c.edge)
            -- Name
            draw.SimpleText(hinfo.name, "VTX_Sub", 16, h / 2 - 10, c.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            -- Full description
            draw.SimpleText(hinfo.description, "VTX_Small", 16, h / 2 + 8, Color(150, 150, 162), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            -- Right side: cost and level
            local costStr = st == "maxed" and "MAXED" or ("Cost: " .. (hinfo.price or 1) .. " point(s)")
            draw.SimpleText(costStr, "VTX_Small", w - 14, h / 2 - 10, st == "maxed" and Color(65,185,85) or Color(130,130,145), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            draw.SimpleText("Level " .. cur .. " / " .. max, "VTX_Small", w - 14, h / 2 + 8, Color(100, 100, 112), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        else
            draw.SimpleText("Hover over a skill to see details", "VTX_Small", w / 2, h / 2, Color(65, 65, 75), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
end

function OpenSkillMenu()
    local lp     = LocalPlayer()
    local sd     = lp.SkillData or {}
    local curLvl = sd.level or 1
    local curXP  = sd.xp or 0
    local reqXP  = math.floor(100 * math.pow(curLvl, 1.5))
    local points = sd.points or 0

    if IsValid(MainMenu) then MainMenu:Remove() end
    treeHover = {}

    local W = math.min(ScrW() * 0.85, 1100)
    local H = math.min(ScrH() * 0.85, 700)
    local SIDEBAR_W = 168
    local HEADER_H  = 52

    MainMenu = vgui.Create("DFrame")
    MainMenu:SetSize(W, H)
    MainMenu:SetTitle("")
    MainMenu:Center()
    MainMenu:MakePopup()
    MainMenu:ShowCloseButton(false)
    MainMenu:SetDraggable(true)

    MainMenu.Paint = function(self, w, h)
        draw.RoundedBox(10, 0, 0, w, h, Color(13, 13, 17))
        draw.RoundedBoxEx(10, 0, 0, w, HEADER_H, Color(19, 19, 25), true, true, false, false)
        surface.SetDrawColor(32, 32, 42)
        surface.DrawLine(0, HEADER_H, w, HEADER_H)
        draw.SimpleText("SKILL PROGRESSION", "VTX_Title", SIDEBAR_W + 14, HEADER_H / 2, Color(205, 205, 218), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        -- XP bar in header
        local bx = w - 250
        draw.SimpleText("LVL " .. curLvl, "VTX_Sub", bx, HEADER_H / 2 - 7, Color(130, 130, 148), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        local bw2 = 180
        draw.RoundedBox(3, bx + 52, HEADER_H / 2 - 5, bw2, 8, Color(0, 0, 0, 120))
        local xpProg = reqXP > 0 and math.Clamp(curXP / reqXP, 0, 1) or 0
        draw.RoundedBox(3, bx + 52, HEADER_H / 2 - 5, math.floor(bw2 * xpProg), 8, Color(110, 70, 190))
        draw.SimpleText(curXP .. " / " .. reqXP, "VTX_Tiny", bx + 52 + bw2 / 2, HEADER_H / 2 - 2, Color(150, 150, 165), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- Close button
    local closeBtn = vgui.Create("DButton", MainMenu)
    closeBtn:SetSize(30, 30)
    closeBtn:SetPos(W - 40, 11)
    closeBtn:SetText("")
    closeBtn.Paint = function(self, w, h)
        draw.RoundedBox(5, 0, 0, w, h, self:IsHovered() and Color(165, 32, 32) or Color(45, 45, 58))
        draw.SimpleText("✕", "VTX_Sub", w / 2, h / 2, Color(215, 215, 215), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    closeBtn.DoClick = function() MainMenu:Remove() end

    -- Sidebar
    local sidebar = vgui.Create("DPanel", MainMenu)
    sidebar:SetPos(0, HEADER_H)
    sidebar:SetSize(SIDEBAR_W, H - HEADER_H)
    sidebar.Paint = function(self, w, h)
        draw.RoundedBoxEx(10, 0, 0, w, h, Color(17, 17, 23), false, false, false, true)
        surface.SetDrawColor(32, 32, 42)
        surface.DrawLine(w - 1, 0, w - 1, h)
        -- Points box
        local bh = 68
        local by = h - bh - 8
        draw.RoundedBox(6, 10, by, w - 20, bh, Color(20, 20, 28))
        surface.SetDrawColor(38, 38, 52)
        surface.DrawOutlinedRect(10, by, w - 20, bh)
        draw.SimpleText("SKILL POINTS", "VTX_Tiny", w / 2, by + 14, Color(90, 90, 108), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(tostring(points), "VTX_Title", w / 2, by + bh / 2 + 8, Color(85, 205, 115), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- Content area
    local content = vgui.Create("DPanel", MainMenu)
    content:SetPos(SIDEBAR_W, HEADER_H)
    content:SetSize(W - SIDEBAR_W, H - HEADER_H)
    content.Paint = function(self, w, h)
        draw.RoundedBoxEx(10, 0, 0, w, h, Color(15, 15, 19), false, false, true, false)
    end

    -- Category scroll list in sidebar
    local catScroll = vgui.Create("DScrollPanel", sidebar)
    catScroll:SetPos(0, 8)
    catScroll:SetSize(SIDEBAR_W, H - HEADER_H - 88)
    catScroll:GetVBar():SetWide(3)

    local catList = vgui.Create("DIconLayout", catScroll)
    catList:Dock(TOP)
    catList:SetSpaceY(3)
    catList:DockMargin(8, 0, 8, 0)

    local myTeam    = lp:Team()
    local myJobName = team.GetName(myTeam)
    local myRank    = lp:GetUserGroup()
    local myID      = lp:SteamID()
    local allBtns   = {}

    local firstCat, firstData, firstBtn

    local function SelectCat(catName, catData, btn)
        for _, b in ipairs(allBtns) do b._active = false end
        btn._active = true
        ShowTree(catName, catData, content)
    end

    for catName, catData in pairs(SkillTrees.Tree) do
        local access = (not catData.Teams and not catData.MRSGroup and not catData.SteamIDs and not catData.Ranks)
        if catData.Teams then
            for _, v in pairs(catData.Teams) do
                if v == myTeam or v == myJobName then access = true break end
            end
        end
        if catData.MRSGroup and MRS then
            if table.HasValue(catData.MRSGroup, MRS.GetNWdata(lp, "Group")) then access = true end
        end
        if catData.Ranks then
            for _, r in pairs(catData.Ranks) do
                if r == myRank then access = true break end
            end
        end
        if catData.SteamIDs then
            for _, id in pairs(catData.SteamIDs) do
                if id == myID then access = true break end
            end
        end
        if not access then continue end

        local treeCol = catData.Color or Color(155, 155, 165)
        local btn     = catList:Add("DButton")
        btn:SetSize(SIDEBAR_W - 16, 44)
        btn:SetText("")
        btn._active = false

        btn.Paint = function(self, w, h)
            local bg = self._active and Color(26, 32, 48) or (self:IsHovered() and Color(20, 24, 34) or Color(0, 0, 0, 0))
            draw.RoundedBox(6, 0, 0, w, h, bg)
            if self._active then
                draw.RoundedBox(3, 0, 8, 3, h - 16, treeCol)
                draw.SimpleText(catName, "VTX_NodeName", 14, h / 2, treeCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            else
                draw.SimpleText(catName, "VTX_NodeName", 10, h / 2, Color(118, 118, 132), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
        end

        table.insert(allBtns, btn)
        if not firstCat then firstCat, firstData, firstBtn = catName, catData, btn end

        local cn, cd = catName, catData
        btn.DoClick = function(self) SelectCat(cn, cd, self) end
    end

    -- Reset button
    local resetBtn = vgui.Create("DButton", sidebar)
    resetBtn:SetPos(10, H - HEADER_H - 80)
    resetBtn:SetSize(SIDEBAR_W - 20, 26)
    resetBtn:SetText("")
    resetBtn.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, self:IsHovered() and Color(125, 32, 32) or Color(65, 20, 20))
        draw.SimpleText("RESET SKILLS", "VTX_Tiny", w / 2, h / 2, Color(205, 165, 165), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    resetBtn.DoClick = function()
        Derma_Query("Reset all skills and refund points?", "Confirm Reset",
            "Yes, Reset", function() net.Start("vtx_skills_reset") net.SendToServer() end,
            "No, Cancel", function() end)
    end

    if firstBtn then SelectCat(firstCat, firstData, firstBtn) end
end

net.Receive("vtx_skills_menu", function()
    if IsValid(MainMenu) and MainMenu:IsVisible() then return end
    OpenSkillMenu()
end)

net.Receive("vtx_skills_sync", function()
    local data = net.ReadTable()
    LocalPlayer().SkillData = data
    if IsValid(MainMenu) then OpenSkillMenu() end
    print("[Vortex] UI Refreshed")
end)
