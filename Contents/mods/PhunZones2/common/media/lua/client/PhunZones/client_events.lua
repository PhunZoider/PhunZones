if isServer() then
    return
end
local Core = PhunZones
local Commands = require "PhunZones/client_commands"

local playersInNozedZone = {}
local nozedPlayerCount = 0

Events[Core.events.OnEffectiveZoneChanged].Add(function(playerObj, stored)
    local zone = Core.data.lookup[stored.zone] or {}
    local playerNum = playerObj:getPlayerNum()
    local wasIn = playersInNozedZone[playerNum]
    local inNozedZone = zone.nozeds or zone.nobandits
    playersInNozedZone[playerNum] = inNozedZone or nil
    if inNozedZone and not wasIn then
        nozedPlayerCount = nozedPlayerCount + 1
    elseif not inNozedZone and wasIn then
        nozedPlayerCount = nozedPlayerCount - 1
    end

    Core:updatePlayerUI(playerObj, zone)
    if inNozedZone then
        Core.evictZeds(playerObj, zone.key)
    end
end)

Events[Core.events.OnPhunZonesObjectLocationChanged].Add(function(object, zone)

end)

Events[Core.events.OnPhunZoneReady].Add(function()

    local nextCheck = 0

    Events.OnTick.Add(function()
        if getTimestamp() >= nextCheck then
            nextCheck = getTimestamp() + (Core.settings.updateInterval or 1)
            local players = Core.tools.onlinePlayers()
            for i = 0, players:size() - 1, 1 do
                local p = players:get(i)
                Core.updateModData(p, true)
                if nozedPlayerCount > 0 then
                    local stored = p:getModData().PhunZones
                    if stored and stored.zone then
                        Core.evictZeds(p, stored.zone)
                    end
                end
            end
        end
    end)

end)

Events[Core.events.OnZonesUpdated].Add(function(playerObj, buttonId)
    playersInNozedZone = {}
    nozedPlayerCount = 0
    Core:updatePlayers()
    local players = Core.tools.onlinePlayers()
    for i = 0, players:size() - 1 do
        local p = players:get(i)
        local num = p:getPlayerNum()
        if not playersInNozedZone[num] then
            local stored = p:getModData().PhunZones
            if stored and stored.zone then
                local zone = Core.data.lookup[stored.zone] or {}
                if zone.nozeds or zone.nobandits then
                    playersInNozedZone[num] = true
                    nozedPlayerCount = nozedPlayerCount + 1
                end
            end
        end
    end

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
        if not data.PhunZones or not data.PhunZones.at then
            data.PhunZones = {
                zone = nil,
                at = {}
            }
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

