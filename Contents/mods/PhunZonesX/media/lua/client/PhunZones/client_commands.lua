if not isClient() then
    return
end
local PZ = PhunZones

local Commands = {}

Commands[PZ.commands.playerSetup] = function(data)
    -- send any exemption/changes to the client
end

return Commands
