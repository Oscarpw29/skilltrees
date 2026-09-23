-- Raise a player's level, granting the points earned between the old and new level.
-- Returns levels gained and points granted.
function SkillTrees:SetLevel(ply, newLevel, bonusPoints)
    local data = ply.SkillData
    local oldLevel = data.level
    newLevel = math.Clamp(newLevel, 1, self.MaxLevel)
    if newLevel <= oldLevel then return 0, 0 end

    local points = bonusPoints or (self:PointsForLevel(newLevel) - self:PointsForLevel(oldLevel))
    data.level  = newLevel
    data.points = data.points + points
    if newLevel >= self.MaxLevel then data.xp = 0 end

    return newLevel - oldLevel, points
end

-- `raw` skips the rank/skill XP multiplier (admin grants). Returns the XP actually awarded.
function SkillTrees:AddXP(ply, amount, raw)
    if not IsValid(ply) or not ply.SkillData or not ply.SkillDataLoaded then return 0 end
    local data = ply.SkillData
    if data.level >= self.MaxLevel then return 0 end

    local gained = raw and math.Round(amount) or math.Round(amount * self:GetPlayerMultiplier(ply))
    data.xp = data.xp + gained

    local required = self:GetRequiredXP(data.level)
    while data.level < self.MaxLevel and data.xp >= required do
        data.xp = data.xp - required
        local _, points = self:SetLevel(ply, data.level + 1)

        if points > 0 then
            ply:ChatPrint("[VORTEX] LEVEL UP! You are now level " .. data.level .. " and earned " .. points .. " skill point(s)!")
        else
            ply:ChatPrint("[VORTEX] LEVEL UP! You are now level " .. data.level)
        end
        ply:EmitSound("garrysmod/save_load1.wav")

        required = self:GetRequiredXP(data.level)
    end

    self:SaveAndSync(ply)
    return gained
end

-- Admin helper: add levels, with explicit points or (nil) the normal rate
function SkillTrees:AddLevels(ply, amount, bonusPoints)
    if not IsValid(ply) or not ply.SkillData or not ply.SkillDataLoaded then return 0, 0 end
    local gained, points = self:SetLevel(ply, ply.SkillData.level + amount, bonusPoints)
    if gained > 0 then self:SaveAndSync(ply) end
    return gained, points
end

hook.Add("OnNPCKilled", "Vortex_SimpleNPCXP", function(npc, attacker)
    if not IsValid(attacker) then return end
    -- Credit the owner when the killer is something a player controls (e.g. a turret)
    local ply = attacker:IsPlayer() and attacker or (attacker.GetOwner and attacker:GetOwner())
    if IsValid(ply) and ply:IsPlayer() then
        SkillTrees:AddXP(ply, SkillTrees.NPC_XP_REWARD)
    end
end)

timer.Create("Vortex_PassiveXP_Timer", SkillTrees.PASSIVE_INTERVAL, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == TEAM_SPECTATOR then continue end
        local gained = SkillTrees:AddXP(ply, SkillTrees.PASSIVE_XP)
        if gained > 0 then
            ply:ChatPrint("Passive XP received: " .. gained)
        end
    end
end)
