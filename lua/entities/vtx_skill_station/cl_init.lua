include("entities/vtx_skill_station/shared.lua")

surface.CreateFont("Vtx_Station_3D", {
    font = "Roboto",
    size = 60,
    weight = 800,
    antialias = true
})

function ENT:Draw()
    self:DrawModel()
    local pos = self:GetPos() + Vector(0,0,50)

    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)

    local offset = math.sin(CurTime()*2) * 2
    pos = pos + Vector(0,0,offset)

    cam.Start3D2D(pos, ang, 0.1)
        local text = "Skill Station"
        surface.SetFont("Vtx_Station_3D")
        local tW, tH = surface.GetTextSize(text)

        draw.RoundedBox(12, -tW/2 - 20, -tH/2, tW+40, tH, Color(0,0,0,200))
        draw.SimpleText(text, "Vtx_Station_3D",0,0,Color(255,255,255), TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    cam.End3D2D()
end