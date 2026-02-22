require "PhunZones/core"
require "PhunLib/core"
local Core = PhunZones
local allLocations = require("PhunZones/data")

local getActivatedMods = getActivatedMods

local LEGACY_FIELDS = {
    region = true,
    zone = true
}
-- ---------------------------------------------------------------------------
-- MOD FILTER
-- Evaluates a zone's mod conditions against currently active mods.
-- Returns true if the zone should be included, false if it should be dropped.
--
-- Supported fields on a zone:
--   modsRequired = "mod1;mod2"   include if ANY of these mods are active
--   modsAllRequired = "mod1;mod2" include if ALL of these mods are active
--   modsExcluded = "mod1;mod2"   exclude if ANY of these mods are active
-- ---------------------------------------------------------------------------
local function passesModFilter(zone)
    local activeMods = getActivatedMods()

    -- modsRequired: include only if at least one listed mod is active
    if zone.modsRequired then
        local mods = luautils.split(zone.modsRequired .. ";", ";")
        local found = false
        for _, m in ipairs(mods) do
            if m ~= "" and activeMods:contains(m) then
                found = true
                break
            end
        end
        if not found then
            return false
        end
    end

    -- modsAllRequired: include only if every listed mod is active
    if zone.modsAllRequired then
        local mods = luautils.split(zone.modsAllRequired .. ";", ";")
        for _, m in ipairs(mods) do
            if m ~= "" and not activeMods:contains(m) then
                return false
            end
        end
    end

    -- modsExcluded: exclude if any listed mod is active
    if zone.modsExcluded then
        local mods = luautils.split(zone.modsExcluded .. ";", ";")
        for _, m in ipairs(mods) do
            if m ~= "" and activeMods:contains(m) then
                return false
            end
        end
    end

    return true
end

-- ---------------------------------------------------------------------------
-- NORMALISE FORMAT
-- Converts old nested subzone format into the new flat format with explicit
-- `inherits` fields. New-format configs pass through unchanged.
-- Safe to remove once old configs are no longer in circulation.
-- ---------------------------------------------------------------------------
function Core.normaliseFormat(zones)
    local flat = {}
    for key, zone in pairs(zones) do
        if key == "_default" then
            flat["_default"] = Core.tools.shallowCopy(zone)
        else
            -- Copy all non-subzone fields
            local entry = {}
            for k, v in pairs(zone) do
                if k ~= "subzones" and not LEGACY_FIELDS[k] then
                    entry[k] = v
                end
            end
            -- Implicit inheritance from _default unless explicitly isolated
            if not entry.inherits and not entry.isolated then
                entry.inherits = "_default"
            end
            flat[key] = entry

            -- Promote old-format subzones to top-level entries
            if zone.subzones then
                for subKey, sub in pairs(zone.subzones) do
                    local subEntry = Core.tools.shallowCopy(sub)
                    -- Inherit from parent zone unless overridden
                    if not subEntry.inherits then
                        subEntry.inherits = key
                    end
                    flat[key .. "_" .. subKey] = subEntry
                end
            end
        end
    end
    return flat
end

-- ---------------------------------------------------------------------------
-- MERGE LAYERS
-- Merges base (shipped defaults) with custom (admin config).
-- Admin values always win. Tombstones (disabled = true) suppress base entries.
-- Admin can introduce entirely new zones not present in base.
-- ---------------------------------------------------------------------------
function Core.mergeLayers(base, custom)
    local result = {}

    -- Start with a shallow copy of base
    for k, v in pairs(base) do
        result[k] = Core.tools.shallowCopy(v)
    end

    -- Apply admin customisations
    for k, v in pairs(custom or {}) do
        if v.disabled then
            -- Tombstone: suppress this zone entirely
            result[k] = nil
        elseif result[k] then
            -- Zone exists in base: merge admin fields over it
            for field, val in pairs(v) do
                if field == "points" and type(val) == "table" and #val == 0 then
                    -- empty points means "no geometry change", preserve base value
                    -- backward compat: old save format wrote empty points when only properties changed
                else
                    result[k][field] = val
                end
            end
        else
            -- New zone from admin, not in base
            result[k] = Core.tools.shallowCopy(v)
        end
    end

    return result
end

