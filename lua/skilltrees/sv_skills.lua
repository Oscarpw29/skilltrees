util.AddNetworkString("vtx_skills_purchase")
util.AddNetworkString("vtx_skills_reset")
util.AddNetworkString("vtx_skills_menu")
util.AddNetworkString("Vortex_RefreshWeapon") 
util.AddNetworkString("vtx_skills_sync")

net.Receive("vtx_skills_purchase", function(len, ply)
    local skillID = net.ReadString()
    local skillInfo, categoryName = SkillTrees:GetSkill(skillID)

    if not skillInfo then return end

    ply.SkillData = ply.SkillData or { points = 0, skills = {} }

    if skillInfo.requirement then
        local reqId = skillInfo.requirement
        local reqInfo = SkillTrees:GetSkill(reqId)
        
        if reqInfo then
            local playerReqLevel = ply.SkillData.skills[reqId] or 0
            local targetMaxLevel = reqInfo.maxLevel or 1
            
            if playerReqLevel < targetMaxLevel then
                ply:ChatPrint("Locked! You must reach Max Level with ".. reqInfo.name .." first.")
                return 
            end
        end
    end

    if skillInfo.allowedJobs then
        local jobName = team.GetName(ply:Team())
        if not table.HasValue(skillInfo.allowedJobs, jobName) then
            ply:ChatPrint("Your current job cannot learn this!")
            return 
        end
    end

    if skillInfo.allowedSteamIDs and not table.HasValue(skillInfo.allowedSteamIDs, ply:SteamID()) then
        ply:ChatPrint("You do not have permission to use this skill.")
        return 
    end
    local currentLevel = 0
    if ply.SkillData and ply.SkillData.skills and ply.SkillData.skills[skillID] then
        currentLevel = ply.SkillData.skills[skillID]
    end
    local cost = skillInfo.price or 1
    if currentLevel >= (skillInfo.maxLevel or 1) then ply:ChatPrint("You are already max level") return end
    if (ply.SkillData.points or 0) < cost then return end
    
    ply.SkillData.points = ply.SkillData.points - cost
    ply.SkillData.skills[skillID] = (ply.SkillData.skills[skillID] or 0) +1

    ply:ChatPrint(skillInfo.name .. " Upgraded to level ".. (currentLevel + 1))
    SkillTrees:SaveAndSync(ply)
    SkillTrees:ApplyBuffs(ply)

    net.Start("Vortex_RefreshWeapon")
    net.Send(ply)
end)

net.Receive("vtx_skills_reset", function(len, ply)
    if not IsValid(ply) or not ply.SkillData then return end
    local totalRefund = 0
    for skillID, level in pairs(ply.SkillData.skills) do
        local skillInfo = SkillTrees:GetSkill(skillID)
        if skillInfo then
            local cost = skillInfo.price or 1
            totalRefund = totalRefund + (cost*level)
        end
    end
    ply.SkillData.points = ply.SkillData.points + totalRefund
    ply.SkillData.skills = {}
    
    SkillTrees:SaveAndSync(ply)
    hook.Run("SkillTree_UpdateStats", ply)
    ply:ChatPrint("[VORTEX] SKills Reset! Refunded ".. totalRefund .."points.")
end)


function SkillTrees:SaveAndSync(ply)
    if not IsValid(ply) or not ply.SkillData then return end
    -- Block any save while PData hasn't been read from disk yet.
    -- ply.SkillDataLoaded is set true by sv_data.lua after the 2-second load timer.
    -- Without this, anything that triggers SaveAndSync in that window (passive XP
    -- timer, NPC kills, UserGroupSet) overwrites real data with empty defaults.
    if not ply.SkillDataLoaded then return end
    local json = util.TableToJSON(ply.SkillData)
    ply:SetPData("vtx_skilldata", json)

    net.Start("vtx_skills_sync")
        net.WriteTable(ply.SkillData)
    net.Send(ply)
end

function SkillTrees:ApplyBuffs(ply)
    if not IsValid(ply) or not ply.SkillData then return end
    
    local buffs = SkillTrees:CalculateBuffs(ply)
    local job = ply:getJobTable()

    -- 1. Get the new clean variables from the job file
    local baseHP = job.maxhealth or 100
    local baseArmor = job.armor or 0

    -- 2. Calculate totals
    local finalMax = baseHP + (buffs.hp or 0)
    local finalArmor = baseArmor + (buffs.armor or 0)

    -- 3. Apply Health
    ply:SetMaxHealth(finalMax)
    ply:SetHealth(finalMax) -- This "Heals to full" as you requested

    -- 4. Apply Armor
    ply:SetArmor(finalArmor)

    -- 5. Sync the MaxHP to the client HUD
    ply:SetNWInt("MaxHP", finalMax)
    ply:SetNWInt("MaxArmor", finalArmor)

end

