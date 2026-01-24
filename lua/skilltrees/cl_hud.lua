-- Ensure these are initialized to 0, not nil
local xpAlpha = xpAlpha or 0
local lastXP = lastXP or -1
local xpStayTime = 0 

hook.Add("HUDPaint", "Vortex_XP_HUD", function()
    local lp = LocalPlayer()
    if not IsValid(lp) or not lp.SkillData then return end

    local sd = lp.SkillData
    local curXP = sd.xp or 0
    local curLvl = sd.level or 1
    local reqXP = math.floor(100 * math.pow(curLvl, 1.5))

    -- Safety: If reqXP is 0 (to avoid division by zero error)
    if reqXP <= 0 then reqXP = 100 end

    if lastXP != -1 and lastXP != curXP then
        xpAlpha = 255
        xpStayTime = CurTime() + 3 
    end
    lastXP = curXP

    if xpAlpha > 0 then
        if CurTime() > xpStayTime then
            xpAlpha = Lerp(FrameTime() * 2, xpAlpha, 0)
        end
        
        -- The Fix: Ensure xpAlpha is treated as a number here
        local displayAlpha = math.Clamp(tonumber(xpAlpha) or 0, 0, 255)

        local w, h = 300, 20
        local x, y = (ScrW() / 2) - (w / 2), 50 

        -- Background
        draw.RoundedBox(4, x, y, w, h, Color(20, 20, 20, displayAlpha * 0.8))
        
        local progress = math.Clamp(curXP / reqXP, 0, 1)
        draw.RoundedBox(4, x + 2, y + 2, (w - 4) * progress, h - 4, Color(155, 89, 182, displayAlpha))

        draw.SimpleText("LEVEL " .. curLvl .. " - " .. curXP .. "/" .. reqXP .. " XP", "DermaDefaultBold", x + (w/2), y + (h/2), Color(255, 255, 255, displayAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end)