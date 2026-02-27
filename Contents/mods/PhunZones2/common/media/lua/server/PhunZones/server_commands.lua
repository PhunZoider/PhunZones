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
    if not player:getRole():hasCapability(Capability.CanSetupNonPVPZone) then
        return
    end
    Core.debug("[modifyZone]", data)
    Core.saveChanges(data.changes)
    ModData.transmit(Core.const.modifiedModData)

end

Commands[Core.commands.deleteZone] = function(player, data)
    if not player:getRole():hasCapability(Capability.CanSetupNonPVPZone) then
        return
    end
    Core.addDeletion(data.key)
    ModData.transmit(Core.const.modifiedModData)
end

Commands[Core.commands.evictZeds] = function(player, args)
    print("evicting zeds for " .. player:getUsername() .. " in zone " .. tostring(args and args.zone))
    Core.evictZeds(player, args and args.zone)
end

Commands[Core.commands.removeZeds] = function(player, args)
    -- Re-derive from server state: only remove zeds that are
    -- (a) in the player's current cell, AND
    -- (b) in a zone that actually has zeds==3 action
    local zone = Core.getLocation(player:getX(), player:getY()) or {}
    if tonumber(zone.zeds) ~= 3 then
        return -- player isn't even in a remove-zeds zone; ignore
    end

    local removed = {}
    local zombies = player:getCell():getZombieList()
    for i = 0, zombies:size() - 1 do
        local zombie = zombies:get(i)
        if instanceof(zombie, "IsoZombie") then
            local zZone = Core.getLocation(zombie:getX(), zombie:getY()) or {}
            local id = Core.getZId(zombie)
            if id then
                table.insert(removed, tostring(id))
                zombie:removeFromWorld()
                zombie:removeFromSquare()
            end

        end
    end
    if #removed > 0 then
        triggerEvent(Core.events.OnZombieRemoved, removed)
    end
end

return Commands
