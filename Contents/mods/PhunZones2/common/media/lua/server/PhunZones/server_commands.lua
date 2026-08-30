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

Commands[Core.commands.removeZeds] = function(player, args)
    Core.debug("Removing zeds in " .. tostring(args and args.zone), args)
    -- Re-derive from server state: only remove zeds that are
    -- (a) in the player's current cell, AND
    -- (b) in a zone that actually has zeds==3 action
    local zone = Core.getLocation(player:getX(), player:getY()) or {}
    if tostring(zone.zeds) ~= "remove" then
        return -- player isn't even in a remove-zeds zone; ignore
    end

    local removed = {}
    local zombies = player:getCell():getZombieList()
    for i = zombies:size() - 1, 0, -1 do
        local zombie = zombies:get(i)
        if instanceof(zombie, "IsoZombie") then
            local zZone = Core.getLocation(zombie:getX(), zombie:getY()) or {}
            local id = Core.getZId(zombie)
            if id and zZone.key == zone.key then
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
