require "PhunZones/core"

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
-- Normalise a mod name: ensure it always starts with "\".
-- Handles data saved before the UI auto-prepend was added.
local function normMod(m)
    return (m:sub(1, 1) == "\\" and m:sub(2)) or m
end

local function passesModFilter(zone)
    local activeMods = getActivatedMods()

    -- modsRequired: include only if at least one listed mod is active
    if zone.modsRequired then
        local mods = luautils.split(zone.modsRequired .. ";", ";")
        local found = false
        for _, m in ipairs(mods) do
            if m ~= "" and activeMods:contains(normMod(m)) then
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
            if m ~= "" and not activeMods:contains(normMod(m)) then
                return false
            end
        end
    end

    -- modsExcluded: exclude if any listed mod is active
    if zone.modsExcluded then
        local mods = luautils.split(zone.modsExcluded .. ";", ";")
        for _, m in ipairs(mods) do
            if m ~= "" and activeMods:contains(normMod(m)) then
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
--
-- addDefaultInherits (bool): when true, zones without an explicit `inherits`
-- get `inherits = "_default"` injected. Pass false for the custom/admin layer
-- so that absent `inherits` means "keep whatever the base layer says" rather
-- than "override with _default".
-- ---------------------------------------------------------------------------
function Core.normaliseFormat(zones, addDefaultInherits)
    local flat = {}
    for key, zone in pairs(zones) do
        if key == "_default" then
            flat["_default"] = Core.tools.shallowCopy(zone)
            flat["_default"].inherits = nil -- _default is the root; inheriting from anything would create a cycle
        else
            local entry = {}
            for k, v in pairs(zone) do
                if k ~= "subzones" and not LEGACY_FIELDS[k] then
                    entry[k] = v
                end
            end

            if addDefaultInherits and not entry.inherits and not entry.isolated then
                entry.inherits = "_default"
            end

            flat[key] = entry

            if zone.subzones then
                for subKey, sub in pairs(zone.subzones) do
                    local subEntry = Core.tools.shallowCopy(sub)
                    if addDefaultInherits and not subEntry.inherits then
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

    for k, v in pairs(base) do
        result[k] = Core.tools.shallowCopy(v)
    end

    for k, v in pairs(custom or {}) do
        if result[k] then
            for field, val in pairs(v) do
                if field == "points" and type(val) == "table" and #val == 0 then
                    -- preserve base points
                else
                    result[k][field] = val
                end
            end
        else
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
        if key == "_default" then
            filtered[key] = zone
        elseif zone.disabled then
            print("PhunZones: dropping zone '" .. key .. "' (disabled)")
        elseif passesModFilter(zone) then
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

-- ---------------------------------------------------------------------------
-- FLATTEN ZONE RECTS
-- Explodes every zone into its individual rects and sorts them by precedence,
-- highest first, which is what decides who wins where two zones overlap.
--
-- Anything that needs to reason about overlap has to consume this same list
-- rather than build its own. A zone with no explicit order gets one derived
-- from its position in pairs() iteration, and that is not stable between
-- calls, so two callers flattening separately would disagree about who is on
-- top of whom.
--
-- Each entry: {key, order, x1, y1, x2, y2}
-- ---------------------------------------------------------------------------
function Core.flattenZoneRects(zones)
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

    return flattened
end

-- flattened is optional. Pass the array from Core.flattenZoneRects when the
-- caller needs it too, so every view of precedence comes from one sort.
function Core.buildChunkMap(zones, flattened)
    flattened = flattened or Core.flattenZoneRects(zones)

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

-- Converts a v1 admin config into a v2-compatible flat data table.
-- v1 stored: deletions (region->zone->true) + nested subzones with many fields.
-- v2 stores:  flat zone keys, disabled=true tombstones, only points preserved.
local function migrateV1toV2(d)
    local result = {}

    -- Convert v1 deletions into disabled tombstones.
    -- v1 key "main" refers to the parent region zone itself.
    if d.deletions then
        for region, zones in pairs(d.deletions) do
            for zoneName, _ in pairs(zones) do
                local key = (zoneName == "main") and region or (region .. "_" .. zoneName)
                result[key] = {
                    disabled = true
                }
            end
        end
    end

    -- Flatten data: promote subzones to top level, strip all fields except points.
    if d.data then
        for key, zone in pairs(d.data) do
            local entry = result[key] or {}
            if zone.points then
                entry.points = zone.points
            end
            entry.inherits = "Medium"
            result[key] = entry

            if zone.subzones then
                for subKey, sub in pairs(zone.subzones) do
                    local subEntry = result[key .. "_" .. subKey] or {}
                    if sub.points then
                        subEntry.points = sub.points
                    end
                    subEntry.inherits = key
                    result[key .. "_" .. subKey] = subEntry
                end
            end
        end
    end

    return result
