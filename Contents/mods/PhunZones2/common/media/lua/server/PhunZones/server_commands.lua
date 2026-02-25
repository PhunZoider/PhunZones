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

Commands[Core.commands.evictZeds] = function(player, args)
    print("evicting zeds for " .. player:getUsername() .. " in zone " .. tostring(args and args.zone))
    Core.evictZeds(player, args and args.zone)
end

return Commands
