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

-- ArcCW reads every weapon stat as a base value plus a "Mult_<Stat>" multiplier, and asks a global
-- hook named M_Hook_Mult_<Stat> for changes: hook(wep, data) with data = { buff, mult }, returning
-- data with `mult` changed. (Earlier versions of this file used ArcCW_Mod_Mult_RPM and
-- ArcCW_ModifyReloadTime, which ArcCW never calls, so none of these bonuses reached ArcCW weapons.)
-- Shared: the client predicts firing and reloading with the same numbers as the server.
local function arcBuffs(wep)
    local ply = wep.GetOwner and wep:GetOwner()
    if not IsValid(ply) or not ply:IsPlayer() or not ply.SkillData then return nil end
    return SkillTrees:CalculateBuffs(ply)
end

-- Bullet damage: scale both ends of the range so falloff keeps its shape
local function scaleDamage(wep, data)
    local buffs = arcBuffs(wep)
    if not buffs or buffs.damage <= 0 then return end
    data.mult = data.mult * (1 + buffs.damage)
    return data
end
hook.Add("M_Hook_Mult_Damage", "Vortex_Skills_ArcCW_Damage", scaleDamage)
hook.Add("M_Hook_Mult_DamageMin", "Vortex_Skills_ArcCW_DamageMin", scaleDamage)

-- Fire rate: CycleTime is the delay between shots, so a faster gun is a smaller multiplier
hook.Add("M_Hook_Mult_CycleTime", "Vortex_Skills_ArcCW_FireRate", function(wep, data)
    local buffs = arcBuffs(wep)
    if not buffs or buffs.firerate <= 0 then return end
    data.mult = data.mult / (1 + buffs.firerate)
    return data
end)

-- Reload speed: ReloadTime is a duration multiplier (floored so a reload can't become instant)
hook.Add("M_Hook_Mult_ReloadTime", "Vortex_Skills_ArcCW_Reload", function(wep, data)
    local buffs = arcBuffs(wep)
    if not buffs or buffs.reloadspeed <= 0 then return end
    data.mult = data.mult * math.Clamp(1 - buffs.reloadspeed, 0.5, 1)
    return data
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
