local allLocations = require("PhunZones/data")

PhunZones = {
    name = 'PhunZones',
    events = {
        OnPhunZoneReady = "PhunZonesOnPhunZoneReady",
        OnPhysicalZoneChanged = "PhunZonesOnPhysicalZoneChanged",
        OnEffectiveZoneChanged = "PhunZonesOnEffectiveZoneChanged",
        OnPhunZonesObjectLocationChanged = "PhunZonesOnPhunZonesObjectLocationChanged",
        OnPhunZoneWidgetClicked = "PhunZonesOnPhunZoneWidgetClicked",
        OnZonesUpdated = "PhunZonesOnZonesUpdated",
        OnZombieRemoved = "PhunZonesOnZombieRemoved",
        OnDataBuilt = "PhunZonesOnDataBuilt"
    },
    const = {
        modifiedLuaFile = "PhunZones.json",
        legacyLuaFile = "PhunZones.txt",
        modifiedModData = "PhunZones",
        -- Runtime (non-authored) state: the authored profile definitions plus
        -- which one is currently active. Lives in global ModData rather than the
        -- admin JSON file so scheduled profile swaps never rewrite their config.
        runtimeModData = "PhunZonesRuntime",

        playerData = "PhunZonesPlayers"
    },
    ui = {},
    data = {},
    commands = {
        playerSetup = "PhunZonesPlayerSetup",
        modifyZone = "PhunZonesModifyZone",
        playerTeleport = "PhunZonesPlayerTeleport",
        teleportVehicle = "PhunZonesTeleportVehicle",
        deleteZone = "PhunZonesDeleteZone",
        updateEffectiveZone = "PhunZonesUpdateEffectiveZone",
        evictZeds = "PhunZonesEvictZeds",
        removeZeds = "PhunZonesRemoveZeds",
        zoneUpdated = "PhunZonesZoneUpdated",
        setProfile = "PhunZonesSetProfile",
        modifyProfile = "PhunZonesModifyProfile",
        createProfile = "PhunZonesCreateProfile",
        removeProfile = "PhunZonesRemoveProfile",
        syncNoPvp = "PhunZonesSyncNoPvp"
    },
    tools = require("PhunZones/tools"),
    groups = {
        combat = {
            label = "Combat",
            order = 3
        },
        functionality = {
            label = "Functionality",
            order = 2
        },
        general = {
            label = "General",
            order = 1
        },
        mods = {
            label = "Mods",
            order = 4
        },
        other = {
            label = "Other",
            order = 10
        }
    },
    fields = {
        region = {
            label = "IGUI_PhunZones_Region",
            type = "string",
            tooltip = "IGUI_PhunZones_Region_tooltip",
            group = "general"
        },
        zone = {
            label = "IGUI_PhunZones_Zone",
            type = "string",
            tooltip = "IGUI_PhunZones_Zone_tooltip",
            group = "general"
        },
        title = {
            label = "IGUI_PhunZones_Title",
            type = "string",
            tooltip = "IGUI_PhunZones_Title_Tooltip",
            group = "general",
            order = 1
        },
        subtitle = {
            label = "IGUI_PhunZones_Subtitle",
            type = "string",
            tooltip = "IGUI_PhunZones_Subtitle_tooltip",
            group = "general",
            order = 2
        },
        difficulty = {
            label = "IGUI_PhunZones_Difficulty",
            type = "int",
            tooltip = "IGUI_PhunZones_Difficulty_tooltip",
            group = "combat",
            order = 1
        },
        modsRequired = {
            label = "IGUI_PhunZones_ModsRequired",
            type = "string",
            tooltip = "IGUI_PhunZones_ModsRequired_tooltip",
            group = "mods",
            -- Ensure every semicolon-separated mod name starts with "\".
            -- PZ text-entry widgets strip leading backslashes, so we re-add
            -- them automatically so the user doesn't need to type them.
            normalize = function(v)
                if type(v) ~= "string" then
                    return v
                end
                local result = {}
                for entry in (v .. ";"):gmatch("([^;]*);") do
                    entry = entry:match("^%s*(.-)%s*$")
                    if entry ~= "" then
                        if entry:sub(1, 1) ~= "\\" then
                            entry = "\\" .. entry
                        end
                        table.insert(result, entry)
                    end
                end
                local joined = table.concat(result, ";")
                return joined ~= "" and joined or nil
            end
        },
        zeds = {
            label = "IGUI_PhunZones_Zeds",
            type = "combo",
            tooltip = "IGUI_PhunZones_Zeds_tooltip",
            group = "combat",
            getOptions = function()
                return {{
                    label = getText("IGUI_PhunZones_ZedAction_None"),
                    value = "none"
                }, {
                    label = getText("IGUI_PhunZones_ZedAction_Move"),
                    value = "move"
                }, {
                    label = getText("IGUI_PhunZones_ZedAction_Remove"),
                    value = "remove"
                }}
            end
        },
        bandits = {
            label = "IGUI_PhunZones_Bandits",
            type = "combo",
            tooltip = "IGUI_PhunZones_Bandits_tooltip",
            group = "combat",
            getOptions = function()
                return {{
                    label = getText("IGUI_PhunZones_ZedAction_None"),
                    value = "none"
                }, {
                    label = getText("IGUI_PhunZones_ZedAction_Move"),
                    value = "move"
                }, {
                    label = getText("IGUI_PhunZones_ZedAction_Remove"),
                    value = "remove"
                }, {
                    label = getText("IGUI_PhunZones_ZedAction_NoSpawn"),
                    value = "nospawn"
                }}
            end
        },
        noannounce = {
            label = "IGUI_PhunZones_NoWelcome",
            type = "boolean",
            tooltip = "IGUI_PhunZones_NoWelcome_tooltip",
            group = "general"
        },
        nosafehouse = {
            label = "IGUI_PhunZones_NoSafeHouse",
            type = "boolean",
            tooltip = "IGUI_PhunZones_NoSafehouse_tooltip",
            group = "functionality"
        },
        nobuilding = {
            label = "IGUI_PhunZones_NoBuilding",
            type = "boolean",
            tooltip = "IGUI_PhunZones_NoBuilding_tooltip",
            group = "functionality"
        },
        noplacing = {
            label = "IGUI_PhunZones_NoPlacing",
            type = "boolean",
            tooltip = "IGUI_PhunZones_NoPlacing_tooltip",
            group = "functionality"
        },
        nopickup = {
            label = "IGUI_PhunZones_NoPickup",
            type = "boolean",
            tooltip = "IGUI_PhunZones_NoPickup_tooltip",
            group = "functionality"
        },
        noscrap = {
            label = "IGUI_PhunZones_NoScrap",
            type = "boolean",
            tooltip = "IGUI_PhunZones_NoScrap_tooltip",
            group = "functionality"
        },
        nodestruction = {
            label = "IGUI_PhunZones_NoDestruction",
            type = "boolean",
            tooltip = "IGUI_PhunZones_NoDestruction_tooltip",
            group = "functionality"
        },
        nofire = {
            label = "IGUI_PhunZones_NoFire",
            type = "boolean",
            tooltip = "IGUI_PhunZones_NoFire_tooltip",
            group = "functionality"
        },
        pvp = {
            label = "IGUI_PhunZones_Pvp",
            type = "boolean",
            tooltip = "IGUI_PhunZones_Pvp_tooltip",
            group = "combat"
        },
        noplayers = {
            label = "IGUI_PhunZones_NoPlayers",
            type = "boolean",
            tooltip = "IGUI_PhunZones_NoPlayers_tooltip",
            group = "functionality"
        },
        order = {
            label = "IGUI_PhunZones_Order",
            type = "int",
            tooltip = "IGUI_PhunZones_Order_tooltip"
        }
    }
}

