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
        OnZombieRemoved = "PhunZonesOnZombieRemoved"
    },
    const = {
        modifiedLuaFile = "PhunZones.lua",
        modifiedModData = "PhunZones",

        playerData = "PhunZonesPlayers"
    },
    ui = {},
    data = {},
    commands = {
        playerSetup = "PhunZonesPlayerSetup",
        modifyZone = "PhunZonesModifyZone",
        cleanPlayersZeds = "PhunZonescleanPlayersZeds",
        playerTeleport = "PhunZonesPlayerTeleport",
        teleportVehicle = "PhunZonesTeleportVehicle",
        deleteZone = "PhunZonesDeleteZone",
        updateEffectiveZone = "PhunZonesUpdateEffectiveZone"
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
            group = "combat"
        },
        mods = {
            label = "IGUI_PhunZones_Mods",
            type = "string",
            tooltip = "IGUI_PhunZones_Mods_tooltip",
            group = "general"
        },
        zeds = {
            label = "IGUI_PhunZones_Zeds",
            type = "boolean",
            tooltip = "IGUI_PhunZones_Zeds_tooltip",
            group = "combat"
        },
        bandits = {
            label = "IGUI_PhunZones_Bandits",
            type = "boolean",
            tooltip = "IGUI_PhunZones_Bandits_tooltip",
            group = "mods"
        },
        rv = {
            label = "IGUI_PhunZones_RVInteriors",
            type = "boolean",
            tooltip = "IGUI_PhunZones_RVInteriors_tooltip",
            group = "mods"
        },
        Announce = {
            label = "IGUI_PhunZones_NoWelcome",
            type = "boolean",
            tooltip = "IGUI_PhunZones_NoWelcome_tooltip",
            group = "general"
        },
        enabled = {
            label = "IGUI_PhunZones_Enabled",
            type = "boolean",
            tooltip = "IGUI_PhunZones_Enabled_tooltip",
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
    -- if Core.settings.Debug then
    print("[" .. Core.name .. "] " .. str)
    -- end
end

function Core.debug(...)
    -- if Core.settings.Debug then
    Core.tools.debug(Core.name, ...)
    -- end
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
-- Initialisation
-- ---------------------------------------------------------------------------

function Core:ini()
    if self.inied then
        return
    end
    self.inied = true

    if (Core.tools.isLocal or isServer()) then
        print("PhunZones: Loading changes as server")
        self:updateZoneData(true)
    else
        print("PhunZones: Loading changes as client")
        self:updateZoneData(true, ModData.getOrCreate(self.const.modifiedModData))
    end

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

-- Walks outward in expanding perimeter squares from (x, y) until a tile is
-- found whose zone key differs from restrictedZoneKey. Returns x, y, z or nil
-- if no safe tile is found within the search radius.
local function findNearestSafePosition(x, y, z, restrictedZoneKey)
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

-- lastAt is stored.at { zone, x, y, z } from the previous accepted tick —
-- used as the teleport-back target when access is denied.
-- If lastAt is itself inside the restricted zone (e.g. login after a
-- restriction was added), a spiral search finds the nearest safe tile instead.
function Core.enforceZoneAccess(obj, effectiveZone, lastAt)
    if effectiveZone.noplayers ~= true then
        return true
    end

    local tx, ty, tz
    local lastZone = lastAt and lastAt.x and Core.getLocation(lastAt.x, lastAt.y)
    if lastZone and lastZone.key ~= effectiveZone.key then
        tx, ty, tz = lastAt.x, lastAt.y, lastAt.z
    else
        tx, ty, tz = findNearestSafePosition(obj:getX(), obj:getY(), obj:getZ(), effectiveZone.key)
    end

    if not tx then
        return true -- zone fills entire search area; let player stay
    end

    local vehicle = obj.getVehicle and obj:getVehicle() or nil
    if vehicle then
        Core.teleportVehicleToCoords(obj, vehicle, tx, ty, tz)
    else
        Core.portPlayer(obj, tx, ty, tz)
    end

    if (isClient() or Core.isLocal) and instanceof(obj, "IsoPlayer") then
        obj:setHaloNote(getText("IGUI_PhunZones_SayNoPlayers"), 255, 0, 0, 300)
    end

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

        if stored.zone ~= oldZone then
            triggerEvent(Core.events.OnEffectiveZoneChanged, obj, stored)
        end
    end

    return stored
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
    return Core.getLocation(obj) or {}
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
-- ---------------------------------------------------------------------------

function Core.portPlayer(player, x, y, z)
    player:setX(x)
    player:setY(y)
    player:setZ(z)
end

-- ---------------------------------------------------------------------------
-- Zombie ID helper
-- ---------------------------------------------------------------------------

function Core.getZId(zedObj)
    if zedObj and instanceof(zedObj, "IsoZombie") and zedObj:isZombie() then
        if isClient() or isServer() then
            return tostring(zedObj:getOnlineID())
        else
            return tostring(zedObj:getID())
        end
    end
end
