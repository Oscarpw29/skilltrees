util.AddNetworkString("vtx_skills_purchase")

net.Receive("vtx_skills_purchase", function(len, ply)
    local skillID = net.ReadString()
    print("[Debug] Recieved purcahse request from".. ply:Nick().. " for " .. skillID)
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
    print("[DEBUG] Comparing Level: ", currentLevel, " to Max: ", skillInfo.maxLevel)
    local cost = skillInfo.price or 1
    if currentLevel >= (skillInfo.maxLevel or 1) then ply:ChatPrint("You are already max level") return end
    if (ply.SkillData.points or 0) < cost then return end
    
    ply.SkillData.points = ply.SkillData.points - cost
    ply.SkillData.skills[skillID] = (ply.SkillData.skills[skillID] or 0) +1

    ply:ChatPrint(skillInfo.name .. " Upgraded to level".. (currentLevel + 1))
    SkillTrees:SaveAndSync(ply)

    ply:SetPData("vtx_skilldata", util.TableToJSON(ply.SkillData))
end)

function SkillTrees:SaveAndSync(ply)
    if not IsValid(ply) or not ply.SkillData then return end
    local json = util.TableToJSON(ply.SkillData)
    ply:SetPData("vtx_skilldata", json)

    net.Start("vtx_skills_sync")
        net.WriteTable(ply.SkillData)
    net.Send(ply)
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
    local target = player
    if IsValid(target) then 
        target.SkillData = target.SkillData or { points = 0, skills = {} }
        target.skillData.points = target.SkillData.points + amount
        
        target:ChatPrint("Debug Added " .. amount .. " points, new total" .. target.SkillData.points)
        net.Start(vtx_update_skills)
            net.WriteTable(target.SkillData)
        net.Send(target)

        if SkillTrees.SavePlayerData then
            SkillTrees:SavePlayerData(target)
        end
    end
end)