-- Fonts, colours and small draw helpers shared by every menu panel.
--
-- The palette/fonts/panel helpers now live in OG_core (og_core/menu/cl_theme.lua) as
-- OG.UI, shared with OG_stims and future addons. This file aliases SkillTrees.UI to it
-- when OG_core is installed, and falls back to the original standalone theme otherwise
-- so skilltrees keeps working with no other addons present.
SkillTrees.UI = SkillTrees.UI or {}
local UI = SkillTrees.UI

-- Skilltrees' own menu files reference these VTX_* fonts by name, so they are created whether or
-- not OG_core is installed (OG_core only provides colours and draw helpers, under OG_* fonts).
surface.CreateFont("VTX_Title",   { font = "Roboto", size = 20, weight = 800 })
surface.CreateFont("VTX_Heading", { font = "Roboto", size = 16, weight = 800 })
surface.CreateFont("VTX_Body",    { font = "Roboto", size = 14, weight = 500 })
surface.CreateFont("VTX_Small",   { font = "Roboto", size = 12, weight = 500 })
surface.CreateFont("VTX_Rank",    { font = "Roboto", size = 12, weight = 800 })
surface.CreateFont("VTX_Big",     { font = "Roboto", size = 26, weight = 800 })
surface.CreateFont("VTX_Initial", { font = "Roboto", size = 22, weight = 800 })

if OG and OG.UI then
    -- OG_core is loaded: just borrow its colours and helpers.
    for k, v in pairs(OG.UI) do UI[k] = v end