local Core = PhunZones
Core.isLocal = Core.tools.isLocal
Core.settings = SandboxVars[Core.name] or {}

-- ---------------------------------------------------------------------------
-- Event registration
-- NOTE: The server-side triggerEvent implementation is a Java binding with a
-- fixed arity of 3 arguments (eventName, arg1, arg2). Do not call triggerEvent
-- with more than 3 arguments or it will throw at runtime on the server.
-- Any additional data should be bundled into arg1 or arg2 as nested fields.
-- ---------------------------------------------------------------------------
for _, event in pairs(Core.events or {}) do
    if not Events[event] then
        LuaEventManager.AddEvent(event)
    end
end

function Core.debugLn(str)
    if Core.settings.Debug then
        print("[" .. Core.name .. "] " .. str)
    end
end

function Core.debug(...)
    if Core.settings.Debug then
        Core.tools.debug(Core.name, ...)
    end
end

-- Always printed. For the cases an admin needs to find in the log without
-- having had Debug on beforehand: something we tried to do and could not.
function Core.logLn(str)
    print("[" .. Core.name .. "] " .. str)
end

-- ---------------------------------------------------------------------------
-- Cached module-level locals
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Settings
-- ---------------------------------------------------------------------------

function Core.getOption(name, default)
    local options = getSandboxOptions()
    if not options then
        return default
    end
    local n = Core.name .. "." .. name
    local opt = options:getOptionByName(n)
    local val = opt and opt:getValue()
    if val == nil then
        return default
    end
    return val
