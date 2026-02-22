if isServer() then
    return
end

local PZ = PhunZones
local PL = PhunLib
local Commands = {}

Commands[PZ.commands.playerSetup] = function(data)
    -- send any exemption/changes to the client
    print("PhunZones: Received player setup data")
    PL.debug(data)
    ModData.add(PZ.const.modifiedModData, data.data or {})
    ModData.add(PZ.const.modifiedDeletions, data.deletes or {})
    PZ:updateZoneData(true, data)

    local players = PL.onlinePlayers()
    for i = 0, players:size() - 1 do
        local p = players:get(i)
        PZ.updateModData(p, true, true)
    end
end

Commands[PZ.commands.playerTeleport] = function(data)
    PZ.portPlayer(PL.getPlayerByUsername(data.username), data.x, data.y, data.z)
end

Commands[PZ.commands.teleportVehicle] = function(data)
    local vehicle = getVehicleById(data.id)
    local player = PL.getPlayerByUsername(data.username)
    if player and vehicle then
        PZ:portVehicle(player, vehicle, data.x, data.y, data.z)
    end
end

return Commands
