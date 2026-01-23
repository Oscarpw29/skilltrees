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

SkillTrees.Config = {}

SkillTrees.Tree = {
    ["Trooper"] = {
        -- Teams = {},
        -- Ranks = {},
        Color = Color(138,198,209),

        Skills = {
            ["health_25"] = {
                name = "Health Boost I",
                description = "Increase base health by 25.",
                price = 1,
                maxLevel = 3,
                requirement = nil,
            },
            ["health_50"] = {
                name = "Health Boost II",
                description = "Increase base health by 50.",
                price = 2,
                maxLevel = 2,
                requirement = "health_25",
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
    ["health_25"] = { hp = 25 },
    ["health_50"] = { hp = 50 },
    ["armor_25"] = { armor = 25 },
    ["armor_50"] = { armor = 50 }
}

function SkillTrees:CalculateBuffs(ply)
    local stats = { hp = 0, speed = 0, armor = 0 }
    if not ply.SkillData or not ply.SkillData.skills then return stats end

    for skillID, level in pairs(ply.SkillData.skills) do
        local buff = SkillTrees.Buffs[skillID]
        if buff then
            if buff.hp then stats.hp = stats.hp + (buff.hp * level) end
            if buff.speed then stats.speed = stats.speed + (buff.speed * level) end
            if buff.armor then stats.armor = stats.armor + (buff.armor * level) end
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