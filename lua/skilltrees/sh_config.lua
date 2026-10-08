-- Everything a server owner is expected to edit lives in this file.
SkillTrees = SkillTrees or {}

SkillTrees.MaxLevel = 30

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
    ["Bronze VIP"]    = 1.55,
    ["user"]          = 1.0,
}

--[[
Tree fields
    Color            tree accent colour
    Emblem           optional material path for the unit badge shown on its tab
    Order            optional sort position in the menu (lower first, then by name)
    Access (a tree with none of these is open to everyone; matching any one grants access):
        Teams        { "1st Sector Wolfpack Company" }   DarkRP job names (or TEAM_X ids); the player must be on one of
                     them. Whitelists live in the GAS job whitelist addon, so this follows the job a player is on
                     right now. Skills they have learned stay saved to them when they change job.
        MRSGroup     { "212th Attack" }   must match the player's MRS group exactly (only if you use MRS ranks)
        Ranks        { "superadmin" }     user groups
        SteamIDs     { "STEAM_0:1:..." }
    Attachments      ArcCW attachment ids every member of this unit can use (e.g. its scopes).
                     Like skill `unlocks`, listing an attachment here locks it for everyone else.
    Skills           { [id] = skill }
    Specializations  { [name] = { name, description, unlockLevel, RowPoints, comingSoon, Skills } }
                     A tree's specialisations are either/or: a player who has put a point into one cannot
                     learn the other until they take those points back out or reset. `Skills` uses the
                     same fields as a base tree skill (below); leave it empty (or set comingSoon) to show a
                     placeholder. `unlockLevel` is the player level needed. `RowPoints` is the points that
                     must be spent in the rows above to open the next one (default ROW_POINTS); specialisations
                     use a smaller gate because they share the player's points with the base tree. Skill ids
                     must be unique across the whole file.

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

-- Job names come from DarkRP (darkrp_customthings/jobs.lua). A player gets a tree while they are on one
-- of its jobs; the skills they have learned are saved to them and survive changing job.
local FIRST_SECTOR_LEADERS = {
    "1st Sector Senior Commander", "1st Sector Commander", "1st Sector Officer", "1st Sector Squad Leader",
}

-- jobs(listOrName, ...) flattens job lists and single names into one list
local function jobs(...)
    local out = {}
    for _, part in ipairs({ ... }) do
        if istable(part) then table.Add(out, part) else table.insert(out, part) end
    end
    return out
end

SkillTrees.Tree = {
    ["212th"] = {
        Emblem = "vtx_skills/unit_212th.png",
        Order = 1,
        Color = Color(255, 140, 0),
        Teams = jobs(FIRST_SECTOR_LEADERS, "1st Sector 2nd Airborne Company", "1st Sector Ghost Ranger Company"),
        Attachments = { "fml_mw2r_optic_holo", "fml_mw_optic_viper", "fml_mw_optic_mag_holo", "fml_mw2r_optic_acog" }, -- unit scopes
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
                description = "Capstone. Unlocks a specialised Energization cell, internal modification and training perk for your weapons.",
                price = 2, maxLevel = 1,
                minLevel = 15,
                icon = "vtx_skills/capstone.png",
                unlocks = { "ammo_rapidcycle", "mod_cooling_vents", "perk_veteran_training" },
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
        Specializations = {
            ["Assault Specialist"] = {
                name = "Assault Specialist",
                description = "Close-range burst damage for breaching and pushing objectives.",
                unlockLevel = 15,
                RowPoints = 3,
                Skills = {
                    ["212th_as_breach"] = {
                        row = 1, col = 1,
                        name = "Breaching Doctrine",
                        description = "Increase bullet damage by 4% per level",
                        price = 1, maxLevel = 3,
                        buffs = { damage = 0.04 },
                    },
                    ["212th_as_rush"] = {
                        row = 1, col = 2,
                        name = "Rush Tactics",
                        description = "Increase move speed by 3% per level",
                        price = 1, maxLevel = 2,
                        buffs = { movespeed = 0.03 },
                    },
                    ["212th_as_cycle"] = {
                        row = 1, col = 3,
                        name = "Rapid Cycling",
                        description = "Increase fire rate by 4% per level",
                        price = 1, maxLevel = 3,
                        buffs = { firerate = 0.04 },
                    },
                    ["212th_as_plate"] = {
                        row = 1, col = 4,
                        name = "Breacher Plating",
                        description = "Increase armor by 8 per level",
                        price = 1, maxLevel = 2,
                        buffs = { armor = 8 },
                    },
                    ["212th_as_shock"] = {
                        row = 2, col = 1,
                        name = "Shock Entry",
                        description = "Increase bullet damage by 5% per level",
                        price = 2, maxLevel = 2,
                        requirement = "212th_as_breach",
                        unlocks = { "cw_charm_212th_badge" },
                        buffs = { damage = 0.05 },
                    },
                    ["212th_as_momentum"] = {
                        row = 2, col = 2,
                        name = "Momentum",
                        description = "Regenerate 2 health every 2 seconds out of combat",
                        price = 1, maxLevel = 2,
                        requirement = "212th_as_rush",
                        buffs = { hpregen = 2 },
                    },
                    ["212th_as_overdrive"] = {
                        row = 2, col = 3,
                        name = "Overdrive",
                        description = "Increase reload speed by 6% per level",
                        price = 1, maxLevel = 2,
                        requirement = "212th_as_cycle",
                        buffs = { reloadspeed = 0.06 },
                    },
                    ["212th_as_breach_clear"] = {
                        row = 3, col = 2,
                        name = "Breach and Clear",
                        description = "Increase bullet damage by 8% and fire rate by 6%, and unlock the Assault tactical, foregrip and grip attachments",
                        price = 3, maxLevel = 1,
                        requirement = "212th_as_shock",
                        icon = "vtx_skills/capstone.png",
                        unlocks = { "cw_tac_breach_link", "cw_fg_assault_stabilizer", "cw_grip_shock_entry" },
                        buffs = { damage = 0.08, firerate = 0.06 },
                    },
                },
            },
            ["Gunnery"] = {
                name = "Gunnery",
                description = "Sustained heavy fire that keeps the enemy pinned down.",
                unlockLevel = 15,
                comingSoon = true,
                Skills = {},
            },
        },
    },

    ["104th"] = {
        Emblem = "vtx_skills/unit_104th.png",
        Order = 2,
        Color = Color(150, 60, 60),
        Teams = jobs(FIRST_SECTOR_LEADERS, "1st Sector Wolfpack Company"),
        Attachments = { "fml_mw_optic_opk7", "fml_mw2r_optic_mars", "fml_mw_optic_mag_kobra", "fml_mw2r_optic_aug" }, -- unit scopes
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
                description = "Capstone. Unlocks a specialised Energization cell, internal modification and training perk for your weapons.",
                price = 2, maxLevel = 1,
                minLevel = 15,
                icon = "vtx_skills/capstone.png",
                unlocks = { "ammo_highoutput", "mod_lightweight_internals", "perk_quickdraw_training" },
            },
        },
        Specializations = {
            ["Tactics"] = {
                name = "Tactics",
                description = "Mobile skirmishing: hit, reposition and flank.",
                unlockLevel = 15,
                RowPoints = 3,
                Skills = {
                    ["104th_tac_footwork"] = {
                        row = 1, col = 1,
                        name = "Light Footwork",
                        description = "Increase move speed by 3% per level",
                        price = 1, maxLevel = 3,
                        buffs = { movespeed = 0.03 },
                    },
                    ["104th_tac_hands"] = {
                        row = 1, col = 2,
                        name = "Quick Hands",
                        description = "Increase reload speed by 6% per level",
                        price = 1, maxLevel = 2,
                        buffs = { reloadspeed = 0.06 },
                    },
                    ["104th_tac_conditioning"] = {
                        row = 1, col = 3,
                        name = "Field Conditioning",
                        description = "Increase health by 10 per level",
                        price = 1, maxLevel = 3,
                        buffs = { hp = 10 },
                    },
                    ["104th_tac_snap"] = {
                        row = 1, col = 4,
                        name = "Snap Shooting",
                        description = "Increase fire rate by 4% per level",
                        price = 1, maxLevel = 2,
                        buffs = { firerate = 0.04 },
                    },
                    ["104th_tac_flank"] = {
                        row = 2, col = 1,
                        name = "Flanking Manoeuvres",
                        description = "Increase move speed by 3% per level",
                        price = 2, maxLevel = 2,
                        requirement = "104th_tac_footwork",
                        unlocks = { "cw_charm_104th_token" },
                        buffs = { movespeed = 0.03 },
                    },
                    ["104th_tac_opportunist"] = {
                        row = 2, col = 2,
                        name = "Opportunist",
                        description = "Increase bullet damage by 4% per level",
                        price = 2, maxLevel = 2,
                        requirement = "104th_tac_hands",
                        buffs = { damage = 0.04 },
                    },
                    ["104th_tac_wind"] = {
                        row = 2, col = 3,
                        name = "Second Wind",
                        description = "Regenerate 2 health every 2 seconds out of combat",
                        price = 1, maxLevel = 2,
                        requirement = "104th_tac_conditioning",
                        buffs = { hpregen = 2 },
                    },
                    ["104th_tac_hit_and_run"] = {
                        row = 3, col = 2,
                        name = "Hit and Run",
                        description = "Increase move speed, bullet damage and reload speed by 5%, and unlock the Skirmisher tactical, foregrip and grip attachments",
                        price = 3, maxLevel = 1,
                        requirement = "104th_tac_opportunist",
                        icon = "vtx_skills/capstone.png",
                        unlocks = { "cw_tac_skirmish_rangefinder", "cw_fg_light_skirmish", "cw_grip_quick_release" },
                        buffs = { movespeed = 0.05, damage = 0.05, reloadspeed = 0.05 },
                    },
                },
            },
            ["Sharpshooter"] = {
                name = "Sharpshooter",
                description = "Long-range precision with access to long-range scopes.",
                unlockLevel = 15,
                comingSoon = true,
                Skills = {},
            },
        },
    },

    ["Torrent"] = {
        Order = 3,
        Color = Color(60, 120, 230),
        Teams = jobs(FIRST_SECTOR_LEADERS, "1st Sector Torrent Company"),
        Skills = {
            ["torrent_hp"] = {
                row = 1, col = 1,
                name = "Torrent Resolve",
                description = "Increase health by 10 per level",
                price = 1, maxLevel = 3,
                buffs = { hp = 10 },
            },
            ["torrent_armor"] = {
                row = 2, col = 1,
                name = "Sturdy Plating",
                description = "Increase armor by 6 per level",
                price = 1, maxLevel = 3,
                requirement = "torrent_hp",
                buffs = { armor = 6 },
            },
            ["torrent_damage"] = {
                row = 1, col = 2,
                name = "Aggressive Doctrine",
                description = "Increase bullet damage by 5% per level",
                price = 1, maxLevel = 3,
                buffs = { damage = 0.05 },
            },
            ["torrent_firerate"] = {
                row = 2, col = 2,
                name = "Sustained Assault",
                description = "Increase fire rate by 5% per level",
                price = 2, maxLevel = 2,
                requirement = "torrent_damage",
                buffs = { firerate = 0.05 },
            },
            ["torrent_res"] = {
                row = 1, col = 3,
                name = "Hold Fast",
                description = "Reduce damage taken by 1% per level",
                price = 1, maxLevel = 3,
                buffs = { resistance = 0.01 },
            },
            ["torrent_speed"] = {
                row = 2, col = 3,
                name = "Press the Attack",
                description = "Increase move speed by 2% per level",
                price = 1, maxLevel = 3,
                requirement = "torrent_res",
                buffs = { movespeed = 0.02 },
            },
            ["torrent_salary"] = {
                row = 3, col = 2,
                name = "Company Pay",
                description = "Increase salary by 5% per level",
                price = 2, maxLevel = 2,
                buffs = { salary_bonus = 0.05 },
            },
            ["torrent_capstone"] = {
                row = 3, col = 3,
                name = "Torrent Company Veteran",
                description = "Capstone. Unlocks a specialised Energization cell, internal modification and training perk for your weapons.",
                price = 2, maxLevel = 1,
                minLevel = 15,
                icon = "vtx_skills/capstone.png",
                unlocks = { "ammo_highoutput", "mod_reinforced_barrel", "perk_veteran_training" },
            },
        },
        Specializations = {
            ["Vanguard"] = {
                name = "Vanguard",
                description = "Lead the charge: close assault, breaching and holding ground.",
                unlockLevel = 15,
                comingSoon = true,
                Skills = {},
            },
            ["Heavy Gunner"] = {
                name = "Heavy Gunner",
                description = "Sustained heavy fire that breaks up enemy formations.",
                unlockLevel = 15,
                comingSoon = true,
                Skills = {},
            },
        },
    },

    ["Bacta"] = {
        Order = 4,
        Color = Color(70, 180, 120),
        Teams = jobs(FIRST_SECTOR_LEADERS, "1st Sector Bacta Company"),
        Skills = {
            ["bacta_hp"] = {
                row = 1, col = 1,
                name = "Medic's Constitution",
                description = "Increase health by 10 per level",
                price = 1, maxLevel = 3,
                buffs = { hp = 10 },
            },
            ["bacta_hpregen"] = {
                row = 2, col = 1,
                name = "Bacta Infusion",
                description = "Regenerate 2 health every 2 seconds out of combat",
                price = 1, maxLevel = 2,
                requirement = "bacta_hp",
                buffs = { hpregen = 2 },
            },
            ["bacta_armorregen"] = {
                row = 1, col = 2,
                name = "Field Plate Repair",
                description = "Regenerate 1 armor every 2 seconds",
                price = 1, maxLevel = 2,
                buffs = { armorregen = 1 },
            },
            ["bacta_res"] = {
                row = 2, col = 2,
                name = "Triage Discipline",
                description = "Reduce damage taken by 1% per level",
                price = 2, maxLevel = 3,
                requirement = "bacta_armorregen",
                buffs = { resistance = 0.01 },
            },
            ["bacta_speed"] = {
                row = 1, col = 3,
                name = "Fleet-Footed",
                description = "Increase move speed by 2% per level",
                price = 1, maxLevel = 3,
                buffs = { movespeed = 0.02 },
            },
            ["bacta_reload"] = {
                row = 2, col = 3,
                name = "Steady Hands",
                description = "Increase reload speed by 5% per level",
                price = 1, maxLevel = 3,
                requirement = "bacta_speed",
                buffs = { reloadspeed = 0.05 },
            },
            ["bacta_xp"] = {
                row = 3, col = 2,
                name = "Combat Medicine Training",
                description = "Gain 10% more XP",
                price = 2, maxLevel = 1,
                buffs = { xp_boost = 0.1 },
            },
            ["bacta_capstone"] = {
                row = 3, col = 3,
                name = "Field Surgeon",
                description = "Capstone. Unlocks a specialised Energization cell, internal modification and training perk for your weapons.",
                price = 2, maxLevel = 1,
                minLevel = 15,
                icon = "vtx_skills/capstone.png",
                unlocks = { "ammo_stabilized", "mod_lightweight_internals", "perk_veteran_training" },
            },
        },
        Specializations = {
            ["Triage"] = {
                name = "Triage",
                description = "Keep the squad alive: faster healing and sturdier allies.",
                unlockLevel = 15,
                comingSoon = true,
                Skills = {},
            },
            ["Combat Support"] = {
                name = "Combat Support",
                description = "Fight alongside the line with better weapons handling.",
                unlockLevel = 15,
                comingSoon = true,
                Skills = {},
            },
        },
    },

    ["Shock"] = {
        Emblem = "vtx_skills/unit_shock.png",
        Order = 5,
        Color = Color(0, 210, 255),
        Teams = { "Shock Commander", "Shock Officer", "Shock Tracker", "Shock NCO", "Shock Medic", "Shock Enlisted" },
        Attachments = { "fml_mw_optic_holo", "fml_mw_optic_mag_holo", "fml_mw_optic_pkas", "fml_mw2r_optic_susat", "cw_ammo_stun_shot" }, -- unit scopes and gear
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
                description = "Capstone. Unlocks a specialised Energization cell, internal modification and training perk for your weapons.",
                price = 2, maxLevel = 1,
                minLevel = 15,
                icon = "vtx_skills/capstone.png",
                unlocks = { "ammo_stabilized", "mod_reinforced_barrel", "perk_marksman_training" },
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
        Specializations = {
            ["Shield Specialist"] = {
                name = "Shield Specialist",
                description = "Hold the line with heavier armour and damage reduction.",
                unlockLevel = 15,
                RowPoints = 3,
                Skills = {
                    ["shock_shield_plate"] = {
                        row = 1, col = 1,
                        name = "Reinforced Plating",
                        description = "Increase armor by 8 per level",
                        price = 1, maxLevel = 3,
                        buffs = { armor = 8 },
                    },
                    ["shock_shield_frame"] = {
                        row = 1, col = 2,
                        name = "Hardened Frame",
                        description = "Increase health by 10 per level",
                        price = 1, maxLevel = 3,
                        buffs = { hp = 10 },
                    },
                    ["shock_shield_guard"] = {
                        row = 1, col = 3,
                        name = "Guard Stance",
                        description = "Reduce damage taken by 1% per level",
                        price = 1, maxLevel = 2,
                        buffs = { resistance = 0.01 },
                    },
                    ["shock_shield_mend"] = {
                        row = 1, col = 4,
                        name = "Field Repair",
                        description = "Regenerate 1 armor every 2 seconds",
                        price = 1, maxLevel = 2,
                        buffs = { armorregen = 1 },
                    },
                    ["shock_shield_bulwark"] = {
                        row = 2, col = 1,
                        name = "Bulwark",
                        description = "Increase armor by 8 and health by 5 per level",
                        price = 2, maxLevel = 2,
                        requirement = "shock_shield_plate",
                        unlocks = { "cw_charm_shock_tag" },
                        buffs = { armor = 8, hp = 5 },
                    },
                    ["shock_shield_endure"] = {
                        row = 2, col = 2,
                        name = "Endure",
                        description = "Regenerate 2 health every 2 seconds out of combat",
                        price = 1, maxLevel = 2,
                        requirement = "shock_shield_frame",
                        buffs = { hpregen = 2 },
                    },
                    ["shock_shield_stand"] = {
                        row = 2, col = 3,
                        name = "Stand Firm",
                        description = "Reduce damage taken by 1.5% per level",
                        price = 2, maxLevel = 2,
                        requirement = "shock_shield_guard",
                        buffs = { resistance = 0.015 },
                    },
                    ["shock_shield_immovable"] = {
                        row = 3, col = 2,
                        name = "Immovable Object",
                        description = "Increase armor by 15 and health by 20, reduce damage taken by 3%, and unlock the Bulwark tactical, foregrip and grip attachments",
                        price = 3, maxLevel = 1,
                        requirement = "shock_shield_bulwark",
                        icon = "vtx_skills/capstone.png",
                        unlocks = { "cw_tac_guardian_link", "cw_fg_bulwark_handguard", "cw_grip_anchor" },
                        buffs = { armor = 15, hp = 20, resistance = 0.03 },
                    },
                },
            },
            ["Gunnery"] = {
                name = "Gunnery",
                description = "Suppressive fire to control crowds and choke points.",
                unlockLevel = 15,
                comingSoon = true,
                Skills = {},
            },
        },
    },

    -- Special operations: stronger ranks than the line units.
    -- Access is by DarkRP job name (whitelists are handled by the GAS job whitelist addon).
    ["Muunilinst 10"] = {
        Emblem = "vtx_skills/unit_mun10.png",
        Order = 6,
        Color = Color(150, 110, 235),
        Teams = { "M10 Alpha-77 Fordo", "M10 Alpha-17", "M10 Alpha ARC Pilot", "M10 Alpha ARC Heavy", "M10 Alpha ARC" },
        Attachments = { "fml_mw_optic_1p29", "fml_mw2r_optic_acog_acog", "fml_mw_optic_mag_opk7", "fml_mw2r_optic_thermal" }, -- unit scopes
        Skills = {
            ["mun10_damage_1"] = {
                row = 1, col = 1,
                name = "Precision Strikes",
                description = "Increase bullet damage by 6% per level",
                price = 1, maxLevel = 3,
                buffs = { damage = 0.06 },
            },
            ["mun10_hp"] = {
                row = 1, col = 2,
                name = "Commando Conditioning",
                description = "Increase health by 12 per level",
                price = 1, maxLevel = 3,
                buffs = { hp = 12 },
            },
            ["mun10_reload"] = {
                row = 1, col = 3,
                name = "Rapid Reload",
                description = "Increase reload speed by 6% per level",
                price = 1, maxLevel = 3,
                buffs = { reloadspeed = 0.06 },
            },
            ["mun10_speed"] = {
                row = 1, col = 4,
                name = "Infiltrator",
                description = "Increase move speed by 3% per level",
                price = 1, maxLevel = 2,
                buffs = { movespeed = 0.03 },
            },
            ["mun10_damage_2"] = {
                row = 2, col = 1,
                name = "Lethal Focus",
                description = "Increase bullet damage by a further 6% per level",
                price = 2, maxLevel = 2,
                requirement = "mun10_damage_1",
                buffs = { damage = 0.06 },
            },
            ["mun10_armor"] = {
                row = 2, col = 2,
                name = "Special Issue Plating",
                description = "Increase armor by 8 per level",
                price = 1, maxLevel = 3,
                requirement = "mun10_hp",
                buffs = { armor = 8 },
            },
            ["mun10_firerate"] = {
                row = 2, col = 3,
                name = "Trigger Discipline",
                description = "Increase fire rate by 6% per level",
                price = 1, maxLevel = 2,
                requirement = "mun10_reload",
                buffs = { firerate = 0.06 },
            },
            ["mun10_res"] = {
                row = 3, col = 2,
                name = "Hardened Operative",
                description = "Reduce damage taken by 1.5% per level",
                price = 2, maxLevel = 3,
                requirement = "mun10_armor",
                buffs = { resistance = 0.015 },
            },
            ["mun10_capstone"] = {
                row = 3, col = 3,
                name = "Special Operations Loadout",
                description = "Capstone. Unlocks a specialised Energization cell, internal modification and training perk for your weapons.",
                price = 2, maxLevel = 1,
                minLevel = 15,
                icon = "vtx_skills/capstone.png",
                unlocks = { "ammo_highoutput", "mod_reinforced_barrel", "perk_marksman_training" },
            },
        },
        Specializations = {
            ["Concealment"] = {
                name = "Concealment",
                description = "Stealth operations and devastating first strikes.",
                unlockLevel = 15,
                comingSoon = true,
                Skills = {},
            },
            ["Marksmanship"] = {
                name = "Marksmanship",
                description = "Sniper training with access to long-range scopes.",
                unlockLevel = 15,
                RowPoints = 3,
                Skills = {
                    ["mun10_mark_aim"] = {
                        row = 1, col = 1,
                        name = "Steady Aim",
                        description = "Increase bullet damage by 5% per level",
                        price = 1, maxLevel = 3,
                        buffs = { damage = 0.05 },
                    },
                    ["mun10_mark_reload"] = {
                        row = 1, col = 2,
                        name = "Deliberate Reload",
                        description = "Increase reload speed by 5% per level",
                        price = 1, maxLevel = 2,
                        buffs = { reloadspeed = 0.05 },
                    },
                    ["mun10_mark_vest"] = {
                        row = 1, col = 3,
                        name = "Sniper's Vest",
                        description = "Increase armor by 5 per level",
                        price = 1, maxLevel = 2,
                        buffs = { armor = 5 },
                    },
                    ["mun10_mark_body"] = {
                        row = 1, col = 4,
                        name = "Disciplined Body",
                        description = "Increase health by 8 per level",
                        price = 1, maxLevel = 2,
                        buffs = { hp = 8 },
                    },
                    ["mun10_mark_dragunov"] = {
                        row = 2, col = 1,
                        name = "Long Shot",
                        description = "Increase bullet damage by 4% and unlock the Dragunov PSO-1 scope",
                        price = 2, maxLevel = 1,
                        requirement = "mun10_mark_aim",
                        icon = "vtx_skills/scope.png",
                        unlocks = { "fml_mw2r_optic_dragunov", "cw_charm_hunter_mark" },
                        buffs = { damage = 0.04 },
                    },
                    ["mun10_mark_bolt"] = {
                        row = 2, col = 2,
                        name = "Bolt Discipline",
                        description = "Increase reload speed by 6% per level",
                        price = 1, maxLevel = 2,
                        requirement = "mun10_mark_reload",
                        buffs = { reloadspeed = 0.06 },
                    },
                    ["mun10_mark_resolve"] = {
                        row = 2, col = 3,
                        name = "Sniper's Resolve",
                        description = "Reduce damage taken by 1% per level",
                        price = 2, maxLevel = 2,
                        requirement = "mun10_mark_vest",
                        buffs = { resistance = 0.01 },
                    },
                    ["mun10_mark_apex"] = {
                        row = 3, col = 2,
                        name = "Apex Marksman",
                        description = "Increase bullet damage by 8% and unlock the WA2000 scope plus the Marksman tactical, foregrip and grip attachments",
                        price = 3, maxLevel = 1,
                        requirement = "mun10_mark_dragunov",
                        icon = "vtx_skills/capstone.png",
                        unlocks = { "fml_mw2r_optic_wa2000", "cw_tac_ballistic_rangefinder", "cw_fg_precision_rest", "cw_grip_marksman" },
                        buffs = { damage = 0.08 },
                    },
                },
            },
        },
    },
}

-- Attachments locked for everyone until something unlocks them. The long-range sniper scopes
-- are held back for specialisations: Marksmanship (Muunilinst 10) unlocks the Dragunov, then the WA2000.
-- Sharpshooter (104th) is planned to offer them too.
SkillTrees.LockedAttachments = {
    "fml_mw2r_optic_dragunov",
    "fml_mw2r_optic_wa2000",
}

-- Skills removed from the trees. Anyone who owned one is refunded price x level on their
-- next join and it's removed from their data. Keep entries here after removing a skill.
SkillTrees.RetiredSkills = {
    ["adv_munitions"] = { price = 4, reason = "Advanced Munitions Training was replaced by the level 15 capstones" },
}

-- Rebuild lookups when this file is live-reloaded on its own
if SkillTrees.BuildIndex then SkillTrees:BuildIndex() SkillTrees:PatchArcCW() end
