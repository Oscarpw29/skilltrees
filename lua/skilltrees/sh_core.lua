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
    -- Unit trees are small for now; more skills arrive in later updates. MRSGroup must match the player's MRS group exactly.
    -- Specializations unlock at unlockLevel and show COMING SOON until comingSoon is removed.
    ["212th"] = {
        Color = Color(255, 140, 0),
        MRSGroup = {"212th Attack"},
        Skills = {
            ["212th_hp_1"] = {
                name = "Frontline Conditioning",
                description = "Increase health by 10 per level",
                price = 1,
                maxLevel = 3,
                requirement = nil,
            },
            ["212th_hpregen"] = {
                name = "Battle Recovery",
                description = "Regenerate 2 health every 2 seconds out of combat",
                price = 1,
                maxLevel = 2,
                requirement = "212th_hp_1",
            },
            ["212th_hp_2"] = {
                name = "Veteran's Body",
                description = "Increase health by 10 and armor by 5 per level",
                price = 1,
                maxLevel = 2,
                requirement = "212th_hp_1",
            },
            ["212th_res"] = {
                name = "Unbreakable",
                description = "Reduce damage taken by 1% per level",
                price = 2,
                maxLevel = 3,
                requirement = "212th_hpregen",
            },
            ["212th_firerate"] = {
                name = "Squad Suppression",
                description = "Increase fire rate by 5% per level",
                price = 1,
                maxLevel = 2,
                requirement = nil,
            },
            ["212th_damage"] = {
                name = "Frontline Aggression",
                description = "Increase bullet damage by 5% per level",
                price = 2,
                maxLevel = 3,
                requirement = "212th_firerate",
            },
            ["212th_salary"] = {
                name = "Combat Pay",
                description = "Increase salary by 5% per level",
                price = 1,
                maxLevel = 3,
                requirement = nil,
            },
        },
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
        MRSGroup = {"104th Mechanized"},
        Skills = {
            ["104th_speed_1"] = {
                name = "Pack Hunter",
                description = "Increase move speed by 2% per level",
                price = 1,
                maxLevel = 3,
                requirement = nil,
            },
            ["104th_speed_2"] = {
                name = "Relentless Pursuit",
                description = "Increase move speed by a further 2% per level",
                price = 2,
                maxLevel = 2,
                requirement = "104th_speed_1",
            },
            ["104th_reload"] = {
                name = "Quick Hands",
                description = "Increase reload speed by 5% per level",
                price = 1,
                maxLevel = 3,
                requirement = nil,
            },
            ["104th_damage"] = {
                name = "Wolf's Precision",
                description = "Increase bullet damage by 5% per level",
                price = 2,
                maxLevel = 3,
                requirement = "104th_reload",
            },
            ["104th_hp"] = {
                name = "Hardened Pack",
                description = "Increase health by 5 per level",
                price = 1,
                maxLevel = 3,
                requirement = nil,
            },
            ["104th_armor"] = {
                name = "Pack Armor",
                description = "Increase armor by 5 per level",
                price = 1,
                maxLevel = 3,
                requirement = "104th_hp",
            },
            ["104th_xp"] = {
                name = "Wolfpack Training",
                description = "Gain 10% more XP",
                price = 2,
                maxLevel = 1,
                requirement = nil,
            },
        },
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
        Skills = {
            ["shock_armor_1"] = {
                name = "Riot Plating",
                description = "Increase armor by 5 per level",
                price = 1,
                maxLevel = 3,
                requirement = nil,
            },
            ["shock_armorregen"] = {
                name = "Reinforced Gear",
                description = "Regenerate 1 armor every 2 seconds out of combat",
                price = 1,
                maxLevel = 2,
                requirement = "shock_armor_1",
            },
            ["shock_res"] = {
                name = "Riot Conditioning",
                description = "Reduce damage taken by 1% per level",
                price = 2,
                maxLevel = 3,
                requirement = "shock_armorregen",
            },
            ["shock_hp"] = {
                name = "Determination",
                description = "Increase health by 8 and armor by 4 per level",
                price = 1,
                maxLevel = 3,
                requirement = nil,
            },
            ["shock_hpregen"] = {
                name = "Second Wind",
                description = "Regenerate 2 health every 2 seconds out of combat",
                price = 1,
                maxLevel = 2,
                requirement = "shock_hp",
            },
            ["shock_damage"] = {
                name = "Enforcement Firepower",
                description = "Increase bullet damage by 3% per level",
                price = 1,
                maxLevel = 3,
                requirement = nil,
            },
            ["shock_firerate"] = {
                name = "Suppressive Fire",
                description = "Increase fire rate by 5% per level",
                price = 2,
                maxLevel = 2,
                requirement = "shock_damage",
            },
        },
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
    ["212th_hp_1"] = { hp = 10 },
    ["212th_hpregen"] = { hpregen = 2 },
    ["212th_hp_2"] = { hp = 10, armor = 5 },
    ["212th_res"] = { resistance = 0.01 },
    ["212th_firerate"] = { firerate = 0.05 },
    ["212th_damage"] = { damage = 0.05 },
    ["212th_salary"] = { salary_bonus = 0.05 },
    ["104th_speed_1"] = { movespeed = 0.02 },
    ["104th_speed_2"] = { movespeed = 0.02 },
    ["104th_reload"] = { reloadspeed = 0.05 },
    ["104th_damage"] = { damage = 0.05 },
    ["104th_hp"] = { hp = 5 },
    ["104th_armor"] = { armor = 5 },
    ["104th_xp"] = { xp_boost = 0.1 },
    ["shock_armor_1"] = { armor = 5 },
    ["shock_armorregen"] = { armorregen = 1 },
    ["shock_res"] = { resistance = 0.01 },
    ["shock_hp"] = { hp = 8, armor = 4 },
    ["shock_hpregen"] = { hpregen = 2 },
    ["shock_damage"] = { damage = 0.03 },
    ["shock_firerate"] = { firerate = 0.05 },
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
