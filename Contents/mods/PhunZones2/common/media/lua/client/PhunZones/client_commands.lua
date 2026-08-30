if isServer() then
    return
end

local Core = PhunZones

local Commands = {}

Commands[Core.commands.playerSetup] = function(data)
    ModData.add(Core.const.modifiedModData, data.data or {})
    if type(data.runtime) == "table" then
        ModData.add(Core.const.runtimeModData, data.runtime)
    end
    Core.updateZoneData()

    local players = Core.tools.onlinePlayers()
    for i = 0, players:size() - 1 do
        local p = players:get(i)
        Core.updateModData(p, true, true)
    end
end

Commands[Core.commands.zoneUpdated] = function(data)
    -- data.data is only set by playerSetup; zoneUpdated sends data.changes.
    -- Calling ModData.add with an empty table can wipe the client's zone data,
    -- so only update ModData when the server actually provides a full dataset.
    -- OnReceiveGlobalModData (triggered by ModData.transmit on the server) handles
    -- the authoritative full-data sync for all clients.
    -- next() is not exposed to mod code in B42.20.4; isEmpty uses pairs instead.
    if data.data and not Core.tools.isEmpty(data.data) then
        ModData.add(Core.const.modifiedModData, data.data)
    end
    Core.updateZoneData()
    local players = Core.tools.onlinePlayers()
    for i = 0, players:size() - 1 do
        local p = players:get(i)
        Core.updateModData(p, true, true)
    end
end

Commands[Core.commands.updateEffectiveZone] = function(data)
    local player = Core.tools.getPlayerByUsername(data.player)
    if player then
        Core.setEffectiveZone(player, data.zone)
    end
end

Commands[Core.commands.playerTeleport] = function(data)
    Core.portPlayer(Core.tools.getPlayerByUsername(data.username), data.x, data.y, data.z)
end

Commands[Core.commands.teleportVehicle] = function(data)
    local vehicle = getVehicleById(data.id)
    local player = Core.tools.getPlayerByUsername(data.username)
    if player and vehicle then
        if not Core.teleportVehicleToCoords(player, vehicle, data.x, data.y, data.z) then
            Core.debugLn("teleportVehicle: could not relocate vehicle " .. tostring(data.id))
        end
    end
end

return Commands
