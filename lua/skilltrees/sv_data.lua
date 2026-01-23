if SERVER then
    util.AddNetworkString("vtx_skills_sync")
    util.AddNetworkString("vtx_skills_purchase")
end

local PDATA_KEY = "vtx_skilldata"

hook.Add("PlayerInitialSpawn", "SkillTrees_Load", function(ply)
    local timerID = "SkillTree_Load_" .. ply:SteamID64()
    timer.Create(timerID, 1, 5, function()
        if not IsValid(ply) then timer.Remove(timerID) return end

        local data = ply:GetPData(PDATA_KEY, nil)

        if data then
            ply.SkillData = util.JSONToTable(data)
        end

        if not ply.SkillData then 
            ply.SkillData = { points = 5, skills = {}}
        end
        
        if ply.SkillData and type(ply.SkillData) == "table" then
            net.Start("vtx_skills_sync")
            net.WriteTable(ply.SkillData)
            net.Send(ply)
            print("[Vortex Skill Trees] Data Synced for ", ply:Nick())
            timer.Remove(timerID)
        end
    end)
end)

concommand.Add("vtx_skills_reset", function(ply, cmd, args)
    -- Check if it's a console command or if the player is Admin
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    local target = ply
    -- If you type 'vtx_skills_reset playerName', it resets them instead
    if args[1] then
        target = player.GetByText(args[1])
    end

    if IsValid(target) then
        -- Wipe the PData entry
        target:RemovePData("vtx_skilldata")
        
        -- Reset the live table so the change happens immediately
        target.SkillData = {
            points = 5,
            skills = {}
        }
        
        target:ChatPrint("Skill data has been reset!")
    end
end)