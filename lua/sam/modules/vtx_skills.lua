if SAM_LOADED then return end

local sam, command = sam, sam.command

command.set_category("Vortex Skills")

command.new("givexp")
    :SetPermission("givexp", "superadmin")
    :AddArg("player")
    :AddArg("number", { hint = "amount", min = 1, round = true })
    :Help("Give XP to a player. Levels up as normal; ignores XP multipliers.")
    :OnExecute(function(ply, targets, amount)
        for _, target in ipairs(targets) do
            SkillTrees:AddXP(target, amount, true)
        end
        sam.player.send_message(nil, "{A} gave {V} XP to {T}.", { A = ply, T = targets, V = amount })
    end)
:End()

command.new("vtx_givepts")
    :SetPermission("vtx_givepts", "superadmin")
    :AddArg("player")
    :AddArg("number", { hint = "amount", min = 1, round = true })
    :Help("Give skill points to a player.")
    :OnExecute(function(ply, targets, amount)
        for _, target in ipairs(targets) do
            if target.SkillData and target.SkillDataLoaded then
                target.SkillData.points = target.SkillData.points + amount
                SkillTrees:SaveAndSync(target)
            end
        end
        sam.player.send_message(nil, "{A} gave {V} points to {T}.", { A = ply, T = targets, V = amount })
    end)
:End()

command.new("vtx_givelevels")
    :SetPermission("vtx_givelevels", "superadmin")
    :AddArg("player")
    :AddArg("number", { hint = "levels", min = 1, round = true })
    :AddArg("number", { hint = "points (0 = auto)", min = 0, round = true })
    :Help("Give levels to a player. Points = 0 awards skill points at the normal rate.")
    :OnExecute(function(ply, targets, amount, bonusPoints)
        for _, target in ipairs(targets) do
            local gained, points = SkillTrees:AddLevels(target, amount, bonusPoints > 0 and bonusPoints or nil)
            if gained > 0 then
                target:ChatPrint("[VORTEX] An admin gave you " .. gained .. " level(s)! You are now level " .. target.SkillData.level .. ".")
                if points > 0 then
                    target:ChatPrint("[VORTEX] You earned " .. points .. " skill point(s)!")
                end
            end
        end
        sam.player.send_message(nil, "{A} gave {V} levels to {T}.", { A = ply, T = targets, V = amount })
    end)
:End()

command.new("resetskills")
    :SetPermission("resetskills", "superadmin")
    :AddArg("player")
    :Help("Completely reset a player's skill progress (level, XP, points and skills).")
    :OnExecute(function(ply, targets)
        for _, target in ipairs(targets) do
            if target.SkillDataLoaded then
                target.SkillData = { xp = 0, level = 1, points = 0, skills = {}, version = target.SkillData.version }
                SkillTrees:SaveAndSync(target)
                SkillTrees:ApplyBuffs(target)
            end
        end
        sam.player.send_message(nil, "{A} reset the skill profile of {T}.", { A = ply, T = targets })
    end)
:End()

command.new("vortex_savestations")
    :SetPermission("vortex_savestations", "superadmin")
    :Help("Save all skill stations on the map.")
    :OnExecute(function(ply)
        SkillTrees:SaveStations()
        sam.player.send_message(nil, "{A} saved all skill stations.", { A = ply })
    end)
:End()

command.new("vortex_clearstations")
    :SetPermission("vortex_clearstations", "superadmin")
    :Help("Clear all skill stations on the current map.")
    :OnExecute(function(ply)
        SkillTrees:ClearStations()
        sam.player.send_message(nil, "{A} cleared all skill stations.", { A = ply })
    end)
:End()
