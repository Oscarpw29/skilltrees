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
            local multi = self:SkillTrees:GetPlayerMultiplier(ply)
            SkillTrees:AddXP(ply, PASSIVE_XP)
            local finalxp = PASSIVE_XP * multi
            ply:ChatPrint("Passive XP Recieved: " .. finalxp)
        end
    end
end)

function SkillTrees:GetPlayerMultiplier(ply)
    local rank = ply:GetUserGroup()
    local multiplier = self.RankMultipliers[rank] or 1.0
    return multipler
end