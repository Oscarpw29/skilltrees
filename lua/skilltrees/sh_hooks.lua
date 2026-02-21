hook.Add("ArcCW_Mod_Mult_RPM", "Vortex_Test_Logic", function(wep, mult)
    local ply = wep:GetOwner()
    if not IsValid(ply) or not ply.SkillData then return mult end

    local buffs = SkillTrees:CalculateBuffs(ply)
    
    if buffs and buffs.firerate and buffs.firerate > 0 then
        -- This will print to the Server Console AND your F10 Console
        local side = SERVER and "SERVER" or "CLIENT"
        print("[Vortex] " .. side .. " is applying RPM: " .. (mult + buffs.firerate))
        
        return mult + buffs.firerate
    end

    return mult
end)