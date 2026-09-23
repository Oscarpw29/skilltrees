-- Server data lands here. Nothing in this file touches the menu directly: it fires
-- SkillTrees_DataUpdated and any open panels update themselves in place.

net.Receive("vtx_skills_sync", function()
    local data = net.ReadTable()
    local lp = LocalPlayer()
    if not IsValid(lp) then return end

    lp.SkillData = data
    SkillTrees:InvalidateBuffs(lp)
    hook.Run("SkillTrees_DataUpdated", data)
end)

net.Receive("vtx_skills_menu", function()
    SkillTrees:OpenMenu()
end)

net.Receive("Vortex_RefreshWeapon", function()
    local wep = LocalPlayer():GetActiveWeapon()
    if IsValid(wep) and wep.ArcCW then
        wep:PostModifyStats()
    end
end)

-- Send staged levels ({ id = levels }) to be saved
function SkillTrees:SendCommit(adds)
    local list = {}
    for id, n in pairs(adds) do
        if n > 0 then table.insert(list, { id, n }) end
    end
    if #list == 0 then return false end

    net.Start("vtx_skills_commit")
        net.WriteUInt(#list, 8)
        for _, e in ipairs(list) do
            net.WriteString(e[1])
            net.WriteUInt(e[2], 8)
        end
    net.SendToServer()
    return true
end

function SkillTrees:SendReset()
    net.Start("vtx_skills_reset")
    net.SendToServer()
end
