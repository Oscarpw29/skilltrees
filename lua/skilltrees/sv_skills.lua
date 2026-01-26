util.AddNetworkString("vtx_skills_purchase")
util.AddNetworkString("vtx_skills_reset")
util.AddNetworkString("vtx_skills_menu")

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

    ply:ChatPrint(skillInfo.name .. " Upgraded to level".. (currentLevel + 1))
    SkillTrees:SaveAndSync(ply)
    SkillTrees:ApplyBuffs(ply)

    ply:SetPData("vtx_skilldata", util.TableToJSON(ply.SkillData))
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
    
end

local base_xp = 100
local xp_exponent = 1.5

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
        if ply.SkillData.level > 0 and (ply.SkillData.level % 3 == 0) then
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


concommand.Add("vtx_skills_give_points", function(ply, cmd, args)
    local amount = tonumber(args[1] or 10)
    local target = ply
    if not IsValid(target) then return end 
    target.SkillData = target.SkillData or { points = 0, skills = {} }
    target.SkillData.points = target.SkillData.points + amount
       
    target:ChatPrint("Debug Added " .. amount .. " points, new total" .. target.SkillData.points)
        

    if SkillTrees and SkillTrees.SaveAndSync then
        SkillTrees:SaveAndSync(target)
    else
        net.Start("vtx_update_skills")
            net.WriteTable(target.SkillData)
        net.Send(target)
    end
end)

concommand.Add("vtx_skills_wipe_all", function(ply, cmd, args)
    -- 1. Permission Check
    -- Allow execution from Server Console (ply is NULL) or SuperAdmin
    if IsValid(ply) then 
        ply:PrintMessage(HUD_PRINTCONSOLE, "[Vortex] This command can only be run from the SERVER console for security.")
        return 
    end

    -- 2. Confirmation Check
    -- Prevents accidental wipes. Must type: vtx_skills_wipe_all confirm
    if args[1] ~= "confirm" then
        local msg = "WARNING: This will delete ALL skill levels and points for EVERY player. Type 'vtx_skills_wipe_all confirm' to proceed."
        if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end
        return
    end

    -- 3. The Database Wipe
    -- This removes the entry from the global PData table in sv.db
    sql.Query("DELETE FROM playerpdata WHERE infoid = 'vtx_skilldata'")

    -- 4. Immediate Live Reset
    -- We must reset players currently on the server so they don't overwrite the wipe when they leave
    for _, target in ipairs(player.GetAll()) do
        target.SkillData = {
            points = 0, -- Or whatever your starting points are
            skills = {}
        }
        target:ChatPrint("[SkillTrees] An administrator has wiped all global skill data.")
    end

    print("[SkillTrees] SUCCESS: All player skill data has been deleted from the database.")
    SkillTrees:SaveAndSync(ply)
end)

hook.Add("ArcCW_ModifyRPM", "Vortex_Skills_FireRate", function(wep, rpm)
    local ply = wep:GetOwner()
    if not IsValid(ply) or not ply:IsPlayer() or not ply.SkillData then return end

    local buffs = SkillTrees:CalculateBuffs(ply)

    if buffs.firerate and buffs.firerate > 0 then
        return rpm * (1 + buffs.firerate)
    end
end)

local COMBAT_COOLDOWN = 15

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
    end
end)

hook.Add("EntityTakeDamage", "Vortex_Skills_CombatTracker", function(target, dmginfo)
    if IsValid(target) and target:IsPlayer() then
        target.Vortex_LastDamageTime = CurTime()
    end    
end)

hook.Add("EntityTakeDamage", "Vortex_Skills_Resistance", function(target, dmginfo)
    if IsValid(target) and target:IsPlayer() then
        local buffs = SkillTrees:CalculateBuffs(target)
        if buffs.resistance and buffs.resistance > 0 then
            local scale = math.max(0, 1 - buffs.resistance)
            dmginfo:ScaleDamage(scale)
        end    
    end
end)

hook.Add("DarkRP_SalaryPayload", "Vortex_Skills_Salary", function(ply, amount)
    local buffs = SkillTrees:CalculateBuffs(ply)
    if buffs.salary_bonus and buffs.salary_bonus > 0 then
        return amount + (amount * buffs.salary_bonus)
    end    
end)

hook.Add("ArcCW_ModifyReloadTime", "Vortex_Skills_ReloadSpeed", function(wep, duration)
    local ply = wep:GetOwner()
    if not IsValid(ply) or not ply:IsPlayer() then return end

    local buffs = SkillTrees:CalculateBuffs(ply)

    if buffs.reloadspeed and buffs.reloadspeed > 0 then
        local mult = math.Clamp(1 - buffs.reloadspeed, 0.5, 1)
        return duration * mult
    end
end)