end

function Core.loadAdminConfig()
    if isClient() then
        -- Clients receive customisations via ModData, not from disk
        return ModData.get(Core.const.modifiedModData) or {}
    end

    local d = Core.tools.loadTable(Core.const.modifiedLuaFile)
    if d == nil then
        local legacy = getFileReader(Core.const.legacyLuaFile, false)
        if legacy then
            legacy:close()
            print("PhunZones: found legacy Lua config at ./lua/" .. Core.const.legacyLuaFile ..
                      "; convert it to JSON with the Phun config converter")
        else
            print("PhunZones: no customisation file found at ./lua/" .. Core.const.modifiedLuaFile ..
                      " (normal if no zones have been customised)")
        end
        ModData.add(Core.const.modifiedModData, {})
        Core.storeProfiles({})
        return {}
    end

    if d.data == nil then
        print("PhunZones: unexpected JSON format in ./lua/" .. Core.const.modifiedLuaFile .. ", skipping")
        ModData.add(Core.const.modifiedModData, {})
        Core.storeProfiles({})
        return {}
    end

    local data = d.data

    if d.version == 1 then
        print("PhunZones: detected v1 format in admin config, backing up to PhunZones_Old.json")
        Core.tools.saveTable("PhunZones_Old.json", d)
        print("PhunZones: migrating v1 admin config to v2 format")
        data = migrateV1toV2(d)
        d.version = 2
        Core.tools.saveTable(Core.const.modifiedLuaFile, {
            version = 2,
            data = data
        })
    end

    -- Store in ModData so it survives and is accessible for transmission
    ModData.add(Core.const.modifiedModData, data)

    -- v3 adds `profiles` alongside `data`. Absent in v1/v2 files, which load
    -- unchanged and simply have no profiles defined.
    local profiles = Core.storeProfiles(d.profiles)

    print("PhunZones: loaded customisations from ./lua/" .. Core.const.modifiedLuaFile)
    local count = 0
    for _ in pairs(profiles) do
        count = count + 1
    end
    if count > 0 then
        print("PhunZones: " .. count .. " profile(s) defined; active: " ..
                  (Core.getActiveProfile() or "none"))
    end
    return data
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

    if isClient() and not isCoopHost() then
        -- Send the full batch up to server in one command
        sendClientCommand(getPlayer(), Core.name, Core.commands.modifyZone, {
            changes = changes
        })
    else
        -- Persist full custom layer to disk
        Core.saveAdminConfig(custom)
        -- Sync clients. ModData.transmit is the only path that actually carries
        -- the data: clients rebuild from the full custom layer when it lands in
        -- OnReceiveGlobalModData. Sending zoneUpdated alongside it would race a
        -- second rebuild against the transmit, and a rebuild that ran on the
        -- pre-transmit data could evict a player from a zone that was just
        -- reopened. One path only.
        ModData.transmit(Core.const.modifiedModData)
        -- Reprocess locally once for the entire batch
        Core.updateZoneData()
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

    Core.debugLn("marking zone '" .. tostring(key) .. "' as disabled")

    -- Tombstone: disabled = true suppresses the zone in mergeLayers
    custom[key] = custom[key] or {}
    custom[key].disabled = true

    if not isClient() then
        Core.saveAdminConfig(custom)
    end

    ModData.add(Core.const.modifiedModData, custom)
    Core.updateZoneData()
end

-- ---------------------------------------------------------------------------
-- PROFILES
--
-- A profile is a named, sparse overlay applied on top of base+custom. It stores
-- only the fields it changes, so zones added to the shipped data and later edits
-- to the admin config both stay visible while a profile is active.
--
-- Definitions are authored in the `profiles` block of PhunZones.json. Which
-- profile is live is runtime state and lives in global ModData instead, so a
-- scheduled swap never rewrites the admin's file and the choice survives a
-- restart. Reverting is just activating nothing: the overlay is dropped and
-- every value recomputes from base+custom, so no prior value is ever captured.
-- ---------------------------------------------------------------------------

