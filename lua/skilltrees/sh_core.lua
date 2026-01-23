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
            ["health_boost_1"] = {
                name = "Health Boost I",
                description = "Increase base health by 25.",
                price = 1,
                maxLevel = 3,
                requirement = nil,
            },
            ["health_boost_2"] = {
                name = "Health Boost II",
                description = "Increase base health by 50.",
                price = 2,
                maxLevel = 2,
                requirement = "health_boost_1",
            },
            
        }
    },

    ["Jedi"] = {
        Teams = {TEAM_JEDI},
        SteamIDs = {"STEAM_0:1:12345"},
        Color = Color(50,255,67),

        Skills = {
            ["push_1"] = {
                name = "Force Push",
                description = "Knock back enemies infront of you",
                price = 3,
                maxLevel = 1,
            },
        }
    }
}

function SkillTrees:GetSkill(skillID)
    for catName, catData in pairs(SkillTrees.Tree) do
        if catData.Skills and catData.Skills[skillID] then
            return catData.Skills[skillID], catName
        end
    end
    return nil, nil
end