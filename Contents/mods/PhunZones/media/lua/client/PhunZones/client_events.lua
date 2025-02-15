if isServer() then
    return
end
local PZ = PhunZones
local Commands = require "PhunZones/client_commands"

Events.OnPreFillWorldObjectContextMenu.Add(function(playerObj, context, worldobjects)
    PZ:showContext(playerObj, context, worldobjects)
end);

Events[PZ.events.OnPhunZonesPlayerLocationChanged].Add(function(playerObj, zone, oldZone)
    PZ:updatePlayerUI(playerObj, zone)
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
            print("Removed zombie " .. tostring(object:getOnlineID()))
            sendClientCommand(PZ.name, PZ.commands.cleanPlayersZeds, {
                id = object:getOnlineID()
            })
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
        if not md.PhunZones or md.PhunZones.id ~= zed:getOnlineID() or not md.PhunZones.checked or md.PhunZones.checked <
            getTimestamp() then
            md.PhunZones = getTimestamp() + (PZ.settings.ZedUpdateFrequency or 10)
            PZ:updateModData(zed, true)
        end
    end)
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

Events.EveryTenMinutes.Add(shit)

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

Events.OnTick.Add(setup)

local oldDestroyStuffAction = ISDestroyStuffAction["isValid"];

ISDestroyStuffAction["isValid"] = function(self)

    if self.character then

        local p = self.character
        local md = p:getModData().PhunZones

        if md.destruction == false then
            p:setHaloNote("You cannot use a sledgehammer in this area", 255, 255, 0, 300);
            return false
        end

    end
    return oldDestroyStuffAction(self)

end
