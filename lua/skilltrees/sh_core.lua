-- SkillTrees.Skills = {
--     strength_1 = {
--         name = "Strength I",
--         maxLevel = 1,
--         description = "more damage",
--         -- allowedJobs = {""},
--         -- allowedSteamIDs = {""},
--         pointsPerLevel = 1,
--         requirement = nil,
--         category = "roids",
--     },
--     strength_2 = {
--         name = "Strength II",
--         maxLevel = 1, 
--         description = "even more damage",
--         requirement = "strength_1",
--         category = "roids",
--     },
--     jedi_jump = {
--         name = "Force Jump",
--         maxLevel = 3,
--         description = "Jump Higher",
--         allowedJobs = {""},
--         category = "jedi"
--     }
-- }
SkillTrees = SkillTrees or {}

SkillTrees.Config = {}

SkillTrees.MaxLevel = 15

SkillTrees.Tree = {
    -- Unit trees ship empty; skills are added in later updates. MRSGroup must match the player's MRS group exactly.
    -- Specializations unlock at unlockLevel and show COMING SOON until comingSoon is removed.
    ["212th"] = {
        Color = Color(255, 140, 0),
        MRSGroup = {"212th Attack"},
        Skills = {},
        Specializations = {
            ["Scout"] = {
                name = "Scout",
                description = "Unlocks long-range scopes and optics.",
                unlockLevel = 15,
                comingSoon = true,
                Skills = {},
            },
            ["Field Medic"] = {
                name = "Field Medic",
                description = "Increases move speed and support utility.",
                unlockLevel = 15,
                comingSoon = true,
                Skills = {},
            },
        },
    },
    ["104th"] = {
        Color = Color(150, 60, 60),
        MRSGroup = {"104th Battallion"},
        Skills = {},
        Specializations = {
            ["Scout"] = {
                name = "Scout",
                description = "Unlocks long-range scopes and optics.",
                unlockLevel = 15,
                comingSoon = true,
                Skills = {},
            },
            ["Field Medic"] = {
                name = "Field Medic",
                description = "Increases move speed and support utility.",
                unlockLevel = 15,
                comingSoon = true,
                Skills = {},
            },
        },
    },
    ["Shock"] = {
        Color = Color(0, 210, 255),
        MRSGroup = {"Shock"},
        Skills = {},
        Specializations = {
            ["Scout"] = {
                name = "Scout",
                description = "Unlocks long-range scopes and optics.",
                unlockLevel = 15,
                comingSoon = true,
                Skills = {},
            },
            ["Field Medic"] = {
                name = "Field Medic",
                description = "Increases move speed and support utility.",
                unlockLevel = 15,
                comingSoon = true,
                Skills = {},
            },
        },
    },
    -- Ordnance: universal single-unlock tree (no MRSGroup/Teams = open to every job).
    -- Gates the Clone Wars 2003 pack's Energization/Perk/Internal Mod attachments -
    -- see that pack's att.Hook_Compatible checks against "adv_munitions".
    ["Ordnance"] = {
        Color = Color(200, 160, 40),
        Skills = {
            ["adv_munitions"] = {
                name = "Advanced Munitions Training",
                description = "Unlocks access to specialized Energization cells, combat perks, and internal weapon modifications.",
                price = 4,
                maxLevel = 1,
                requirement = nil,
            },
        }
    },
}

SkillTrees.Buffs = {
}

SkillTrees.RankMultipliers = {
    ["superadmin"] = 5.0,
    ["Management"] = 4.0,
    ["Senior Admin"] = 3.0,
    ["Admin"] = 2.0,
    ["INSANE VIP"] = 5.0,
    ["Legendary VIP"] = 4.5,
    ["Beskar VIP"] = 4.0,
    ["Diamond VIP"] = 3.5,
    ["Platinum VIP"] = 3,
    ["Gold VIP"] = 2.5,
    ["Silver VIP"] = 2.0,
    ["Bronze VIP"] = 1.5,
    ["user"] = 1.0,
}

function SkillTrees:GetPlayerMultiplier(ply)
    if not IsValid(ply) then return 1 end
    local rank = ply:GetUserGroup()
    return SkillTrees.RankMultipliers[rank] or 1.0
end

SkillTrees.NPC_XP_REWARD = 5

function SkillTrees:CalculateBuffs(ply)
    local stats = { hp = 0, speed = 0, armor = 0, hpregen = 0, armorregen = 0, firerate = 0, reloadspeed = 0, movespeed = 0, resistance = 0, damage = 0, salary_bonus = 0, salary_per_kill = 0, lscs_damage = 0, lscs_force_regen = 0, lscs_block = 0, xp_boost = 0 }
    if not IsValid(ply) then return stats end
    ply.SkillData = ply.SkillData or {}

    ply.SkillData.skills = ply.SkillData.skills or {}

    for skillID, level in pairs(ply.SkillData.skills) do
        local buff = SkillTrees.Buffs[skillID]
        if buff then
            local lvl = isnumber(level) and level or 1
            if buff.hp then stats.hp = stats.hp + (buff.hp * lvl) end
            if buff.speed then stats.speed = stats.speed + (buff.speed * lvl) end
            if buff.armor then stats.armor = stats.armor + (buff.armor * lvl) end

            if buff.hpregen then stats.hpregen = stats.hpregen + (buff.hpregen * lvl) end
            if buff.armorregen then stats.armorregen = stats.armorregen + (buff.armorregen * lvl) end
            if buff.firerate then stats.firerate = stats.firerate + (buff.firerate * lvl) end
            if buff.reloadspeed then stats.reloadspeed = stats.reloadspeed + (buff.reloadspeed * level) end
            if buff.movespeed then stats.movespeed = stats.movespeed + (buff.movespeed * lvl) end
            if buff.resistance then stats.resistance = (stats.resistance) + (buff.resistance * lvl) end
            if buff.damage then stats.damage = stats.damage + (buff.damage * lvl) end
            if buff.salary_bonus then stats.salary_bonus = stats.salary_bonus + (buff.salary_bonus * lvl) end
            if buff.salary_per_kill then stats.salary_per_kill = stats.salary_per_kill + (buff.salary_per_kill * lvl) end
            if buff.lscs_damage then stats.lscs_damage = stats.lscs_damage + (buff.lscs_damage * lvl) end
            if buff.lscs_force_regen then stats.lscs_force_regen = stats.lscs_force_regen + (buff.lscs_force_regen * lvl) end
            if buff.lscs_block then stats.lscs_block = stats.lscs_block + (buff.lscs_block * lvl) end
            if buff.xp_boost then stats.xp_boost = stats.xp_boost + (buff.xp_boost * lvl) end
        end
    end
    return stats
end

function SkillTrees:GetSkill(skillID)
    for catName, catData in pairs(SkillTrees.Tree) do
        if catData.Skills and catData.Skills[skillID] then
            return catData.Skills[skillID], catName
        end
    end
    return nil, nil
end
