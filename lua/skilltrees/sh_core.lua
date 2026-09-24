-- Shared rules. Both the server (to enforce) and the menu (to display) go through these,
-- so what the menu says you can do is exactly what the server allows.
SkillTrees = SkillTrees or {}

-- Every stat a skill's `buffs` table can use. Values are per skill level.
-- `pct` stats are fractions (0.05 = 5%) and are shown as percentages in the menu.
-- `icon` is the node icon used when a skill doesn't set its own `icon` (built-in silk icons).
SkillTrees.StatLabels = {
    hp               = { label = "Max Health",    icon = "icon16/heart.png" },
    armor            = { label = "Armor",         icon = "icon16/shield.png" },
    speed            = { label = "Speed",         icon = "icon16/user_go.png" },
    hpregen          = { label = "Health Regen",  icon = "icon16/heart_add.png",   suffix = " / 2s" },
    armorregen       = { label = "Armor Regen",   icon = "icon16/shield_add.png",  suffix = " / 2s" },
    firerate         = { label = "Fire Rate",     icon = "icon16/lightning.png",   pct = true },
    reloadspeed      = { label = "Reload Speed",  icon = "icon16/arrow_refresh.png", pct = true },
    movespeed        = { label = "Move Speed",    icon = "icon16/user_go.png",     pct = true },
    resistance       = { label = "Damage Resist", icon = "icon16/shield.png",      pct = true },
    damage           = { label = "Bullet Damage", icon = "icon16/bomb.png",        pct = true },
    salary_bonus     = { label = "Salary",        icon = "icon16/money.png",       pct = true },
    salary_per_kill  = { label = "Pay per Kill",  icon = "icon16/money_add.png",   pct = true },
    lscs_damage      = { label = "Saber Damage",  icon = "icon16/wand.png",        pct = true },
    lscs_force_regen = { label = "Force Regen",   icon = "icon16/wand.png",        suffix = " / 2s" },
    lscs_block       = { label = "Saber Block",   icon = "icon16/shield.png",      pct = true },
    xp_boost         = { label = "XP Gain",       icon = "icon16/star.png",        pct = true },
}

function SkillTrees:BuildIndex()
    self.SkillIndex       = {}
    self.Buffs            = {} -- id -> buffs, kept for anything outside the addon that still reads it
    self.TreeOrder        = {}
    self.AttachmentLocks  = {} -- attachment id -> { skills = { skill ids }, trees = { tree names } }

    local function lock(att)
        self.AttachmentLocks[att] = self.AttachmentLocks[att] or { skills = {}, trees = {} }
        return self.AttachmentLocks[att]
    end

    for treeName, tree in pairs(self.Tree or {}) do
        table.insert(self.TreeOrder, treeName)
        for _, att in ipairs(tree.Attachments or {}) do
            table.insert(lock(att).trees, treeName)
        end
        for id, info in pairs(tree.Skills or {}) do
            self.SkillIndex[id] = { info = info, tree = treeName }
            self.Buffs[id] = info.buffs
            for _, att in ipairs(info.unlocks or {}) do
                table.insert(lock(att).skills, id)
            end
        end
    end
    for _, att in ipairs(self.LockedAttachments or {}) do lock(att) end

    table.sort(self.TreeOrder, function(a, b)
        local oa, ob = self.Tree[a].Order or math.huge, self.Tree[b].Order or math.huge
        if oa ~= ob then return oa < ob end
        return a < b
    end)
end

function SkillTrees:GetSkill(skillID)
    local entry = self.SkillIndex[skillID]
    if not entry then return nil, nil end
    return entry.info, entry.tree
end

function SkillTrees:GetRequiredXP(level)
    level = math.max(level or 1, 1)
    return math.floor(self.XP_BASE * math.pow(level, self.XP_EXPONENT))
end

function SkillTrees:GetPlayerMultiplier(ply)
    if not IsValid(ply) then return 1 end
    local mult = self.RankMultipliers[ply:GetUserGroup()] or 1
    local boost = self:CalculateBuffs(ply).xp_boost
    if boost > 0 then mult = mult * (1 + boost) end
    return mult