-- True on a dedicated server, a co-op host, or in singleplayer: anywhere that
-- is allowed to decide which profile is live. Pure clients are told.
local function isProfileAuthority()
    return not isClient() or isCoopHost()
end

function Core.getRuntime()
    local rt
    if isProfileAuthority() then
        -- getOrCreate registers the table as a global, which is what makes the
        -- active profile survive a restart.
        rt = ModData.getOrCreate(Core.const.runtimeModData)
    else
        rt = ModData.get(Core.const.runtimeModData)
        if type(rt) ~= "table" then
            rt = {}
            ModData.add(Core.const.runtimeModData, rt)
        end
    end
    if type(rt.profiles) ~= "table" then
        rt.profiles = {}
    end
    return rt
end

-- Replaces the authored profile definitions. Server side only; called as part
-- of reading the admin config.
function Core.storeProfiles(profiles)
    local rt = Core.getRuntime()
    rt.profiles = type(profiles) == "table" and profiles or {}

    -- An active profile renamed or deleted in the file since it was activated
    -- would otherwise stay active while applying nothing, which looks exactly
    -- like a broken overlay. Clear it loudly instead.
    if rt.profile and rt.profile ~= "" and not rt.profiles[rt.profile] then
        print("PhunZones: active profile '" .. tostring(rt.profile) ..
                  "' is no longer defined in the config, clearing it")
        rt.profile = ""
    end

    ModData.add(Core.const.runtimeModData, rt)
    return rt.profiles
end

-- Writes the admin config back to disk, carrying the authored profiles block
-- through untouched. Every writer must go through this: emitting a bare
-- { version, data } would silently delete every profile the admin has defined
-- the next time anyone edited a zone in the UI.
function Core.saveAdminConfig(data)
    local out = {
        version = 3,
        data = data
    }
    local profiles = Core.getRuntime().profiles
    if not Core.tools.isEmpty(profiles) then
        out.profiles = profiles
    end
    Core.tools.saveTable(Core.const.modifiedLuaFile, out)
end

-- Writes the current custom layer back out, picking up whatever the profiles
-- block now holds. Used by the profile mutators, which change the file's
-- profiles without touching its data.
function Core.persistAdminConfig()
    Core.saveAdminConfig(ModData.get(Core.const.modifiedModData) or {})
end

-- A profile name becomes a JSON object key and a /zoneprofile argument, and
-- PhunServer2's chat hook splits arguments on whitespace. Keep names to what
-- survives both.
function Core.isValidProfileName(name)
    return type(name) == "string" and name ~= "" and name:match("^[%w_%-]+$") ~= nil
end

-- Sorted list of defined profile names.
function Core.getProfileNames()
    local names = {}
    for name in pairs(Core.getRuntime().profiles) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

-- Name of the active profile, or nil when none is active.
function Core.getActiveProfile()
    local name = Core.getRuntime().profile
    if type(name) == "string" and name ~= "" then
        return name
    end
    return nil
end

-- The active profile's sparse overlay table, or nil when none is active.
function Core.getActiveProfileData()
    local name = Core.getActiveProfile()
    if not name then
        return nil
    end
    return Core.getRuntime().profiles[name]
end

-- Names that mean "no profile" when typed or scheduled. Case-insensitive.
local CLEAR_ALIASES = {
    none = true,
    default = true
}

function Core.isProfileClearAlias(name)
    return type(name) == "string" and CLEAR_ALIASES[name:lower()] == true
end

-- Activates a profile by name. nil, "", "none" or "default" clears it. Returns
-- true, or false plus a reason. Server/singleplayer only — clients ask via the
-- setProfile command.
function Core.setActiveProfile(name)
    if not isProfileAuthority() then
        return false, "setActiveProfile can only run on the server"
    end

    if name == nil then
        name = ""
    end
    if type(name) ~= "string" then
        return false, "profile name must be a string"
    end
    name = name:match("^%s*(.-)%s*$")

    local rt = Core.getRuntime()

    -- A defined profile always wins over the clearing aliases, so an admin who
    -- names one of theirs "default" can still reach it. Without this guard the
    -- alias would make that profile permanently unreachable.
    if name ~= "" and not rt.profiles[name] and Core.isProfileClearAlias(name) then
        name = ""
    end

    if name ~= "" and not rt.profiles[name] then
        return false, "no such profile '" .. name .. "'"
    end

    if (rt.profile or "") == name then
        return true
    end

    rt.profile = name
    ModData.add(Core.const.runtimeModData, rt)
    ModData.transmit(Core.const.runtimeModData)

    print("PhunZones: active profile is now " .. (name ~= "" and ("'" .. name .. "'") or "none"))

    -- Rebuild locally; clients rebuild when the transmitted table lands.
    Core.updateZoneData()
    return true
