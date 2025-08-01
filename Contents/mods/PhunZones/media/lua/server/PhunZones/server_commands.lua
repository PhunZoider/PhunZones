if isClient() then
    return
end
local Commands = {}
local PZ = PhunZones

Commands[PZ.commands.playerSetup] = function(player)
    -- send any exemption/changes to the client
    local p = player
    local modData = p:getModData()

    if not modData.PhunZones then
        modData.PhunZones = {}
    end
    modData.PhunZones.modified = false
    PZ:updateModData(player, true, true)
    sendServerCommand(player, PZ.name, PZ.commands.playerSetup, ModData.get(PZ.const.modifiedModData) or {})
end

Commands[PZ.commands.transmitChanges] = function()
    -- send any exemption/changes to the client
    ModData.transmit(PZ.const.modifiedModData)
end

Commands[PZ.commands.modifyZone] = function(player, data)
    PZ:saveChanges(data)
    ModData.transmit(PZ.const.modifiedModData)
end

Commands[PZ.commands.cleanPlayersZeds] = function(player, args)

    local ids = {}
    local passed = type(args.id) == "table" and args.id or {args.id}

    for _, id in ipairs(passed) do
        ids[id] = true
    end

    local zombies = player:getCell():getZombieList()
    print("There are " .. tostring(zombies:size()) .. " zombies in " .. player:getUsername() .. " cell " ..
              tostring(player:getX()) .. ", " .. tostring(player:getY()))
    for i = 0, zombies:size() - 1 do
        local zombie = zombies:get(i)
        if instanceof(zombie, "IsoZombie") and ids[zombie:getOnlineID()] then
            print("Cleaning zombie " .. tostring(zombie:getOnlineID()))
            zombie:removeFromWorld()
            zombie:removeFromSquare()
            return
        end
    end

end

return Commands
