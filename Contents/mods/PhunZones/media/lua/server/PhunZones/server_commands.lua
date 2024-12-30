if isClient() then
    return
end
local Commands = {}
local PZ = PhunZones

Commands[PZ.commands.playerSetup] = function(player)
    -- send any exemption/changes to the client
    local p = player
    local z = PZ
    local data = ModData.get(PZ.const.modifiedModData) or {}

    PZ:getZones(true)

end

Commands[PZ.commands.transmitChanges] = function()
    -- send any exemption/changes to the client
    ModData.transmit(PZ.const.modifiedModData)
end

Commands[PZ.commands.modifyZone] = function(player, data)
    -- send any exemption/changes to the client
    PZ:printTable(data)
    PZ:saveChanges(data)
end

Commands[PZ.commands.killZombie] = function(player, args)

    local ids = {}
    local passed = type(args.id) == "table" and args.id or {args.id}

    for _, id in ipairs(passed) do
        ids[id] = true
    end

    local zombies = player:getCell():getZombieList()

    for i = 0, zombies:size() - 1 do
        local zombie = zombies:get(i)
        if instanceof(zombie, "IsoZombie") and ids[zombie:getOnlineID()] then
            zombie:removeFromWorld()
            zombie:removeFromSquare()
            return
        end
    end

end

Commands[PZ.commands.trackVehicle] = function(player, args)

    args.zone = PZ:getLocation(args.x or 0, args.y or 0)
    -- PZ:debug("trackVehicle", args, "-----")
    -- PZ.trackedVehicles[player:getUsername()] = args

    -- local modData = player:getModData()
    -- if not modData.PhunZoneVehicle then
    --     modData.PhunZoneVehicle = {}
    -- end
    -- modData.PhunZoneVehicle.lastVehicleId = args.id
    -- modData.PhunZoneVehicle.lastVehicleX = args.x
    -- modData.PhunZoneVehicle.lastVehicleY = args.y
end

return Commands
