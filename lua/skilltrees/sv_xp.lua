hook.Add("OnNPCKilled", "Vortex_SimpleNPCXP", function(npc, attacker, inflictor)
    local ply = (attacker:IsPlayer() and attacker) or (attacker.GetPlayerColor and attacker:GetOwner())
    if IsValid(ply) and ply:IsPlayer() then
        local baseXP = SkillTrees.NPC_XP_REWARD
        SkillTrees:AddXP(attacker, baseXP)
    end
end)

local PASSIVE_XP = 25
local PASSIVE_TIME = 300

timer.Create("Vortex_PassiveXP_Timer", PASSIVE_TIME, 0, function ()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Team() ~= TEAM_SPECTATOR then
            local multi = SkillTrees:GetPlayerMultiplier(ply)
            SkillTrees:AddXP(ply, PASSIVE_XP)
            local finalxp = PASSIVE_XP * multi
            ply:ChatPrint("Passive XP Recieved: " .. finalxp)
        end
    end
end)

function SkillTrees:GetPlayerMultipliers(ply)
    local rank = ply:GetUserGroup()
    local multiplier = self.RankMultipliers[rank] or 1.0
    return multiplier
end