end

function Core.refreshSettings()
    Core.settings = SandboxVars[Core.name] or {}
end

-- ---------------------------------------------------------------------------
-- Staff exemption
--
-- When StaffExempt is on, staff walk through the "No ..." restrictions instead
-- of being blocked by them, so an admin can build, scrap or enter a zone they
-- have closed to players. The second option decides whether that reaches past
-- Admin to the lesser staff roles.
--
-- Matching is on the role's name, case-insensitively, which is the same thing
-- the EditorRole option does. A server with custom roles can therefore still
-- line up with these by naming a role after one of them.
-- ---------------------------------------------------------------------------
local EXEMPT_ADMIN = {
    admin = true
}
local EXEMPT_STAFF = {
    moderator = true,
    gm = true,
    overseer = true
}

local function roleNameOf(player)
    local role = player and player.getRole and player:getRole()
    local name = role and role.getName and role:getName()
    if type(name) == "string" and name ~= "" then
        return name:lower()
    end
    -- No role object. In singleplayer or on a co-op host there is one local
    -- player, so the global access level is the right answer for them; in
    -- multiplayer it would be the *viewer's* level, which is not, so it is only
    -- consulted where there is nobody else it could mean.
    if (Core.isLocal or isCoopHost()) and getAccessLevel then
        local level = getAccessLevel()
        if type(level) == "string" and level ~= "" then
            return level:lower()
        end
    end
    return nil
end

-- True when this player should be let through a zone's "No ..." restrictions.
function Core.isExempt(player)
    if not player or Core.settings.StaffExempt ~= true then
        return false
    end

    local name = roleNameOf(player)
    if not name then
        return false
    end
    if EXEMPT_ADMIN[name] then
        return true
    end
    return EXEMPT_STAFF[name] == true and Core.settings.ExemptModGM == true
end

-- ---------------------------------------------------------------------------
-- Zed / bandit actions
-- ---------------------------------------------------------------------------

-- Zones authored before the zeds/bandits combos moved from index values to
-- string values store "1"/"2"/"3". Both formats are read here so a config
-- saved by an older build keeps working without a migration pass.
local ZED_ACTION_MIGRATE = {
    ["1"] = "none",
    ["2"] = "move",
    ["3"] = "remove"
}

-- The action a zone asks for, as one of "none", "move" or "remove", plus
-- "nospawn" for bandits. field is "zeds" or "bandits". Anything unset or
-- unrecognised reads as "none", so callers only ever have to test the values
-- that mean something.
--
-- "nospawn" refuses new bandits in the zone but leaves alone any bandit that
-- walks in, so allies can follow a player there. It is bandit-only because
-- the bandit spawn is the only one we see before it happens; a zed spawn is
-- the engine's and can only be dealt with after the fact.
function Core.zedAction(zone, field)
    if not zone then
        return "none"
    end
    local v = zone[field]
    if v == nil then
        return "none"
    end
    local action = ZED_ACTION_MIGRATE[tostring(v)] or v
    if action == "move" or action == "remove" then
        return action
    end
    if action == "nospawn" and field == "bandits" then
        return action
    end
    return "none"
end

-- True when the action acts on something already in the zone, which is what
-- the per-zombie enforcement exists for. "nospawn" is settled at the spawn.
function Core.evicts(action)
    return action == "move" or action == "remove"
end

-- The action that applies to a bandit in this zone. A zone that says nothing at
-- all about bandits has no bandit rule of its own, so a bandit is treated as
-- the zombie it is and follows the zone's zeds setting. An explicit "none" is a
-- rule in its own right: it exempts bandits from that setting.
--
-- Note this reads the resolved zone, so a bandit value inherited from _default
-- counts as set. Only a chain that mentions bandits nowhere falls back.
function Core.banditAction(zone)
    if zone and zone.bandits ~= nil then
        return Core.zedAction(zone, "bandits")
    end
    return Core.zedAction(zone, "zeds")
