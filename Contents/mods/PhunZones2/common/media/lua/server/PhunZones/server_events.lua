if isClient() then
    return
end
local Commands = require "PhunZones/server_commands"
local Core = PhunZones
local getTimestamp = getTimestamp

Events.OnClientCommand.Add(function(module, command, playerObj, arguments)
    if module == Core.name and Commands[command] then
        Commands[command](playerObj, arguments)
    elseif module == "RVInterior" and Core.settings.VehicleTracking then
        if command == "updateVehiclePosition" then
            Core:setTrackedVehicleData(arguments.vehicleId)
        elseif command == "clientStartEnterInterior" then
            -- args will have the vehicleId
            Core:setTrackedVehicleData(arguments.vehicleId)
        end
    end
end)

Events[Core.events.OnPhunZoneReady].Add(function(playerObj, zone)
    if not Core.settings.ProcessOnClient and not isClient() then
        local nextCheck = 0

        Events.OnTick.Add(function()
            if getTimestamp() >= nextCheck then
                nextCheck = getTimestamp() + (Core.settings.updateInterval or 1)
                Core:updatePlayers()
            end
        end)
    end
end)

Events.OnServerStarted.Add(function()
    Core:ini()
end)

