if isServer() then
    return
end
local PZ = PhunZones
local PL = PhunLib
local Commands = require "PhunZones/client_commands"

Events[PZ.events.OnPhunZonesPlayerLocationChanged].Add(function(playerObj, zone, oldZone)

    if PZ.isLocal or PZ.settings.ProcessOnClient then
        local players = PL.onlinePlayers()
        if not PZ.players then
            PZ.players = ModData.getOrCreate(PZ.const.playerData)
        end
        for i = 0, players:size() - 1 do
            local p = players:get(i)
            if p:getID() == playerObj:getID() then
                local existing = PL.table.deepCopy(p:getModData().PhunZones)
                PZ.players[p:getID()] = zone
                p:getModData().PhunZones = zone
                PZ:updatePlayerUI(p, zone, existing)

            end

        end
    end

end)

Events[PZ.events.OnPhunZonesObjectLocationChanged].Add(function(object, zone)
    -- check if zed is in a nozed zone
    if instanceof(object, "IsoZombie") then
        local doRemove = false
        if zone.zeds == false then
            PZ:updateModData(object)
            doRemove = true
        elseif zone.bandits == false and object:getModData().brain ~= nil then
            object:getModData().PZChecked = nil
            doRemove = true
        end
        if doRemove then
            if isClient() then
                sendClientCommand(PZ.name, PZ.commands.cleanPlayersZeds, {
                    id = PZ.getZId(object)
                })
            end
            triggerEvent(PZ.events.OnZombieRemoved, PZ.getZId(object))
            object:removeFromWorld()
            object:removeFromSquare()

        end
    end
end)

Events[PZ.events.OnPhunZoneReady].Add(function()
    Events.OnZombieUpdate.Add(function(zed)
        if not zed then
            return
        end
        local md = zed:getModData()
        local checked = zed:getModData().PZChecked or 0
        if not md.PhunZones or md.PhunZones.id ~= PZ.getZId(zed) or not md.PhunZones.checked or md.PhunZones.checked <
            getTimestamp() then
            md.PhunZones = getTimestamp() + (PZ.settings.ZedUpdateFrequency or 10)
            PZ:updateModData(zed, true)
        end
    end)

    if PZ.settings.ProcessOnClient then
        local nextCheck = 0

        Events.OnTick.Add(function()
            if getTimestamp() >= nextCheck then
                nextCheck = getTimestamp() + (PZ.settings.updateInterval or 1)
                local players = PL.onlinePlayers()
                for i = 0, players:size() - 1, 1 do
                    local p = players:get(i)
                    PZ:updateModData(p, true)
                end
            end
        end)
    end
end)

Events[PZ.events.OnZonesUpdated].Add(function(playerObj, buttonId)
    PZ:updatePlayers()
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

Events.OnPreFillWorldObjectContextMenu.Add(function(playerObj, context, worldobjects)
    PZ:showContext(playerObj, context, worldobjects)
end);

Events.OnReceiveGlobalModData.Add(function(tableName, tableData)
    if tableName == PZ.const.modifiedModData then
        ModData.add(PZ.const.modifiedModData, tableData)
        PZ:updateZoneData(true, tableData)
    elseif tableName == PZ.const.modifiedDeletions then
        ModData.add(PZ.const.modifiedDeletions, tableData)
        PZ:updateZoneData(true, tableData)
    end
end)

Events.OnEnterVehicle.Add(function(player)
    if player and PZ.settings.VehicleTracking then
        local vehicle = player:getVehicle();
        if vehicle then
            PZ:setTrackedVehicleData(vehicle:getId())
        end
    end
end)

Events.OnServerCommand.Add(function(module, command, arguments)
    if module == PZ.name then
        if Commands[command] then
            Commands[command](arguments)
        end
    end
end)

local sh = nil
local function setup()
    Events.OnTick.Remove(setup)
    PZ:ini()
    PZ:showWidgets()
    sendClientCommand(PZ.name, PZ.commands.playerSetup, {})

    if sh == nil then
        sh = SafeHouse.canBeSafehouse
        SafeHouse.canBeSafehouse = function(square, player)
            local md = player:getModData().PhunZones
            if md.safehouse == false then
                return getText("IGUI_PhunZones_NoSafeHouse")
            end

            return sh(square, player)
        end
    end
end

Events.OnNewFire.Add(function(fire)
    PZ:checkFire(fire)
end)

Events.OnTick.Add(setup)

local oldDestroyStuffAction = ISDestroyStuffAction["isValid"];

ISDestroyStuffAction["isValid"] = function(self)

    if self.character then

        local p = self.character
        local md = p:getModData().PhunZones

        if md.destruction == false then
            p:setHaloNote(getText("IGUI_PhunZones_NoDestruction"), 255, 255, 0, 300);
            return false
        end

    end
    return oldDestroyStuffAction(self)

end
