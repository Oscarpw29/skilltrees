-- Gameplay effects of skill buffs. HP/armor are applied in SkillTrees:ApplyBuffs (sv_skills.lua),
-- weapon fire rate / reload for TFA and ArcCW RPM live in sh_hooks.lua.

local COMBAT_COOLDOWN = 15 -- seconds without taking damage before regen kicks in

local function buffsOf(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply.SkillData then return nil end
    return SkillTrees:CalculateBuffs(ply)
end

hook.Add("SetupMove", "Vortex_Skills_Speed", function(ply, mv)
    local buffs = buffsOf(ply)
    if not buffs or buffs.movespeed <= 0 then return end

    local mult = 1 + buffs.movespeed
    mv:SetMaxClientSpeed(mv:GetMaxClientSpeed() * mult)
    mv:SetMaxSpeed(mv:GetMaxSpeed() * mult)
end)

timer.Create("Vortex_Skill_RegenTimer", 2, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if not ply:Alive() then continue end
        if CurTime() - (ply.Vortex_LastDamageTime or 0) < COMBAT_COOLDOWN then continue end

        local buffs = buffsOf(ply)
        if not buffs then continue end

        if buffs.hpregen > 0 and ply:Health() < ply:GetMaxHealth() then
            ply:SetHealth(math.min(ply:GetMaxHealth(), ply:Health() + buffs.hpregen))
        end

        local maxArmor = ply:GetNWInt("MaxArmor", 100)
        if buffs.armorregen > 0 and ply:Armor() < maxArmor then
            ply:SetArmor(math.min(maxArmor, ply:Armor() + buffs.armorregen))
        end

        if buffs.lscs_force_regen > 0 and ply.lscsGetForce then
            local maxForce = ply:lscsGetMaxForce()
            if ply:lscsGetForce() < maxForce then
                ply:lscsSetForce(math.min(maxForce, ply:lscsGetForce() + buffs.lscs_force_regen))
            end
        end
    end
end)

hook.Add("ScalePlayerDamage", "Vortex_Skills_CombatAndResistance", function(ply, hitgroup, dmginfo)
    ply.Vortex_LastDamageTime = CurTime()

    local buffs = buffsOf(ply)
    if buffs and buffs.resistance > 0 then
        -- Floor at 10% so stacking can never make a player immune
        dmginfo:ScaleDamage(math.max(0.1, 1 - buffs.resistance))
    end
end)

hook.Add("ArcCW_ModifyReloadTime", "Vortex_Skills_ReloadSpeed", function(wep, duration)
    local buffs = buffsOf(wep:GetOwner())
    if buffs and buffs.reloadspeed > 0 then
        return duration * math.Clamp(1 - buffs.reloadspeed, 0.5, 1)
    end
end)

-- TFA fires through standard FireBullets, so outgoing bullet damage is scaled here.
-- IsTFAWeapon is TFA's marker field.
hook.Add("EntityTakeDamage", "Vortex_TFA_BulletDamage", function(target, dmginfo)
    if not dmginfo:IsBulletDamage() then return end

    local attacker = dmginfo:GetAttacker()
    local buffs = buffsOf(attacker)
    if not buffs or buffs.damage <= 0 then return end

    local wep = attacker:GetActiveWeapon()
    if IsValid(wep) and wep.IsTFAWeapon then
        dmginfo:ScaleDamage(1 + buffs.damage)
    end
end)

hook.Add("EntityTakeDamage", "Vortex_LSCS_Combat", function(target, dmginfo)
    if not dmginfo:IsDamageType(DMG_ENERGYBEAM) then return end

    local attacker = dmginfo:GetAttacker()
    local atkBuffs = buffsOf(attacker)
    if atkBuffs and atkBuffs.lscs_damage > 0 then
        local wep = attacker:GetActiveWeapon()
        if IsValid(wep) and wep.LSCS then
            dmginfo:ScaleDamage(1 + atkBuffs.lscs_damage)
        end
    end

    local defBuffs = buffsOf(target)
    if defBuffs and defBuffs.lscs_block > 0 then
        dmginfo:ScaleDamage(math.max(0.1, 1 - defBuffs.lscs_block))
    end
end)

-- Money

local function jobSalary(ply)
    local job = ply.getJobTable and ply:getJobTable()
    return job and job.salary or 0
end

-- Salary bonus on DarkRP's payday interval. DarkRP_PlayerEarned passes the team name rather
-- than "salary" as the reason, so a matching standalone timer is simpler and reliable.
hook.Add("InitPostEntity", "Vortex_SalaryBonus_Setup", function()
    local delay = (GAMEMODE and GAMEMODE.Config and GAMEMODE.Config.paydelay) or 160

    timer.Create("Vortex_SalaryBonus", delay, 0, function()
        for _, ply in ipairs(player.GetAll()) do
            local buffs = buffsOf(ply)
            if not buffs or buffs.salary_bonus <= 0 or not ply:Alive() then continue end

            local bonus = math.Round(jobSalary(ply) * buffs.salary_bonus)
            if bonus > 0 then ply:addMoney(bonus) end
        end
    end)
end)

local function killReward(attacker)
    local buffs = buffsOf(attacker)
    if not buffs or buffs.salary_per_kill <= 0 then return end

    local bonus = math.Round(jobSalary(attacker) * buffs.salary_per_kill)
    if bonus > 0 then attacker:addMoney(bonus) end
end

hook.Add("PlayerDeath", "Vortex_GoldenBullets_PlayerKill", function(victim, inflictor, attacker)
    if attacker ~= victim then killReward(attacker) end
end)

hook.Add("OnNPCKilled", "Vortex_GoldenBullets_NPCKill", function(npc, attacker)
    killReward(attacker)
end)
