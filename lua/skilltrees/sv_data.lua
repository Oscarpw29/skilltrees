local PDATA_KEY    = "vtx_skilldata"
local DATA_VERSION = 2

-- Data saved before version 2 used 1 point per 2 levels and had no tree rows.
-- The redesign refunds every skill and tops up points to the new rate. Points granted
-- by admins survive because only the difference between the two rates is added.
local function migrate(ply, data)
    local version = data.version or 1
    if version >= DATA_VERSION then return end

    if version < 2 then
        local refund = 0
        for id, level in pairs(data.skills) do
            local info = SkillTrees:GetSkill(id)
            if info then refund = refund + (info.price or 1) * level end
        end

        local topUp = math.max(SkillTrees:PointsForLevel(data.level) - SkillTrees:PointsForLevel(data.level, 2), 0)

        data.skills = {}
        data.points = data.points + refund + topUp

        timer.Simple(5, function()
            if not IsValid(ply) then return end
            ply:ChatPrint("[VORTEX] The skill trees have been redesigned. Your skills were refunded and you gained "
                .. topUp .. " bonus point(s). You have " .. data.points .. " point(s) to spend.")
        end)
    end

    data.version = DATA_VERSION
end

local function normalise(data)
    data = istable(data) and data or {}
    data.xp     = tonumber(data.xp) or 0
    data.level  = math.Clamp(tonumber(data.level) or 1, 1, SkillTrees.MaxLevel)
    data.points = tonumber(data.points) or 0
    data.skills = istable(data.skills) and data.skills or {}
    return data
end

function SkillTrees:SaveAndSync(ply)
    if not IsValid(ply) or not ply.SkillData then return end
    -- Never save before PData has been read, or the empty defaults would overwrite real data
    -- (passive XP, NPC kills and UserGroupSet can all land inside the load window).
    if not ply.SkillDataLoaded then return end

    self:InvalidateBuffs(ply)
    ply:SetPData(PDATA_KEY, util.TableToJSON(ply.SkillData))

    net.Start("vtx_skills_sync")
        net.WriteTable(ply.SkillData)
    net.Send(ply)
end

hook.Add("PlayerInitialSpawn", "SkillTrees_Load", function(ply)
    -- SAM can re-fire this hook on rank change; don't wipe data that's loaded or loading
    if ply.SkillData then return end

    ply.SkillDataLoaded = false
    ply.SkillData = normalise(nil)
    ply.SkillData.version = DATA_VERSION

    timer.Simple(2, function()
        if not IsValid(ply) then return end

        local raw = ply:GetPData(PDATA_KEY, nil)
        if raw and raw ~= "" then
            local decoded = util.JSONToTable(raw)
            if decoded then
                ply.SkillData = normalise(decoded)
                migrate(ply, ply.SkillData)
            end
        end

        ply.SkillDataLoaded = true
        SkillTrees:SaveAndSync(ply)
        SkillTrees:ApplyBuffs(ply)
    end)
end)

hook.Add("UserGroupSet", "SkillTrees_RankChange", function(ply)
    if not IsValid(ply) or not ply.SkillDataLoaded then return end
    SkillTrees:SaveAndSync(ply)
    timer.Simple(1, function()
        if IsValid(ply) then SkillTrees:ApplyBuffs(ply) end
    end)
end)

hook.Add("OnPlayerChangedTeam", "Vortex_Skills_TeamSwitch", function(ply)
    -- Delay so MC Ranks finishes its own network messages first
    timer.Simple(1, function()
        if IsValid(ply) then SkillTrees:ApplyBuffs(ply) end
    end)
end)

concommand.Add("vtx_skills_wipe_all", function(ply, cmd, args)
    if IsValid(ply) then return end -- server console only

    if args[1] ~= "confirm" then
        print("Type 'vtx_skills_wipe_all confirm' to delete all player data.")
        return
    end

    -- PData rows are keyed "<steamid>[<key>]", so an exact match on the key finds nothing
    sql.Query("DELETE FROM playerpdata WHERE infoid LIKE '%[" .. PDATA_KEY .. "]'")
    for _, target in ipairs(player.GetAll()) do
        target.SkillData = normalise(nil)
        target.SkillData.version = DATA_VERSION
        SkillTrees:SaveAndSync(target)
        SkillTrees:ApplyBuffs(target)
    end

    print("[Vortex] Skill data wiped.")
end)
