-- PVP zones: turning zone data into the engine's NonPvpZone rectangles.
--
-- Run: ..\PhunTestKit\run.cmd . nopvp

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

-- Cell grid bounds, in cells. getMaxX is the last cell index, not one past it,
-- so this is a 56x56 cell map: tiles 0..16799 on both axes. Big enough to hold
-- the real zone data, which matters because a rect only prunes away as covered
-- if it actually sits inside the map.
local mapCells = {minX = 0, minY = 0, maxX = 55, maxY = 55}
local MAP_MIN, MAP_MAX = 0, 16799
_G.getWorld = function()
    return {
        getMetaGrid = function()
            return {
                getMinX = function() return mapCells.minX end,
                getMinY = function() return mapCells.minY end,
                getMaxX = function() return mapCells.maxX end,
                getMaxY = function() return mapCells.maxY end
            }
        end
    }
end

-- Stand-in for zombie.iso.areas.NonPvpZone. Only the four entry points the
-- feature uses, with the same half-open bounds the real getNonPvpZone applies.
local engineZones = {}
_G.NonPvpZone = {
    getAllZones = function()
        return {
            size = function()
                return #engineZones
            end,
            get = function(_, i)
                return engineZones[i + 1]
            end
        }
    end,
    addNonPvpZone = function(title, x1, y1, x2, y2)
        engineZones[#engineZones + 1] = {
            title = title,
            x1 = x1,
            y1 = y1,
            x2 = x2,
            y2 = y2,
            getTitle = function(self)
                return self.title
            end
        }
    end,
    removeNonPvpZone = function(title)
        for i, zone in ipairs(engineZones) do
            if zone.title == title then
                table.remove(engineZones, i)
                return
            end
        end
    end
}

kit.addMod("PhunZones2")

require "PhunZones/core"
require "PhunZones/process"
require "PhunZones/features/pvp"
local Core = PhunZones

kit.strip()

-- Explicit orders are spaced far apart on purpose. flattenZoneRects breaks
-- ties with the flatten index, so a gap smaller than the total number of rects
-- would not reliably decide which zone is on top.
local BASE_ORDER = 100000
local HOLE_ORDER = 200000

local function writeConfig(data)
    Core.tools.saveTable(Core.const.modifiedLuaFile, {
        version = 3,
        data = data or {}
    })
end

local function reload()
    engineZones = {}
    Core.updateZoneData()
    Core.inied = true
end

-- Is this tile inside the rects buildNoPvpRects produced? Inclusive bounds,
-- the same convention zone points use.
local function inRects(rects, x, y)
    for _, r in ipairs(rects) do
        if x >= r[2] and x <= r[4] and y >= r[3] and y <= r[5] then
            return true
        end
    end
    return false
end

-- Is this tile inside a zone we handed the engine? Half-open on the far edge,
-- matching NonPvpZone.getNonPvpZone.
local function inEngine(x, y)
    for _, zone in ipairs(engineZones) do
        if x >= zone.x1 and x < zone.x2 and y >= zone.y1 and y < zone.y2 then
            return true
        end
    end
    return false
end

-- Whether this tile should be safe. pvp is three-state, so unset falls back to
-- whatever the map-wide position works out to be.
local function shouldBeSafe(x, y)
    local zone = Core.getLocation(x, y)
    local pvp = zone and zone.pvp
    if pvp ~= nil then
        return pvp == false
    end
    return Core.isMapSafeByDefault()
end

-- The invariant worth testing: a tile is protected exactly when getLocation
-- says it is. Anything else means the two disagree about overlap somewhere.
local function sweep(label, x1, y1, x2, y2, step)
    local rects = Core.buildNoPvpRects()
    local rectMisses, engineMisses = 0, 0
    for x = x1, x2, step do
        for y = y1, y2, step do
            local want = shouldBeSafe(x, y)
            if inRects(rects, x, y) ~= want then
                rectMisses = rectMisses + 1
            end
            if inEngine(x, y) ~= want then
                engineMisses = engineMisses + 1
            end
        end
    end
    check.same(label .. ": rects agree with getLocation", rectMisses, 0)
    check.same(label .. ": engine zones agree with getLocation", engineMisses, 0)
