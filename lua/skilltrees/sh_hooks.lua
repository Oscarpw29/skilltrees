hook.Add("ArcCW_Mod_Mult_RPM", "Vortex_Test_Logic", function(wep, mult)
    local ply = wep:GetOwner()
    if not IsValid(ply) or not ply.SkillData then return mult end

    local buffs = SkillTrees:CalculateBuffs(ply)

    if buffs and buffs.firerate and buffs.firerate > 0 then
        local side = SERVER and "SERVER" or "CLIENT"
        print("[Vortex] " .. side .. " is applying RPM: " .. (mult + buffs.firerate))

        return mult + buffs.firerate
    end

    return mult
end)

-- TFA Base: intercept cached stat reads to modify fire rate and reload speed.
-- TFA_GetStat is Shared (runs both client prediction and server), so this file is the right place.
-- Stat names come from SWEP table structure: Primary.RPM, ProceduralReloadTime, LoopedReloadInsertTime.
hook.Add("TFA_GetStat", "Vortex_TFA_WeaponStats", function(wep, stat, value)
    local ply = wep:GetOwner()
    if not IsValid(ply) or not ply:IsPlayer() or not ply.SkillData then return end

    local buffs = SkillTrees:CalculateBuffs(ply)

    if stat == "Primary.RPM" and buffs.firerate and buffs.firerate > 0 then
        return value * (1 + buffs.firerate)
    end

    if (stat == "ProceduralReloadTime" or stat == "LoopedReloadInsertTime") and buffs.reloadspeed and buffs.reloadspeed > 0 then
        return value * math.Clamp(1 - buffs.reloadspeed, 0.5, 1)
    end
end)