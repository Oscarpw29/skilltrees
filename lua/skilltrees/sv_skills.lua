util.AddNetworkString("vtx_skills_purchase")
util.AddNetworkString("vtx_skills_reset")

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
    if not IsValid(ply) then return  end

    local buffs = SkillTrees:CalculateBuffs(ply)

    local baseHP = (ply.GetJobTable and ply:GetJobTable().maxhealth) or 100
    local baseArmor = (ply.GetJobTable and ply:GetJobTable().armor) or 50
    local baseSpeed = (ply.GetJobTable and ply:GetJobTable().walkspeed) or 200
    local baseRun = (ply.GetJobTable and ply:GetJobTable().runspeed) or 400

    local newMaxHP = baseHP + buffs.hp
    local newArmor = baseArmor + buffs.armor
    local newWalk = baseSpeed + buffs.speed
    local newRun = baseRun + buffs.speed
    
    ply:SetMaxHealth(newMaxHP)
    ply:SetNWInt("MaxArmor", newArmor)
    ply:SetWalkSpeed(newWalk)
    ply:SetRunSpeed(newRun)

    if ply:Armor() < buffs.armor then
        ply:SetArmor(buffs.armor)
    end
    
end

local base_xp = 100
local xp_exponent = 1.5

function SkillTrees:GetRequiredXP(level)
    if level <= 0 then return BASE_XP end
    return math.floor(base_xp * math.pow(level,xp_exponent))
end

function SkillTrees:AddXP(ply, amount)
    if not IsValid(ply) or not ply.SkillData then return end

    local multiplier = self:GetPlayerMultiplier(ply)
    local finalAmount = math.Round(amount*multiplier)

    ply.SkillData.xp = (ply.SkillData.xp or 0) + amount
    ply.SkillData.level = ply.SkillData.level or 1

    local required = self:GetRequiredXP(ply.SkillData.level)

    while ply.SkillData.xp >= required do
        ply.SkillData.xp = ply.SkillData.xp - required
        ply.SkillData.level = ply.SkillData.level + 1
        ply.SkillData.points = (ply.SkillData.Points or 0) + 1

        required = self:GetRequiredXP(ply.SkillData.level)

        ply:ChatPrint("[VORTEX] LEVEL UP! You are now level ".. ply.SkillData.level)
        ply:EmitSound("garrysmod/save_load1.wav")
    end
    self:SaveAndSync(ply)
end

concommand.Add("vtx_skills_wipe_all", function(ply, cmd, args)
    -- 1. Permission Check
    -- Allow execution from Server Console (ply is NULL) or SuperAdmin
    if IsValid(ply) and not ply:IsSuperAdmin() then 
        ply:ChatPrint("Access Denied: You must be a SuperAdmin to wipe all skill data.")
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
            points = 5, -- Or whatever your starting points are
            skills = {}
        }
        target:ChatPrint("[SkillTrees] An administrator has wiped all global skill data.")
    end

    print("[SkillTrees] SUCCESS: All player skill data has been deleted from the database.")
    SkillTrees:SaveAndSync(ply)
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