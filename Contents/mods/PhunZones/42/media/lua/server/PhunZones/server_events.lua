if isClient() then
    return
end
local Commands = require "PhunZones/server_commands"
local PZ = PhunZones

Events.OnClientCommand.Add(function(module, command, playerObj, arguments)
    if module == PZ.name and Commands[command] then
        Commands[command](playerObj, arguments)
    end
end)

Events.OnServerStarted.Add(function()
    PZ:getZones(true)
end)