-- ---------------------------------------------------------------------------
-- APPLY MOD FILTER
-- Drops zones that fail their mod conditions.
-- Runs after merging layers so admin overrides are respected before filtering.
-- ---------------------------------------------------------------------------
function Core.applyModFilter(zones)
    local filtered = {}
    for key, zone in pairs(zones) do
        if key == "_default" or passesModFilter(zone) then
            filtered[key] = zone
        else
            print("PhunZones: dropping zone '" .. key .. "' (mod filter)")
        end
    end
    return filtered
end

-- ---------------------------------------------------------------------------
-- ASSIGN ORDERS
-- Ensures every zone has a deterministic numeric order value.
-- Children are always assigned a strictly higher order than their parent,
-- guaranteeing children take precedence over parents in spatial lookups.
-- Explicit `order` values on zones are honoured as a floor.
-- ---------------------------------------------------------------------------
function Core.assignOrders(zones)
    local assigned = {}
    local counter = 0

    -- Detect cycles before assigning to avoid infinite recursion
    local function hasCycle(key, visited, stack)
        if stack[key] then
            return true
        end
        if visited[key] then
            return false
        end
        visited[key] = true
        stack[key] = true
        local zone = zones[key]
        if zone and zone.inherits then
            if hasCycle(zone.inherits, visited, stack) then
                return true
            end
        end
        stack[key] = nil
        return false
    end

    for key, _ in pairs(zones) do
        if hasCycle(key, {}, {}) then
            print("PhunZones: cycle detected involving zone '" .. key .. "', breaking chain")
            if zones[key] then
                zones[key].inherits = nil
            end
        end
    end

    local function getOrder(key)
        if assigned[key] then
            return assigned[key]
        end
        local zone = zones[key]
        if not zone then
            return 0
        end

        local parentOrder = 0
        if zone.inherits and zones[zone.inherits] then
            parentOrder = getOrder(zone.inherits)
        end

        counter = counter + 1
        -- Honour explicit order as a floor, but always beat the parent
        local order = math.max(counter, parentOrder + 1)
        if zone.order then
            order = math.max(zone.order, parentOrder + 1)
        end
        assigned[key] = order
        return order
    end

    -- _default gets the lowest possible order (everything overrides it)
    assigned["_default"] = 0
    if zones["_default"] then
        zones["_default"].order = 0
    end

    for key, _ in pairs(zones) do
        if key ~= "_default" then
            getOrder(key)
        end
    end

    -- Write assigned orders back to zones
    for key, order in pairs(assigned) do
        if zones[key] then
            zones[key].order = order
        end
    end

    return zones
end

-- ---------------------------------------------------------------------------
-- RESOLVE INHERITANCE
-- Builds a fully resolved property set for each zone by walking the
-- inheritance chain from most-general to most-specific.
-- `points` and structural fields are never inherited.
-- Results are stored in a separate lookup table; raw zones are unchanged.
-- ---------------------------------------------------------------------------
local NEVER_INHERIT = {
    points = true,
    inherits = true,
    isolated = true,
    order = true,
    modsRequired = true,
    modsAllRequired = true,
    modsExcluded = true,
    disabled = true
}

function Core.resolveInheritance(zones)
    local resolved = {}

    local function resolve(key, stack)
        if resolved[key] then
            return resolved[key]
        end

        -- Cycle guard (should not occur after assignOrders, but belt-and-braces)
        if stack[key] then
            print("PhunZones: cycle during resolution at '" .. key .. "'")
            return {}
        end
        stack[key] = true

        local zone = zones[key]
        if not zone then
            return {}
        end

        local result = {}

        -- Layer in parent properties first
        if zone.inherits then
            local parent = resolve(zone.inherits, stack)
            for k, v in pairs(parent) do
                result[k] = v
            end
        end

        -- Layer in this zone's own properties (skipping structural fields)
        for k, v in pairs(zone) do
            if not NEVER_INHERIT[k] then
                result[k] = v
            end
        end

        -- Structural fields on the resolved entry come from the zone itself
        result.points = zone.points
        result.order = zone.order
        result.key = key

        resolved[key] = result
        stack[key] = nil
        return result
    end

    for key, _ in pairs(zones) do
        resolve(key, {})
    end

    return resolved
end

