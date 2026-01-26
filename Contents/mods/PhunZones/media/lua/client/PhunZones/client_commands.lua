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
        PZ:updateModData(p, true, true)
    end
end

Commands[PZ.commands.playerTeleport] = function(data)
    PZ:portPlayer(PL.getPlayerByUsername(data.username), data.x, data.y, data.z)
end

Commands[PZ.commands.teleportVehicle] = function(data)
    local vehicle = getVehicleById(data.id)
    local player = PL.getPlayerByUsername(data.username)
    if player and vehicle then
        PZ:portVehicle(player, vehicle, data.x, data.y, data.z)
    end
end

Commands[PZ.commands.updatePlayerZone] = function(args)
    local p = nil
    local players = PL.onlinePlayers()
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player:getOnlineID() == args.pid then
            p = player
            break
        end
    end

    if p then
        args.pid = nil
        local name = p:getUsername()
        if not PZ.players then
            PZ.players = ModData.getOrCreate(PZ.const.playerData)
        end
        local old = PZ:getPlayerData(p)
        local existing = old
        PZ.players[name] = args
        p:getModData().PhunZones = args
        triggerEvent(PZ.events.OnPhunZonesPlayerLocationChanged, p, args, existing)
    end
end

return Commands
