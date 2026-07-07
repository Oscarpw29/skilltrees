if SERVER then
    -- 1. Tell the client to download these files from the server
    AddCSLuaFile("skilltrees/sh_core.lua")
    AddCSLuaFile("skilltrees/sh_hooks.lua")
    AddCSLuaFile("skilltrees/cl_menu.lua")
    AddCSLuaFile("skilltrees/cl_hud.lua")
    AddCSLuaFile("autorun/client/cl_vortex_util.lua")
    AddCSLuaFile("autorun/client/cl_init.lua")

    -- 2. Load the server-side files
    include("skilltrees/sh_core.lua")
    include("skilltrees/sh_hooks.lua")
    include("skilltrees/sv_data.lua")
    include("skilltrees/sv_skills.lua")
    include("skilltrees/sv_persistence.lua")
    include("skilltrees/sv_xp.lua")
    include("autorun/client/cl_init.lua")
end

if CLIENT then
    -- 3. The client now loads the files the server told it to download
    include("skilltrees/sh_core.lua")
    include("skilltrees/cl_menu.lua")
    include("skilltrees/cl_hud.lua")
    include("autorun/client/cl_vortex_util.lua")
    include("skilltrees/sh_hooks.lua")
    include("autorun/client/cl_init.lua")
end