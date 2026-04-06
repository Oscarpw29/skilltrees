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
    ["Clone Troopers"] = {
        Color = Color(255,255,255),
        Skills = {
            ["health_10"] = {
                name = "Endurance",
                description = "Increases health by 10",
                price = 1,
                maxLevel = 10,
                requirement = nil,
            },
            ["hp_regen_2"] = {
                name = "Nano Robotic Flesh",
                description = "Regenerate health out of combat",
                price = 3,
                maxLevel = 5,
                requirement = "health_10",
            },
            ["armor_5"] = {
                name = "Armor Boost",
                description = "Increase your armor by 5",
                price = 1,
                maxLevel = 10,
                requirement = nil,
            },
            ["armor_regen_1"] = {
                name = "Nanite Armor",
                description = "Regenerate armor out of combat",
                price = 3,
                maxLevel = 3,
                requirement = "armor_5",
            },
            ["tank"] = {
                name = "Battle Hardened",
                description = "Increase your health by 25, and armor by 10",
                price = 3,
                maxLevel = 5,
                requirement = "armor_regen_1", "hp_regen_2",
            },
            ["damageres_1"] = {
                name = "Brick Wall",
                description = "Reduce damage you take from NPCs by 1% per level",
                price = 5,
                maxLevel = 5,
                requirement = "tank",
            }
        }
    },
    ["Commando"] = {
        Color = Color(10,100,100),
        Ranks = {"superadmin"},
        Teams = {"501ST TC ARC TROOPER","327TH KC ARC TROOPER", "CG DES ARC TROOPER", "DU CC ARC TROOPER"},
        Skills = {
            ["commando_training"] = {
                name = "ARC Training",
                description = "Increase health by 25, armor by 15",
                price = 2, 
                maxLevel = 10,
                requirement = nil,
            }
        }
    },
    ["Alpha Arc"] = {
        Teams = {"Head Staff On Duty"},
        Color = Color(255,100,100),
        Ranks = {"superadmin"},
        Skills = {
            ["tank_arc"] = {
                name = "Enhanced Survivability",
                description = "25 health, 10 armor, and 1% damage reduction from NPCs per level",
                price = 1,
                maxLevel = 10,
                requirement = nil,
            },
            ["hp_regen_2"] = {
                name = "Nano Robotic Armor",
                description = "Regen 2 health every 5 seconds when out of combat",
                price = 1,
                maxLevel = 10,
                requirement = nil,
            },
            ["armor_regen_1"] = {
                name = "Nano Robotic Armor Coating",
                description = "Regen 1 armor every 5 seconds when out of combat",
                price = 1,
                maxLevel = 10,
                requirement = nil,
            },
            ["reloadspeed_25"] = {
                name = "Quick Fingers",
                description = "Increase reload speed by 2.5% per level.",
                price = 1,
                maxLevel = 5,
                requirement = nil,
            },
            ["firerate_25"] = {
                name = "Quick Fingers",
                description = "Increase firerate by 2.5% per level.",
                price = 1,
                maxLevel = 5,
                requirement = nil,
            },
        }
    },
    ["Jedi"] = {
        Teams = {TEAM_JEDI},
        SteamIDs = {"STEAM_0:1:12345"},
        Color = Color(50,255,67),

        Skills = {
            ["armor_50"] = {
                name = "Force Push",
                description = "Knock back enemies infront of you",
                price = 3,
                maxLevel = 1,
            },
        }
    }
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
    ["reloadspeed_25"] = { reloadspeed = 0.025},
    ["reloadspeed_01"] = { reloadspeed = 0.01},
    ["commando_training"] = { hp = 25, armor = 15, resistance = 0.01},
    ["speed"] = { movespeed = 0.02}
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
    local stats = { hp = 0, speed = 0, armor = 0, hpregen = 0, armorregen = 0, firerate = 0, reloadspeed = 0, movespeed = 0, resistance = 0}
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
