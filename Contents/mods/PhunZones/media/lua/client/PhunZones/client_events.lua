if isServer() then
    return
end
local PZ = PhunZones
local Commands = require "PhunZones/client_commands"

Events.OnPreFillWorldObjectContextMenu.Add(function(playerObj, context, worldobjects)
    PZ:showContext(playerObj, context, worldobjects)
end);

Events[PZ.events.OnPhunZonesPlayerLocationChanged].Add(function(playerObj, zone)
    if not zone.noAnnounce then
        if not zone.isVoid then
            playerObj:setHaloNote((zone.title or "") .. (zone.subtitle and " - " .. zone.subtitle or ""))
        end
    end
end)

Events[PZ.events.OnPhunZonesPlayerLocationChanged].Add(function(playerObj, zone)
    PZ:updatePlayerUI(playerObj, zone)
end)

Events[PZ.events.OnPhunZoneReady].Add(function(playerObj, zone)
    local nextCheck = 0
    local every = 1
    local getTimestamp = getTimestamp
    Events.OnTick.Add(function()
        if getTimestamp() >= nextCheck then
            nextCheck = getTimestamp() + every
            PZ:updatePlayers()
        end
    end)
end)

Events.OnReceiveGlobalModData.Add(function(tableName, tableData)
    if tableName == PZ.const.modifiedModData then
        ModData.add(PZ.const.modifiedModData, tableData)
        PZ:getZones(true, tableData)
    end
end)

Events.OnServerCommand.Add(function(module, command, arguments)
    if module == PZ.name and Commands[command] then
        Commands[command](arguments)
    end
end)

local function setup()
    Events.OnTick.Remove(setup)
    PZ:ini()
    PZ:showWidgets()
    sendClientCommand(PZ.name, PZ.commands.playerSetup, {})
end

Events.OnTick.Add(setup)