-- ---------------------------------------------------------------------------
-- BUILD CHUNK MAP
-- Groups zone rects by map chunk (300 unit cells) for fast spatial lookup.
-- Uses raw zone points, not resolved properties.
-- Each cell entry contains enough info to test point containment and
-- identify the zone for property lookup.
-- ---------------------------------------------------------------------------
local CHUNK_SIZE = 300

function Core.buildChunkMap(zones)
    -- Flatten all zone rects into a sortable array
    local flattened = {}
    local maxExplicitOrder = 0

    for key, zone in pairs(zones) do
        if key ~= "_default" and zone.points then
            if zone.order then
                maxExplicitOrder = math.max(maxExplicitOrder, zone.order)
            end
            for _, rect in ipairs(zone.points) do
                table.insert(flattened, {key, -- 1: zone key
                zone.order, -- 2: order (may be nil at this stage if called before assignOrders)
                rect[1], -- 3: x1
                rect[2], -- 4: y1
                rect[3], -- 5: x2
                rect[4] -- 6: y2
                })
            end
        end
    end

    -- Assign implicit order to any entries still missing it
    -- Entries with explicit order are pushed above all implicit ones
    for i, v in ipairs(flattened) do
        if not v[2] then
            v[2] = i
        else
            v[2] = i + maxExplicitOrder + v[2]
        end
    end

    -- Sort descending: highest order tested first (wins on overlap)
    table.sort(flattened, function(a, b)
        return a[2] ~= b[2] and a[2] > b[2]
    end)

    -- Build chunk map
    local cells = {}
    for _, v in ipairs(flattened) do
        local x1, y1, x2, y2 = v[3], v[4], v[5], v[6]
        local cx1 = math.floor(x1 / CHUNK_SIZE)
        local cy1 = math.floor(y1 / CHUNK_SIZE)
        local cx2 = math.floor(x2 / CHUNK_SIZE)
        local cy2 = math.floor(y2 / CHUNK_SIZE)

        for cx = cx1, cx2 do
            for cy = cy1, cy2 do
                local ckey = cx .. "_" .. cy
                if not cells[ckey] then
                    cells[ckey] = {}
                end
                -- Store: zone key + rect bounds (for point-in-rect test)
                table.insert(cells[ckey], {v[1], x1, y1, x2, y2})
            end
        end
    end

    return cells
end

-- ---------------------------------------------------------------------------
-- LOAD ADMIN CONFIG
-- Loads the admin customisation file from disk (server/SP only).
-- Returns empty table if missing or malformed.
-- ---------------------------------------------------------------------------
function Core.loadAdminConfig()
    if isClient() then
        -- Clients receive customisations via ModData, not from disk
        return {}
        -- return ModData.get(Core.const.modifiedModData) or {}
    end

    local d = Core.tools.loadTable(Core.const.modifiedLuaFile)
    if d == nil then
        print("PhunZones: no customisation file found at ./lua/" .. Core.const.modifiedLuaFile ..
                  " (normal if no zones have been customised)")
        return {}
    end

    if d.data == nil then
        print("PhunZones: unexpected format in ./lua/" .. Core.const.modifiedLuaFile .. ", skipping")
        return {}
    end

    -- Store in ModData so it survives and is accessible for transmission
    ModData.add(Core.const.modifiedDeletions, d.deletions or {})
    ModData.add(Core.const.modifiedModData, d.data or {})

    print("PhunZones: loaded customisations from ./lua/" .. Core.const.modifiedLuaFile)
    return d.data or {}
end

-- ---------------------------------------------------------------------------
-- SAVE CHANGES
-- Accepts a table of zone changes keyed by zone key.
-- Merges into the custom layer, persists, and syncs to clients.
-- Single zone changes are just a batch of one:
--   Core.saveChanges({ MarchRidge = { zeds = false } })
-- ---------------------------------------------------------------------------
function Core.saveChanges(changes)
    local hasChanges = false
    for _ in pairs(changes) do
        hasChanges = true
        break
    end
    if not hasChanges then
        return
    end

    -- Load existing custom layer
    local custom = ModData.get(Core.const.modifiedModData) or {}

    -- Merge all changes into the custom layer in one pass
    for key, zoneData in pairs(changes) do
        custom[key] = custom[key] or {}
        for field, val in pairs(zoneData) do
            custom[key][field] = val
        end
    end

    ModData.add(Core.const.modifiedModData, custom)

    if isClient() then
        -- Send the full batch up to server in one command
        sendClientCommand(getPlayer(), Core.name, Core.commands.modifyZone, {
            changes = changes
        })
    else
        -- Persist full custom layer to disk
        Core.tools.saveTable(Core.const.modifiedLuaFile, {
            version = 2,
            data = custom
        })
        -- Broadcast the batch to all clients in one command
        sendServerCommand(Core.name, Core.commands.zoneUpdated, {
            changes = changes
        })
        -- Reprocess locally once for the entire batch
        Core.updateZoneData(true)
    end
