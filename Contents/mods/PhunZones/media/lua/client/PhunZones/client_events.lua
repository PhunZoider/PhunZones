if isServer() then
    return
end
local PZ = PhunZones
local Commands = require "PhunZones/client_commands"

Events.OnPreFillWorldObjectContextMenu.Add(function(playerObj, context, worldobjects)
    PZ:showContext(playerObj, context, worldobjects)
end);

Events[PZ.events.OnPhunZonesPlayerLocationChanged].Add(function(playerObj, zone, oldZone)

end)

Events[PZ.events.OnPhunZoneReady].Add(function(playerObj, zone)

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
            PZ:setTrackedVehicleData(vehicle:getId())
            -- local rvInfo = RVInterior and RVInterior.getVehicleModData(vehicle)
            -- local hasInteriorParams = RVInterior and RVInterior.vehicleHasInteriorParameters(vehicle)
            -- sendClientCommand(PZ.name, PZ.commands.trackVehicle, {
            --     sqlId = vehicle:getSqlId(),
            --     id = vehicle:getId(),
            --     x = player:getX(),
            --     y = player:getY()
            -- })
        end
        -- local data = player:getModData().PhunZonesVehicleInfo
        -- local id = vehicle:getId()
        -- data.lastVehicleId = id
        -- data.lastVehicleEntered = {
        --     x = player:getX(),
        --     y = player:getY()
        -- }
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

