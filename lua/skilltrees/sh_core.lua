<<<<<<< Updated upstream
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

SkillTrees.Tree = {
    -- Navy: speed focus. HP cap 50, armor cap 30.
    ["Navy"] = {
        Color = Color(0, 120, 220),
        MRSGroup = {"Republic Navy"},
        Skills = {
            ["navy_speed_1"] = {
                name = "Fleet Footing",
                description = "Increase move speed by 2% per level",
                price = 1,
                maxLevel = 5,
                requirement = nil,
            },
            ["navy_speed_2"] = {
                name = "Rapid Advance",
                description = "Increase move speed by a further 3% per level",
                price = 2,
                maxLevel = 5,
                requirement = "navy_speed_1",
            },
            ["navy_reload"] = {
                name = "Combat Efficiency",
                description = "Increase reload speed by 5% per level",
                price = 2,
                maxLevel = 5,
                requirement = nil,
            },
            ["navy_hp"] = {
                name = "Officer Conditioning",
                description = "Increase health by 5 per level",
                price = 1,
                maxLevel = 10,
                requirement = nil,
            },
            ["navy_armor"] = {
                name = "Light Plating",
                description = "Increase armor by 3 per level",
                price = 1,
                maxLevel = 10,
                requirement = nil,
            },
            ["navy_damage"] = {
                name = "Naval Precision",
                description = "Increase bullet damage by 5% per level",
                price = 3,
                maxLevel = 5,
                requirement = "navy_reload",
            },
            ["navy_salary"] = {
                name = "Officer Pay",
                description = "Increase salary by 5% per level",
                price = 2,
                maxLevel = 5,
                requirement = nil,
            },
            ["navy_salary_kill"] = {
                name = "Privateer",
                description = "Earn 1% of salary per kill per level",
                price = 3,
                maxLevel = 5,
                requirement = "navy_salary",
            },
            ["navy_xp"] = {
                name = "Officer Training",
                description = "Gain 10% more XP per level",
                price = 3,
                maxLevel = 5,
                requirement = nil,
            },
        }
    },
    -- 212th: health focus. HP cap 150 (hp_1 x10=100 + hp_2 x5=50), armor cap 25.
    ["212th Attack"] = {
        Color = Color(255, 140, 0),
        MRSGroup = {"212th Attack"},
        Skills = {
            ["212th_hp_1"] = {
                name = "Frontline Conditioning",
                description = "Increase health by 10 per level",
                price = 1,
                maxLevel = 10,
                requirement = nil,
            },
            ["212th_hpregen"] = {
                name = "Battle Recovery",
                description = "Regenerate 2 health every 5 seconds out of combat",
                price = 3,
                maxLevel = 5,
                requirement = "212th_hp_1",
            },
            ["212th_hp_2"] = {
                name = "Veteran's Body",
                description = "Increase health by 10 and armor by 5 per level",
                price = 4,
                maxLevel = 5,
                requirement = "212th_hpregen",
            },
            ["212th_res"] = {
                name = "Unbreakable",
                description = "Reduce damage taken by 1% per level",
                price = 5,
                maxLevel = 5,
                requirement = "212th_hp_2",
            },
            ["212th_firerate"] = {
                name = "Squad Suppression",
                description = "Increase fire rate by 5% per level",
                price = 2,
                maxLevel = 5,
                requirement = nil,
            },
            ["212th_damage"] = {
                name = "Frontline Aggression",
                description = "Increase bullet damage by 5% per level",
                price = 3,
                maxLevel = 5,
                requirement = "212th_firerate",
            },
            ["212th_speed"] = {
                name = "Combat Rush",
                description = "Increase move speed by 2% per level",
                price = 2,
                maxLevel = 3,
                requirement = nil,
            },
            ["212th_salary"] = {
                name = "Combat Pay",
                description = "Increase salary by 5% per level",
                price = 2,
                maxLevel = 5,
                requirement = nil,
            },
        }
    },
    -- 501st: armor focus. Armor cap 150 (armor_1 x10=50 + armor_2 x5=75 + armor_3 x5=25), HP cap 50.
    ["501st Legion"] = {
        Color = Color(30, 80, 200),
        MRSGroup = {"501st Legion"},
        Skills = {
            ["501st_armor_1"] = {
                name = "Heavy Plating",
                description = "Increase armor by 5 per level",
                price = 1,
                maxLevel = 10,
                requirement = nil,
            },
            ["501st_armorregen"] = {
                name = "Self-Sealing Armor",
                description = "Regenerate 1 armor every 5 seconds out of combat",
                price = 3,
                maxLevel = 5,
                requirement = "501st_armor_1",
            },
            ["501st_armor_2"] = {
                name = "Mechanized Shell",
                description = "Increase armor by 15 and reduce damage by 1% per level",
                price = 4,
                maxLevel = 5,
                requirement = "501st_armorregen",
            },
            ["501st_armor_3"] = {
                name = "Iron Fortress",
                description = "Increase armor by 5 per level",
                price = 5,
                maxLevel = 5,
                requirement = "501st_armor_2",
            },
            ["501st_hp"] = {
                name = "Tactical Frame",
                description = "Increase health by 10 per level",
                price = 2,
                maxLevel = 5,
                requirement = nil,
            },
            ["501st_firerate"] = {
                name = "Mechanized Assault",
                description = "Increase fire rate by 5% per level",
                price = 2,
                maxLevel = 5,
                requirement = nil,
            },
            ["501st_damage"] = {
                name = "Shock Trooper",
                description = "Increase bullet damage dealt by 5% per level",
                price = 3,
                maxLevel = 5,
                requirement = "501st_firerate",
            },
            ["501st_xp"] = {
                name = "Battlefield Experience",
                description = "Gain 10% more XP per level",
                price = 3,
                maxLevel = 5,
                requirement = nil,
            },
        }
    },
    -- CG: hybrid. HP cap 150 (hp_armor x10=80 + hp_2 x10=70), armor cap 150 (hp_armor x10=40 + armor_2 x10=110).
    ["Coruscant Guard"] = {
        Color = Color(180, 30, 30),
        MRSGroup = {"Coruscant Guard"},
        Skills = {
            ["cg_hp_armor"] = {
                name = "Law Enforcement Training",
                description = "Increase health by 8 and armor by 4 per level",
                price = 2,
                maxLevel = 10,
                requirement = nil,
            },
            ["cg_hp_2"] = {
                name = "Determination",
                description = "Increase health by 7 per level",
                price = 2,
                maxLevel = 10,
                requirement = "cg_hp_armor",
            },
            ["cg_armor_2"] = {
                name = "Riot Plating",
                description = "Increase armor by 11 per level",
                price = 2,
                maxLevel = 10,
                requirement = "cg_hp_armor",
            },
            ["cg_hpregen"] = {
                name = "Field Medic",
                description = "Regenerate 2 health every 5 seconds out of combat",
                price = 3,
                maxLevel = 5,
                requirement = "cg_hp_2",
            },
            ["cg_armorregen"] = {
                name = "Reinforced Gear",
                description = "Regenerate 1 armor every 5 seconds out of combat",
                price = 3,
                maxLevel = 5,
                requirement = "cg_armor_2",
            },
            ["cg_res"] = {
                name = "Riot Conditioning",
                description = "Reduce damage taken by 1% per level",
                price = 5,
                maxLevel = 5,
                requirement = "cg_hpregen",
            },
            ["cg_damage"] = {
                name = "Enforcement Firepower",
                description = "Increase bullet damage by 3% per level",
                price = 3,
                maxLevel = 5,
                requirement = nil,
            },
            ["cg_salary"] = {
                name = "Guard Pay",
                description = "Increase salary by 5% per level",
                price = 2,
                maxLevel = 5,
                requirement = nil,
            },
        }
    },
    -- Shock Vanguard: donator melee troopers (Volt, Charger, Dreadnaught). HP cap 100, armor cap 25.
    ["Shock Vanguard"] = {
        Color = Color(0, 210, 255),
        Teams = {TEAM_212VOLT, TEAM_CGCRG, TEAM_501DREAD},
        Skills = {
            ["vanguard_hp"] = {
                name = "Iron Constitution",
                description = "Increase health by 10 per level",
                price = 1,
                maxLevel = 10,
                requirement = nil,
            },
            ["vanguard_armor"] = {
                name = "Reinforced Plating",
                description = "Increase armor by 5 per level",
                price = 1,
                maxLevel = 5,
                requirement = nil,
            },
            ["vanguard_melee_1"] = {
                name = "Shock Strike",
                description = "Increase melee damage by 5% per level",
                price = 2,
                maxLevel = 5,
                requirement = nil,
            },
            ["vanguard_speed"] = {
                name = "Assault Charge",
                description = "Increase move speed by 2% per level",
                price = 2,
                maxLevel = 5,
                requirement = nil,
            },
            ["vanguard_res"] = {
                name = "Unyielding",
                description = "Reduce all incoming damage by 3% per level",
                price = 3,
                maxLevel = 5,
                requirement = "vanguard_hp",
            },
            ["vanguard_hpregen"] = {
                name = "Combat Endurance",
                description = "Regenerate 3 health every 2 seconds out of combat",
                price = 3,
                maxLevel = 3,
                requirement = "vanguard_hp",
            },
            ["vanguard_melee_2"] = {
                name = "Overcharge",
                description = "Increase melee damage by a further 8% per level",
                price = 4,
                maxLevel = 3,
                requirement = "vanguard_melee_1",
            },
            ["vanguard_block"] = {
                name = "Combat Guard",
                description = "Reduce incoming melee damage by 4% per level",
                price = 3,
                maxLevel = 3,
                requirement = "vanguard_melee_1",
            },
            ["vanguard_salary"] = {
                name = "Veteran's Pay",
                description = "Increase salary by 5% per level",
                price = 2,
                maxLevel = 3,
                requirement = nil,
            },
        }
    },
    -- Jedi: force focus. HP cap 50, armor cap 50 (Force-derived).
    ["Jedi Order"] = {
        Color = Color(0, 180, 255),
        MRSGroup = {"Jedi Order"},
        Skills = {
            ["jedi_force_regen"] = {
                name = "Force Attunement",
                description = "Regenerate 5 force points every 2 seconds",
                price = 2,
                maxLevel = 5,
                requirement = nil,
            },
            ["jedi_force_regen_2"] = {
                name = "Force Mastery",
                description = "Regenerate a further 10 force points every 2 seconds",
                price = 4,
                maxLevel = 3,
                requirement = "jedi_force_regen",
            },
            ["jedi_hp_regen"] = {
                name = "Force Vitality",
                description = "Regenerate 2 health every 5 seconds through the Force",
                price = 3,
                maxLevel = 5,
                requirement = "jedi_force_regen",
            },
            ["jedi_hp"] = {
                name = "Force Endurance",
                description = "Increase health by 5 per level",
                price = 2,
                maxLevel = 10,
                requirement = nil,
            },
            ["jedi_armor"] = {
                name = "Kinetic Shield",
                description = "Increase armor by 5 per level via Force deflection",
                price = 2,
                maxLevel = 10,
                requirement = nil,
            },
            ["jedi_speed"] = {
                name = "Force Speed",
                description = "Increase move speed by 3% per level",
                price = 3,
                maxLevel = 3,
                requirement = "jedi_force_regen",
            },
            ["jedi_saber_dmg"] = {
                name = "Saber Mastery",
                description = "Increase lightsaber damage by 5% per level",
                price = 3,
                maxLevel = 5,
                requirement = nil,
            },
            ["jedi_saber_dmg_2"] = {
                name = "Form Mastery",
                description = "Increase lightsaber damage by a further 8% per level",
                price = 5,
                maxLevel = 3,
                requirement = "jedi_saber_dmg",
            },
            ["jedi_block"] = {
                name = "Blade Defense",
                description = "Reduce incoming lightsaber damage by 5% per level",
                price = 3,
                maxLevel = 5,
                requirement = nil,
            },
        }
    },
}

