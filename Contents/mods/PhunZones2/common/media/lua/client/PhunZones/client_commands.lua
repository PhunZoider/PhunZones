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

-- The server owns the non-pvp zone list; we only mirror what it sends. That
-- matters because a client add or remove broadcasts to everyone, so a client
-- working from stale zone data could otherwise strip protection off a zone for
-- the whole server.
Commands[Core.commands.syncNoPvp] = function(data)
    Core.applyNoPvpZones(data and data.rects or {})
end

Commands[Core.commands.updateEffectiveZone] = function(data)
    local player = Core.tools.getPlayerByUsername(data.player)
    if player then
        Core.setEffectiveZone(player, data.zone)
        -- Kept so OnPhysicalZoneChanged can reapply it: the push can land
        -- before the player reaches the void, and forced updates reset the
        -- display zone to the physical one
        player:getModData().PhunZones.rvZone = data.zone
    end
end

-- Sent by the server when a player standing in a noplayers zone has to be
-- moved. The move is made here rather than there because only this side has
-- the cell to wait on while the destination chunk streams in.
Commands[Core.commands.playerTeleport] = function(data)
    if not data then
        return
    end
    -- onlinePlayers filters to this client's own players, so the lookup
    -- resolves to us (or, split-screen, to whichever of us was named) and
    -- comes back nil for anyone else's. Worth a line either way: the server
    -- addressed this command to somebody.
    local player = Core.tools.getPlayerByUsername(data.username)
    if not player then
        Core.debugLn("playerTeleport: no local player named " .. tostring(data.username))
        return
    end
    Core.portPlayer(player, data.x, data.y, data.z)
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
