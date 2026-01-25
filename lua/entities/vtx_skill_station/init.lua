AddCSLuaFile("entities/vtx_skill_station/cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/epsilon/cwa_furniture/coruscantlowclass/eps_coruscantlowclass_smallworkstation.mdl")
    self:SetSolid(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:DrawShadow(true)

    self:PhysicsInit(SOLID_VPHYSICS)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
end

function ENT:AcceptInput(name, activator, caller)
    if name == "Use" and IsValid(activator) and activator:IsPlayer() then
        if (activator.NextSkillUse or 0) > CurTime() then return end
        activator.NextSkillUse = CurTime() + 0.5

        net.Start("vtx_skills_menu")
        net.Send(activator)
    end
end

