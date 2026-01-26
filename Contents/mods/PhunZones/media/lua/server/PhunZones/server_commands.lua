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
    sendServerCommand(player, PZ.name, PZ.commands.playerSetup, {
        data = ModData.get(PZ.const.modifiedModData) or {},
        deletes = ModData.get(PZ.const.modifiedDeletions) or {}
    })
end

Commands[PZ.commands.modifyZone] = function(player, data)
    PZ:saveChanges(data)
    ModData.transmit(PZ.const.modifiedModData)
    ModData.transmit(PZ.const.modifiedDeletions)
    PZ:updatePlayers()
end

Commands[PZ.commands.deleteZone] = function(player, data)
    PZ:addDeletion(data.key, data.subzone)
    ModData.transmit(PZ.const.modifiedModData)
    ModData.transmit(PZ.const.modifiedDeletions)
    PZ:updatePlayers()
end

Commands[PZ.commands.cleanPlayersZeds] = function(player, args)

    local ids = {}
    local passed = type(args.id) == "table" and args.id or {args.id}

    for _, id in ipairs(passed) do
        ids[id] = true
    end
    local removed = {}
    local zombies = player:getCell():getZombieList()
    print("There are " .. tostring(zombies:size()) .. " zombies in " .. player:getUsername() .. " cell " ..
              tostring(player:getX()) .. ", " .. tostring(player:getY()))
    for i = 0, zombies:size() - 1 do
        local zombie = zombies:get(i)
        local id = PZ.getZId(zombie)
        if instanceof(zombie, "IsoZombie") and ids[id] then
            print("removing zombie " .. tostring(id))
            table.insert(removed, tostring(id))
            zombie:removeFromWorld()
            zombie:removeFromSquare()
            break
        end
    end
    if #removed > 0 then
        triggerEvent(PZ.events.OnZombieRemoved, removed)
    end

end

return Commands
