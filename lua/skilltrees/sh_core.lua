SkillTrees.Skills = {
    strength_1 = {
        name = "Strength I",
        maxLevel = 1,
        description = "more damage",
        -- allowedJobs = {""},
        -- allowedSteamIDs = {""},
        pointsPerLevel = 1,
        requirement = nil,
        category = "roids",
    },
    strength_2 = {
        name = "Strength II",
        maxLevel = 1, 
        description = "even more damage",
        requirement = "strength_1",
        category = "roids",
    },
    jedi_jump = {
        name = "Force Jump",
        maxLevel = 3,
        description = "Jump Higher",
        allowedJobs = {""},
        category = "jedi"
    }
}