end

-- Creates an empty profile. Returns true, or false plus a reason.
function Core.createProfile(name)
    if not isProfileAuthority() then
        return false, "profiles can only be changed on the server"
    end
    if not Core.isValidProfileName(name) then
        return false, "profile names may use only letters, numbers, underscore and hyphen"
    end

    local rt = Core.getRuntime()
    if rt.profiles[name] then
        return false, "profile '" .. name .. "' already exists"
    end

    rt.profiles[name] = {}
    ModData.add(Core.const.runtimeModData, rt)
    Core.persistAdminConfig()
    ModData.transmit(Core.const.runtimeModData)
    return true
end

-- Deletes a profile. If it was the live one, that is cleared and the zone data
-- rebuilt, since the overlay it was applying has just gone away.
function Core.deleteProfile(name)
    if not isProfileAuthority() then
        return false, "profiles can only be changed on the server"
    end

    local rt = Core.getRuntime()
    if type(name) ~= "string" or not rt.profiles[name] then
        return false, "no such profile '" .. tostring(name) .. "'"
    end

    local wasActive = (rt.profile == name)
    rt.profiles[name] = nil
    if wasActive then
        rt.profile = ""
    end

    ModData.add(Core.const.runtimeModData, rt)
    Core.persistAdminConfig()
    ModData.transmit(Core.const.runtimeModData)

    if wasActive then
        Core.updateZoneData()
    end
    return true
end

-- Merges a change payload into rt.profiles[name], creating it if absent.
-- Shared by the authoritative save and the client's optimistic local copy.
function Core.applyProfileChanges(rt, name, changes)
    if not rt.profiles[name] then
        rt.profiles[name] = {}
    end
    local profile = rt.profiles[name]
    for zoneKey, fields in pairs(changes or {}) do
        profile[zoneKey] = profile[zoneKey] or {}
        for field, val in pairs(fields) do
            profile[zoneKey][field] = val
        end
    end
    return profile
end

-- Merges field changes into a profile, keyed by zone, creating the profile if
-- it does not exist. Same shape of payload as Core.saveChanges.
function Core.saveProfileChanges(name, changes)
    if not isProfileAuthority() then
        return false, "profiles can only be changed on the server"
    end
    if not Core.isValidProfileName(name) then
        return false, "invalid profile name '" .. tostring(name) .. "'"
    end
    if type(changes) ~= "table" or Core.tools.isEmpty(changes) then
        return true
    end

    local rt = Core.getRuntime()
    Core.applyProfileChanges(rt, name, changes)
    ModData.add(Core.const.runtimeModData, rt)
    Core.persistAdminConfig()
    ModData.transmit(Core.const.runtimeModData)

    -- Editing a profile that is not live must not change what players are
    -- currently experiencing, so only rebuild when this one is the active
    -- overlay. Editors pick the new definition up from the transmit either way.
    if Core.getActiveProfile() == name then
        Core.updateZoneData()
    end
    return true
end

-- ---------------------------------------------------------------------------
-- Client-safe entry points. On a pure client these ask the server; everywhere
-- else they apply directly. Callers (the editor, the chat command) use these so
-- they never have to branch on where they are running.
-- The server re-checks permissions, so a client request is a request, not a
-- decision. Returning true here means "sent", not "applied".
-- ---------------------------------------------------------------------------
local function isPureClient()
    return isClient() and not isCoopHost()
end

