net.Receive("Vortex_RefreshWeapon", function()
    local ply = LocalPlayer()
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and wep.ArcCW then
        wep:PostModifyStats()
    end
end)