end


-- ---------------------------------------------------------------------------
check.section("saying nothing changes nothing")
-- Installing the mod must not touch pvp on a server that has not asked.

harness.reset()
writeConfig({
    Town = {
        title = "Town",
        order = BASE_ORDER,
        points = {{600, 600, 699, 699}}
    }
})
reload()

check.same("the map is not safe by default", Core.isMapSafeByDefault(), false)
check.same("no rects are produced", #Core.buildNoPvpRects(), 0)
Core.refreshNoPvpZones()
check.same("nothing reaches the engine", #engineZones, 0)
check.ok("no map-wide zone appears from nowhere", not inEngine(1, 1))

-- ---------------------------------------------------------------------------
check.section("one safe zone on a pvp map")
-- pvp=false with nobody claiming a pvp zone: just that zone, no map-wide base.

harness.reset()
writeConfig({
    Town = {
        title = "Town",
        pvp = false,
        order = BASE_ORDER,
        points = {{600, 600, 699, 699}}
    }
})
reload()

check.same("still not safe by default", Core.isMapSafeByDefault(), false)

local rects = Core.buildNoPvpRects()
check.same("one rect out", #rects, 1)
check.same("it names its zone", rects[1][1], "Town")

Core.refreshNoPvpZones()
check.same("one engine zone registered", #engineZones, 1)

-- Zone points are inclusive and NonPvpZone is not, so the far edge has to move
-- out by one or the last row and column of the zone go unprotected.
check.ok("the far corner tile is covered", inEngine(699, 699))
check.ok("one tile past the corner is not", not inEngine(700, 700))
check.ok("the near corner tile is covered", inEngine(600, 600))
check.ok("one tile before the corner is not", not inEngine(599, 599))
check.ok("open map is untouched", not inEngine(1, 1))

sweep("lone safe zone", 590, 590, 710, 710, 3)

-- ---------------------------------------------------------------------------
check.section("marking a pvp zone makes the rest of the map safe")
-- The point of the feature: saying pvp happens here asserts it does not happen
-- elsewhere, because otherwise the mark would do nothing at all.

harness.reset()
writeConfig({
    Arena = {
        title = "Arena",
        pvp = true,
        order = HOLE_ORDER,
        points = {{640, 640, 659, 659}}
    }
})
reload()

check.same("the map is now safe by default", Core.isMapSafeByDefault(), true)
check.same("the arena itself is not", shouldBeSafe(650, 650), false)
check.same("open map is", shouldBeSafe(1, 1), true)

Core.refreshNoPvpZones()
check.ok("the arena is live", not inEngine(650, 650))
check.ok("the tile beside it is not", inEngine(639, 639))
check.ok("nor is the other side", inEngine(660, 660))
check.ok("open map is protected", inEngine(1, 1))
check.ok("so is the far corner of the grid", inEngine(MAP_MAX, MAP_MAX))
check.ok("one tile past the grid is not", not inEngine(MAP_MAX + 1, MAP_MAX + 1))

sweep("around the arena", 500, 500, 800, 800, 3)
sweep("across the map", MAP_MIN, MAP_MIN, MAP_MAX, MAP_MAX, 337)

-- ---------------------------------------------------------------------------
check.section("an explicit _default wins over the assertion")

harness.reset()
writeConfig({
    _default = {
        pvp = true
    },
    Arena = {
        title = "Arena",
        pvp = true,
        order = HOLE_ORDER,
        points = {{640, 640, 659, 659}}
    }
})
reload()

check.same("_default keeps the map hot", Core.isMapSafeByDefault(), false)
Core.refreshNoPvpZones()
check.same("nothing is registered", #engineZones, 0)
check.ok("open map is live", not inEngine(1, 1))

harness.reset()
writeConfig({
    _default = {
        pvp = false
    }
})
reload()

check.same("_default can ask for it outright", Core.isMapSafeByDefault(), true)
local wide = Core.buildNoPvpRects()
check.same("one rect covers everything", #wide, 1)
check.same("it comes from _default", wide[1][1], "_default")
check.same("it spans the cell grid", wide[1][2] .. "," .. wide[1][3] .. "," .. wide[1][4] .. "," .. wide[1][5],
    MAP_MIN .. "," .. MAP_MIN .. "," .. MAP_MAX .. "," .. MAP_MAX)

-- ---------------------------------------------------------------------------
check.section("a safe zone inside a pvp zone is protected again")
-- Map safe by assertion, arena carved out of it, vault carved back out of the
-- arena. Precedence decides, the same as every other property.

harness.reset()
writeConfig({
    Arena = {
        title = "Arena",
        pvp = true,
        order = HOLE_ORDER,
        points = {{640, 640, 659, 659}}
    },
    Vault = {
        title = "Vault",
        pvp = false,
        order = HOLE_ORDER + 100000,
        points = {{648, 648, 651, 651}}
    }
})
reload()

check.same("the vault reads as safe", shouldBeSafe(650, 650), true)
check.same("the arena around it does not", shouldBeSafe(645, 645), false)

Core.refreshNoPvpZones()
check.ok("the vault is protected", inEngine(650, 650))
check.ok("the arena around it is not", not inEngine(645, 645))
check.ok("open map still is", inEngine(1, 1))

sweep("nested zones", 600, 600, 700, 700, 1)

-- ---------------------------------------------------------------------------
check.section("reconciling is a no-op when nothing moved")

local before = #engineZones
local titles = {}
for _, zone in ipairs(engineZones) do
    titles[zone.title] = true
end

Core.refreshNoPvpZones()
check.same("count is unchanged", #engineZones, before)

local sameTitles = true
for _, zone in ipairs(engineZones) do
    if not titles[zone.title] then
        sameTitles = false
    end
end
check.ok("titles are unchanged", sameTitles)

-- ---------------------------------------------------------------------------
check.section("zones made by hand are left alone")

NonPvpZone.addNonPvpZone("Admin Safe House", 5000, 5000, 5100, 5100)
Core.refreshNoPvpZones()

local adminSurvived = false
for _, zone in ipairs(engineZones) do
    if zone.title == "Admin Safe House" then
        adminSurvived = true
    end
end
check.ok("the admin zone is still there", adminSurvived)

-- ---------------------------------------------------------------------------
check.section("clearing the marks takes the zones away")

harness.reset()
writeConfig({
    Arena = {
        title = "Arena",
        order = HOLE_ORDER,
        points = {{640, 640, 659, 659}}
    }
})
reload()
NonPvpZone.addNonPvpZone("Admin Safe House", 5000, 5000, 5100, 5100)
Core.refreshNoPvpZones()

check.same("only the admin zone is left", #engineZones, 1)
check.same("and it is the admin one", engineZones[1].title, "Admin Safe House")

-- ---------------------------------------------------------------------------
check.section("turning the option off hands the list back")

harness.reset()
writeConfig({
    Town = {
        title = "Town",
        pvp = false,
        order = BASE_ORDER,
        points = {{600, 600, 699, 699}}
    }
})
reload()
Core.refreshNoPvpZones()
check.ok("managed while the option is on", #engineZones > 0)

Core.settings.ManageNoPvpZones = false
Core.refreshNoPvpZones()
check.same("our zones are withdrawn", #engineZones, 0)

Core.settings.ManageNoPvpZones = nil
Core.refreshNoPvpZones()
check.ok("and come back when it is on again", #engineZones > 0)

-- ---------------------------------------------------------------------------
check.section("no map bounds means no invented cover")

harness.reset()
writeConfig({
    Arena = {
        title = "Arena",
        pvp = true,
        order = HOLE_ORDER,
        points = {{640, 640, 659, 659}}
    }
})
reload()

local realGetWorld = getWorld
_G.getWorld = function()
    return nil
end
local noBounds = Core.buildNoPvpRects()
_G.getWorld = realGetWorld

local invented = false
for _, rect in ipairs(noBounds) do
    if rect[1] == "_default" then
        invented = true
    end
end
check.ok("no _default rect is guessed at", not invented)

-- ---------------------------------------------------------------------------
check.section("singleplayer does not touch the list")

engineZones = {}
Core.isLocal = true
Core.refreshNoPvpZones()
check.same("nothing registered offline", #engineZones, 0)
Core.isLocal = false

check.finish()
