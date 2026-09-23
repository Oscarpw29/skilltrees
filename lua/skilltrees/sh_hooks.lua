-- Weapon stat hooks. Shared so client prediction and the server agree.

-- ArcCW caches computed stats (RPM etc.), so buff changes only show up once the cache is cleared.
-- On the server AdjustAtts also detaches attachments the player no longer unlocks (after a respec).
function SkillTrees:RefreshWeapons(ply)
    if not IsValid(ply) then return end
    for _, wep in ipairs(ply:GetWeapons()) do
        if not wep.ArcCW then continue end
        if SERVER and wep.AdjustAtts then
            wep:AdjustAtts()
        elseif wep.RecalcAllBuffs then
            wep:RecalcAllBuffs()
        end
    end
end

hook.Add("ArcCW_Mod_Mult_RPM", "Vortex_Skills_ArcCW_RPM", function(wep, mult)
    local ply = wep:GetOwner()
    if not IsValid(ply) or not ply:IsPlayer() or not ply.SkillData then return mult end

    local firerate = SkillTrees:CalculateBuffs(ply).firerate
    if firerate > 0 then return mult + firerate end
    return mult
end)

-- TFA_GetStat intercepts cached stat reads. Stat names come from the SWEP table:
-- Primary.RPM, ProceduralReloadTime, LoopedReloadInsertTime.
hook.Add("TFA_GetStat", "Vortex_TFA_WeaponStats", function(wep, stat, value)
    local ply = wep:GetOwner()
    if not IsValid(ply) or not ply:IsPlayer() or not ply.SkillData then return end

    local buffs = SkillTrees:CalculateBuffs(ply)

    if stat == "Primary.RPM" and buffs.firerate > 0 then
        return value * (1 + buffs.firerate)
    end

    if (stat == "ProceduralReloadTime" or stat == "LoopedReloadInsertTime") and buffs.reloadspeed > 0 then
        return value * math.Clamp(1 - buffs.reloadspeed, 0.5, 1)
    end
end)
