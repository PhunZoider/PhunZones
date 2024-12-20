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
        sendServerCommand(player, PZ.commands.playerSetup, {})
    else
        PZ:getZones()
    end

end

Commands[PZ.commands.transmitChanges] = function()
    print("================")
    print("transmitChanges in server")
    print("================")
    -- send any exemption/changes to the client
    ModData.transmit(PZ.name .. "_Changes")
end

return Commands
