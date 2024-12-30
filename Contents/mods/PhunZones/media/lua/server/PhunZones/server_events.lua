if isClient() then
    return
end
local Commands = require "PhunZones/server_commands"
local PZ = PhunZones

Events.OnClientCommand.Add(function(module, command, playerObj, arguments)
    if module == PZ.name and Commands[command] then
        Commands[command](playerObj, arguments)
    elseif module == "RVInterior" then
        if command == "updateVehiclePosition" then
            PZ:setTrackedVehicleData(arguments.vehicleId)
        elseif command == "clientStartEnterInterior" then
            -- args will have the vehicleId
            PZ:setTrackedVehicleData(arguments.vehicleId)
        end
    end
end)

Events.OnServerStarted.Add(function()
    PZ:getZones(true)
end)

Events[PZ.events.OnPhunZoneReady].Add(function(playerObj, zone)
    if not isClient() then
        local nextCheck = 0
        Events.OnTick.Add(function()
            if getTimestamp() >= nextCheck then
                nextCheck = getTimestamp() + (PZ.settings.updateInterval or 1)
                PZ:updatePlayers()
            end
        end)
    end
end)
