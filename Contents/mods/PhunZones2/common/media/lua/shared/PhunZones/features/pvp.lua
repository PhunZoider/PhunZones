require "PhunZones/core"

local Core = PhunZones

-- ---------------------------------------------------------------------------
-- PVP zones
--
-- Zones carry `pvp`, which is three-state: true means pvp happens here, false
-- means it does not, and unset means nobody has said. Unset is not the same as
-- false, because a zone that has never been thought about should not quietly
-- become a safe zone.
--
-- The engine's own concept is the inverse -- zombie.iso.areas.NonPvpZone, a
-- list of rectangles where pvp is refused -- so everything below is written in
-- the engine's terms and reads `pvp == false` as the thing worth registering.
-- We do not enforce any of it ourselves. Registering a rectangle puts the
-- restriction somewhere Lua cannot reach: CombatManager.checkPVP refuses the
-- swing on the attacker's client, Safety.isToggleAllowed stops anyone turning
-- their safety off while stood inside one, and AntiCheatSafety rejects
-- PlayerHitPlayer and VehicleHitPlayer packets server-side.
--
-- Two consequences worth knowing:
--
--   * The check is positional, so Core.isExempt cannot apply. There is no
--     player to test -- the engine only knows which tile the hit came from and
--     which tile it landed on. A safe zone is a safe zone for staff too.
--   * The server option PVP must be on. checkPVP bails on that before it ever
--     looks at zones, so all of this can only subtract pvp from a pvp server.
-- ---------------------------------------------------------------------------

-- Titles we own. Anything in the engine's list without this prefix was created
-- by an admin through the vanilla panel and is never touched.
local TITLE_PREFIX = "PhunZones_"

-- NonPvpZone.getNonPvpZone is a linear scan of the whole list, and it runs for
-- every pvp hit and once per player per tick. Carving holes out of overlapping
-- zones multiplies rects, so the result is capped rather than left to grow.
local MAX_RECTS = 512

-- Cells are 300 tiles square, and getMaxX/getMaxY give the index of the last
-- cell rather than one past it.
local CELL_SIZE = 300

