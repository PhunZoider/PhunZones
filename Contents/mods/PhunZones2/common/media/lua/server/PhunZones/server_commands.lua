if isClient() then
    return
end
local Commands = {}
local Core = PhunZones

Commands[Core.commands.playerSetup] = function(player)
    -- send any exemption/changes to the client
    local p = player
    local modData = p:getModData()

    if not modData.PhunZones or not modData.PhunZones.at then
        modData.PhunZones = {
            zone = nil,
            at = {}
        }
    end
    Core.updateModData(player, true, true)
    sendServerCommand(player, Core.name, Core.commands.playerSetup, {
        data = ModData.get(Core.const.modifiedModData) or {}
    })
end

Commands[Core.commands.modifyZone] = function(player, data)
    if not data then
        return
    end
    Core.debug("[modifyZone]", data)
    Core.saveChanges(data.changes)
    ModData.transmit(Core.const.modifiedModData)

end

Commands[Core.commands.deleteZone] = function(player, data)
    Core.addDeletion(data.key)
    ModData.transmit(Core.const.modifiedModData)
end

Commands[Core.commands.cleanPlayersZeds] = function(player, args)
    Core.evictZeds(player, args and args.zone)
    -- local ids = {}
    -- local passed = type(args.id) == "table" and args.id or {args.id}

    -- for _, id in ipairs(passed) do
    --     ids[id] = true
    -- end
    -- local removed = {}
    -- local zombies = player:getCell():getZombieList()
    -- Core.debugLn("There are " .. tostring(zombies:size()) .. " zombies in " .. player:getUsername() .. " cell " ..
    --                  tostring(player:getX()) .. ", " .. tostring(player:getY()))
    -- for i = 0, zombies:size() - 1 do
    --     local zombie = zombies:get(i)
    --     local id = Core.getZId(zombie)
    --     if instanceof(zombie, "IsoZombie") and ids[id] then
    --         Core.debugLn("removing zombie " .. tostring(id))
    --         table.insert(removed, tostring(id))
    --         zombie:removeFromWorld()
    --         zombie:removeFromSquare()
    --         break
    --     end
    -- end
    -- if #removed > 0 then
    --     triggerEvent(Core.events.OnZombieRemoved, removed)
    -- end

end

Commands[Core.commands.evictZeds] = function(player, args)
    Core.evictZeds(player, args and args.zone)
end

return Commands
