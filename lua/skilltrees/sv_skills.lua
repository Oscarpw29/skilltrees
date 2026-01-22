util.AddNetworkString("vtx_skills_purchase")

net.Receive("vtx_skills_purchase", function(len, ply)
    local skillID = net.ReadString()
    local skill = SkillTrees.Skills[skillID]

    if not skill or not ply.SkillData then return end

    if skill.requirement then
        local reqId = skill.requirement
        local ownedReq = ply.SkillData.skills[reqId] or 0

        if ownedReq <= 0 then
            ply:ChatPrint("Locked you need to buy".. (SkillTrees.Skills[reqId].name or reqId).. "first.")
            return 
        end
    end

    if skill.allowedJobs then
        local jobName = team.GetName(ply:Team())
        if not table.HasValue(skill.allowedJobs, jobName) then
            ply:ChatPrint("Your current job cannot learn this!")
            return 
        end
    end

    if skill.allowedSteamIDs and not table.HasValue(skill.allowedSteamIDs, ply:SteamID()) then
        ply:ChatPrint("You do not have permission to use this skill.")
        return 
    end

    local current = ply.SkillData.skills[skillID] or 0
    if current >= skill.maxLevel then return end
    if ply.SkillData.points <= 0 then return end
    
    ply.SkillData.points = ply.SkillData.points - 1
    ply.SkillData.skills[skillID] = current + 1

    ply:ChatPrint(skill.name .. " Upgraded to level".. (current + 1))

    ply:SetPData("skilltrees", util.TableToJSON(ply.SkillData))
end)

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
end)