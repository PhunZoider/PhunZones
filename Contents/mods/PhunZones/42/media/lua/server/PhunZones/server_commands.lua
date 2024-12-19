if not isClient() and not isServer() then
    return
end
local Commands = {}
local PZ = PhunZones

Commands[PZ.commands.playerSetup] = function(data)
    -- send any exemption/changes to the client
end

return Commands
