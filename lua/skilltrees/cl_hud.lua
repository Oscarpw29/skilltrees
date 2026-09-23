-- Small XP bar that fades in at the top of the screen whenever XP changes

local alpha, lastXP, lastLevel, stayUntil = 0, nil, nil, 0

hook.Add("HUDPaint", "Vortex_XP_HUD", function()
    local lp = LocalPlayer()
    local sd = IsValid(lp) and lp.SkillData
    if not sd then return end

    local xp, level = sd.xp or 0, sd.level or 1
    if lastXP and (lastXP ~= xp or lastLevel ~= level) then
        alpha = 255
        stayUntil = CurTime() + 3
    end
    lastXP, lastLevel = xp, level

    if alpha <= 1 then return end
    if CurTime() > stayUntil then
        alpha = Lerp(FrameTime() * 2, alpha, 0)
    end

    local maxed    = level >= SkillTrees.MaxLevel
    local required = SkillTrees:GetRequiredXP(level)
    local progress = maxed and 1 or math.Clamp(xp / required, 0, 1)

    local w, h = 300, 20
    local x, y = ScrW() / 2 - w / 2, 50

    draw.RoundedBox(4, x, y, w, h, Color(20, 20, 20, alpha * 0.8))
    draw.RoundedBox(4, x + 2, y + 2, (w - 4) * progress, h - 4, Color(155, 89, 182, alpha))

    local text = maxed and ("LEVEL " .. level .. " - MAX") or ("LEVEL " .. level .. " - " .. xp .. "/" .. required .. " XP")
    draw.SimpleText(text, "DermaDefaultBold", x + w / 2, y + h / 2, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)