-- The client applies the change to its own copy before sending, the way
-- saveChanges already does for the custom layer. Without that, an editor that
-- creates a profile and switches to it finds nothing there until the server
-- replies. The server's transmit is still authoritative and overwrites this; if
-- the request is refused, the local copy is corrected when that lands.
function Core.requestProfileChanges(name, changes)
    if isPureClient() then
        local rt = Core.getRuntime()
        Core.applyProfileChanges(rt, name, changes)
        ModData.add(Core.const.runtimeModData, rt)
        sendClientCommand(getPlayer(), Core.name, Core.commands.modifyProfile, {
            profile = name,
            changes = changes
        })
        return true
    end
    return Core.saveProfileChanges(name, changes)
end

function Core.requestCreateProfile(name)
    if not Core.isValidProfileName(name) then
        return false, "profile names may use only letters, numbers, underscore and hyphen"
    end
    if Core.getRuntime().profiles[name] then
        return false, "profile '" .. name .. "' already exists"
    end
    if isPureClient() then
        local rt = Core.getRuntime()
        rt.profiles[name] = rt.profiles[name] or {}
        ModData.add(Core.const.runtimeModData, rt)
        sendClientCommand(getPlayer(), Core.name, Core.commands.createProfile, {
            profile = name
        })
        return true
    end
    return Core.createProfile(name)
end

function Core.requestDeleteProfile(name)
    if isPureClient() then
        local rt = Core.getRuntime()
        rt.profiles[name] = nil
        ModData.add(Core.const.runtimeModData, rt)
        sendClientCommand(getPlayer(), Core.name, Core.commands.removeProfile, {
            profile = name
        })
        return true
    end
    return Core.deleteProfile(name)
end

function Core.requestSetProfile(name)
    if isPureClient() then
        sendClientCommand(getPlayer(), Core.name, Core.commands.setProfile, {
            profile = name
        })
        return true
    end
    return Core.setActiveProfile(name)
end

-- ---------------------------------------------------------------------------
-- BUILD ZONE DATA
-- Runs the full processing pipeline and returns the result.
-- Does not store globally or trigger events.
-- filter: when false, skips mod filtering (useful for UI editor which
-- needs to see all zones including those excluded by current modset)
-- profileOverride: which profile to overlay.
--   nil    whatever is currently active — the live data
--   false  none, i.e. base+custom only
--   string that profile, whether or not it is active, so the editor can show
--          and mark up a profile it is editing without making it live
-- ---------------------------------------------------------------------------
function Core.buildZoneData(filter, profileOverride)

    local custom = Core.loadAdminConfig()
    local flatBase = Core.normaliseFormat(allLocations, true)
    -- Custom layer must NOT auto-inject inherits=_default: absent inherits means
    -- "keep whatever the base layer says", not "override parent to _default".
    local flatCustom = Core.normaliseFormat(custom, false)
    local merged = Core.mergeLayers(flatBase, flatCustom)

    local profileName
    if profileOverride == nil then
        profileName = Core.getActiveProfile()
    elseif type(profileOverride) == "string" and profileOverride ~= "" then
        profileName = profileOverride
    end

    -- The profile overlays base+custom with the same sparse-merge semantics as
    -- the custom layer, so it only changes the fields it actually names.
    local profile = profileName and Core.getRuntime().profiles[profileName] or nil
    if profile then
        merged = Core.mergeLayers(merged, Core.normaliseFormat(profile, false))
    end

    if filter then
        merged = Core.applyModFilter(merged)
    end

    local ordered = Core.assignOrders(merged)
    local lookup = Core.resolveInheritance(ordered)
    local flat = Core.flattenZoneRects(ordered)
    local cells = Core.buildChunkMap(ordered, flat)

    return {
        cells = cells,
        zones = ordered,
        lookup = lookup,
        -- Every zone rect in precedence order. Kept alongside the chunk map so
        -- callers that need to reason about overlap agree with getLocation.
        flat = flat,
        -- Which profile shaped this build, and its raw sparse layer, so an
        -- editor can tell a profile's own overrides apart from the ones
        -- underneath it.
        profile = profileName,
        profileLayer = profile
    }
end

-- ---------------------------------------------------------------------------
-- UPDATE ZONE DATA
-- Runs the pipeline, stores results globally, and triggers OnZonesUpdated.
-- This is the authoritative rebuild — call this on startup and after saves.
-- ---------------------------------------------------------------------------
function Core.updateZoneData()
    local result = Core.buildZoneData(true) -- always filter mods for live data
    Core.data = result
    triggerEvent(Core.events.OnDataBuilt, result)
    return result
end
