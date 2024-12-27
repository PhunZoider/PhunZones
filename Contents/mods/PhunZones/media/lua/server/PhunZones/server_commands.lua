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
    print("================")
    print("playerSetup in server")
    print("================")
    if isServer() then
        PZ:updateModData(p)
        sendServerCommand(player, PZ.name, PZ.commands.playerSetup, {})
    else
        PZ:getZones(true)
    end

end

Commands[PZ.commands.transmitChanges] = function()
    print("================")
    print("transmitChanges in server")
    print("================")
    -- send any exemption/changes to the client
    ModData.transmit(PZ.const.modifiedModData)
end

Commands[PZ.commands.modifyZone] = function(player, data)
    print("================")
    print("modifyZoner in server")
    print("================")
    -- send any exemption/changes to the client
    PZ:printTable(data)
    print("================")
    PZ:saveChanges(data)
    print("================")
    print("modifyZonexxx in server")
    print("================")
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

return Commands