-- Pay salary bonus on the same interval as DarkRP's payday timer.
-- DarkRP_PlayerEarned passes the team name (not "salary") as the reason,
-- so a standalone timer reading GAMEMODE.Config.paydelay is simpler and reliable.
hook.Add("InitPostEntity", "Vortex_SalaryBonus_Setup", function()
    local delay = (GAMEMODE and GAMEMODE.Config and GAMEMODE.Config.paydelay) or 160

    timer.Create("Vortex_SalaryBonus", delay, 0, function()
        for _, ply in ipairs(player.GetAll()) do
            if not IsValid(ply) or not ply.SkillData or not ply:Alive() then continue end

            local buffs = SkillTrees:CalculateBuffs(ply)
            if not buffs.salary_bonus or buffs.salary_bonus <= 0 then continue end

            local job = ply:getJobTable()
            local baseSalary = job and job.salary or 0
            if baseSalary <= 0 then continue end

            local bonus = math.Round(baseSalary * buffs.salary_bonus)
            if bonus > 0 then
                ply:addMoney(bonus)
            end
        end
    end)
end)

local base_xp = 75
local xp_exponent = 1.2

function SkillTrees:GetRequiredXP(level)
    if level <= 0 then return BASE_XP end
    return math.floor(base_xp * math.pow(level,xp_exponent))
end

function SkillTrees:AddXP(ply, amount)
    if not IsValid(ply) or not ply.SkillData then return end

    local multiplier = self:GetPlayerMultipliers(ply)
    local finalAmount = math.Round(amount*multiplier)

    ply.SkillData.xp = (ply.SkillData.xp or 0) + finalAmount
    ply.SkillData.level = ply.SkillData.level or 1

    local required = self:GetRequiredXP(ply.SkillData.level)
    while ply.SkillData.xp >= required do
        ply.SkillData.xp = ply.SkillData.xp - required
        ply.SkillData.level = ply.SkillData.level + 1
        if ply.SkillData.level > 0 and (ply.SkillData.level % 2 == 0) then
            ply.SkillData.points = (ply.SkillData.points or 0) + 1
            ply:ChatPrint("[VORTEX] LEVEL UP! You are now level ".. ply.SkillData.level .." and earned 1 point!")
        else
            ply:ChatPrint("[VORTEX] LEVEL UP! You are now level ".. ply.SkillData.level)
        end


        required = self:GetRequiredXP(ply.SkillData.level)

        
        ply:EmitSound("garrysmod/save_load1.wav")
    end
    self:SaveAndSync(ply)
end

hook.Add("PlayerSpawn", "Vortex_Skills_JobOverride", function(ply)
    timer.Simple(0.5, function()
        if IsValid(ply) then
            SkillTrees:ApplyBuffs(ply)
        end 
    end)
end)


concommand.Add("vtx_skills_wipe_all", function(ply, cmd, args)
    if IsValid(ply) then return end -- Console only

    if args[1] ~= "confirm" then
        print("Type 'vtx_skills_wipe_all confirm' to delete all player data.")
        return
    end

    -- The correct GMod SQL syntax:
    sql.Query("DELETE FROM playerpdata WHERE infoid = 'vtx_skilldata'")
    for _, target in ipairs(player.GetAll()) do
        target.SkillData = { points = 0, skills = {} }
        SkillTrees:SaveAndSync(target)
    end

    print("[Vortex] Database Wiped Successfully.")
end)

-- hook.Add("ArcCW_ModifyRPM", "Vortex_Skills_FireRate", function(wep, rpm)
--     local ply = wep:GetOwner()
--     if not IsValid(ply) or not ply:IsPlayer() or not ply.SkillData then return end

--     local buffs = SkillTrees:CalculateBuffs(ply)

--     if buffs.firerate and buffs.firerate > 0 then
--         return rpm * (1 + buffs.firerate)
--     end
-- end)

local COMBAT_COOLDOWN = 15

hook.Add("SetupMove", "Vortex_Skills_Speed", function(ply, mv, cmd)
    local buffs = SkillTrees:CalculateBuffs(ply)

    if buffs and buffs.movespeed and buffs.movespeed > 0 then
        local multiplier = 1 + buffs.movespeed

        mv:SetMaxClientSpeed(mv:GetMaxClientSpeed() * multiplier)
        mv:SetMaxSpeed(mv:GetMaxSpeed() * multiplier)
    end
end)

