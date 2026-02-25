if isClient() then
    return
end
local Commands = require "PhunZones/server_commands"
local Core = PhunZones
local getTimestamp = getTimestamp

Events.OnClientCommand.Add(function(module, command, playerObj, arguments)
    if module == Core.name and Commands[command] then
        Commands[command](playerObj, arguments)
    end
end)

Events.OnServerStarted.Add(function()
    Core:ini()
end)

