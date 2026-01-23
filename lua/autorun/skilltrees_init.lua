SkillTrees = SkillTrees or {}

if SERVER then
    AddCSLuaFile("skilltrees/cl_menu.lua")
    AddCSLuaFile("skilltrees/sh_core.lua")
    AddCSLuaFile("skilltrees/cl_commands.lua")

    include("skilltrees/sv_data.lua")
    include("skilltrees/sv_skills.lua")
    include("skilltrees/sv_xp.lua")
else
    include("skilltrees/sh_core.lua")
    include("skilltrees/cl_commands.lua")
    include("skilltrees/cl_menu.lua")
end

include("skilltrees/sh_core.lua")