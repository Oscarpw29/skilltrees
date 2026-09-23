-- Console: vtx_buy_skill <id> learns one rank immediately
concommand.Add("vtx_buy_skill", function(ply, cmd, args)
    if not args[1] then return end
    SkillTrees:SendCommit({ [args[1]] = 1 })
end)

local function adminAction(action)
    net.Start("Vortex_AdminAction")
        net.WriteString(action)
    net.SendToServer()
end

hook.Add("PopulateToolMenu", "Vortex_AdminUtilities", function()
    spawnmenu.AddToolMenuOption("Utilities", "Vortex Skills", "Vortex_StationAdmin", "Station Management", "", "", function(panel)
        panel:ClearControls()
        panel:Help("Skill station placement (superadmin only)")

        panel:Button("Save Stations", "").DoClick = function()
            adminAction("save")
            surface.PlaySound("buttons/button14.wav")
        end

        panel:Button("Clear Stations", "").DoClick = function()
            Derma_Query("Clear all stations on this map?", "Confirm", "Yes", function() adminAction("clear") end, "No")
        end
    end)
end)
