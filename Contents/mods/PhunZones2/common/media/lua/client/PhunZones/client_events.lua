if isServer() then
    return
end
local Core = PhunZones
local Commands = require "PhunZones/client_commands"

local bandits2Active = getActivatedMods():contains("Bandits2")

local playersInZedZone = {}
local zedZonePlayerCount = 0

-- Per-zombie cooldown. Each zombie self-tests its zone location at most once
-- every ZED_COOLDOWN seconds. Out-of-zone zombies get the same cooldown so
-- their location isn't re-queried on every AI update tick.
-- Purged periodically and on zone data changes to prevent stale entries from
-- accumulating as zombies despawn.
local ZED_COOLDOWN = 10 -- seconds, for zombies confirmed outside any action zone
local ZED_RECHECK = 2 -- seconds, re-check interval while players are in action zones
local zedCheckCooldown = {} -- [zedId] = nextAllowedTimestamp
local pendingRemove = {} -- zed IDs queued for removal, flushed each tick
local sentForRemoval = {} -- [zedId] = true; prevents re-queuing until purge

-- Migrate legacy index-based zed/bandit values (stored as "1"/"2"/"3") to
-- the current string values ("none"/"move"/"remove"). Zones saved before the
-- label/value combo change will have numeric strings; new saves will not.
local ZED_MIGRATE = {
    ["1"] = "none",
    ["2"] = "move",
    ["3"] = "remove"
}
local function migrateZedField(v)
    return ZED_MIGRATE[tostring(v)] or v
end

local function zoneHasAction(zone)
    local z = migrateZedField(zone.zeds)
    if z == "move" or z == "remove" then
        return true
    end
    if bandits2Active then
        local b = migrateZedField(zone.bandits)
        if b == "move" or b == "remove" then
            return true
        end
    end
    return false
end