else
    -- Standalone fallback (no OG_core installed) - identical to the original theme.
    UI.Col = {
        bg        = Color(8, 14, 22),
        frame     = Color(12, 22, 34),
        frameEdge = Color(40, 120, 170),
        edgeDim   = Color(28, 60, 84),
        titleBar  = Color(14, 34, 52),
        text      = Color(215, 230, 240),
        textDim   = Color(120, 140, 155),
        textFaint = Color(70, 86, 98),
        gold      = Color(245, 200, 70),
        green     = Color(110, 225, 130),
        staged    = Color(90, 220, 255),
        red       = Color(235, 90, 80),
        locked    = Color(50, 58, 66),
    }

    UI.Mat = {
        gradDown = Material("gui/gradient_down"),
        gradUp   = Material("gui/gradient_up"),
    }

    local iconCache = {}
    function UI.Icon(path)
        if not path then return nil end
        if iconCache[path] == nil then
            local mat = Material(path, "smooth")
            iconCache[path] = (mat and not mat:IsError()) and mat or false
        end
        return iconCache[path] or nil
    end

    function UI.Initials(name)
        local out = ""
        for w in string.gmatch(name, "%a+") do
            out = out .. w:sub(1, 1):upper()
            if #out >= 2 then break end
        end
        return out ~= "" and out or "?"
    end

    function UI.Alpha(col, a)
        return Color(col.r, col.g, col.b, a)
    end

    function UI.Rect(x, y, w, h)
        surface.DrawRect(math.floor(x), math.floor(y), math.max(math.floor(w), 1), math.max(math.floor(h), 1))
    end

    function UI.Outline(x, y, w, h, col, thick)
        surface.SetDrawColor(col)
        surface.DrawOutlinedRect(math.floor(x), math.floor(y), math.floor(w), math.floor(h), thick or 1)
    end

    -- Sci-fi panel: dark fill, optional tinted gradient, outline and small corner brackets
    function UI.Panel(w, h, tint, edge, tintAlpha)
        surface.SetDrawColor(UI.Col.frame)
        surface.DrawRect(0, 0, w, h)

        if tint then
            surface.SetMaterial(UI.Mat.gradUp)
            surface.SetDrawColor(tint.r, tint.g, tint.b, tintAlpha or 60)
            surface.DrawTexturedRect(0, 0, w, h)
        end

        edge = edge or UI.Col.edgeDim
        UI.Outline(0, 0, w, h, edge)

        local c = 10
        surface.SetDrawColor(edge.r, edge.g, edge.b, 255)
        UI.Rect(0, 0, c, 2)          UI.Rect(0, 0, 2, c)
        UI.Rect(w - c, 0, c, 2)      UI.Rect(w - 2, 0, 2, c)
        UI.Rect(0, h - 2, c, 2)      UI.Rect(0, h - c, 2, c)
        UI.Rect(w - c, h - 2, c, 2)  UI.Rect(w - 2, h - c, 2, c)
    end

    -- Greedy word wrap to a pixel width
    function UI.Wrap(text, font, width)
        surface.SetFont(font)
        local lines, line = {}, ""
        for word in string.gmatch(text or "", "%S+") do
            local try = line == "" and word or (line .. " " .. word)
            if surface.GetTextSize(try) > width and line ~= "" then
                table.insert(lines, line)
                line = word
            else
                line = try
            end
        end
        if line ~= "" then table.insert(lines, line) end
        return lines
    end

    -- Flat button used in the title and bottom bars
    function UI.Button(parent, label, onClick)
        local btn = vgui.Create("DButton", parent)
        btn:SetText("")
        btn.Label = label
        btn.DoClick = function(self)
            if self:GetDisabled() then return end
            surface.PlaySound("buttons/lightswitch2.wav")
            onClick(self)
        end
        btn.Paint = function(self, w, h)
            local disabled = self:GetDisabled()
            local accent = self.Accent or UI.Col.frameEdge
            local bg = disabled and Color(14, 22, 30) or (self:IsHovered() and UI.Alpha(accent, 70) or UI.Alpha(accent, 28))
            surface.SetDrawColor(bg)
            surface.DrawRect(0, 0, w, h)
            UI.Outline(0, 0, w, h, disabled and UI.Col.edgeDim or accent)
            draw.SimpleText(self.Label, "VTX_Rank", w / 2, h / 2, disabled and UI.Col.textFaint or UI.Col.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        return btn
    end
end

-- Rounded shapes. Defined here (after the OG_core alias) so they override the square
-- Panel/Button either way without touching OG_stims.
UI.Radius = 6

-- draw.RoundedBox has no outline variant, so the border is a box in the edge colour with
-- the fill box inset on top of it. Keep the fill opaque or the edge shows through it.
function UI.RoundBox(x, y, w, h, r, fill, edge, thick)
    x, y, w, h = math.floor(x), math.floor(y), math.floor(w), math.floor(h)
    r = math.min(r, math.floor(math.min(w, h) / 2))
    if edge then
        thick = thick or 1
        draw.RoundedBox(r, x, y, w, h, edge)
        x, y, w, h, r = x + thick, y + thick, w - thick * 2, h - thick * 2, math.max(r - thick, 0)
    end
    if fill then draw.RoundedBox(r, x, y, w, h, fill) end
end

local function cornerInset(r, row)
    local d = r - row - 0.5
    return math.ceil(r - math.sqrt(r * r - d * d))
end

-- Vertical gradient clipped to a rounded rect: the corner rows are drawn as shortened
-- 1px strips, with the UVs picking the matching slice of the gradient.
function UI.RoundGradient(x, y, w, h, r, mat, col, roundTop, roundBottom)
    surface.SetMaterial(mat)
    surface.SetDrawColor(col)
    local top = roundTop and r or 0
    local bot = roundBottom and r or 0
    for i = 0, top - 1 do
        local o = cornerInset(r, i)
        surface.DrawTexturedRectUV(x + o, y + i, w - o * 2, 1, 0, i / h, 1, (i + 1) / h)
    end
    surface.DrawTexturedRectUV(x, y + top, w, h - top - bot, 0, top / h, 1, (h - bot) / h)
    for i = 0, bot - 1 do
        local o = cornerInset(r, i)
        local row = h - 1 - i
        surface.DrawTexturedRectUV(x + o, y + row, w - o * 2, 1, 0, row / h, 1, (row + 1) / h)
    end
end

function UI.Panel(w, h, tint, edge, tintAlpha)
    local r = UI.Radius
    UI.RoundBox(0, 0, w, h, r, UI.Col.frame, edge or UI.Col.edgeDim)
    if tint then
        UI.RoundGradient(1, 1, w - 2, h - 2, r - 1, UI.Mat.gradUp, UI.Alpha(tint, tintAlpha or 60), true, true)
    end
end

local rankFont = (OG and OG.UI) and "OG_Rank" or "VTX_Rank"

function UI.Button(parent, label, onClick)
    local btn = vgui.Create("DButton", parent)
    btn:SetText("")
    btn.Label = label
    btn.DoClick = function(self)
        if self:GetDisabled() then return end
        surface.PlaySound("buttons/lightswitch2.wav")
        onClick(self)
    end
    btn.Paint = function(self, w, h)
        local disabled = self:GetDisabled()
        local accent = self.Accent or UI.Col.frameEdge
        UI.RoundBox(0, 0, w, h, 5, disabled and Color(14, 22, 30) or UI.Col.frame, disabled and UI.Col.edgeDim or accent)
        if not disabled then
            draw.RoundedBox(4, 1, 1, w - 2, h - 2, UI.Alpha(accent, self:IsHovered() and 70 or 28))
        end
        draw.SimpleText(self.Label, rankFont, w / 2, h / 2, disabled and UI.Col.textFaint or UI.Col.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    return btn
end

-- Skilltrees-specific: reads SkillTrees.StatLabels, so it stays here rather than in core.
function UI.SkillIcon(info)
    if info.icon then return UI.Icon(info.icon) end
    for stat in pairs(info.buffs or {}) do
        local def = SkillTrees.StatLabels[stat]
        if def and def.icon then return UI.Icon(def.icon) end
    end
    return nil
end