end

-- ---------------------------------------------------------------------------
-- Initialisation
-- ---------------------------------------------------------------------------

function Core:ini()
    if self.inied then
        return
    end
    self.inied = true

    self:updateZoneData()

    triggerEvent(self.events.OnPhunZoneReady)
end

-- ---------------------------------------------------------------------------
-- Location lookup
-- ---------------------------------------------------------------------------

function Core.getLocation(x, y)
    if not Core.inied then
        Core:ini()
    end

    local xx, yy = x, y
    if not y and x.getX then
        -- Assume IsoObject or similar with getX/getY
        xx, yy = x:getX(), x:getY()
    end

    if Core.data and Core.data.cells then
        local ckey = math.floor(xx / 300) .. "_" .. math.floor(yy / 300)
        local test = Core.data.cells[ckey] or {}
        for _, v in ipairs(test) do
            -- v[1]=zone, v[2]=x1, v[3]=y1, v[4]=x2, v[5]=y2
            if xx >= v[2] and xx <= v[4] and yy >= v[3] and yy <= v[5] then
                return Core.data.lookup[v[1]]
            end
        end
    end

    return Core.data and Core.data.lookup and Core.data.lookup._default or nil
end

-- Returns an array of all resolved zone tables whose rects intersect (rx1,ry1)-(rx2,ry2).
-- Each zone appears at most once even if multiple rects overlap the query rect.
function Core.getIntersectingZones(rx1, ry1, rx2, ry2)
    if not Core.inied then
        Core:ini()
    end
    if not (Core.data and Core.data.cells) then
        return {}
    end

    local seen, result = {}, {}
    local cx1 = math.floor(rx1 / 300)
    local cy1 = math.floor(ry1 / 300)
    local cx2 = math.floor(rx2 / 300)
    local cy2 = math.floor(ry2 / 300)

    for cx = cx1, cx2 do
        for cy = cy1, cy2 do
            local entries = Core.data.cells[cx .. "_" .. cy]
            if entries then
                for _, v in ipairs(entries) do
                    -- v[1]=key v[2]=x1 v[3]=y1 v[4]=x2 v[5]=y2
                    -- standard AABB intersection: neither rect is fully to one side of the other
                    if not seen[v[1]] and v[4] >= rx1 and v[2] <= rx2 and v[5] >= ry1 and v[3] <= ry2 then
                        seen[v[1]] = true
                        table.insert(result, Core.data.lookup[v[1]])
                    end
                end
            end
        end
    end
    return result
end

-- Returns true if any zone in the array matches the property condition.
-- value omitted/nil → truthy check (good for boolean props like noplayers)
-- value provided     → equality check (good for combo props like zeds/bandits)
function Core.anyZoneHas(zones, prop, value)
    for _, zone in ipairs(zones) do
        local v = zone[prop]
        if value == nil then
            if v then
                return true
            end
        else
            if v == value then
                return true
            end
        end
    end
    return false
end

function Core.hasProp(x1, y1, x2, y2, prop, value)
    local zones = Core.getIntersectingZones(x1, y1, x2, y2)
    return Core.anyZoneHas(zones, prop, value)
end

-- ---------------------------------------------------------------------------
-- Zombie / object zone tracking
-- ---------------------------------------------------------------------------

function Core.updateObjectZoneData(obj, triggerChangeEvent)
    local modData = obj:getModData()
    if not modData.PhunZones then
        modData.PhunZones = {}
    end

    local existing = modData.PhunZones
    local newZone = Core.getLocation(obj) or {}
    local newId = Core.getZId(obj)

    modData.PhunZones = {
        zone = newZone.key,
        id = newId,
        checked = getTimestamp()
    }

    if triggerChangeEvent and (newId ~= existing.id or newZone.key ~= existing.zone) then
        triggerEvent(Core.events.OnPhunZonesObjectLocationChanged, obj, newZone)
    end

    return newZone
end

-- ---------------------------------------------------------------------------
-- Zone access enforcement — client-side only, returns false if player ejected
-- ---------------------------------------------------------------------------