-- Per-zombie ongoing enforcement. Fires every AI update for each nearby zombie.
-- When no player is in a zed-action zone the entire handler is a single boolean
-- check. Otherwise each zombie pays for Core.getLocation at most once per
-- ZED_COOLDOWN seconds; all other updates are a cheap table-lookup + return.
Events.OnZombieUpdate.Add(function(zed)
    if zedZonePlayerCount == 0 then
        return
    end

    local id = Core.getZId(zed)
    if not id then
        return
    end

    local now = getTimestamp()
    if now < (zedCheckCooldown[id] or 0) then
        return
    end

    local zedZone = Core.getLocation(zed:getX(), zed:getY())
    if not zedZone then
        zedCheckCooldown[id] = now + ZED_COOLDOWN
        return
    end

    local zedAction = migrateZedField(zedZone.zeds)
    local banditAction = bandits2Active and migrateZedField(zedZone.bandits) or nil
    if zedAction ~= "move" and zedAction ~= "remove" and banditAction ~= "move" and banditAction ~= "remove" then
        -- Zombie is outside an action zone but a player is in one nearby. Use a
        -- short recheck interval so a chasing zombie is caught quickly on entry.
        zedCheckCooldown[id] = now + ZED_RECHECK
        return
    end

    local isBandit = bandits2Active and zed:getModData().brain ~= nil
    local action = isBandit and banditAction or zedAction

    if action == "move" then
        local ex, ey, ez = Core.findNearestSafePosition(zed:getX(), zed:getY(), zed:getZ(), zedZone.key)
        if ex then
            zed:setX(ex + ZombRand(-2, 2))
            zed:setY(ey + ZombRand(-2, 2))
            zed:setZ(ez)
        end
        -- Cooldown after move prevents immediately re-moving the same zombie.
        zedCheckCooldown[id] = now + ZED_COOLDOWN
    elseif action == "remove" then
        if not sentForRemoval[id] then
            pendingRemove[#pendingRemove + 1] = id
            sentForRemoval[id] = true
            zed:removeFromWorld()
            zed:removeFromSquare()
            -- No cooldown: zombie is gone. Omitting the entry means a newly
            -- wandering-in zombie is caught on its very next update tick.
        end
    end
end)

-- Zone-entry sweep: bulk-processes all zombies currently in the zone so the
-- player sees immediate enforcement on arrival. Also primes each zombie's
-- cooldown so OnZombieUpdate doesn't re-process them straight after.
local function sweepZoneZeds(playerObj, zone)
    if not playerObj or not zone or not zone.key then
        return
    end
    -- _default covers all unzoned world space; sweeping it would remove every
    -- zombie outside any specific zone. This also fires when the player briefly
    -- passes through unzoned space en-route to a named zone (double-event).
    -- Ongoing enforcement via OnZombieUpdate handles the default zone already.
    if zone.key == "_default" then
        return
    end
    local zedAction = migrateZedField(zone.zeds)
    local banditAction = bandits2Active and migrateZedField(zone.bandits) or nil
    if zedAction ~= "move" and zedAction ~= "remove" and banditAction ~= "move" and banditAction ~= "remove" then
        return
    end

    local now = getTimestamp()
    local toRemove = {}
    local toRemoveObjs = {}
    local zombies = playerObj:getCell():getZombieList()
    for i = 0, zombies:size() - 1 do
        local zed = zombies:get(i)
        if instanceof(zed, "IsoZombie") then
            local zedZone = Core.getLocation(zed:getX(), zed:getY())
            if zedZone and zedZone.key == zone.key then
                local isBandit = bandits2Active and zed:getModData().brain ~= nil
                local action = isBandit and banditAction or zedAction
                local id = Core.getZId(zed)
                if action == "move" then
                    local ex, ey, ez = Core.findNearestSafePosition(zed:getX(), zed:getY(), zed:getZ(), zone.key)
                    if ex then
                        zed:setX(ex + ZombRand(-2, 2))
                        zed:setY(ey + ZombRand(-2, 2))
                        zed:setZ(ez)
                    end
                    if id then
                        zedCheckCooldown[id] = now + ZED_COOLDOWN
                    end
                elseif action == "remove" and id then
                    table.insert(toRemove, id)
                    zedCheckCooldown[id] = now + ZED_COOLDOWN
                    table.insert(toRemoveObjs, zed)
                end
            end
        end
    end
    -- Remove after iteration to avoid mutating the zombie list mid-traversal,
    -- which would cause out-of-bounds get() calls and skip/remove unintended zeds.
    for _, zed in ipairs(toRemoveObjs) do
        zed:removeFromWorld()
        zed:removeFromSquare()
    end
    if #toRemove > 0 and isClient() then
        sendClientCommand(Core.name, Core.commands.removeZeds, {
            id = toRemove
        })
    end
end

Events[Core.events.OnEffectiveZoneChanged].Add(function(playerObj, stored)
    local zone = Core.data.lookup[stored.zone] or {}
    -- Use the physical zone for the sweep: stored.at.zone is set from the player's
    -- actual position before any handler can mutate stored.zone for display purposes.
    local physicalZone = Core.data.lookup[stored.at.zone] or zone
    local playerNum = playerObj:getPlayerNum()
    local wasIn = playersInZedZone[playerNum]
    local isIn = zoneHasAction(physicalZone)
    playersInZedZone[playerNum] = isIn or nil
    if isIn and not wasIn then
        zedZonePlayerCount = zedZonePlayerCount + 1
    elseif not isIn and wasIn and zedZonePlayerCount > 0 then
        zedZonePlayerCount = zedZonePlayerCount - 1
    end

    Core:updatePlayerUI(playerObj, zone)
    if isIn then
        sweepZoneZeds(playerObj, physicalZone)
    end
end)

Events[Core.events.OnPhunZonesObjectLocationChanged].Add(function(object, zone)

end)

Events[Core.events.OnPhunZoneReady].Add(function()

    local nextCheck = 0
    local nextPurge = 0

    Events.OnTick.Add(function()
        local now = getTimestamp()

        if now >= nextCheck then
            nextCheck = now + (Core.settings.updateInterval or 1)
            local players = Core.tools.onlinePlayers()
            for i = 0, players:size() - 1, 1 do
                Core.updateModData(players:get(i), true)
            end
        end

        if #pendingRemove > 0 then
            if isClient() then
                sendClientCommand(Core.name, Core.commands.removeZeds, {
                    id = pendingRemove
                })
            end
            pendingRemove = {}
        end

        -- Purge stale cooldown entries every 5 minutes. Despawned zombies leave
        -- dead IDs in the table; clearing it is harmless since live zombies
        -- simply get re-checked on their next OnZombieUpdate.
        if now >= nextPurge then
            nextPurge = now + 300
            zedCheckCooldown = {}
            sentForRemoval = {}
        end
    end)

end)

Events[Core.events.OnDataBuilt].Add(function(playerObj, buttonId)
    playersInZedZone = {}
    zedZonePlayerCount = 0
    zedCheckCooldown = {} -- zone data changed; force fresh zone checks
    sentForRemoval = {}
    pendingRemove = {}
    Core:updatePlayers()
    local players = Core.tools.onlinePlayers()
    for i = 0, players:size() - 1 do
        local p = players:get(i)
        local num = p:getPlayerNum()
        if not playersInZedZone[num] then
            local stored = p:getModData().PhunZones
            if stored and stored.zone then
                local zone = Core.data.lookup[stored.zone] or {}
                if zoneHasAction(zone) then
                    playersInZedZone[num] = true
                    zedZonePlayerCount = zedZonePlayerCount + 1
                end
            end
        end
    end

    for _, instance in pairs(Core.ui.zones.instances or {}) do
        if instance.refreshData then
            -- Preserve the current selection across the data rebuild
            instance:refreshData(instance.selectedData)
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
        -- B42: tableData may be false; data is already in ModData by the time
        -- this event fires, so only write it back if we actually received a table.
        if type(tableData) == "table" then
            ModData.add(Core.const.modifiedModData, tableData)
        end
        local ted = ModData.get(Core.const.modifiedModData) or {}
        Core.debug("[received modifiedModData]", ted)
        Core.updateZoneData()
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
