local COMMIT_COOLDOWN = 0.25
local MAX_ENTRIES     = 64

-- Save { id = levelsToAdd } for a player as one all-or-nothing transaction.
-- Returns ok, reason, levelsAdded.
function SkillTrees:CommitLevels(ply, adds)
    local data = ply.SkillData
    if not data or not ply.SkillDataLoaded then return false, "Your skill data is still loading.", 0 end

    local skills, points, applied, leftover, reason = self:ApplyLevels(ply, data.skills, data.points, adds)
    if leftover > 0 then return false, reason or "Those skills can't be learned.", 0 end

    local added = 0
    for _, n in pairs(applied) do added = added + n end
    if added == 0 then return false, "Nothing to save.", 0 end

    data.skills = skills
    data.points = points

    self:SaveAndSync(ply)
    self:ApplyBuffs(ply)

    net.Start("Vortex_RefreshWeapon")
    net.Send(ply)

    return true, nil, added
end

net.Receive("vtx_skills_commit", function(len, ply)
    if (ply.VtxNextCommit or 0) > CurTime() then return end
    ply.VtxNextCommit = CurTime() + COMMIT_COOLDOWN

    local count = math.min(net.ReadUInt(8), MAX_ENTRIES)
    local adds = {}
    for _ = 1, count do
        local id = net.ReadString()
        local n  = net.ReadUInt(8)
        if SkillTrees:GetSkill(id) and n > 0 then
            adds[id] = (adds[id] or 0) + n
        end
    end

    local ok, reason, added = SkillTrees:CommitLevels(ply, adds)
    if ok then
        ply:ChatPrint("[VORTEX] Learned " .. added .. " skill rank(s).")
    else
        ply:ChatPrint("[VORTEX] " .. reason)
        -- Resync so the menu drops anything it staged against stale data
        SkillTrees:SaveAndSync(ply)
    end
end)

function SkillTrees:ResetSkills(ply)
    local data = ply.SkillData
    if not data or not ply.SkillDataLoaded then return 0 end

    local refund = 0
    for id, level in pairs(data.skills) do
        local info = self:GetSkill(id)
        if info then refund = refund + (info.price or 1) * level end
    end

    data.points = data.points + refund
    data.skills = {}

    self:SaveAndSync(ply)
    self:ApplyBuffs(ply)

    net.Start("Vortex_RefreshWeapon")
    net.Send(ply)

    return refund
end

net.Receive("vtx_skills_reset", function(len, ply)
    if (ply.VtxNextCommit or 0) > CurTime() then return end
    ply.VtxNextCommit = CurTime() + COMMIT_COOLDOWN

    local refund = SkillTrees:ResetSkills(ply)
    ply:ChatPrint("[VORTEX] Skills reset. Refunded " .. refund .. " point(s).")
end)

function SkillTrees:ApplyBuffs(ply)
    if not IsValid(ply) or not ply.SkillData then return end

    local job = ply.getJobTable and ply:getJobTable()
    if not job then return end

    local buffs = self:CalculateBuffs(ply)
    local maxHP = (job.maxhealth or 100) + buffs.hp
    local armor = (job.armor or 0) + buffs.armor

    ply:SetMaxHealth(maxHP)
    ply:SetHealth(maxHP) -- heal to full on purchase/spawn, intended
    ply:SetArmor(armor)

    ply:SetNWInt("MaxHP", maxHP)
    ply:SetNWInt("MaxArmor", armor)
end

hook.Add("PlayerSpawn", "Vortex_Skills_JobOverride", function(ply)
    timer.Simple(0.5, function()
        if IsValid(ply) then SkillTrees:ApplyBuffs(ply) end
    end)
end)
