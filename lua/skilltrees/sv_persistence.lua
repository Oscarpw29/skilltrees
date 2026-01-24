local folder = "vortex_skills"

if not file.Exists(folder, "DATA") then
    file.CreateDir(folder)
end

function SkillTrees:SaveStations()
    local stations = {}
    
    for _, ent in pairs(ents.FindByClass("vtx_skill_station")) do
        table.insert(stations, {
            pos = ent:GetPos(),
            ang = ent:GetAngles()
        })
    end

    local json = util.TableToJSON(stations)
    file.Write(folder .. "/" .. game.GetMap() .. ".txt", json)
    paint("[Vortex] Saved" .. #stations " stations for map: " .. game.GetMap())
end

function SkillTrees:LoadStations()
    local path = folder .. "/" .. game.GetMap() .. ".txt"
    if not file.Exists(path, "DATA") then return end

    local data = file.Read(path, "DATA")
    local stations = util.JSONToTable(data)

    for _, info in ipairs(stations) do
        local ent = ents.Create("vtx_skill_station")
        ent:SetPos(info.pos)
        ent:SetAngles(info.ang)
        ent:Spawn()

        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then
            phys:EnableMotion(false)
        end
    end
    print("[Vortex] Spawned " .. #stations .. " persistent stations.")
end

hook.Add("InitPostEntity", "Vortex_loadStations", function ()
    SkillTrees:LoadStations()
end)

hook.Add("Vortex_Skills_SaveStations", "ExecuteSave", function()
    SkillTrees:SaveStations()
end)

hook.Add("Vortex_ClearStations", "ExecuteClear", function()
    local path = "vortex_skills/" .. game.GetMap() .. ".txt"
    if file.Exists(path, "DATA") then file.Delete(path) end

    for _, ent in ipairs(ents.FindByClass("vtx_skill_station")) do
        ent:Remove()
    end
    print("[Vorted] Stations cleared via hook.")
end)