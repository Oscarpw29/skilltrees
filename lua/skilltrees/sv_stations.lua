-- Skill stations placed on a map are saved per map to data/vortex_skills/<map>.txt

local FOLDER = "vortex_skills"
local CLASS  = "vtx_skill_station"

local function mapFile()
    return FOLDER .. "/" .. game.GetMap() .. ".txt"
end

local function removeAll()
    for _, ent in ipairs(ents.FindByClass(CLASS)) do ent:Remove() end
end

function SkillTrees:SaveStations()
    local stations = {}
    for _, ent in ipairs(ents.FindByClass(CLASS)) do
        table.insert(stations, { pos = ent:GetPos(), ang = ent:GetAngles() })
    end
    if #stations == 0 then return 0 end

    file.CreateDir(FOLDER)
    file.Write(mapFile(), util.TableToJSON(stations, true))
    return #stations
end

function SkillTrees:LoadStations()
    removeAll()

    local raw = file.Read(mapFile(), "DATA")
    local stations = raw and util.JSONToTable(raw)
    if not stations then return end

    for _, info in ipairs(stations) do
        local ent = ents.Create(CLASS)
        ent:SetPos(info.pos)
        ent:SetAngles(info.ang)
        ent:Spawn()

        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then phys:EnableMotion(false) end
    end
    print("[Vortex] Spawned " .. #stations .. " skill station(s).")
end

function SkillTrees:ClearStations()
    if file.Exists(mapFile(), "DATA") then file.Delete(mapFile()) end
    removeAll()
end

hook.Add("InitPostEntity", "Vortex_LoadStations", function()
    SkillTrees:LoadStations()
end)

hook.Add("PostCleanupMap", "Vortex_RestoreStations", function()
    timer.Simple(0.5, function() SkillTrees:LoadStations() end)
end)

-- Kept as hooks so other addons/commands can trigger them
hook.Add("Vortex_SaveStations", "ExecuteSave", function() SkillTrees:SaveStations() end)
hook.Add("Vortex_ClearStations", "ExecuteClear", function() SkillTrees:ClearStations() end)

net.Receive("Vortex_AdminAction", function(len, ply)
    if not ply:IsSuperAdmin() then return end

    local action = net.ReadString()
    if action == "save" then
        ply:ChatPrint("[Vortex] Saved " .. SkillTrees:SaveStations() .. " station(s).")
    elseif action == "clear" then
        SkillTrees:ClearStations()
        ply:ChatPrint("[Vortex] Stations cleared from map.")
    end
end)