-- Returns a position just outside the zone rect containing (x, y).
-- Fast path: looks up the containing rect directly and jumps to its nearest
-- edge in O(1). Falls back to a spiral search only when overlapping rects
-- of the same zone cover that edge tile.
function Core.findNearestSafePosition(x, y, z, restrictedZoneKey)
    -- Find the specific rect for this zone that contains (x, y)
    local ckey = math.floor(x / 300) .. "_" .. math.floor(y / 300)
    local rects = Core.data and Core.data.cells and Core.data.cells[ckey] or {}
    local x1, y1, x2, y2
    for _, v in ipairs(rects) do
        if v[1] == restrictedZoneKey and x >= v[2] and x <= v[4] and y >= v[3] and y <= v[5] then
            x1, y1, x2, y2 = v[2], v[3], v[4], v[5]
            break
        end
    end

    if x1 then
        -- Distance (in tiles) to clear each edge
        local dLeft = x - x1 + 1
        local dRight = x2 - x + 1
        local dTop = y - y1 + 1
        local dBot = y2 - y + 1
        local tx, ty
        local best = math.min(dLeft, dRight, dTop, dBot)
        if best == dLeft then
            tx, ty = x1 - 1, y
        elseif best == dRight then
            tx, ty = x2 + 1, y
        elseif best == dTop then
            tx, ty = x, y1 - 1
        else
            tx, ty = x, y2 + 1
        end
        -- Single check: verify the edge tile isn't inside an overlapping rect
        local check = Core.getLocation(tx, ty)
        if not check or check.key ~= restrictedZoneKey then
            return tx, ty, z
        end
        -- Overlapping rect covers that edge — fall through to spiral
    end

    -- Fallback spiral for degenerate/heavily-overlapping cases
    for radius = 1, 50 do
        for dx = -radius, radius do
            for dy = -radius, radius do
                if math.abs(dx) == radius or math.abs(dy) == radius then
                    local zone = Core.getLocation(x + dx, y + dy)
                    if not zone or zone.key ~= restrictedZoneKey then
                        return x + dx, y + dy, z
                    end
                end
            end
        end
    end
    return nil
end

-- Consecutive denied ticks per player, keyed by username. Resets whenever the
-- player is allowed through, or moves to a different restricted zone.
local denialStreak = {}

-- After this many consecutive failed relocations we conclude the vehicle
-- cannot be moved on this build and switch that player to brake-only mode for
-- as long as they stay in the zone. Also covers strategies that report success
-- but get snapped back by the physics step.
local VEHICLE_ATTEMPTS = 3

-- The same idea for a player on foot, which previously had no limit at all:
-- streak.count was counted but only ever read on the vehicle branch, so a move
-- that would not stick was retried every tick for as long as they stood there.
-- A move the engine cannot service does not become serviceable by repetition,
-- and repeating it is how a client ends up being thrown back and forth while
-- its chunks are still streaming.
local PLAYER_ATTEMPTS = 5

