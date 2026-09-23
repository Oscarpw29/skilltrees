-- Everything a server owner is expected to edit lives in this file.
SkillTrees = SkillTrees or {}

SkillTrees.MaxLevel = 15

-- XP needed to go from `level` to `level + 1` is floor(XP_BASE * level ^ XP_EXPONENT)
SkillTrees.XP_BASE     = 75
SkillTrees.XP_EXPONENT = 1.2

-- One skill point every N levels (1 = a point on every level-up, 14 points by level 15)
SkillTrees.POINTS_EVERY_N_LEVELS = 1

-- Tree grid. Row r unlocks once (r - 1) * ROW_POINTS points are spent in the rows above it.
SkillTrees.TREE_ROWS  = 3
SkillTrees.TREE_COLS  = 4
SkillTrees.ROW_POINTS = 5

SkillTrees.NPC_XP_REWARD    = 5
SkillTrees.PASSIVE_XP       = 25
SkillTrees.PASSIVE_INTERVAL = 300 -- seconds

-- XP multiplier per user group
SkillTrees.RankMultipliers = {
    ["superadmin"]    = 5.0,
    ["Management"]    = 4.0,
    ["Senior Admin"]  = 3.0,
    ["Admin"]         = 2.0,
    ["INSANE VIP"]    = 5.0,
    ["Legendary VIP"] = 4.5,
    ["Beskar VIP"]    = 4.0,
    ["Diamond VIP"]   = 3.5,
    ["Platinum VIP"]  = 3.0,
    ["Gold VIP"]      = 2.5,
    ["Silver VIP"]    = 2.0,
    ["Bronze VIP"]    = 1.5,
    ["user"]          = 1.0,
}

