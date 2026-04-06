if SAM_LOADED then return end

local sam, command = sam, sam.command

command.set_category("Vortex Skills")

-- COMMAND: Give XP
command.new("givexp")
    :SetPermission("givexp", "superadmin")
    :AddArg("player")
    :AddArg("number", {hint = "amount", min = 1, round = true})
    :Help("Give XP to a player.")

    :OnExecute(function(ply, targets, amount)
        for i = 1, #targets do
            local target = targets[i]
            if target.SkillData then
                target.SkillData.xp = (target.SkillData.xp or 0) + amount
                
                -- Ensure SkillTrees global exists
                if SkillTrees and SkillTrees.SaveAndSync then
                    SkillTrees:SaveAndSync(target)
                end
            end
        end

        -- SAM color-coded message
        sam.player.send_message(nil, "{A} gave {V} XP to {T}.", {
            A = ply, T = targets, V = amount
        })
    end)
:End()

command.new("vtx_givepts", "superadmin")
    :SetPermission("vtx_givepts", "superadmin")
    :AddArg("player")
    :AddArg("number", {hint = 'amount', min=1, round=true})
    :Help("Give points to a player.")

    :OnExecute(function(ply, targets, amount)
    for i = 1, #targets do
        local target = targets[i]
        if target.SkillData then
            target.SkillData.points = (target.SkillData.points or 0) + amount
            if SkillTrees and SkillTrees.SaveAndSync then
                SkillTrees:SaveAndSync(target)
            end
        end
    end
    sam.player.send_message(nil, "{A} gave {V} points to {T}.",{
        A = ply, T = targets, V = amount
    })
end)
:End()

-- COMMAND: Give Levels
command.new("vtx_givelevels")
    :SetPermission("vtx_givelevels", "superadmin")
    :AddArg("player")
    :AddArg("number", {hint = "levels", min = 1, round = true})
    :Help("Give levels to a player, awarding skill points at the same rate as normal leveling (1 point per 3 levels).")

    :OnExecute(function(ply, targets, amount)
        for i = 1, #targets do
            local target = targets[i]
            if target.SkillData then
                local oldLevel = target.SkillData.level or 1
                local newLevel = oldLevel + amount

                -- Award points at the same rate as normal level-ups (every 3rd level)
                local pointsEarned = math.floor(newLevel / 3) - math.floor(oldLevel / 3)

                target.SkillData.level = newLevel
                target.SkillData.points = (target.SkillData.points or 0) + pointsEarned

                if SkillTrees and SkillTrees.SaveAndSync then
                    SkillTrees:SaveAndSync(target)
                end

                target:ChatPrint("[VORTEX] An admin gave you " .. amount .. " levels! You are now level " .. newLevel .. ".")
                if pointsEarned > 0 then
                    target:ChatPrint("[VORTEX] You earned " .. pointsEarned .. " skill point(s)!")
                end
            end
        end

        sam.player.send_message(nil, "{A} gave {V} levels to {T}.", {
            A = ply, T = targets, V = amount
        })
    end)
:End()

-- COMMAND: Reset Skills
command.new("resetskills")
    :SetPermission("resetskills", "superadmin")
    :AddArg("player")
    :Help("Completely reset a player's skill progress.")

    :OnExecute(function(ply, targets)
        for i = 1, #targets do
            local target = targets[i]
            target.SkillData = {
                xp = 0,
                level = 1,
                points = 0,
                skills = {}
            }

            if SkillTrees and SkillTrees.SaveAndSync then
                SkillTrees:SaveAndSync(target)
            end
        end

        sam.player.send_message(nil, "{A} reset the skill profile of {T}.", {
            A = ply, T = targets
        })
    end)
:End()

command.new("vortex_savestations")
    :SetPermission("vortex_savestations", "superadmin")
    :Help("Save all stations on the map")
    :OnExecute(function(ply)
        hook.Run("Vortex_SaveStations")
        sam.player.send_message(nil, "{A} saved all skill stations",{
            A = ply
        })
    end)
:End()

command.new("vortex_clearstations")
    :SetPermission("vortex_clearstations", "superadmin")
    :Help("Clears all stations on the current map.")
    :OnExecute(function(ply)
        hook.Run("Vortex_SaveStations")
        
        sam.player.send_message(nil, "{A} cleared all skill stations",{
            A = ply
        })
    end)
:End()