-- lastAt is stored.at { zone, x, y, z } from the previous accepted tick —
-- used as the teleport-back target when access is denied.
-- If lastAt is itself inside the restricted zone (e.g. login after a
-- restriction was added), or is not somewhere the engine can put anybody, a
-- spiral search finds the nearest safe tile instead.
-- Returns false when the player was moved (or could not be), true when they
-- are allowed to stay and the caller should record their position.
function Core.enforceZoneAccess(obj, effectiveZone, lastAt)
    local who = obj.getUsername and obj:getUsername() or tostring(obj)

    -- A port we issued for this player has not landed yet. Its hold loop owns
    -- their position until the destination chunk exists, and stacking a second
    -- move on an unfinished one is precisely what that loop exists to prevent.
    -- Mid-flight their coordinates are the destination while the square under
    -- them is still the origin, so there is nothing worth recording either.
    if Core.isPortPending(obj) then
        return false
    end

    if effectiveZone.noplayers ~= true or Core.isExempt(obj) then
        denialStreak[who] = nil
        return true
    end

    local function notify()
        if (isClient() or Core.isLocal) and instanceof(obj, "IsoPlayer") then
            obj:setHaloNote(getText("IGUI_PhunZones_SayNoPlayers"), 255, 0, 0, 300)
        end
    end

    local streak = denialStreak[who]
    if not streak or streak.zone ~= effectiveZone.key then
        streak = {
            zone = effectiveZone.key,
            count = 0,
            brakeOnly = false,
            stalled = false
        }
        denialStreak[who] = streak
    end
    streak.count = streak.count + 1

    local vehicle = obj.getVehicle and obj:getVehicle() or nil

    -- Vehicle relocation has already proven unavailable for this player in
    -- this zone. Stall the vehicle and warn, but leave them at the wheel so
    -- they can drive back out — ejecting them here is what strands the car.
    if vehicle and streak.brakeOnly then
        Core.brakeVehicle(vehicle)
        notify()
        return false
    end

    -- On foot, and repeated moves have not got them out of this zone. Warn but
    -- stop teleporting: the zone going unenforced for one player is a smaller
    -- problem than a client being moved every tick indefinitely. Resets the
    -- moment they change zone or are let through.
    if not vehicle and streak.stalled then
        notify()
        return false
    end
    if not vehicle and streak.count > PLAYER_ATTEMPTS then
        streak.stalled = true
        Core.logLn("enforceZoneAccess: could not move " .. who .. " out of " .. tostring(effectiveZone.key) .. " in " ..
                       PLAYER_ATTEMPTS .. " attempts; leaving them where they are")
        notify()
        return false
    end

    local tx, ty, tz
    -- Recall them to where they came from, but only somewhere the engine can
    -- actually put them: an off-world target moves them for a frame and is
    -- then undone, which reads here as another failed attempt. The nearest
    -- edge of the zone is a few tiles away and is always real ground.
    local lastZone = lastAt and lastAt.x and Core.isValidWorldPosition(lastAt.x, lastAt.y) and
                         Core.getLocation(lastAt.x, lastAt.y)
    if lastZone and lastZone.key ~= effectiveZone.key then
        tx, ty, tz = lastAt.x, lastAt.y, lastAt.z
    else
        tx, ty, tz = Core.findNearestSafePosition(obj:getX(), obj:getY(), obj:getZ(), effectiveZone.key)
    end

    if not tx then
        denialStreak[who] = nil
        return true -- zone fills entire search area; let player stay
    end

    if vehicle then
        -- Move the vehicle if we can. teleportVehicleToCoords verifies the
        -- vehicle actually landed near the target, so a silently-unsupported
        -- engine API reports false rather than looking like a success.
        if not Core.teleportVehicleToCoords(obj, vehicle, tx, ty, tz) then
            Core.brakeVehicle(vehicle)
            if streak.count >= VEHICLE_ATTEMPTS then
                streak.brakeOnly = true
                Core.debugLn("enforceZoneAccess: cannot relocate vehicle for " .. who .. ", falling back to brake-only")
            end
        end
    else
        Core.portPlayer(obj, tx, ty, tz)
    end

    notify()
    return false
end

-- ---------------------------------------------------------------------------
-- Player zone tracking
-- ---------------------------------------------------------------------------

function Core.updatePlayerZoneData(obj, triggerChangeEvent, force)
    local modData = obj:getModData()
    if not modData.PhunZones or not modData.PhunZones.at then
        modData.PhunZones = {
            zone = nil,
            at = {}
        }
    end

    local stored = modData.PhunZones
    local vehicle = obj.getVehicle and obj:getVehicle() or nil

    local function currentPos()
        return vehicle and {
            x = vehicle:getX(),
            y = vehicle:getY(),
            z = vehicle:getZ()
        } or {
            x = obj:getX(),
            y = obj:getY(),
            z = obj:getZ()
        }
    end

    local newPhysical = Core.getLocation(obj) or {}
    local physicalChanged = newPhysical.key ~= stored.at.zone

    if not force and not physicalChanged then
        -- No zone change — keep coords fresh
        local pos = currentPos()
        stored.at.x, stored.at.y, stored.at.z = pos.x, pos.y, pos.z
        return stored
    end

    -- Enforce on the incoming physical zone
    if not Core.enforceZoneAccess(obj, newPhysical, stored.at) then
        return stored
    end

    -- Accepted — record previous effective zone, update at, default display zone to physical
    local oldZone = stored.zone
    local pos = currentPos()
    stored.at = {
        zone = newPhysical.key,
        x = pos.x,
        y = pos.y,
        z = pos.z
    }
    stored.zone = newPhysical.key

    if triggerChangeEvent then
        triggerEvent(Core.events.OnPhysicalZoneChanged, obj, stored)
        -- ^ handlers (e.g. RV mod) may mutate stored.zone in-place

        -- force means something other than the player's position changed:
        -- fresh zone data, or a login where the stored zone key already matches
        -- where the player stands. Comparing keys skips the event in exactly
        -- those cases, which leaves the UI showing whatever it was last given
        -- (nothing, on a relog) until the player next crosses a boundary.
        if force or stored.zone ~= oldZone then
            triggerEvent(Core.events.OnEffectiveZoneChanged, obj, stored)
        end
    end

    return stored