end

-- Access

local function listHas(list, value)
    for _, v in pairs(list) do
        if v == value then return true end
    end
    return false
end

-- Strict access: does this player's unit/job/rank own the tree?
-- The menu additionally lets superadmins *view* every tree; that's a UI choice, not access.
function SkillTrees:CanAccessTree(ply, treeName)
    local tree = self.Tree[treeName]
    if not tree or not IsValid(ply) then return false end

    if not tree.Teams and not tree.MRSGroup and not tree.Ranks and not tree.SteamIDs then
        return true
    end

    if tree.Teams then
        local t = ply:Team()
        if listHas(tree.Teams, t) or listHas(tree.Teams, team.GetName(t)) then return true end
    end
    if tree.MRSGroup and MRS and MRS.GetNWdata and listHas(tree.MRSGroup, MRS.GetNWdata(ply, "Group")) then
        return true
    end
    if tree.Ranks and listHas(tree.Ranks, ply:GetUserGroup()) then return true end
    if tree.SteamIDs and listHas(tree.SteamIDs, ply:SteamID()) then return true end

    return false
end

-- Levels & points

-- Total skill points a player has earned by reaching `level` (level 1 earns none)
function SkillTrees:PointsForLevel(level, every)
    every = every or self.POINTS_EVERY_N_LEVELS
    level = math.max(level or 1, 1)
    return math.floor(level / every) - math.floor(1 / every)
end

-- Skill state
-- Functions below take an explicit `skills` table ({ id = level }) so the menu can ask the
-- same questions about its staged (unsaved) allocation that the server asks about saved data.

function SkillTrees:GetRowGate(row)
    return ((row or 1) - 1) * self.ROW_POINTS
end

-- Points spent in `treeName` in rows above `row`
function SkillTrees:SpentBelowRow(skills, treeName, row)
    local tree = self.Tree[treeName]
    local spent = 0
    for id, info in pairs(tree and tree.Skills or {}) do
        if (info.row or 1) < row then
            spent = spent + (info.price or 1) * (skills[id] or 0)
        end
    end
    return spent
end

-- Is the skill's row open and its requirement maxed? Returns ok, reason.
-- `level` is optional; when given, the skill's minLevel is checked too.
function SkillTrees:IsUnlocked(skills, skillID, level)
    local info, treeName = self:GetSkill(skillID)
    if not info then return false, "Unknown skill." end

    if level and info.minLevel and level < info.minLevel then
        return false, "Requires level " .. info.minLevel .. "."
    end

    local row = info.row or 1
    local need = self:GetRowGate(row) - self:SpentBelowRow(skills, treeName, row)
    if need > 0 then
        return false, "Spend " .. need .. " more point(s) in " .. treeName .. " to unlock row " .. row .. "."
    end

    if info.requirement then
        local req = self:GetSkill(info.requirement)
        if (skills[info.requirement] or 0) < (req and req.maxLevel or 1) then
            return false, "Requires " .. (req and req.name or info.requirement) .. " at max rank."
        end
    end

    return true
end

-- "locked" | "available" | "partial" | "maxed", current level, max level
function SkillTrees:GetSkillStatus(skills, skillID, level)
    local info = self:GetSkill(skillID)
    if not info then return "locked", 0, 1 end

    skills = skills or {}
    local cur = skills[skillID] or 0
    local max = info.maxLevel or 1

    if cur >= max then return "maxed", cur, max end
    if not self:IsUnlocked(skills, skillID, level) then return "locked", cur, max end
    if cur > 0 then return "partial", cur, max end
    return "available", cur, max
end

