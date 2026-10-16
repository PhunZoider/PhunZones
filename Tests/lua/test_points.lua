-- Zone geometry in the custom layer: deleting rects, including the last one.
--
-- Run: ..\PhunTestKit\run.cmd . points

local kit = require "phuntestkit"
local harness, check = kit.harness, kit.check

kit.installGlobals()

harness.transmitted = {}
ModData.add = function(name, data)
    harness.modData[name] = data
end
ModData.transmit = function(name)
    harness.transmitted[#harness.transmitted + 1] = name
end

_G.sendClientCommand = function()
end
_G.getPlayer = function()
    return {
        getUsername = function()
            return "tester"
        end
    }
end

_G.getActivatedMods = function()
    return {
        contains = function()
            return false
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

kit.addMod("PhunZones2")

require "PhunZones/core"
require "PhunZones/process"
local Core = PhunZones

kit.strip()

local function writeConfig(version, data, profiles)
    local out = {
        version = version,
        data = data or {}
    }
    if profiles then
        out.profiles = profiles
    end
    Core.tools.saveTable(Core.const.modifiedLuaFile, out)
end

local function reload()
    harness.transmitted = {}
    Core.updateZoneData()
end

local function rectCount(key)
    local zone = Core.data.lookup[key]
    return zone and zone.points and #zone.points or 0
end

-- ---------------------------------------------------------------------------
check.section("deleting a shipped zone's last rect sticks")

harness.reset()
writeConfig(4, {})
reload()
check.ok("MarchRidge ships with geometry", rectCount("MarchRidge") > 0, "no base rects")

Core.saveChanges({
    MarchRidge = {
        points = {}
    }
})
check.same("rects are gone after save", rectCount("MarchRidge"), 0)

reload()
check.same("rects stay gone after a reload", rectCount("MarchRidge"), 0)

-- ---------------------------------------------------------------------------
check.section("deleting one of several rects sticks")

harness.reset()
writeConfig(4, {})
reload()

Core.saveChanges({
    MarchRidge = {
        points = {{1, 2, 3, 4}}
    }
})
reload()
check.same("one rect left", rectCount("MarchRidge"), 1)
check.equal("it is the one kept", Core.data.lookup.MarchRidge.points[1], {1, 2, 3, 4})

-- ---------------------------------------------------------------------------
check.section("a profile can remove a zone's rects")

harness.reset()
writeConfig(4, {}, {
    closed = {
        MarchRidge = {
            points = {}
        }
    }
})
reload()
local before = rectCount("MarchRidge")
Core.setActiveProfile("closed")
check.same("no rects under the profile", rectCount("MarchRidge"), 0)
Core.setActiveProfile("none")
check.same("rects return without it", rectCount("MarchRidge"), before)

-- ---------------------------------------------------------------------------
check.section("pre-v4 empty lists are still a no-op")
-- Older saves wrote points = {} whenever only properties changed.

harness.reset()
writeConfig(4, {})
reload()
local shipped = rectCount("MarchRidge")

harness.reset()
writeConfig(3, {
    MarchRidge = {
        points = {},
        difficulty = 2
    }
}, {
    night = {
        MarchRidge = {
            points = {}
        }
    }
})
reload()
check.same("base rects survive a v3 empty list", rectCount("MarchRidge"), shipped)
check.same("the property change still applies", Core.data.lookup.MarchRidge.difficulty, 2)
Core.setActiveProfile("night")
check.same("a v3 profile's empty list is ignored too", rectCount("MarchRidge"), shipped)
Core.setActiveProfile("none")

Core.saveChanges({
    MarchRidge = {
        difficulty = 3
    }
})
local raw = Core.tools.loadTable(Core.const.modifiedLuaFile)
check.same("the next save writes v4", raw.version, 4)
check.same("without the legacy empty list", raw.data.MarchRidge.points, nil)

check.finish()
