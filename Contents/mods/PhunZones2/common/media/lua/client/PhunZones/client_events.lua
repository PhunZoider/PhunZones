if isServer() then
    return
end
local Core = PhunZones
local Commands = require "PhunZones/client_commands"

Events[Core.events.OnPhunZonesPlayerLocationChanged].Add(function(playerObj, newEffective, prevEffective)

    Core:updatePlayerUI(playerObj, newEffective, prevEffective)

end)

Events[Core.events.OnPhunZonesObjectLocationChanged].Add(function(object, zone)
    -- check if zed is in a nozed zone
    if instanceof(object, "IsoZombie") then
        local doRemove = false
        if zone.zeds == false then
            Core.updateModData(object)
            doRemove = true
        elseif zone.bandits == false and object:getModData().brain ~= nil then
            object:getModData().PZChecked = nil
            doRemove = true
        end
        if doRemove then
            if isClient() then
                sendClientCommand(Core.name, Core.commands.cleanPlayersZeds, {
                    id = Core.getZId(object)
                })
            end
            triggerEvent(Core.events.OnZombieRemoved, Core.getZId(object))
            object:removeFromWorld()
            object:removeFromSquare()

        end
    end
end)

Events[Core.events.OnPhunZoneReady].Add(function()
    Events.OnZombieUpdate.Add(function(zed)
        if not zed then
            return
        end
        local md = zed:getModData()
        local checked = zed:getModData().PZChecked or 0
        if not md.PhunZones or md.PhunZones.id ~= Core.getZId(zed) or not md.PhunZones.checked or md.PhunZones.checked <
            getTimestamp() then
            md.PhunZones = getTimestamp() + (Core.settings.ZedUpdateFrequency or 10)
            Core.updateModData(zed, true)
        end
    end)

    local nextCheck = 0

    Events.OnTick.Add(function()
        if getTimestamp() >= nextCheck then
            nextCheck = getTimestamp() + (Core.settings.updateInterval or 1)
            local players = Core.tools.onlinePlayers()
            for i = 0, players:size() - 1, 1 do
                local p = players:get(i)
                Core.updateModData(p, true)
            end
        end
    end)

end)

Events[Core.events.OnZonesUpdated].Add(function(playerObj, buttonId)
    Core:updatePlayers()

    -- In your process/rebuild code, after data is ready:
    for _, instance in pairs(Core.ui.zones.instances or {}) do
        if instance.refreshData then
            instance:refreshData()
        end
    end

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
    if tableName == Core.const.modifiedModData then
        ModData.add(Core.const.modifiedModData, tableData)
        Core:updateZoneData(true, tableData)
    end
end)

Events.OnEnterVehicle.Add(function(player)
    if player and Core.settings.VehicleTracking then
        local vehicle = player:getVehicle();
        if vehicle then
            Core:setTrackedVehicleData(vehicle:getId())
        end
    end
end)

Events.OnServerCommand.Add(function(module, command, arguments)
    if module == Core.name then
        if Commands[command] then
            Commands[command](arguments)
        end
    end
end)

local function setup()
    Events.OnTick.Remove(setup)
    Core:ini()
    Core.iniBuilding()
    Core.iniSafehouses()
    Core:showWidgets()
    sendClientCommand(Core.name, Core.commands.playerSetup, {})

end

Events.OnNewFire.Add(Core.checkFire)

Events.OnTick.Add(setup)