-- Can `ply` add one level of `skillID` on top of `skills` with `points` unspent? Returns ok, reason.
function SkillTrees:CanAddLevel(ply, skills, points, skillID)
    local info, treeName = self:GetSkill(skillID)
    if not info then return false, "Unknown skill." end

    if not self:CanAccessTree(ply, treeName) then
        return false, "Your unit can't learn " .. treeName .. " skills."
    end
    if info.allowedJobs and not listHas(info.allowedJobs, team.GetName(ply:Team())) then
        return false, "Your current job can't learn this."
    end
    if info.allowedSteamIDs and not listHas(info.allowedSteamIDs, ply:SteamID()) then
        return false, "You don't have permission to learn this."
    end

    if (skills[skillID] or 0) >= (info.maxLevel or 1) then
        return false, "Already at max rank."
    end

    local ok, reason = self:IsUnlocked(skills, skillID, ply.SkillData and ply.SkillData.level or 1)
    if not ok then return false, reason end

    local cost = info.price or 1
    if points < cost then
        return false, "Need " .. (cost - points) .. " more point(s)."
    end

    return true
end

-- Can one level of `skillID` be taken back from `skills` without stranding another skill?
-- Only levels above `floor` (the saved level) can be removed. Skills that were already
-- invalid before the removal (e.g. after a config change) don't block it.
function SkillTrees:CanRemoveLevel(skills, skillID, floor)
    local cur = skills[skillID] or 0
    if cur <= (floor or 0) then return false, "That rank is already saved." end

    local _, treeName = self:GetSkill(skillID)
    local tree = self.Tree[treeName]

    local after = table.Copy(skills)
    after[skillID] = cur - 1

    for id in pairs(tree and tree.Skills or {}) do
        if id ~= skillID and (skills[id] or 0) > 0 and self:IsUnlocked(skills, id) and not self:IsUnlocked(after, id) then
            local other = self:GetSkill(id)
            return false, other.name .. " depends on this."
        end
    end

    return true
end