end

-- Returns the live zone properties table for obj's display zone.
-- Falls back to getLocation if moddata is not yet initialised.
function Core.getPhysicalZone(obj)
    local md = obj and obj.getModData and obj:getModData()
    local stored = md and md.PhunZones
    if stored and stored.at and stored.at.zone then
        return Core.data.lookup[stored.at.zone] or {}
    end
    return obj and obj.getX and Core.getLocation(obj:getX(), obj:getY()) or {}
end

-- ---------------------------------------------------------------------------
-- Effective zone helpers
-- ---------------------------------------------------------------------------

-- Returns the live zone properties table for obj's display zone.
-- Falls back to getLocation if moddata is not yet initialised.
function Core.getEffectiveZone(obj)
    local md = obj and obj.getModData and obj:getModData()
    local stored = md and md.PhunZones
    if stored and stored.zone then
        return Core.data.lookup[stored.zone] or {}
    end
    return obj and obj.getX and Core.getLocation(obj:getX(), obj:getY()) or {}
end

-- External push: set obj's display zone and fire OnEffectiveZoneChanged.
-- Called by mods (e.g. RV system) when the display zone changes independently
-- of physical movement (e.g. vehicle drives into a new zone while player is offmap).
function Core.setEffectiveZone(obj, zoneKey)
    local md = obj and obj.getModData and obj:getModData()
    if not md then
        return
    end
    if not md.PhunZones or not md.PhunZones.at then
        md.PhunZones = {
            zone = nil,
            at = {}
        }
    end
    local stored = md.PhunZones
    if stored.zone == zoneKey then
        return
    end
    stored.zone = zoneKey
    triggerEvent(Core.events.OnEffectiveZoneChanged, obj, stored)
end

-- ---------------------------------------------------------------------------
-- Public dispatcher — maintains backward-compatible entry point
-- ---------------------------------------------------------------------------

function Core.updateModData(obj, triggerChangeEvent, force)
    if not obj or not obj.getModData then
        return
    end

    if not instanceof(obj, "IsoPlayer") then
        return Core.updateObjectZoneData(obj, triggerChangeEvent)
    else
        return Core.updatePlayerZoneData(obj, triggerChangeEvent, force)
    end
end

-- ---------------------------------------------------------------------------
-- Player teleport
--
-- setX/setY/setZ move the player immediately, but the destination chunk is not
-- loaded yet and the engine restores anyone standing on a square that does not
-- exist. A single call therefore looks like it worked and then undoes itself a
-- frame later. Worse, the bare setters skip the bookkeeping teleportTo does
-- (last position, square rebinding), so a long move leaves the character
-- interpolating from wherever it used to be.
--
-- Both matter most in exactly the case that bites: someone is teleported into
-- a noplayers zone, and a tick later we throw them back the way they came,
-- across chunks the engine is still streaming in one direction and dropping in
-- the other.
--
-- So: use the vanilla teleport, then re-assert the position every tick until
-- the destination square actually exists. Re-teleporting is also what keeps
-- the chunk map centred on the destination, which is what makes it stream in.
-- This is the same approach PhunInteriors uses to move players across the map.
-- ---------------------------------------------------------------------------

-- Frames to keep re-asserting before concluding the destination is never going
-- to load. Roughly three seconds; a chunk that has not arrived by then is not
-- coming, and holding a player in limbo indefinitely is worse than giving up.
local PORT_HOLD_TICKS = 180

-- [username] = { player, x, y, z, ticks }. Keyed rather than singular so
-- split-screen holds each local player's port independently.
local portPending = {}
local portHolding = false
local holdPorts

local function portKey(player)
    return (player.getUsername and player:getUsername()) or tostring(player)
end

-- True while a port issued for this player has not landed yet. Callers must
-- not issue another move for them while this holds: the hold loop owns their
-- position until the destination chunk exists or it gives up.
function Core.isPortPending(player)
    return player ~= nil and portPending[portKey(player)] ~= nil
end

local function clearPort(key)
    portPending[key] = nil
    if portHolding and Core.tools.isEmpty(portPending) then
        portHolding = false
        Events.OnTick.Remove(holdPorts)
    end
end

local function squareLoaded(x, y, z)
    local cell = getCell()
    return cell ~= nil and cell:getGridSquare(x, y, z) ~= nil