SkillTrees.Buffs = {
    ["tank"] = { hp = 25, armor = 10 },
    ["tank_arc"] = { hp=25, armor=10, resistance = 0.01},
    ["health_10"] = { hp = 10 },
    ["armor_5"] = { armor = 5 },
    ["armor_50"] = { armor = 50 },
    ["hp_regen_2"] = { hpregen = 2 },
    ["armor_regen_1"] = { armorregen = 1 },
    ["firerate_5"] = { firerate = 0.05 },
    ["firerate_25"] = { firerate = 0.025},
    ["damageres_1"] = { resistance = 0.01 },
    ["reloadspeed_5"] = { reloadspeed = 0.05 },
    ["reloadspeed_25"] = { reloadspeed = 0.025},
    ["reloadspeed_01"] = { reloadspeed = 0.01},
    ["bullet_damage_5"] = { damage = 0.05 },
    ["salary_5"] = { salary_bonus = 0.05 },
    ["gold_bullets"] = { salary_per_kill = 0.01 },
    ["xp_boost_10"] = { xp_boost = 0.1 },
    ["lscs_saber_dmg"] = { lscs_damage = 0.05 },
    ["lscs_force_regen_5"] = { lscs_force_regen = 5 },
    ["lscs_block_5"] = { lscs_block = 0.05 },
    ["commando_training"] = { hp = 25, armor = 15, resistance = 0.01},
    ["speed"] = { movespeed = 0.02},
    -- Navy
    ["navy_speed_1"]    = { movespeed = 0.02 },
    ["navy_speed_2"]    = { movespeed = 0.03 },
    ["navy_reload"]     = { reloadspeed = 0.05 },
    ["navy_hp"]         = { hp = 5 },
    ["navy_armor"]      = { armor = 3 },
    ["navy_damage"]     = { damage = 0.05 },
    ["navy_salary"]     = { salary_bonus = 0.05 },
    ["navy_salary_kill"]= { salary_per_kill = 0.01 },
    ["navy_xp"]         = { xp_boost = 0.1 },
    -- 212th Attack Battalion
    ["212th_hp_1"]      = { hp = 10 },
    ["212th_hpregen"]   = { hpregen = 2 },
    ["212th_hp_2"]      = { hp = 10, armor = 5 },
    ["212th_res"]       = { resistance = 0.01 },
    ["212th_firerate"]  = { firerate = 0.05 },
    ["212th_damage"]    = { damage = 0.05 },
    ["212th_speed"]     = { movespeed = 0.02 },
    ["212th_salary"]    = { salary_bonus = 0.05 },
    -- 501st Legion
    ["501st_armor_1"]   = { armor = 5 },
    ["501st_armorregen"]= { armorregen = 1 },
    ["501st_armor_2"]   = { armor = 15, resistance = 0.01 },
    ["501st_armor_3"]   = { armor = 5 },
    ["501st_hp"]        = { hp = 10 },
    ["501st_firerate"]  = { firerate = 0.05 },
    ["501st_damage"]    = { damage = 0.05 },
    ["501st_xp"]        = { xp_boost = 0.1 },
    -- Coruscant Guard
    ["cg_hp_armor"]     = { hp = 8, armor = 4 },
    ["cg_hp_2"]         = { hp = 7 },
    ["cg_armor_2"]      = { armor = 11 },
    ["cg_hpregen"]      = { hpregen = 2 },
    ["cg_armorregen"]   = { armorregen = 1 },
    ["cg_res"]          = { resistance = 0.01 },
    ["cg_damage"]       = { damage = 0.03 },
    ["cg_salary"]       = { salary_bonus = 0.05 },
    -- Shock Vanguard
    ["vanguard_hp"]       = { hp = 10 },
    ["vanguard_armor"]    = { armor = 5 },
    ["vanguard_melee_1"]  = { lscs_damage = 0.05 },
    ["vanguard_speed"]    = { movespeed = 0.02 },
    ["vanguard_res"]      = { resistance = 0.03 },
    ["vanguard_hpregen"]  = { hpregen = 3 },
    ["vanguard_melee_2"]  = { lscs_damage = 0.08 },
    ["vanguard_block"]    = { lscs_block = 0.04 },
    ["vanguard_salary"]   = { salary_bonus = 0.05 },
    -- Jedi Order
    ["jedi_force_regen"]  = { lscs_force_regen = 5 },
    ["jedi_force_regen_2"]= { lscs_force_regen = 10 },
    ["jedi_hp_regen"]     = { hpregen = 2 },
    ["jedi_hp"]           = { hp = 5 },
    ["jedi_armor"]        = { armor = 5 },
    ["jedi_speed"]        = { movespeed = 0.03 },
    ["jedi_saber_dmg"]    = { lscs_damage = 0.05 },
    ["jedi_saber_dmg_2"]  = { lscs_damage = 0.08 },
    ["jedi_block"]        = { lscs_block = 0.05 },
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
=======
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

SkillTrees.Tree = {
    -- Navy: speed focus. HP cap 50, armor cap 30.
    ["Navy"] = {
        Color = Color(0, 120, 220),
        MRSGroup = {"Republic Navy"},
        Skills = {
            ["navy_speed_1"] = {
                name = "Fleet Footing",
                description = "Increase move speed by 2% per level",
                price = 1,
                maxLevel = 5,
                requirement = nil,
            },
            ["navy_speed_2"] = {
                name = "Rapid Advance",
                description = "Increase move speed by a further 3% per level",
                price = 2,
                maxLevel = 5,
                requirement = "navy_speed_1",
            },
            ["navy_reload"] = {
                name = "Combat Efficiency",
                description = "Increase reload speed by 5% per level",
                price = 2,
                maxLevel = 5,
                requirement = nil,
            },
            ["navy_hp"] = {
                name = "Officer Conditioning",
                description = "Increase health by 5 per level",
                price = 1,
                maxLevel = 10,
                requirement = nil,
            },
            ["navy_armor"] = {
                name = "Light Plating",
                description = "Increase armor by 3 per level",
                price = 1,
                maxLevel = 10,
                requirement = nil,
            },
            ["navy_damage"] = {
                name = "Naval Precision",
                description = "Increase bullet damage by 5% per level",
                price = 3,
                maxLevel = 5,
                requirement = "navy_reload",
            },
            ["navy_salary"] = {
                name = "Officer Pay",
                description = "Increase salary by 5% per level",
                price = 2,
                maxLevel = 5,
                requirement = nil,
            },
            ["navy_salary_kill"] = {
                name = "Privateer",
                description = "Earn 1% of salary per kill per level",
                price = 3,
                maxLevel = 5,
                requirement = "navy_salary",
            },
            ["navy_xp"] = {
                name = "Officer Training",
                description = "Gain 10% more XP per level",
                price = 3,
                maxLevel = 5,
                requirement = nil,
            },
        }
    },
    -- 212th: health focus. HP cap 150 (hp_1 x10=100 + hp_2 x5=50), armor cap 25.
    ["212th Attack"] = {
        Color = Color(255, 140, 0),
        MRSGroup = {"212th Attack"},
        Skills = {
            ["212th_hp_1"] = {
                name = "Frontline Conditioning",
                description = "Increase health by 10 per level",
                price = 1,
                maxLevel = 10,
                requirement = nil,
            },
            ["212th_hpregen"] = {
                name = "Battle Recovery",
                description = "Regenerate 2 health every 5 seconds out of combat",
                price = 3,
                maxLevel = 5,
                requirement = "212th_hp_1",
            },
            ["212th_hp_2"] = {
                name = "Veteran's Body",
                description = "Increase health by 10 and armor by 5 per level",
                price = 4,
                maxLevel = 5,
                requirement = "212th_hpregen",
            },
            ["212th_res"] = {
                name = "Unbreakable",
                description = "Reduce damage taken by 1% per level",
                price = 5,
                maxLevel = 5,
                requirement = "212th_hp_2",
            },
            ["212th_firerate"] = {
                name = "Squad Suppression",
                description = "Increase fire rate by 5% per level",
                price = 2,
                maxLevel = 5,
                requirement = nil,
            },
            ["212th_damage"] = {
                name = "Frontline Aggression",
                description = "Increase bullet damage by 5% per level",
                price = 3,
                maxLevel = 5,
                requirement = "212th_firerate",
            },
            ["212th_speed"] = {
                name = "Combat Rush",
                description = "Increase move speed by 2% per level",
                price = 2,
                maxLevel = 3,
                requirement = nil,
            },
            ["212th_salary"] = {
                name = "Combat Pay",
                description = "Increase salary by 5% per level",
                price = 2,
                maxLevel = 5,
                requirement = nil,
            },
        }
    },
    -- 501st: armor focus. Armor cap 150 (armor_1 x10=50 + armor_2 x5=75 + armor_3 x5=25), HP cap 50.
    ["501st Legion"] = {
        Color = Color(30, 80, 200),
        MRSGroup = {"501st Legion"},
        Skills = {
            ["501st_armor_1"] = {
                name = "Heavy Plating",
                description = "Increase armor by 5 per level",
                price = 1,
                maxLevel = 10,
                requirement = nil,
            },
            ["501st_armorregen"] = {
                name = "Self-Sealing Armor",
                description = "Regenerate 1 armor every 5 seconds out of combat",
                price = 3,
                maxLevel = 5,
                requirement = "501st_armor_1",
            },
            ["501st_armor_2"] = {
                name = "Mechanized Shell",
                description = "Increase armor by 15 and reduce damage by 1% per level",
                price = 4,
                maxLevel = 5,
                requirement = "501st_armorregen",
            },
            ["501st_armor_3"] = {
                name = "Iron Fortress",
                description = "Increase armor by 5 per level",
                price = 5,
                maxLevel = 5,
                requirement = "501st_armor_2",
            },
            ["501st_hp"] = {
                name = "Tactical Frame",
                description = "Increase health by 10 per level",
                price = 2,
                maxLevel = 5,
                requirement = nil,
            },
            ["501st_firerate"] = {
                name = "Mechanized Assault",
                description = "Increase fire rate by 5% per level",
                price = 2,
                maxLevel = 5,
                requirement = nil,
            },
            ["501st_damage"] = {
                name = "Shock Trooper",
                description = "Increase bullet damage dealt by 5% per level",
                price = 3,
                maxLevel = 5,
                requirement = "501st_firerate",
            },
            ["501st_xp"] = {
                name = "Battlefield Experience",
                description = "Gain 10% more XP per level",
                price = 3,
                maxLevel = 5,
                requirement = nil,
            },
        }
    },
    -- CG: hybrid. HP cap 150 (hp_armor x10=80 + hp_2 x10=70), armor cap 150 (hp_armor x10=40 + armor_2 x10=110).
    ["Coruscant Guard"] = {
        Color = Color(180, 30, 30),
        MRSGroup = {"Coruscant Guard"},
        Skills = {
            ["cg_hp_armor"] = {
                name = "Law Enforcement Training",
                description = "Increase health by 8 and armor by 4 per level",
                price = 2,
                maxLevel = 10,
                requirement = nil,
            },
            ["cg_hp_2"] = {
                name = "Determination",
                description = "Increase health by 7 per level",
                price = 2,
                maxLevel = 10,
                requirement = "cg_hp_armor",
            },
            ["cg_armor_2"] = {
                name = "Riot Plating",
                description = "Increase armor by 11 per level",
                price = 2,
                maxLevel = 10,
                requirement = "cg_hp_armor",
            },
            ["cg_hpregen"] = {
                name = "Field Medic",
                description = "Regenerate 2 health every 5 seconds out of combat",
                price = 3,
                maxLevel = 5,
                requirement = "cg_hp_2",
            },
            ["cg_armorregen"] = {
                name = "Reinforced Gear",
                description = "Regenerate 1 armor every 5 seconds out of combat",
                price = 3,
                maxLevel = 5,
                requirement = "cg_armor_2",
            },
            ["cg_res"] = {
                name = "Riot Conditioning",
                description = "Reduce damage taken by 1% per level",
                price = 5,
                maxLevel = 5,
                requirement = "cg_hpregen",
            },
            ["cg_damage"] = {
                name = "Enforcement Firepower",
                description = "Increase bullet damage by 3% per level",
                price = 3,
                maxLevel = 5,
                requirement = nil,
            },
            ["cg_salary"] = {
                name = "Guard Pay",
                description = "Increase salary by 5% per level",
                price = 2,
                maxLevel = 5,
                requirement = nil,
            },
        }
    },
    -- Jedi: force focus. HP cap 50, armor cap 50 (Force-derived).
    ["Jedi Order"] = {
        Color = Color(0, 180, 255),
        MRSGroup = {"Jedi Order"},
        Skills = {
            ["jedi_force_regen"] = {
                name = "Force Attunement",
                description = "Regenerate 5 force points every 2 seconds",
                price = 2,
                maxLevel = 5,
                requirement = nil,
            },
            ["jedi_force_regen_2"] = {
                name = "Force Mastery",
                description = "Regenerate a further 10 force points every 2 seconds",
                price = 4,
                maxLevel = 3,
                requirement = "jedi_force_regen",
            },
            ["jedi_hp_regen"] = {
                name = "Force Vitality",
                description = "Regenerate 2 health every 5 seconds through the Force",
                price = 3,
                maxLevel = 5,
                requirement = "jedi_force_regen",
            },
            ["jedi_hp"] = {
                name = "Force Endurance",
                description = "Increase health by 5 per level",
                price = 2,
                maxLevel = 10,
                requirement = nil,
            },
            ["jedi_armor"] = {
                name = "Kinetic Shield",
                description = "Increase armor by 5 per level via Force deflection",
                price = 2,
                maxLevel = 10,
                requirement = nil,
            },
            ["jedi_speed"] = {
                name = "Force Speed",
                description = "Increase move speed by 3% per level",
                price = 3,
                maxLevel = 3,
                requirement = "jedi_force_regen",
            },
            ["jedi_saber_dmg"] = {
                name = "Saber Mastery",
                description = "Increase lightsaber damage by 5% per level",
                price = 3,
                maxLevel = 5,
                requirement = nil,
            },
            ["jedi_saber_dmg_2"] = {
                name = "Form Mastery",
                description = "Increase lightsaber damage by a further 8% per level",
                price = 5,
                maxLevel = 3,
                requirement = "jedi_saber_dmg",
            },
            ["jedi_block"] = {
                name = "Blade Defense",
                description = "Reduce incoming lightsaber damage by 5% per level",
                price = 3,
                maxLevel = 5,
                requirement = nil,
            },
        }
    },
}

SkillTrees.Buffs = {
    ["tank"] = { hp = 25, armor = 10 },
    ["tank_arc"] = { hp=25, armor=10, resistance = 0.01},
    ["health_10"] = { hp = 10 },
    ["armor_5"] = { armor = 5 },
    ["armor_50"] = { armor = 50 },
    ["hp_regen_2"] = { hpregen = 2 },
    ["armor_regen_1"] = { armorregen = 1 },
    ["firerate_5"] = { firerate = 0.05 },
    ["firerate_25"] = { firerate = 0.025},
    ["damageres_1"] = { resistance = 0.01 },
    ["reloadspeed_5"] = { reloadspeed = 0.05 },
    ["reloadspeed_25"] = { reloadspeed = 0.025},
    ["reloadspeed_01"] = { reloadspeed = 0.01},
    ["bullet_damage_5"] = { damage = 0.05 },
    ["salary_5"] = { salary_bonus = 0.05 },
    ["gold_bullets"] = { salary_per_kill = 0.01 },
    ["xp_boost_10"] = { xp_boost = 0.1 },
    ["lscs_saber_dmg"] = { lscs_damage = 0.05 },
    ["lscs_force_regen_5"] = { lscs_force_regen = 5 },
    ["lscs_block_5"] = { lscs_block = 0.05 },
    ["commando_training"] = { hp = 25, armor = 15, resistance = 0.01},
    ["speed"] = { movespeed = 0.02},
    -- Navy
    ["navy_speed_1"]    = { movespeed = 0.02 },
    ["navy_speed_2"]    = { movespeed = 0.03 },
    ["navy_reload"]     = { reloadspeed = 0.05 },
    ["navy_hp"]         = { hp = 5 },
    ["navy_armor"]      = { armor = 3 },
    ["navy_damage"]     = { damage = 0.05 },
    ["navy_salary"]     = { salary_bonus = 0.05 },
    ["navy_salary_kill"]= { salary_per_kill = 0.01 },
    ["navy_xp"]         = { xp_boost = 0.1 },
    -- 212th Attack Battalion
    ["212th_hp_1"]      = { hp = 10 },
    ["212th_hpregen"]   = { hpregen = 2 },
    ["212th_hp_2"]      = { hp = 10, armor = 5 },
    ["212th_res"]       = { resistance = 0.01 },
    ["212th_firerate"]  = { firerate = 0.05 },
    ["212th_damage"]    = { damage = 0.05 },
    ["212th_speed"]     = { movespeed = 0.02 },
    ["212th_salary"]    = { salary_bonus = 0.05 },
    -- 501st Legion
    ["501st_armor_1"]   = { armor = 5 },
    ["501st_armorregen"]= { armorregen = 1 },
    ["501st_armor_2"]   = { armor = 15, resistance = 0.01 },
    ["501st_armor_3"]   = { armor = 5 },
    ["501st_hp"]        = { hp = 10 },
    ["501st_firerate"]  = { firerate = 0.05 },
    ["501st_damage"]    = { damage = 0.05 },
    ["501st_xp"]        = { xp_boost = 0.1 },
    -- Coruscant Guard
    ["cg_hp_armor"]     = { hp = 8, armor = 4 },
    ["cg_hp_2"]         = { hp = 7 },
    ["cg_armor_2"]      = { armor = 11 },
    ["cg_hpregen"]      = { hpregen = 2 },
    ["cg_armorregen"]   = { armorregen = 1 },
    ["cg_res"]          = { resistance = 0.01 },
    ["cg_damage"]       = { damage = 0.03 },
    ["cg_salary"]       = { salary_bonus = 0.05 },
    -- Jedi Order
    ["jedi_force_regen"]  = { lscs_force_regen = 5 },
    ["jedi_force_regen_2"]= { lscs_force_regen = 10 },
    ["jedi_hp_regen"]     = { hpregen = 2 },
    ["jedi_hp"]           = { hp = 5 },
    ["jedi_armor"]        = { armor = 5 },
    ["jedi_speed"]        = { movespeed = 0.03 },
    ["jedi_saber_dmg"]    = { lscs_damage = 0.05 },
    ["jedi_saber_dmg_2"]  = { lscs_damage = 0.08 },
    ["jedi_block"]        = { lscs_block = 0.05 },
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
>>>>>>> Stashed changes