-- Apply { id = levelsToAdd } on top of `skills`/`points` one level at a time through
-- CanAddLevel, so order doesn't matter (a row-2 skill waits until enough row-1 levels are in).
-- Returns newSkills, newPoints, applied ({ id = n }), leftover (levels that couldn't go in), reason.
function SkillTrees:ApplyLevels(ply, skills, points, adds)
    skills = table.Copy(skills)
    local pending, applied, leftover, reason = table.Copy(adds), {}, 0, nil

    local progress = true
    while progress do
        progress = false
        for id, n in pairs(pending) do
            if n > 0 then
                local ok, why = self:CanAddLevel(ply, skills, points, id)
                if ok then
                    skills[id] = (skills[id] or 0) + 1
                    points = points - (self:GetSkill(id).price or 1)
                    pending[id] = n - 1
                    applied[id] = (applied[id] or 0) + 1
                    progress = true
                else
                    reason = why
                end
            end
        end
    end

    for _, n in pairs(pending) do leftover = leftover + n end
    return skills, points, applied, leftover, reason
end

-- Convenience for a single immediate purchase against saved data
function SkillTrees:CanPurchase(ply, skillID)
    local data = ply.SkillData
    if not data or not data.skills then return false, "Your skill data is still loading." end
    return self:CanAddLevel(ply, data.skills, data.points or 0, skillID)
end

-- Attachments

-- Can `ply` use an ArcCW attachment? An attachment that no skill `unlocks`, no tree's
-- `Attachments` and no LockedAttachments entry names is always allowed. Otherwise the player
-- needs one of those skills or access to one of those trees.
function SkillTrees:CanUseAttachment(ply, attID)
    local lock = self.AttachmentLocks[attID]
    if not lock then return true end
    if not IsValid(ply) or not ply:IsPlayer() then return false end

    -- Clients only receive their own skill data; don't hide other players' attachments
    if CLIENT and ply ~= LocalPlayer() then return true end

    for _, treeName in ipairs(lock.trees) do
        if self:CanAccessTree(ply, treeName) then return true end
    end

    local skills = ply.SkillData and ply.SkillData.skills
    if not skills then return false end
    for _, id in ipairs(lock.skills) do
        if (skills[id] or 0) > 0 then return true end
    end
    return false
end

-- Wrap Hook_Compatible on every locked ArcCW attachment so the lock applies without editing
-- attachment files. Safe to call repeatedly; runs whenever ArcCW (re)loads its attachments.
function SkillTrees:PatchArcCW()
    if not ArcCW or not ArcCW.AttachmentTable then return end
    for attID in pairs(self.AttachmentLocks) do
        local atttbl = ArcCW.AttachmentTable[attID]
        if atttbl and not atttbl.VtxSkillLock then
            local original = atttbl.Hook_Compatible
            atttbl.VtxSkillLock = true
            atttbl.Hook_Compatible = function(wep, data)
                if SkillTrees.AttachmentLocks[attID] and not SkillTrees:CanUseAttachment(wep:GetOwner(), attID) then
                    return false
                end
                if original then return original(wep, data) end
            end
        end
    end
end

hook.Add("ArcCW_PostLoadAtts", "SkillTrees_PatchAttachments", function() SkillTrees:PatchArcCW() end)
hook.Add("InitPostEntity", "SkillTrees_PatchAttachments", function() SkillTrees:PatchArcCW() end)

-- Points spent in a tree and the most it can take
function SkillTrees:GetTreeProgress(skills, treeName)
    local tree = self.Tree[treeName]
    local spent, total = 0, 0
    if not tree then return 0, 0 end
    skills = skills or {}
    for id, info in pairs(tree.Skills or {}) do
        local price = info.price or 1
        spent = spent + price * (skills[id] or 0)
        total = total + price * (info.maxLevel or 1)
    end
    return spent, total
end

-- Buffs

-- Summed stats for a player, cached until InvalidateBuffs. This runs from SetupMove and
-- damage/weapon hooks, so it must stay cheap. Every known stat is present (0 when unused).
function SkillTrees:CalculateBuffs(ply)
    if not IsValid(ply) then return self:EmptyStats() end
    if ply.SkillBuffs then return ply.SkillBuffs end

    local stats = self:EmptyStats()
    local skills = ply.SkillData and ply.SkillData.skills
    if skills then
        for skillID, level in pairs(skills) do
            local info = self:GetSkill(skillID)
            local lvl = isnumber(level) and level or 0
            if info and info.buffs and lvl > 0 then
                for stat, amount in pairs(info.buffs) do
                    stats[stat] = (stats[stat] or 0) + amount * lvl
                end
            end
        end
    end

    -- OG_core is optional: if it's installed, fold in every other addon's contributed
    -- stats (e.g. OG_stims buffs) so every hook below picks them up for free.
    if OG and OG.Stats then
        for stat, amount in pairs(OG.Stats.Get(ply)) do
            stats[stat] = (stats[stat] or 0) + amount
        end
    end

    ply.SkillBuffs = stats
    return stats
end

function SkillTrees:InvalidateBuffs(ply)
    if IsValid(ply) then ply.SkillBuffs = nil end
end

-- When OG_core is installed, any addon (e.g. OG_stims) can call OG.Stats.Invalidate(ply)
-- to tell every stat consumer its cached total is stale. Recompute ours and, on the
-- server, re-apply HP/armor and refresh weapon stat caches the same way a skill respec
-- would (ApplyBuffs/RefreshWeapons already read straight through CalculateBuffs).
do -- registered unconditionally: OG_core may load after this addon (workshop mount order)
    hook.Add("OG_StatsChanged", "SkillTrees_OGStatsChanged", function(ply)
        if not IsValid(ply) or not ply.SkillData then return end
        SkillTrees:InvalidateBuffs(ply)
        if SERVER then
            SkillTrees:ApplyBuffs(ply, true)
            SkillTrees:RefreshWeapons(ply)
        end
    end)
end

function SkillTrees:EmptyStats()
    local stats = {}
    for stat in pairs(self.StatLabels) do stats[stat] = 0 end
    return stats
end

-- "+10" / "+5%" / "+2 / 2s"
function SkillTrees:FormatStat(stat, value)
    local def = self.StatLabels[stat] or {}
    local text
    if def.pct then
        text = string.format("%g%%", math.Round(value * 100, 1))
    else
        text = string.format("%g", math.Round(value, 2))
    end
    return "+" .. text .. (def.suffix or "")
end

SkillTrees:BuildIndex()
SkillTrees:PatchArcCW() -- in case ArcCW loaded its attachments before this addon