-- ---------------------------------------------------------------------------
-- Rect subtraction
--
-- Zone precedence means a pvp zone can sit on top of a safe one, and
-- getLocation returns the higher zone's answer there. To match that, the hole
-- has to be cut out of the rect we hand the engine, which has no notion of
-- precedence and would otherwise protect the lot.
--
-- Coordinates are inclusive on all four sides here, matching zone points.
-- Appends the parts of a not covered by b to out, as up to four rects.
-- ---------------------------------------------------------------------------
local function subtractRect(a, b, out)
    local ax1, ay1, ax2, ay2 = a[1], a[2], a[3], a[4]
    local bx1, by1, bx2, by2 = b[1], b[2], b[3], b[4]

    -- No overlap: a survives whole
    if bx2 < ax1 or bx1 > ax2 or by2 < ay1 or by1 > ay2 then
        out[#out + 1] = {ax1, ay1, ax2, ay2}
        return out
    end

    -- Clip b to a so the bands below cannot run outside it
    local cx1 = math.max(ax1, bx1)
    local cy1 = math.max(ay1, by1)
    local cx2 = math.min(ax2, bx2)
    local cy2 = math.min(ay2, by2)

    -- Full-width band above the cut
    if cy1 > ay1 then
        out[#out + 1] = {ax1, ay1, ax2, cy1 - 1}
    end
    -- Full-width band below the cut
    if cy2 < ay2 then
        out[#out + 1] = {ax1, cy2 + 1, ax2, ay2}
    end
    -- Left of the cut, between the two bands
    if cx1 > ax1 then
        out[#out + 1] = {ax1, cy1, cx1 - 1, cy2}
    end
    -- Right of the cut, between the two bands
    if cx2 < ax2 then
        out[#out + 1] = {cx2 + 1, cy1, ax2, cy2}
    end

    return out
end

-- ---------------------------------------------------------------------------
-- Tile bounds of the whole map, inclusive, or nil if the cell grid is not up.
-- The grid is built during world load, which finishes before zone data is
-- first built on a running server.
-- ---------------------------------------------------------------------------
function Core.getMapBounds()
    local world = getWorld and getWorld()
    local grid = world and world.getMetaGrid and world:getMetaGrid()
    if not grid then
        return nil
    end

    local minX, minY = grid:getMinX(), grid:getMinY()
    local maxX, maxY = grid:getMaxX(), grid:getMaxY()
    if not (minX and minY and maxX and maxY) or maxX < minX or maxY < minY then
        return nil
    end

    return {minX * CELL_SIZE, minY * CELL_SIZE, (maxX + 1) * CELL_SIZE - 1, (maxY + 1) * CELL_SIZE - 1}
end

-- ---------------------------------------------------------------------------
-- Is the map safe everywhere nobody has said otherwise?
--
-- An explicit _default settles it either way. With _default unset, marking any
-- zone as pvp settles it instead: saying "pvp happens here" only means anything
-- if it does not happen elsewhere, so the rest of the map is asserted safe
-- rather than leaving the mark to do nothing at all.
--
-- Marking nothing leaves the engine list empty and the server's own PVP option
-- in charge, which is why installing the mod changes nothing on its own.
-- ---------------------------------------------------------------------------
function Core.isMapSafeByDefault()
    local data = Core.data
    if not (data and data.lookup) then
        return false
    end

    local root = data.lookup._default
    local rootPvp = root and root.pvp
    if rootPvp ~= nil then
        return rootPvp == false
    end

    for _, v in ipairs(data.flat or {}) do
        local zone = data.lookup[v[1]]
        if zone and zone.pvp == true then
            return true
        end
    end

    return false
end

-- ---------------------------------------------------------------------------
-- Drops rects that another rect already covers entirely. A map-wide base has
-- every zone that inherits from it sitting inside, and keeping those would
-- treble the list the engine scans on every hit while protecting nothing extra.
-- Rects arrive widest first, so one forward pass catches what matters.
-- ---------------------------------------------------------------------------
local function pruneCovered(rects)
    local kept = {}
    for _, rect in ipairs(rects) do
        local covered = false
        for _, other in ipairs(kept) do
            if rect[2] >= other[2] and rect[3] >= other[3] and rect[4] <= other[4] and rect[5] <= other[5] then
                covered = true
                break
            end
        end
        if not covered then
            kept[#kept + 1] = rect
        end
    end
    return kept
end

-- ---------------------------------------------------------------------------
-- Works out the rects to register, which are the areas where getLocation would
-- report no pvp.
--
-- Walks the same precedence-sorted rect list the chunk map is built from, so
-- overlap resolves the way it does everywhere else in the mod. Safe rects have
-- any higher-precedence pvp rect cut out of them.
--
-- Returns an array of {zoneKey, x1, y1, x2, y2}, inclusive.
-- ---------------------------------------------------------------------------
function Core.buildNoPvpRects()
    if not Core.inied then
        Core:ini()
    end

    local data = Core.data
    if not (data and data.flat and data.lookup) then
        return {}
    end

    local lookup = data.lookup
    local flat = data.flat
    local baseKey = nil

    -- _default owns no rects, so when the map is safe by default one covering
    -- it is synthesised and appended. Appended puts it at the bottom of the
    -- precedence order, which is exactly where _default sits everywhere else,
    -- with everything overriding it. The subtraction below then carves the pvp
    -- zones out of it with no special case of its own.
    if Core.isMapSafeByDefault() then
        local bounds = Core.getMapBounds()
        if bounds then
            baseKey = "_default"
            local widened = {}
            for i = 1, #flat do
                widened[i] = flat[i]
            end
            widened[#widened + 1] = {baseKey, 0, bounds[1], bounds[2], bounds[3], bounds[4]}
            flat = widened
        else
            print("[" .. Core.name .. "] pvp: the map should be safe by default but its bounds are not " ..
                      "available, so only zones explicitly set to pvp=false are covered.")
        end
    end

    -- Resolve each zone once. Lookup is by zone key and the same key turns up
    -- on every rect that zone owns. Unset does neither job: it neither asks for
    -- protection nor takes it away.
    local protects, cuts = {}, {}
    for _, v in ipairs(flat) do
        local key = v[1]
        if protects[key] == nil then
            local zone = lookup[key]
            local pvp = zone and zone.pvp
            protects[key] = key == baseKey or pvp == false
            cuts[key] = pvp == true
        end
    end

    -- Kept apart so that if the cap bites it takes the small zones rather than
    -- the cover over the rest of the map.
    local basePieces, zonePieces = {}, {}

    for i = 1, #flat do
        local v = flat[i]
        if protects[v[1]] then
            local pieces = {{v[3], v[4], v[5], v[6]}}

            -- Only rects above this one in precedence can take tiles from it,
            -- and only if they are pvp themselves.
            for j = 1, i - 1 do
                local higher = flat[j]
                if cuts[higher[1]] then
                    local cut = {higher[3], higher[4], higher[5], higher[6]}
                    local remaining = {}
                    for _, piece in ipairs(pieces) do
                        subtractRect(piece, cut, remaining)
                    end
                    pieces = remaining
                    if #pieces == 0 then
                        break
                    end
                end
            end

            local bucket = v[1] == baseKey and basePieces or zonePieces
            for _, piece in ipairs(pieces) do
                bucket[#bucket + 1] = {v[1], piece[1], piece[2], piece[3], piece[4]}
            end
        end
    end

    local combined = {}
    for _, bucket in ipairs({basePieces, zonePieces}) do
        for _, rect in ipairs(bucket) do
            combined[#combined + 1] = rect
        end
    end
    combined = pruneCovered(combined)

    local wanted = #combined
    local result = {}
    for _, rect in ipairs(combined) do
        if #result < MAX_RECTS then
            result[#result + 1] = rect
        end
    end

    if wanted > MAX_RECTS then
        print("[" .. Core.name .. "] pvp: needed " .. wanted .. " rects but the limit is " .. MAX_RECTS ..
                  ". The rest were dropped and those areas are NOT protected. Reduce the number of zones " ..
                  "overlapping your safe zones.")
    end

    return result
end

-- A rect's title is derived from its zone and its bounds, so a rebuild that did
-- not actually move anything produces the same titles and reconciles to a
-- no-op. That matters because adding a zone from a client sends a packet.
local function titleFor(rect)
    return TITLE_PREFIX .. rect[1] .. "_" .. rect[2] .. "_" .. rect[3] .. "_" .. rect[4] .. "_" .. rect[5]
end

-- ---------------------------------------------------------------------------
-- Brings the engine's zone list in line with rects, leaving any zone an admin
-- made by hand alone. Safe to call repeatedly.
--
-- Called on both sides. On the server this updates the authoritative list the
-- anti-cheat consults; on a client it updates the list checkPVP consults, which
-- is what actually stops the swing. NonPvpZone.addNonPvpZone broadcasts when
-- called from a client and the receiving end ignores a title it already holds,
-- so clients converge on each other cheaply.
-- ---------------------------------------------------------------------------
function Core.applyNoPvpZones(rects)
    if not NonPvpZone then
        return
    end

    local desired = {}
    for _, rect in ipairs(rects or {}) do
        desired[titleFor(rect)] = rect
    end

    local existing = {}
    local all = NonPvpZone.getAllZones()
    for i = 0, all:size() - 1 do
        local zone = all:get(i)
        local title = zone:getTitle()
        if type(title) == "string" and title:sub(1, #TITLE_PREFIX) == TITLE_PREFIX then
            existing[title] = true
        end
    end

    local added, removed = 0, 0

    for title in pairs(existing) do
        if not desired[title] then
            NonPvpZone.removeNonPvpZone(title)
            removed = removed + 1
        end
    end

    for title, rect in pairs(desired) do
        if not existing[title] then
            -- Zone points are inclusive; NonPvpZone tests x >= x1 and x < x2,
            -- so the far edge moves out by one to cover the same tiles.
            NonPvpZone.addNonPvpZone(title, rect[2], rect[3], rect[4] + 1, rect[5] + 1)
            added = added + 1
        end
    end

    if added > 0 or removed > 0 then
        Core.debugLn("pvp: " .. added .. " zone(s) added, " .. removed .. " removed")
    end
end

-- ---------------------------------------------------------------------------
-- Rebuilds the rect list from current zone data and applies it.
--
-- Skipped in singleplayer: CombatManager only consults these zones on a
-- multiplayer client, so offline the list would cost a scan per player tick and
-- buy nothing.
--
-- Returns the rects applied, so the server can forward them to clients.
-- ---------------------------------------------------------------------------
function Core.refreshNoPvpZones()
    if Core.isLocal then
        return {}
    end

    -- Turning the option off hands the engine's list back to the admin, so our
    -- own zones are cleared rather than left behind.
    local rects = Core.settings.ManageNoPvpZones ~= false and Core.buildNoPvpRects() or {}
    Core.applyNoPvpZones(rects)
    return rects
end
