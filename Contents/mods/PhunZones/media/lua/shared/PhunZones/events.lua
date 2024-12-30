require "PhunZones/core"
local PZ = PhunZones
local getTimestamp = getTimestamp

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
