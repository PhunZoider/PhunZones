-- Zone-change events on a forced update.
--
-- A player's zone key is kept in their mod data, so it is still there when they
-- log back in standing exactly where they logged out. The UI is painted from
-- OnEffectiveZoneChanged, and the only thing that used to fire it was the key
-- changing — which, on a relog, it does not. The result was a widget showing
-- nothing until the player next walked across a boundary. The forced update the
-- login handshake and every zone-data rebuild already make now announces the
-- zone as well, whether or not the key moved.
--
-- Run: ..\PhunTestKit\run.cmd . relog

local kit = require "phuntestkit"
local harness, check = kit.harness, kit.check

kit.installGlobals()

harness.activeMods = {}
_G.getActivatedMods = function()
    return {
        contains = function(_, name)
            return harness.activeMods[name] == true
        end
    }
end
_G.getCore = function()
    return {
        getGameVersion = function()
            return {
                getMajor = function()
                    return 42
                end,
                getMinor = function()
                    return 20
                end
            }
        end
    }
end

_G.instanceof = function(obj, class)
    return type(obj) == "table" and obj.class == class
end

kit.addMod("PhunZones2")

require "PhunZones/core"
local Core = PhunZones

kit.strip()

-- ---------------------------------------------------------------------------
-- Two open zones, side by side: 1000..1100 is Westpoint, everything else is the
-- default. Nothing here restricts access, so enforceZoneAccess always passes
-- and the events are the only thing under test.
-- ---------------------------------------------------------------------------
local WESTPOINT = {
    key = "WestPoint",
    title = "West Point"
}
local OPEN = {
    key = "_default",
    title = "Kentucky"
}

Core.inied = true
Core.data = {
    lookup = {
        WestPoint = WESTPOINT,
        _default = OPEN
    },
    cells = {
        -- floor(1000/300) == 3 on both axes
        ["3_3"] = {{"WestPoint", 1000, 1000, 1100, 1100}}
    }
}
Core.settings = Core.settings or {}
Core.settings.StaffExempt = false

local function makePlayer(name, x, y)
    local p = {
        class = "IsoPlayer",
        x = x,
        y = y,
        z = 0,
        modData = {}
    }
    function p:getUsername()
        return name
    end
    function p:getX()
        return self.x
    end
    function p:getY()
        return self.y
    end
    function p:getZ()
        return self.z
    end
    function p:getVehicle()
        return nil
    end
    function p:getModData()
        return self.modData
    end
    function p:setHaloNote()
    end
    return p
end

--- How many times an event fired since the last reset.
local function fired(name)
    local n = 0
    for _, e in ipairs(harness.events) do
        if e.name == name then
            n = n + 1
        end
    end
    return n
end

local EFFECTIVE = Core.events.OnEffectiveZoneChanged
local PHYSICAL = Core.events.OnPhysicalZoneChanged

-- ---------------------------------------------------------------------------
check.section("walking into a zone")

local walker = makePlayer("walker", 5000, 5000)
harness.events = {}
Core.updatePlayerZoneData(walker, true)
check.same("arriving in the default zone announces it", fired(EFFECTIVE), 1)
check.same("and the zone is recorded", walker.modData.PhunZones.zone, "_default")

harness.events = {}
walker.x, walker.y = 1050, 1050
Core.updatePlayerZoneData(walker, true)
check.same("crossing into West Point announces it", fired(EFFECTIVE), 1)
check.same("and the zone is recorded", walker.modData.PhunZones.zone, "WestPoint")

harness.events = {}
walker.x, walker.y = 1060, 1060
Core.updatePlayerZoneData(walker, true)
check.same("moving about inside it announces nothing", fired(EFFECTIVE), 0)
check.same("but the position is kept current", walker.modData.PhunZones.at.x, 1060)

-- ---------------------------------------------------------------------------
check.section("logging back in where you logged out")

-- Mod data as it comes back from the save: the zone key is already the one the
-- player is standing in, so nothing about their position has changed.
local returning = makePlayer("returning", 1050, 1050)
returning.modData.PhunZones = {
    zone = "WestPoint",
    at = {
        zone = "WestPoint",
        x = 1050,
        y = 1050,
        z = 0
    }
}

harness.events = {}
Core.updatePlayerZoneData(returning, true)
check.same("an ordinary update has nothing to say", fired(EFFECTIVE), 0)

harness.events = {}
Core.updatePlayerZoneData(returning, true, true)
check.same("the login's forced update announces the zone", fired(EFFECTIVE), 1)
check.same("with the zone the player is actually in", returning.modData.PhunZones.zone, "WestPoint")
check.same("and the physical zone alongside it", fired(PHYSICAL), 1)

-- ---------------------------------------------------------------------------
check.section("a zone-data rebuild under a stationary player")

-- Same shape as a relog, and the reason force exists: an admin edits a zone's
-- title while somebody is standing in it. The key never moves, so the UI is
-- only repainted if the forced rebuild announces it.
harness.events = {}
WESTPOINT.title = "West Point (closed)"
Core.updatePlayerZoneData(returning, true, true)
check.same("the rebuild re-announces the zone", fired(EFFECTIVE), 1)
check.same("carrying the live zone properties", Core.getEffectiveZone(returning).title, "West Point (closed)")

-- ---------------------------------------------------------------------------
check.section("a forced update still respects a handler's rewrite")

-- The RV mod rewrites stored.zone from OnPhysicalZoneChanged, and the effective
-- event has to be the one that goes out afterwards, carrying its value.
local seen = nil
Events[PHYSICAL].Add(function(_, stored)
    stored.zone = "_default"
end)
Events[EFFECTIVE].Add(function(_, stored)
    seen = stored.zone
end)

harness.events = {}
Core.updatePlayerZoneData(returning, true, true)
check.same("the effective event still fires", fired(EFFECTIVE), 1)
check.same("with the zone the handler put there", seen, "_default")

check.finish()
