if isServer() then
    return
end
local Core = PhunZones
local Commands = require "PhunZones/client_commands"

local bandits2Active = getActivatedMods():contains("Bandits2")

local playersInZedZone = {}
local zedZonePlayerCount = 0
-- True when any zone at all asks for zed/bandit enforcement. This is what gates
-- the per-zombie check, not whether a player is standing in an action zone: a
-- zombie's zone and the player's zone are frequently not the same one, and
-- gating on the player meant a zed sitting in a restricted zone was ignored
-- whenever every player happened to be somewhere unrestricted.
local zoneActionsExist = false

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

-- The action a zone asks for, as "none"/"move"/"remove". Legacy index values are
-- migrated by Core.zedAction. Core.banditAction only matters when Bandits2 is
-- loaded, so a config carried in from a server that ran it does nothing here.
local function zedActionOf(zone)
    return Core.zedAction(zone, "zeds")
end

local function actionFor(zone, isBandit)
    if isBandit then
        return Core.banditAction(zone)
    end
    return zedActionOf(zone)
end

local function zoneHasAction(zone)
    if zedActionOf(zone) ~= "none" then
        return true
    end
    return bandits2Active and Core.banditAction(zone) ~= "none"
end

-- Per-zombie ongoing enforcement. Fires every AI update for each nearby zombie.
-- When no zone anywhere asks for enforcement the entire handler is a single
-- boolean check. Otherwise each zombie pays for Core.getLocation at most once
-- per cooldown; all other updates are a cheap table-lookup + return.
Events.OnZombieUpdate.Add(function(zed)
    if not zoneActionsExist then
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

    if not zoneHasAction(zedZone) then
        -- Zombie is outside an action zone. Recheck quickly while a player is
        -- in one nearby, so a chasing zombie is caught as it crosses in;
        -- otherwise back off, since nothing is watching that boundary.
        zedCheckCooldown[id] = now + (zedZonePlayerCount > 0 and ZED_RECHECK or ZED_COOLDOWN)
        return
    end

    local isBandit = bandits2Active and zed:getModData().brain ~= nil
    local action = actionFor(zedZone, isBandit)

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
    if not zoneHasAction(zone) then
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
                local action = actionFor(zone, isBandit)
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
    -- Recomputed per build: an admin turning the last action off should cost
    -- nothing per zombie afterwards, and turning one on must take effect
    -- without waiting for anyone to walk into it.
    zoneActionsExist = (Core.data and Core.data.hasZedAction) == true
    playersInZedZone = {}
    zedZonePlayerCount = 0
    zedCheckCooldown = {} -- zone data changed; force fresh zone checks
    sentForRemoval = {}
    pendingRemove = {}
    -- force: the zone data itself changed, so a player who has not moved may
    -- now be standing in a zone that just became restricted. Without forcing,
    -- updatePlayerZoneData short-circuits on an unchanged physical zone and
    -- nobody is evicted until they next cross a boundary.
    Core:updatePlayers(true)
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

-- On a dedicated server the server reconciles the engine non-pvp zone list and
-- pushes it to us. A co-op host has no such server: server_events never loads
-- there because isClient() is true, so the host does its own reconcile. That
-- reaches the guests for free, since adding a zone from a client broadcasts.
Events[Core.events.OnDataBuilt].Add(function()
    if isCoopHost() then
        Core.refreshNoPvpZones()
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
    elseif tableName == Core.const.runtimeModData then
        -- Profile definitions plus which one is active. Same B42 caveat as above.
        if type(tableData) == "table" then
            ModData.add(Core.const.runtimeModData, tableData)
        end
        Core.debug("[received runtimeModData]", ModData.get(Core.const.runtimeModData) or {})
        -- The rebuild re-runs the merge with the new overlay, and OnDataBuilt
        -- forces re-enforcement so anyone standing in a newly closed zone moves.
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
