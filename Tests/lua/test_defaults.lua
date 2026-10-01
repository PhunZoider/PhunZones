-- The shipped default zones (data.lua): shape checks, and precedence.
--
-- A sub-zone exists to override its parent where they overlap. If the parent
-- wins there instead, the sub-zone is silently dead: nothing errors, the
-- player just never sees it. So every rect of every zone is probed and must
-- not resolve to one of that zone's own ancestors.
--
-- Run: ..\PhunTestKit\run.cmd . defaults

local kit = require "phuntestkit"
local harness, check = kit.harness, kit.check

kit.installGlobals()

-- The kit's ModData stand-in covers get/getOrCreate; loading the admin config
-- also calls add and transmit.
ModData.add = function(name, data)
    harness.modData[name] = data
end
ModData.transmit = function()
end

-- Every mod counts as active, so mod-gated defaults are checked too.
_G.getActivatedMods = function()
    return {
        contains = function()
            return true
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
local defaults = require "PhunZones/data"

kit.strip()

local function build()
    Core.tools.saveTable(Core.const.modifiedLuaFile, {
        version = 3,
        data = {}
    })
    local data = Core.buildZoneData(false)
    Core.data = data
    Core.inied = true
    return data
end

local function isAncestor(zones, key, maybeAncestor)
    local seen = {}
    local cur = zones[key] and zones[key].inherits
    while cur and not seen[cur] do
        if cur == maybeAncestor then
            return true
        end
        seen[cur] = true
        cur = zones[cur] and zones[cur].inherits
    end
    return false
end

local function sortedKeys(t)
    local keys = {}
    for k in pairs(t) do
        keys[#keys + 1] = k
    end
    table.sort(keys)
    return keys
end

check.section("shape")

local bad = 0
for _, key in ipairs(sortedKeys(defaults)) do
    for i, r in ipairs(defaults[key].points or {}) do
        if not (r[1] <= r[3] and r[2] <= r[4]) then
            bad = bad + 1
            check.ok(key .. " rect " .. i .. " is not inverted", false, "{" .. table.concat(r, ",") .. "}")
        end
    end
end
check.ok("every default rect has x1 <= x2 and y1 <= y2", bad == 0)

bad = 0
for _, key in ipairs(sortedKeys(defaults)) do
    local parent = defaults[key].inherits
    if parent ~= nil and not defaults[parent] then
        bad = bad + 1
        check.ok(key .. " inherits an existing zone", false, "missing " .. tostring(parent))
    end
end
check.ok("every default inherits names a zone that exists", bad == 0)

check.section("precedence")

-- pairs() order feeds the implicit orders, so build several times: precedence
-- must not depend on it.
local failures = {}
for _ = 1, 5 do
    local data = build()
    for _, key in ipairs(sortedKeys(data.zones)) do
        for i, r in ipairs(data.zones[key].points or {}) do
            local hit = Core.getLocation(math.floor((r[1] + r[3]) / 2), math.floor((r[2] + r[4]) / 2))
            if hit and isAncestor(data.zones, key, hit.key) then
                failures[key .. " rect " .. i .. " covered by ancestor " .. hit.key] = true
            end
        end
    end
end
local failed = sortedKeys(failures)
for _, msg in ipairs(failed) do
    check.ok(msg, false)
end
check.ok("no default zone is covered by one of its own ancestors", #failed == 0)

-- The Phun cells overlap the RV void, which has no explicit order. Probe every
-- corner as well as the middle, since the overlap is only a strip in places.
check.section("phun cells beat the RV void")

failures = {}
for _ = 1, 5 do
    build()
    -- PhunInteriors registers its own zone at load now, with the same order,
    -- so it is not in these defaults and is skipped rather than failed.
    for _, key in ipairs({"PhunInteriors", "PhunRooms", "PhunSpawn_TaxiGarage"}) do
        for i, r in ipairs(defaults[key] and defaults[key].points or {}) do
            local probes = {{r[1], r[2]}, {r[3], r[2]}, {r[1], r[4]}, {r[3], r[4]},
                            {math.floor((r[1] + r[3]) / 2), math.floor((r[2] + r[4]) / 2)}}
            for _, p in ipairs(probes) do
                local hit = Core.getLocation(p[1], p[2])
                if not hit or hit.key ~= key then
                    failures[key .. " rect " .. i .. " at " .. p[1] .. "," .. p[2] .. " resolves to " ..
                        tostring(hit and hit.key)] = true
                end
            end
        end
    end
end
failed = sortedKeys(failures)
for _, msg in ipairs(failed) do
    check.ok(msg, false)
end
check.ok("every Phun cell resolves to its own zone", #failed == 0)

check.finish()
