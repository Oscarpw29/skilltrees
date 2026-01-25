if SERVER then
    util.AddNetworkString("vtx_skills_sync")
    util.AddNetworkString("vtx_skills_purchase")
end

local PDATA_KEY = "vtx_skilldata"

hook.Add("PlayerInitialSpawn", "SkillTrees_Load", function(ply)
    local steamid = ply:SteamID64()

    ply.SkillData = {
        xp = 0,
        level = 1,
        points = 0,
        skills = {}
    }

    timer.Simple(2, function()
        if not IsValid(ply) then return end

        local data = ply:GetPData(PDATA_KEY, nil)
        
        if data and data ~= "" then
            local decoded = util.JSONToTable(data)
            if decoded then
                ply.SkillData = decoded
                print("[Skills] Loaded data for " .. ply:Nick())
                ply.SkillData.skills = ply.SkillData.skills or {}
            end
        end

        if not ply.SkillData then 
            ply.SkillData = { points = 10, skills = {} }
            print("[Skills] New player detected: " .. ply:Nick())
        end
        
        -- Final Sync
        if SkillTrees.SaveAndSync then
            SkillTrees:SaveAndSync(ply)
        else
            net.Start("vtx_skills_sync")
                net.WriteTable(ply.SkillData)
            net.Send(ply)
        end
    SkillTrees:ApplyBuffs(ply)
    end)
end)

hook.Add("OnPlayerChangedTeam", "Vortex_Skills_TeamSwitch", function(ply, oldTeam, newTeam)
    -- We use a slightly longer delay (1 second)
    -- This allows MC Ranks to finish its buggy network messages first
    timer.Simple(1, function()
        if IsValid(ply) then
            -- Safely refresh the skill buffs
            if SkillTrees and SkillTrees.ApplyBuffs then
                SkillTrees:ApplyBuffs(ply)
            end
        end
    end)
end)