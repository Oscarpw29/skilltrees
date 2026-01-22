concommand.Add("vtx_buy_skill", function(ply, cmd, args)
    local skillToBuy = args[1]
    if not skillToBuy then return end
    
    net.Start("vtx_skills_purchase")
        net.WriteString(skillToBuy)
    net.SendToServer()
end)