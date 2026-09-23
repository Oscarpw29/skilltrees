-- Load order matters: config -> core -> everything else. Prefix decides the realm.
local FILES = {
    "sh_config.lua",
    "sh_core.lua",
    "sh_hooks.lua",

    "sv_net.lua",
    "sv_data.lua",
    "sv_skills.lua",
    "sv_effects.lua",
    "sv_xp.lua",
    "sv_stations.lua",

    "cl_net.lua",
    "cl_hud.lua",
    "cl_admin.lua",

    "menu/cl_theme.lua",
    "menu/cl_node.lua",
    "menu/cl_tree.lua",
    "menu/cl_tooltip.lua",
    "menu/cl_frame.lua",
    "menu/cl_menu.lua",
}

for _, name in ipairs(FILES) do
    local path = "skilltrees/" .. name
    local realm = string.GetFileFromFilename(name):sub(1, 3)

    if realm == "sv_" then
        if SERVER then include(path) end
    elseif realm == "cl_" then
        if SERVER then AddCSLuaFile(path) else include(path) end
    else
        if SERVER then AddCSLuaFile(path) end
        include(path)
    end
end