end

-- ---------------------------------------------------------------------------
-- ADD DELETION
-- Marks a zone as disabled in the admin config, persists to disk,
-- and triggers a rebuild.
-- ---------------------------------------------------------------------------
function Core.addDeletion(key)
    local custom = {}

    if not isClient() then
        local d = Core.tools.loadTable(Core.const.modifiedLuaFile)
        if d and d.data then
            custom = d.data
        end
    else
        custom = ModData.get(Core.const.modifiedModData) or {}
    end

    print("PhunZones: marking zone '" .. tostring(key) .. "' as disabled")

    -- Tombstone: disabled = true suppresses the zone in mergeLayers
    custom[key] = custom[key] or {}
    custom[key].disabled = true

    if not isClient() then
        Core.tools.saveTable(Core.const.modifiedLuaFile, {
            version = 2,
            data = custom
        })
    end

    ModData.add(Core.const.modifiedModData, custom)
    Core.updateZoneData(true)
end

-- ---------------------------------------------------------------------------
-- UPDATE ZONE DATA
-- Master pipeline. Runs the full processing chain and stores results.
-- Called on server/SP startup and after any config change.
-- `omitMods`: when true, applies mod filtering and stores data globally.
-- ---------------------------------------------------------------------------
function Core.updateZoneData(omitMods)
    -- 1. Select base dataset
    local base = Core.settings.LoadDefaults and allLocations or {
        ["_default"] = {
            title = "Kentucky",
            difficulty = 2
        }
    }

    -- 2. Load admin customisations
    local custom = Core.loadAdminConfig()

    -- 3. Merge layers (admin wins, tombstones applied)
    local merged = Core.mergeLayers(base, custom)

    -- 4. Normalise format (old subzone nesting → flat inherits)
    -- local flat = Core.normaliseFormat(merged)
    local flat = Core.normaliseFormat(merged)

    -- 5. Apply mod filter (drop zones that fail mod conditions)
    if omitMods then
        flat = Core.applyModFilter(flat)
    end

    -- 6. Assign deterministic orders (topological, children > parents)
    local ordered = Core.assignOrders(flat)

    -- 7. Resolve inheritance chains into effective property sets
    local lookup = Core.resolveInheritance(ordered)

    -- 8. Build spatial chunk map from raw geometry
    local cells = Core.buildChunkMap(ordered)

    -- 9. Store globally if this is the authoritative build (omitMods = true)
    if omitMods then
        Core.data = {
            cells = cells, -- chunk map for spatial lookup
            zones = ordered, -- raw flat zones (with orders baked in) — transmitted to clients
            lookup = lookup -- fully resolved property sets — built client-side too
        }
    end

    triggerEvent(Core.events.OnZonesUpdated)

    return {
        cells = cells,
        zones = ordered,
        lookup = lookup
    }
end

-- ---------------------------------------------------------------------------
-- POINT LOOKUP (CLIENT-SIDE)
-- Given world coordinates, returns the resolved zone the player is in.
-- Falls back to _default if no zone matches.
-- ---------------------------------------------------------------------------
function Core.getZoneAt(worldX, worldY)
    if not Core.data then
        return nil
    end

    local cx = math.floor(worldX / CHUNK_SIZE)
    local cy = math.floor(worldY / CHUNK_SIZE)
    local ckey = cx .. "_" .. cy

    local candidates = Core.data.cells[ckey]
    if candidates then
        -- Candidates are already sorted by descending order (highest priority first)
        for _, c in ipairs(candidates) do
            -- c = { zoneKey, x1, y1, x2, y2 }
            local key, x1, y1, x2, y2 = c[1], c[2], c[3], c[4], c[5]
            if worldX >= x1 and worldX <= x2 and worldY >= y1 and worldY <= y2 then
                return Core.data.lookup[key]
            end
        end
    end

    return Core.data.lookup["_default"]
end
