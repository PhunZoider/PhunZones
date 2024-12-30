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
    -- PZ:debug("player location changed", zone)
end)

Events[PZ.events.OnPhunZoneReady].Add(function(playerObj, zone)
    -- local nextCheck = 0
    -- local every = 1
    -- local getTimestamp = getTimestamp

    -- Events.OnTick.Add(function()
    --     if getTimestamp() >= nextCheck then
    --         nextCheck = getTimestamp() + every
    --         PZ:updatePlayers()
    --     end
    -- end)

    -- local nextCheck = 0
    -- local every = 1
    -- local getTimestamp = getTimestamp
    -- local lastMoved = 0
    -- local lastChecked = 0
    -- Events.OnPlayerMove.Add(function(player)
    --     lastMoved = getTimestamp()
    -- end)

    -- Events.OnTick.Add(function()
    --     if lastChecked < lastMoved then
    --         lastChecked = getTimestamp()
    --         --nextCheck = getTimestamp() + every
    --         PZ:updatePlayers()
    --     end
    -- end)
end)

Events.OnCreatePlayer.Add(function(id)
    local playerObj = getSpecificPlayer(id)
    if playerObj then
        local data = playerObj:getModData()
        if not data.PhunZones then
            data.PhunZones = {}
        end
        if not data.PhunZonesVehicleInfo then
            data.PhunZonesVehicleInfo = {}
        end
    end
end)

Events.OnReceiveGlobalModData.Add(function(tableName, tableData)
    if tableName == PZ.const.modifiedModData then
        ModData.add(PZ.const.modifiedModData, tableData)
        PZ:getZones(true, tableData)
    end
end)

Events.OnEnterVehicle.Add(function(player)
    if player then
        local vehicle = player:getVehicle();
        if vehicle then
            local rvInfo = RVInterior and RVInterior.getVehicleModData(vehicle)
            local hasInteriorParams = RVInterior and RVInterior.vehicleHasInteriorParameters(vehicle)
            sendClientCommand(PZ.name, PZ.commands.trackVehicle, {
                sqlId = vehicle:getSqlId(),
                id = vehicle:getId(),
                x = player:getX(),
                y = player:getY()
            })
        end
        local data = player:getModData().PhunZonesVehicleInfo
        local id = vehicle:getId()
        data.lastVehicleId = id
        data.lastVehicleEntered = {
            x = player:getX(),
            y = player:getY()
        }
    end
end)

local lastAttempt = {}

Events.OnServerCommand.Add(function(module, command, arguments)

    if module == PZ.name then
        if Commands[command] then
            Commands[command](arguments)
        end
    end
end)

local function setup()
    Events.OnTick.Remove(setup)
    PZ:ini()
    PZ:showWidgets()
    sendClientCommand(PZ.name, PZ.commands.playerSetup, {})
end

Events.OnTick.Add(setup)