--[[
Tree fields
    Color            tree accent colour
    Order            optional sort position in the menu (lower first, then by name)
    Access (a tree with none of these is open to everyone; matching any one grants access):
        MRSGroup     { "212th Attack" }   must match the player's MRS group exactly
        Teams        { TEAM_X, "Job Name" }
        Ranks        { "superadmin" }     user groups
        SteamIDs     { "STEAM_0:1:..." }
    Skills           { [id] = skill }
    Specializations  { [name] = { name, description, unlockLevel, comingSoon, Skills } }

Skill fields
    name, description
    price            points per level (default 1)
    maxLevel         (default 1)
    row, col         grid position (row 1..TREE_ROWS, col 1..TREE_COLS)
    requirement      skill id that must be at its max level first (drawn as a connector)
    minLevel         player level needed before the skill can be learned
    unlocks          ArcCW attachment ids this skill unlocks. An attachment listed on any skill
                     is locked until the player owns one of those skills; unlisted ones are free.
    allowedJobs      optional list of job names
    allowedSteamIDs  optional list of SteamIDs
    buffs            per-level stat bonuses, see SkillTrees.StatLabels in sh_core.lua for the keys
    icon             optional material path for the node (defaults to the first buff's icon)
]]

local SPECS = {
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
}

SkillTrees.Tree = {
    ["212th"] = {
        Order = 1,
        Color = Color(255, 140, 0),
        MRSGroup = { "212th Attack" },
        Skills = {
            ["212th_hp_1"] = {
                row = 1, col = 1,
                name = "Frontline Conditioning",
                description = "Increase health by 10 per level",
                price = 1, maxLevel = 3,
                buffs = { hp = 10 },
            },
            ["212th_hpregen"] = {
                row = 2, col = 2,
                name = "Battle Recovery",
                description = "Regenerate 2 health every 2 seconds out of combat",
                price = 1, maxLevel = 2,
                requirement = "212th_hp_1",
                buffs = { hpregen = 2 },
            },
            ["212th_hp_2"] = {
                row = 2, col = 1,
                name = "Veteran's Body",
                description = "Increase health by 10 and armor by 5 per level",
                price = 1, maxLevel = 2,
                requirement = "212th_hp_1",
                buffs = { hp = 10, armor = 5 },
            },
            ["212th_res"] = {
                row = 3, col = 2,
                name = "Unbreakable",
                description = "Reduce damage taken by 1% per level",
                price = 2, maxLevel = 3,
                requirement = "212th_hpregen",
                buffs = { resistance = 0.01 },
            },
            ["212th_capstone"] = {
                row = 3, col = 3,
                name = "Ghost Company Veteran",
                description = "Capstone. Unlocks the Veteran Training weapon perk: faster reloads and steadier recoil.",
                price = 2, maxLevel = 1,
                minLevel = 15,
                icon = "icon16/medal_gold_1.png",
                unlocks = { "perk_veteran_training" },
            },
            ["212th_firerate"] = {
                row = 1, col = 3,
                name = "Squad Suppression",
                description = "Increase fire rate by 5% per level",
                price = 1, maxLevel = 2,
                buffs = { firerate = 0.05 },
            },
            ["212th_damage"] = {
                row = 2, col = 3,
                name = "Frontline Aggression",
                description = "Increase bullet damage by 5% per level",
                price = 2, maxLevel = 3,
                requirement = "212th_firerate",
                buffs = { damage = 0.05 },
            },
            ["212th_salary"] = {
                row = 1, col = 4,
                name = "Combat Pay",
                description = "Increase salary by 5% per level",
                price = 1, maxLevel = 3,
                buffs = { salary_bonus = 0.05 },
            },
        },
        Specializations = SPECS,
    },

    ["104th"] = {
        Order = 2,
        Color = Color(150, 60, 60),
        MRSGroup = { "104th Mechanized" },
        Skills = {
            ["104th_speed_1"] = {
                row = 1, col = 1,
                name = "Pack Hunter",
                description = "Increase move speed by 2% per level",
                price = 1, maxLevel = 3,
                buffs = { movespeed = 0.02 },
            },
            ["104th_speed_2"] = {
                row = 2, col = 1,
                name = "Relentless Pursuit",
                description = "Increase move speed by a further 2% per level",
                price = 2, maxLevel = 2,
                requirement = "104th_speed_1",
                buffs = { movespeed = 0.02 },
            },
            ["104th_reload"] = {
                row = 1, col = 2,
                name = "Quick Hands",
                description = "Increase reload speed by 5% per level",
                price = 1, maxLevel = 3,
                buffs = { reloadspeed = 0.05 },
            },
            ["104th_damage"] = {
                row = 2, col = 2,
                name = "Wolf's Precision",
                description = "Increase bullet damage by 5% per level",
                price = 2, maxLevel = 3,
                requirement = "104th_reload",
                buffs = { damage = 0.05 },
            },
            ["104th_hp"] = {
                row = 1, col = 3,
                name = "Hardened Pack",
                description = "Increase health by 5 per level",
                price = 1, maxLevel = 3,
                buffs = { hp = 5 },
            },
            ["104th_armor"] = {
                row = 2, col = 3,
                name = "Pack Armor",
                description = "Increase armor by 5 per level",
                price = 1, maxLevel = 3,
                requirement = "104th_hp",
                buffs = { armor = 5 },
            },
            ["104th_xp"] = {
                row = 3, col = 2,
                name = "Wolfpack Training",
                description = "Gain 10% more XP",
                price = 2, maxLevel = 1,
                buffs = { xp_boost = 0.1 },
            },
            ["104th_capstone"] = {
                row = 3, col = 3,
                name = "Alpha of the Pack",
                description = "Capstone. Unlocks the Quickdraw Training weapon perk: faster draw and movement.",
                price = 2, maxLevel = 1,
                minLevel = 15,
                icon = "icon16/medal_gold_1.png",
                unlocks = { "perk_quickdraw_training" },
            },
        },
        Specializations = SPECS,
    },

    ["Shock"] = {
        Order = 3,
        Color = Color(0, 210, 255),
        MRSGroup = { "Shock" },
        Skills = {
            ["shock_armor_1"] = {
                row = 1, col = 1,
                name = "Riot Plating",
                description = "Increase armor by 5 per level",
                price = 1, maxLevel = 3,
                buffs = { armor = 5 },
            },
            ["shock_armorregen"] = {
                row = 2, col = 1,
                name = "Reinforced Gear",
                description = "Regenerate 1 armor every 2 seconds out of combat",
                price = 1, maxLevel = 2,
                requirement = "shock_armor_1",
                buffs = { armorregen = 1 },
            },
            ["shock_res"] = {
                row = 3, col = 1,
                name = "Riot Conditioning",
                description = "Reduce damage taken by 1% per level",
                price = 2, maxLevel = 3,
                requirement = "shock_armorregen",
                buffs = { resistance = 0.01 },
            },
            ["shock_capstone"] = {
                row = 3, col = 2,
                name = "Enforcer Marksmanship",
                description = "Capstone. Unlocks the Marksman Training weapon perk: faster, tighter aim down sights.",
                price = 2, maxLevel = 1,
                minLevel = 15,
                icon = "icon16/medal_gold_1.png",
                unlocks = { "perk_marksman_training" },
            },
            ["shock_hp"] = {
                row = 1, col = 2,
                name = "Determination",
                description = "Increase health by 8 and armor by 4 per level",
                price = 1, maxLevel = 3,
                buffs = { hp = 8, armor = 4 },
            },
            ["shock_hpregen"] = {
                row = 2, col = 2,
                name = "Second Wind",
                description = "Regenerate 2 health every 2 seconds out of combat",
                price = 1, maxLevel = 2,
                requirement = "shock_hp",
                buffs = { hpregen = 2 },
            },
            ["shock_damage"] = {
                row = 1, col = 3,
                name = "Enforcement Firepower",
                description = "Increase bullet damage by 3% per level",
                price = 1, maxLevel = 3,
                buffs = { damage = 0.03 },
            },
            ["shock_firerate"] = {
                row = 2, col = 3,
                name = "Suppressive Fire",
                description = "Increase fire rate by 5% per level",
                price = 2, maxLevel = 2,
                requirement = "shock_damage",
                buffs = { firerate = 0.05 },
            },
        },
        Specializations = SPECS,
    },

    -- Universal single-unlock tree (no access fields = open to every job).
    -- Gates the Clone Wars 2003 pack's Energization and Internal Mod attachments via `unlocks`.
    ["Ordnance"] = {
        Order = 4,
        Color = Color(200, 160, 40),
        Skills = {
            ["adv_munitions"] = {
                row = 1, col = 2,
                name = "Advanced Munitions Training",
                description = "Unlocks specialized Energization cells and internal weapon modifications.",
                price = 4, maxLevel = 1,
                icon = "icon16/bullet_star.png",
                unlocks = {
                    "ammo_highoutput", "ammo_rapidcycle", "ammo_stabilized",
                    "mod_cooling_vents", "mod_lightweight_internals", "mod_reinforced_barrel",
                },
            },
        },
    },
}

-- Rebuild lookups when this file is live-reloaded on its own
if SkillTrees.BuildIndex then SkillTrees:BuildIndex() end
