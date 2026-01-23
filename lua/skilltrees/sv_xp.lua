hook.Add("OnNPCKilled", "Vortex_SimpleNPCXP", function(npc, attacker, inflictor)
    if IsValid(attacker) and attacker:IsPlayer() then
        local baseXP = SkillTrees.NPC_XP_REWARD
        SkillTrees:AddXP(attacker, baseXP)
    end
end)

local PASSIVE_XP = 25
local PASSIVE_TIME = 300

timer.Create("Vortex_PassiveXP_Timer", PASSIVE_TIME, 0, function ()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Team() ~= TEAM_SPECTATOR then
            SkillTrees:AddXP(ply, PASSIVE_XP)
            ply:ChatPrint("Passive XP Recieved: " .. PASSIVE_XP)
        end
    end
end)