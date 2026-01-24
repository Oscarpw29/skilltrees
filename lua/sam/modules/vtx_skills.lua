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