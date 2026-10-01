if isClient() then
    return
end
local Commands = {}
local Core = PhunZones

Commands[Core.commands.playerSetup] = function(player)
    -- send any exemption/changes to the client
    local p = player
    local modData = p:getModData()

    if not modData.PhunZones or not modData.PhunZones.at then
        modData.PhunZones = {
            zone = nil,
            at = {}
        }
    end
    Core.updateModData(player, true, true)
    sendServerCommand(player, Core.name, Core.commands.playerSetup, {
        data = ModData.get(Core.const.modifiedModData) or {},
        -- ModData.transmit only reaches clients already connected, so a joining
        -- client gets the profile state as part of the handshake instead.
        runtime = ModData.get(Core.const.runtimeModData) or {}
    })
end

Commands[Core.commands.modifyZone] = function(player, data)
    if not data then
        return
    end
    if not player:getRole():hasCapability(Capability.CanSetupNonPVPZone) then
        return
    end
    Core.debug("[modifyZone]", data)
    Core.saveChanges(data.changes)

    Core.debug("[custom]", ModData.get(Core.const.modifiedModData))
    -- saveChanges transmits on the server branch; no second transmit needed.
end

Commands[Core.commands.setProfile] = function(player, data)
    if not player:getRole():hasCapability(Capability.CanSetupNonPVPZone) then
        return
    end
    local ok, err = Core.setActiveProfile(data and data.profile)
    if not ok then
        print("PhunZones: " .. player:getUsername() .. " could not activate profile '" ..
                  tostring(data and data.profile) .. "': " .. tostring(err))
    end
end

-- Profile definition edits. All three re-check the capability rather than
-- trusting the editor to have hidden the buttons.
local function profileLog(player, what, ok, err)
    if not ok then
        print("PhunZones: " .. player:getUsername() .. " could not " .. what .. ": " .. tostring(err))
    end
end

Commands[Core.commands.modifyProfile] = function(player, data)
    if not player:getRole():hasCapability(Capability.CanSetupNonPVPZone) then
        return
    end
    local ok, err = Core.saveProfileChanges(data and data.profile, data and data.changes)
    profileLog(player, "save profile '" .. tostring(data and data.profile) .. "'", ok, err)
end

Commands[Core.commands.createProfile] = function(player, data)
    if not player:getRole():hasCapability(Capability.CanSetupNonPVPZone) then
        return
    end
    local ok, err = Core.createProfile(data and data.profile)
    profileLog(player, "create profile '" .. tostring(data and data.profile) .. "'", ok, err)
end

Commands[Core.commands.removeProfile] = function(player, data)
    if not player:getRole():hasCapability(Capability.CanSetupNonPVPZone) then
        return
    end
    local ok, err = Core.deleteProfile(data and data.profile)
    profileLog(player, "delete profile '" .. tostring(data and data.profile) .. "'", ok, err)
end

Commands[Core.commands.deleteZone] = function(player, data)
    if not player:getRole():hasCapability(Capability.CanSetupNonPVPZone) then
        return
    end
    Core.addDeletion(data.key)
    ModData.transmit(Core.const.modifiedModData)
end

Commands[Core.commands.evictZeds] = function(player, args)
    print("evicting zeds for " .. player:getUsername() .. " in zone " .. tostring(args and args.zone))
    Core.evictZeds(player, args and args.zone)
end

-- How far, in tiles, the server's copy of a zombie may be from where the client
-- saw it created and still count as the same one.
local SPAWN_MATCH_RANGE = 2

Commands[Core.commands.removeZeds] = function(player, args)
    Core.debug("Removing zeds in " .. tostring(args and args.zone), args)
    -- Re-derive from server state: only remove zeds that are
    -- (a) in the player's current cell, AND
    -- (b) in the player's zone, AND
    -- (c) ones that zone's rule says to remove. A bandit exempted by its own
    --     rule, or an A-Life NPC, is left alone even where zeds are removed;
    --     the server is where A-Life's markers can be trusted.
    --
    -- args.at lists where the client removed a zombie as it was created. The
    -- zombie there is removed too, wherever it is, provided its own zone removes
    -- at creation; that is the only way a spawn-only zone works, since sweeping
    -- it would take the zeds that were allowed to wander in. Positions rather
    -- than IDs, because from B42.17 a zombie's ID differs between machines.
    local zone = Core.getLocation(player:getX(), player:getY()) or {}
    local sweep = Core.zedAction(zone, "zeds") == "remove" or Core.banditAction(zone) == "remove"
    local at = args and args.at or {}
    if not sweep and #at == 0 then
        return -- player isn't even in a remove zone; ignore
    end

    local function wasNamed(zombie)
        local x, y, z = zombie:getX(), zombie:getY(), math.floor(zombie:getZ())
        for _, p in ipairs(at) do
            if math.floor(p.z or 0) == z and math.abs(p.x - x) <= SPAWN_MATCH_RANGE and math.abs(p.y - y) <=
                SPAWN_MATCH_RANGE then
                return true
            end
        end
        return false
    end

    local removed = {}
    local zombies = player:getCell():getZombieList()
    for i = zombies:size() - 1, 0, -1 do
        local zombie = zombies:get(i)
        if instanceof(zombie, "IsoZombie") then
            local zZone = Core.getLocation(zombie:getX(), zombie:getY()) or {}
            local id = Core.getZId(zombie)
            local action = Core.zombieAction(zZone, zombie)
            if id and ((sweep and zZone.key == zone.key and action == "remove") or
                (#at > 0 and Core.onCreateAction(action) == "remove" and wasNamed(zombie))) then
                if Core.settings.Debug then
                    Core.debugLn(
                        "Removing zed " .. id .. " at " .. zombie:getX() .. "," .. zombie:getY() .. " in zone " ..
                            tostring(zZone.key))
                end
                table.insert(removed, tostring(id))
                zombie:removeFromWorld()
                zombie:removeFromSquare()
            end

        end
    end
    if #removed > 0 then
        triggerEvent(Core.events.OnZombieRemoved, removed)
    end
end

return Commands