end

-- Refuses coordinates that are not part of this world. The meta grid is
-- written when the world is created, so a map added to an existing save is in
-- the mod list but not in the world. Teleporting there moves the player for a
-- frame and the engine then restores them, which is indistinguishable from a
-- port that never landed and would burn the whole hold window every time.
function Core.isValidWorldPosition(x, y)
    local world = getWorld and getWorld()
    local grid = world and world.getMetaGrid and world:getMetaGrid()
    if not grid or not grid.isValidSquare then
        return true -- cannot tell on this build; let it through
    end
    -- Callers pass live player coordinates as often as tile indices, and the
    -- grid is indexed in whole squares.
    return grid:isValidSquare(math.floor(x), math.floor(y)) == true
end

-- The move itself. teleportTo is the vanilla path and does the bookkeeping the
-- bare setters skip. The half tile centres the player on the square rather
-- than dropping them on its corner, where they can read as being on either of
-- two tiles -- and therefore, on a zone boundary, in either of two zones.
local function place(player, x, y, z)
    if player.teleportTo then
        player:teleportTo(x + 0.5, y + 0.5, z)
        return
    end
    -- Builds without teleportTo. setLx/Ly/Lz are the part that matters here:
    -- left pointing at the old position, the character interpolates towards
    -- the new one from wherever it was, across the whole map if need be.
    player:setX(x + 0.5)
    player:setY(y + 0.5)
    player:setZ(z)
    if player.setLx then
        player:setLx(x + 0.5)
        player:setLy(y + 0.5)
        player:setLz(z)
    end
end

function holdPorts()
    for key, port in pairs(portPending) do
        local player = port.player
        if not player then
            clearPort(key)
        else
            port.ticks = port.ticks + 1
            local landed = squareLoaded(port.x, port.y, port.z) and math.floor(player:getX()) == port.x and
                               math.floor(player:getY()) == port.y

            if landed then
                Core.debugLn(string.format("port: %s landed at %d,%d,%d after %d tick(s)", key, port.x, port.y, port.z,
                    port.ticks))
                clearPort(key)
            elseif port.ticks >= PORT_HOLD_TICKS then
                Core.logLn(string.format(
                    "port: gave up moving %s to %d,%d,%d after %d ticks; the square %s and they are at %s,%s", key,
                    port.x, port.y, port.z, port.ticks,
                    squareLoaded(port.x, port.y, port.z) and "loaded but they never arrived" or "never loaded",
                    tostring(player:getX()), tostring(player:getY())))
                clearPort(key)
            else
                place(player, port.x, port.y, port.z)
            end
        end
    end
end

-- Returns true if a move was issued (or handed to the owning client).
function Core.portPlayer(player, x, y, z)
    if not player or not x or not y then
        return false
    end

    local tx, ty, tz = math.floor(x), math.floor(y), math.floor(z or 0)

    if not Core.isValidWorldPosition(tx, ty) then
        Core.logLn(string.format("port: refusing to move %s to %d,%d, which is outside this world", portKey(player), tx,
            ty))
        return false
    end

    -- On a dedicated server this is a remote player: moving them from here
    -- fights the position their own client is authoritative for, and there is
    -- no local cell to wait on either. The client owns the move, so ask it to
    -- make one and let its hold loop see it through.
    if isServer() then
        sendServerCommand(player, Core.name, Core.commands.playerTeleport, {
            username = player:getUsername(),
            x = tx,
            y = ty,
            z = tz
        })
        return true
    end

    place(player, tx, ty, tz)

    portPending[portKey(player)] = {
        player = player,
        x = tx,
        y = ty,
        z = tz,
        ticks = 0
    }
    if not portHolding then
        portHolding = true
        Events.OnTick.Add(holdPorts)
    end

    return true
end

-- ---------------------------------------------------------------------------
-- Zombie ID helper
-- ---------------------------------------------------------------------------
-- I suppose getOnlineID is no longer a thing in B42.17
local testForOnlineId = getCore():getGameVersion():getMajor() == 42 and getCore():getGameVersion():getMinor() < 17 and
                            (isClient() or isServer() or isCoopHost())

function Core.getZId(zed)
    if zed then
        if instanceof(zed, "IsoZombie") then
            if zed:isZombie() then

                if testForOnlineId then
                    return tostring(zed:getOnlineID())
                else
                    return tostring(zed:getID())
                end

            end
        end
    end
end
