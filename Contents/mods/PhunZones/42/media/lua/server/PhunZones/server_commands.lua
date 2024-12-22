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
    print("modifyZone in server")
    print("================")
    -- send any exemption/changes to the client
    PZ:saveChanges(data)

end

return Commands
