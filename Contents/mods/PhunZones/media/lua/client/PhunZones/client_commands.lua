if isServer() then
    return
end

local Core = PhunZones

local Commands = {}

Commands[Core.commands.playerSetup] = function(data)
    -- send any exemption/changes to the client
    -- print("PhunZones: Received player setup data")
    -- Coredebug(data)
    ModData.add(Core.const.modifiedModData, data.data or {})
    ModData.add(Core.const.modifiedDeletions, data.deletes or {})
    Core:updateZoneData(true, data)

    local players = Core.tools.onlinePlayers()
    for i = 0, players:size() - 1 do
        local p = players:get(i)
        Core.updateModData(p, true, true)
    end
end

Commands[Core.commands.zoneUpdated] = function(data)
    ModData.add(Core.const.modifiedModData, data.data or {})
    ModData.add(Core.const.modifiedDeletions, data.deletes or {})
    Core:updateZoneData(true, data)
    local players = Core.tools.onlinePlayers()
    for i = 0, players:size() - 1 do
        local p = players:get(i)
        Core.updateModData(p, true, true)
    end
end

Commands[Core.commands.playerTeleport] = function(data)
    Core.portPlayer(Core.tools.getPlayerByUsername(data.username), data.x, data.y, data.z)
end

Commands[Core.commands.teleportVehicle] = function(data)
    local vehicle = getVehicleById(data.id)
    local player = Core.tools.getPlayerByUsername(data.username)
    if player and vehicle then
        Core:portVehicle(player, vehicle, data.x, data.y, data.z)
    end
end

return Commands
