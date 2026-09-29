-- Project A-Life NPC spawn control.
--
-- A-Life spawns from the server. Every spot it considers for an NPC body --
-- natural encounters, admin and raid jobs, offline squads arriving, and a
-- dormant NPC being restored near a returning player -- is vetted by
-- ProjectALife.SpawnPolicy.check, and the first thing that asks is
-- SpawnPolicy.excludedRegionAt(position). The mod uses that itself to keep NPCs
-- out of RV interiors. Answering it for our zones means A-Life picks another
-- spot on its own, rather than us refusing a body after the fact and leaving
-- it to retry forever.
--
-- The one path it does not cover is the watchdog putting back a body it lost
-- track of at its last position. That is an NPC that was already there, which
-- is exactly what "nospawn" is meant to leave alone.
local Core = PhunZones

if not getActivatedMods():contains("ProjectALifeNPCs") then
    return
end

local installed = false

local function install()
    if installed then
        return
    end
    local policy = ProjectALife and ProjectALife.SpawnPolicy
    if not policy or not policy.excludedRegionAt then
        return
    end
    installed = true

    local excludedRegionAt = policy.excludedRegionAt

    -- Returns an id for the region the position falls in, or nil for none.
    -- A-Life only tests the result against nil.
    policy.excludedRegionAt = function(position)
        local region = excludedRegionAt(position)
        if region ~= nil then
            return region
        end
        local x, y = tonumber(position and position.x), tonumber(position and position.y)
        if x == nil or y == nil then
            return nil
        end
        local zone = Core.getLocation(x, y)
        if Core.alifeAction(zone) == "nospawn" then
            return "PhunZones:" .. tostring(zone.key)
        end
        return nil
    end
end

Core.installALifeHooks = install

-- Same reasoning as the bandit hook: load order between mods is not ours to
-- decide, so retry from events that fire after every mod's Lua has loaded.
install()
Events.OnGameBoot.Add(install)
Events.OnServerStarted.Add(install)
Events.OnGameStart.Add(install)
