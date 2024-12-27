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
    PhunZones:getZones(true)
end)

Events[PZ.events.OnPhunZoneReady].Add(function()

    local nextTick = 0
    local interval = 3
    Events.OnTick.Add(function()
        if getTimestamp() >= nextTick then
            nextTick = getTimestamp() + interval
            PhunZones:checkPlayersInZedlessZone()
        end

    end)

end)

Events.EveryTenMinutes.Add(function()
    -- clear out any stale zedless players
    local on = {}
    for i = 0, getOnlinePlayers():size() - 1 do
        local p = getOnlinePlayers():get(i)
        on[p:getUsername()] = true
    end
    for k, v in pairs(PZ.playersWithinZedlessZone) do
        if not on[k] then
            PZ.playersWithinZedlessZone[k] = nil
        end
    end
end)

Events[PZ.events.OnPhunZonesPlayerLocationChanged].Add(function(playerObj, zone)

    if zone.zeds == false then
        PZ.playersWithinZedlessZone[playerObj:getUsername()] = playerObj
        PZ:clearPlayerZeds(playerObj)
    else
        PZ.playersWithinZedlessZone[playerObj:getUsername()] = nil
    end
end)
