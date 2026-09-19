surface.CreateFont("VTX_Title",    { font = "Roboto", size = 22, weight = 800 })
surface.CreateFont("VTX_Sub",      { font = "Roboto", size = 14, weight = 500 })
surface.CreateFont("VTX_NodeName", { font = "Roboto", size = 13, weight = 700 })
surface.CreateFont("VTX_Small",    { font = "Roboto", size = 11, weight = 400 })
surface.CreateFont("VTX_Banner",   { font = "Roboto", size = 32, weight = 800 })
surface.CreateFont("VTX_Rank",     { font = "Roboto", size = 12, weight = 800 })
surface.CreateFont("VTX_Tiny",     { font = "Roboto", size = 10, weight = 600 })

local MainMenu
local ICON       = 60   -- square talent icon
local CELL_W     = 128  -- horizontal slot per node
local LABEL_H    = 18   -- name label under the icon
local ROW_H      = 118  -- vertical slot per tier
local TREE_TOP   = 84   -- banner height above the first tier
local TREE_PAD   = 28
local GOLD       = Color(235, 190, 70)

-- Shared hover state written by node buttons, read by canvas Paint
local treeHover = {}

local COLS = {
    locked    = { bg = Color(22,22,27),   edge = Color(48,48,55),   text = Color(75,75,82),   bar = Color(48,48,55)    },
    available = { bg = Color(20,30,52),   edge = Color(52,96,178),  text = Color(170,205,255), bar = Color(52,96,178)   },
    partial   = { bg = Color(20,40,28),   edge = Color(50,148,76),  text = Color(155,238,175), bar = Color(50,148,76)   },
    maxed     = { bg = Color(50,40,14),   edge = Color(235,190,70), text = Color(255,220,120), bar = Color(235,190,70)  },
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

local function Initials(name)
    local out = ""
    for w in string.gmatch(name, "%a+") do
        out = out .. w:sub(1, 1):upper()
        if #out >= 2 then break end
    end
    return out ~= "" and out or "?"
end

-- Tiers go top to bottom like a classic talent tree: roots on row 0, each requirement one row deeper.
local function BuildLayout(skillsTable, availW)
    local parentOf, childrenOf = {}, {}
    for id, info in pairs(skillsTable) do
        local req = info.requirement
        if req and skillsTable[req] then
            parentOf[id] = req
            childrenOf[req] = childrenOf[req] or {}
            table.insert(childrenOf[req], id)
        end
    end

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

    local rows, maxDepth, maxRow = {}, 0, 1
    for id, d in pairs(depth) do
        rows[d] = rows[d] or {}
        table.insert(rows[d], id)
        if d > maxDepth then maxDepth = d end
    end
    for d = 0, maxDepth do
        if rows[d] then maxRow = math.max(maxRow, #rows[d]) end
    end

    local canvasW = math.max(availW, maxRow * CELL_W + TREE_PAD * 2)
    local positions = {}
    for d = 0, maxDepth do
        local row = rows[d] or {}
        table.sort(row, function(a, b)
            local pa = parentOf[a] and positions[parentOf[a]] and positions[parentOf[a]].x or 0
            local pb = parentOf[b] and positions[parentOf[b]] and positions[parentOf[b]].x or 0
            if pa ~= pb then return pa < pb end
            return a < b
        end)
        local startX = (canvasW - #row * CELL_W) / 2
        for i, id in ipairs(row) do
            positions[id] = {
                x = math.floor(startX + (i - 1) * CELL_W + (CELL_W - ICON) / 2),
                y = TREE_TOP + d * ROW_H,
            }
        end
    end

    local connections = {}
    for id in pairs(skillsTable) do
        if parentOf[id] then table.insert(connections, { from = parentOf[id], to = id }) end
    end

    return positions, connections, canvasW, TREE_TOP + (maxDepth + 1) * ROW_H
end

local function Bar(x, y, w, h)
    surface.DrawRect(math.floor(x), math.floor(y), math.max(w, 1), math.max(h, 1))
end

-- Elbow connector: down from the parent, across, down into the child.
local function Connector(px, py, cx, cy, col)
    surface.SetDrawColor(col)
    local midY = math.floor((py + cy) / 2)
    Bar(px - 1, py, 2, midY - py)
    Bar(math.min(px, cx) - 1, midY - 1, math.abs(cx - px) + 2, 2)
    Bar(cx - 1, midY, 2, cy - midY - 6)
    draw.NoTexture()
    surface.DrawPoly({ { x = cx - 5, y = cy - 7 }, { x = cx + 5, y = cy - 7 }, { x = cx, y = cy } })
end

local function ShowTree(catName, catData, container)
    container:Clear()
    treeHover = {}

    local skills                        = catData.Skills or {}
    local positions, connections, cW, cH = BuildLayout(skills, container:GetWide())

    -- Scroll area (leaves room for detail strip)
    local DETAIL_H = 72
    local specs    = catData.Specializations
    local SPEC_H   = specs and 118 or 0
    local scroll   = vgui.Create("DScrollPanel", container)
    scroll:SetPos(0, 0)
    scroll:SetSize(container:GetWide(), container:GetTall() - DETAIL_H - SPEC_H - 1)

    local vbar = scroll:GetVBar()
    vbar:SetWide(5)
    vbar.Paint         = function(_, w, h) draw.RoundedBox(0, 0, 0, w, h, Color(18, 18, 22)) end
    vbar.btnUp.Paint   = function() end
    vbar.btnDown.Paint = function() end
    vbar.btnGrip.Paint = function(_, w, h) draw.RoundedBox(3, 1, 1, w - 2, h - 2, Color(55, 55, 70)) end

    -- Canvas that holds drawing + invisible node buttons
    local hasSkills = next(skills) ~= nil
    local treeCol   = catData.Color or Color(155, 155, 165)

    -- Placeholder silhouette so an empty tree still reads as a tree
    local ghost, ghostRows = {}, { 1, 3, 2, 1 }
    if not hasSkills then
        for r, n in ipairs(ghostRows) do
            for i = 1, n do
                table.insert(ghost, { x = (cW - n * CELL_W) / 2 + (i - 1) * CELL_W + (CELL_W - ICON) / 2, y = TREE_TOP + (r - 1) * ROW_H, row = r })
            end
        end
        cH = TREE_TOP + #ghostRows * ROW_H + 10
    end

    local canvas = vgui.Create("DPanel", scroll)
    canvas:SetSize(math.max(cW, scroll:GetWide()), math.max(cH, scroll:GetTall()))
    canvas.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(13, 13, 17))
        -- soft tint under the banner
        for i = 0, 5 do
            draw.RoundedBox(0, 0, i * 12, w, 12, Color(treeCol.r, treeCol.g, treeCol.b, 16 - i * 3))
        end

        local pd = LocalPlayer().SkillData or {}

        -- Banner
        local spent = 0
        for id, info in pairs(skills) do spent = spent + (info.price or 1) * ((pd.skills or {})[id] or 0) end
        draw.SimpleText(string.upper(catName), "VTX_Banner", w / 2, 30, treeCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        local sub = hasSkills and (spent .. " points invested") or "Training programme under development"
        draw.SimpleText(sub, "VTX_Small", w / 2, 56, Color(110, 110, 124), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(treeCol.r, treeCol.g, treeCol.b, 90)
        surface.DrawRect(w / 2 - 90, 70, 180, 1)

        if not hasSkills then
            for _, g in ipairs(ghost) do
                if g.row < #ghostRows then
                    surface.SetDrawColor(40, 40, 50, 160)
                    Bar(g.x + ICON / 2 - 1, g.y + ICON, 2, ROW_H - ICON)
                end
                draw.RoundedBox(8, g.x, g.y, ICON, ICON, Color(24, 24, 30, 210))
                surface.SetDrawColor(44, 44, 54, 220)
                surface.DrawOutlinedRect(g.x, g.y, ICON, ICON, 2)
                draw.SimpleText("?", "VTX_Title", g.x + ICON / 2, g.y + ICON / 2, Color(58, 58, 68), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            draw.RoundedBox(8, w / 2 - 130, cH / 2 - 26, 260, 52, Color(13, 13, 17, 235))
            draw.SimpleText("SKILLS COMING SOON", "VTX_Title", w / 2, cH / 2, GOLD, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            return
        end

        -- Connections
        for _, conn in ipairs(connections) do
            local fp, tp = positions[conn.from], positions[conn.to]
            if not fp or not tp then continue end
            local fromSt = GetSkillStatus(conn.from, skills[conn.from], pd)
            local col    = (fromSt == "maxed") and Color(235, 190, 70, 230) or Color(52, 52, 62, 230)
            Connector(fp.x + ICON / 2, fp.y + ICON + LABEL_H, tp.x + ICON / 2, tp.y - 2, col)
        end

        -- Nodes
        for id, pos in pairs(positions) do
            local info = skills[id]
            if not info then continue end
            local st, cur, max = GetSkillStatus(id, info, pd)
            local c   = COLS[st]
            local hov = treeHover[id]
            local x, y = pos.x, pos.y
            local edge = (st == "available") and treeCol or c.edge

            if st ~= "locked" then
                draw.RoundedBox(12, x - 6, y - 6, ICON + 12, ICON + 12, Color(edge.r, edge.g, edge.b, hov and 45 or 22))
            end
            draw.RoundedBox(8, x + 2, y + 3, ICON, ICON, Color(0, 0, 0, 90))
            draw.RoundedBox(8, x - 2, y - 2, ICON + 4, ICON + 4, Color(edge.r, edge.g, edge.b, hov and 255 or (st == "locked" and 120 or 200)))
            draw.RoundedBox(6, x, y, ICON, ICON, hov and Color(c.bg.r + 14, c.bg.g + 14, c.bg.b + 14) or c.bg)

            draw.SimpleText(Initials(info.name), "VTX_Title", x + ICON / 2, y + ICON / 2 - 1, st == "locked" and Color(62, 62, 70) or c.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            -- Rank badge (bottom-right, WoW style)
            local rk = cur .. "/" .. max
            surface.SetFont("VTX_Rank")
            local tw = surface.GetTextSize(rk)
            local bw = tw + 8
            draw.RoundedBox(4, x + ICON - bw + 3, y + ICON - 12, bw, 16, Color(8, 8, 10, 240))
            draw.SimpleText(rk, "VTX_Rank", x + ICON - bw / 2 + 3, y + ICON - 4, st == "maxed" and GOLD or (st == "locked" and Color(80, 80, 88) or Color(110, 235, 130)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            -- Name label
            draw.SimpleText(Trunc(info.name, 20), "VTX_Tiny", x + ICON / 2, y + ICON + 12, st == "locked" and Color(70, 70, 78) or Color(185, 185, 198), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    -- Invisible DButton overlays for each node (hover + click)
    for id, pos in pairs(positions) do
        local info = skills[id]
        if not info then continue end

        local btn = vgui.Create("DButton", canvas)
        btn:SetPos(pos.x, pos.y)
        btn:SetSize(ICON, ICON)
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

    -- Specialization strip (unlocks at level 15; content not released yet)
    if specs then
        local sp = vgui.Create("DPanel", container)
        sp:SetPos(0, container:GetTall() - DETAIL_H - SPEC_H)
        sp:SetSize(container:GetWide(), SPEC_H)
        local names = {}
        for n in pairs(specs) do table.insert(names, n) end
        table.sort(names)
        sp.Paint = function(self, w, h)
            surface.SetDrawColor(30, 30, 38)
            surface.DrawLine(0, 0, w, 0)
            draw.RoundedBox(0, 0, 1, w, h - 1, Color(17, 17, 22))
            local lvl = (LocalPlayer().SkillData or {}).level or 1
            draw.SimpleText("SPECIALIZATION", "VTX_Sub", 16, 16, Color(150, 150, 165), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            local cw, ch, x = 200, 68, 16
            for _, n in ipairs(names) do
                local sd = specs[n]
                draw.RoundedBox(8, x, 34, cw, ch, Color(22, 22, 27))
                surface.SetDrawColor(48, 48, 55)
                surface.DrawOutlinedRect(x, 34, cw, ch)
                draw.SimpleText(sd.comingSoon and "???" or sd.name, "VTX_NodeName", x + cw / 2, 34 + 18, Color(95, 95, 105), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText("COMING SOON", "VTX_Sub", x + cw / 2, 34 + 40, Color(200, 160, 40), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                local need = sd.unlockLevel or 15
                if lvl < need then
                    draw.SimpleText("Unlocks at Level " .. need, "VTX_Tiny", x + cw / 2, 34 + 58, Color(75, 75, 82), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
                x = x + cw + 12
            end
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
        local isMax = curLvl >= SkillTrees.MaxLevel
        local bw2 = 180
        draw.RoundedBox(3, bx + 52, HEADER_H / 2 - 5, bw2, 8, Color(0, 0, 0, 120))
        local xpProg = isMax and 1 or (reqXP > 0 and math.Clamp(curXP / reqXP, 0, 1) or 0)
        draw.RoundedBox(3, bx + 52, HEADER_H / 2 - 5, math.floor(bw2 * xpProg), 8, Color(110, 70, 190))
        draw.SimpleText(isMax and "MAX LEVEL" or (curXP .. " / " .. reqXP), "VTX_Tiny", bx + 52 + bw2 / 2, HEADER_H / 2 - 2, Color(150, 150, 165), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
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
    catScroll:SetSize(SIDEBAR_W, H - HEADER_H - 126)
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
        if lp:IsSuperAdmin() then access = true end -- admins can preview every tree
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
    resetBtn:SetPos(10, H - HEADER_H - 112)
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