timer.Create("Vortex_Skill_RegenTimer", 2, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if not ply:Alive() or not ply.SkillData then continue end
        
        local lastHit = ply.Vortex_LastDamageTime or 0
        if (CurTime() - lastHit) < COMBAT_COOLDOWN then
            continue
        end

        local buffs = SkillTrees:CalculateBuffs(ply)
        
        if buffs.hpregen and buffs.hpregen > 0 then
            local currentHP = ply:Health()
            local maxHP = ply:GetMaxHealth()
            if currentHP < maxHP then
                ply:SetHealth(math.min(maxHP, currentHP + buffs.hpregen))
            end
        end
        if buffs.armorregen and buffs.armorregen > 0 then
            local currentArmor = ply:Armor()
            local maxArmor = ply:GetNWInt("MaxArmor", 100)
            if currentArmor < maxArmor then
                ply:SetArmor(math.min(maxArmor, currentArmor + buffs.armorregen))
            end
        end
        if buffs.lscs_force_regen and buffs.lscs_force_regen > 0 and ply.lscsGetForce then
            local curForce = ply:lscsGetForce()
            local maxForce = ply:lscsGetMaxForce()
            if curForce < maxForce then
                ply:lscsSetForce(math.min(maxForce, curForce + buffs.lscs_force_regen))
            end
        end
    end
end)

hook.Add("ScalePlayerDamage", "Vortex_Skills_CombatAndResistance", function(ply, hitgroup, dmginfo)
    -- 1. Track Combat for Regen
    ply.Vortex_LastDamageTime = CurTime()

    -- 2. Handle Resistance
    local buffs = SkillTrees:CalculateBuffs(ply)
    if buffs and buffs.resistance and buffs.resistance > 0 then
        -- math.max(0.1) prevents players from being 100% immune (god mode)
        local scale = math.max(0.1, 1 - buffs.resistance)
        dmginfo:ScaleDamage(scale)
    end
end)

-- Ensure this starts on or around line 281

hook.Add("ArcCW_ModifyReloadTime", "Vortex_Skills_ReloadSpeed", function(wep, duration)
    local ply = wep:GetOwner()
    if not IsValid(ply) or not ply:IsPlayer() then return end

    local buffs = SkillTrees:CalculateBuffs(ply)

    if buffs.reloadspeed and buffs.reloadspeed > 0 then
        local mult = math.Clamp(1 - buffs.reloadspeed, 0.5, 1)
        return duration * mult
    end
end)

-- Bullet damage for TFA weapons. Server-only; EntityTakeDamage is the reliable way to scale
-- outgoing damage since TFA fires bullets through standard FireBullets.
-- IsTFAWeapon is the correct TFA marker field (not wep.TFA).
-- Fire rate and reload speed are handled in sh_hooks.lua via TFA_GetStat.
local function GoldenBulletsReward(attacker)
    if not IsValid(attacker) or not attacker:IsPlayer() or not attacker.SkillData then return end
    local buffs = SkillTrees:CalculateBuffs(attacker)
    if not buffs.salary_per_kill or buffs.salary_per_kill <= 0 then return end
    local job = attacker:getJobTable()
    local baseSalary = job and job.salary or 0
    if baseSalary <= 0 then return end
    local bonus = math.Round(baseSalary * buffs.salary_per_kill)
    if bonus > 0 then attacker:addMoney(bonus) end
end

hook.Add("PlayerDeath", "Vortex_GoldenBullets_PlayerKill", function(victim, inflictor, attacker)
    if not IsValid(attacker) or attacker == victim then return end
    GoldenBulletsReward(attacker)
end)

hook.Add("OnNPCKilled", "Vortex_GoldenBullets_NPCKill", function(npc, attacker, inflictor)
    GoldenBulletsReward(attacker)
end)

hook.Add("EntityTakeDamage", "Vortex_LSCS_Combat", function(target, dmginfo)
    if not dmginfo:IsDamageType(DMG_ENERGYBEAM) then return end

    local attacker = dmginfo:GetAttacker()
    if IsValid(attacker) and attacker:IsPlayer() and attacker.SkillData then
        local wep = attacker:GetActiveWeapon()
        if IsValid(wep) and wep.LSCS then
            local buffs = SkillTrees:CalculateBuffs(attacker)
            if buffs.lscs_damage and buffs.lscs_damage > 0 then
                dmginfo:ScaleDamage(1 + buffs.lscs_damage)
            end
        end
    end

    if target:IsPlayer() and target.SkillData then
        local buffs = SkillTrees:CalculateBuffs(target)
        if buffs.lscs_block and buffs.lscs_block > 0 then
            dmginfo:ScaleDamage(math.max(0.1, 1 - buffs.lscs_block))
        end
    end
end)

hook.Add("EntityTakeDamage", "Vortex_TFA_BulletDamage", function(target, dmginfo)
    if not dmginfo:IsBulletDamage() then return end

    local attacker = dmginfo:GetAttacker()
    if not IsValid(attacker) or not attacker:IsPlayer() then return end

    local wep = attacker:GetActiveWeapon()
    if not IsValid(wep) or not wep.IsTFAWeapon then return end

    local buffs = SkillTrees:CalculateBuffs(attacker)
    if buffs.damage and buffs.damage > 0 then
        dmginfo:ScaleDamage(1 + buffs.damage)
    end
end)