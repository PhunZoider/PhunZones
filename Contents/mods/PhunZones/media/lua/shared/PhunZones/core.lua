local allLocations = require("PhunZones/data")

PhunZones = {
    name = 'PhunZones',
    events = {
        OnPhunZoneReady = "PhunZonesOnPhunZoneReady",
        OnPhunZonesPlayerLocationChanged = "PhunZonesOnPhunZonesPlayerLocationChanged",
        OnPhunZonesObjectLocationChanged = "PhunZonesOnPhunZonesObjectLocationChanged",
        OnPhunZoneWidgetClicked = "PhunZonesOnPhunZoneWidgetClicked",
        OnZonesUpdated = "PhunZonesOnZonesUpdated",
        OnZombieRemoved = "PhunZonesOnZombieRemoved"
    },
    const = {
        modifiedLuaFile = "PhunZones.lua",
        modifiedModData = "PhunZones",
        modifiedDeletions = "PhunZonesDeletions",
        playerData = "PhunZonesPlayers",
        trackedVehicles = "PhunZonesTrackedVehicles"
    },
    extended = {},
    ui = {},
    data = {},
    commands = {
        playerSetup = "PhunZonesPlayerSetup",
        modifyZone = "PhunZonesModifyZone",
        cleanPlayersZeds = "PhunZonescleanPlayersZeds",
        playerTeleport = "PhunZonesPlayerTeleport",
        teleportVehicle = "PhunZonesTeleportVehicle",
        deleteZone = "PhunZonesDeleteZone"
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
            disableOnEdit = true,
            group = "general"
        },
        zone = {
            label = "IGUI_PhunZones_Zone",
            type = "string",
            tooltip = "IGUI_PhunZones_Zone_tooltip",
            disableOnEdit = true,
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
            trueIsNil = true,
            group = "combat"
        },
        bandits = {
            label = "IGUI_PhunZones_Bandits",
            type = "boolean",
            tooltip = "IGUI_PhunZones_Bandits_tooltip",
            trueIsNil = true,
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
            trueIsNil = true,
            group = "general"
        },
        safehouse = {
            label = "IGUI_PhunZones_SafeHouse",
            type = "boolean",
            tooltip = "IGUI_PhunZones_Safehouse_tooltip",
            trueIsNil = true,
            group = "functionality"
        },
        building = {
            label = "IGUI_PhunZones_Building",
            type = "boolean",
            tooltip = "IGUI_PhunZones_Building_tooltip",
            trueIsNil = true,
            group = "functionality"
        },
        placing = {
            label = "IGUI_PhunZones_Placing",
            type = "boolean",
            tooltip = "IGUI_PhunZones_Placing_tooltip",
            trueIsNil = true,
            group = "functionality"
        },
        pickup = {
            label = "IGUI_PhunZones_Pickup",
            type = "boolean",
            tooltip = "IGUI_PhunZones_Pickup_tooltip",
            trueIsNil = true,
            group = "functionality"
        },
        scrap = {
            label = "IGUI_PhunZones_Scrap",
            type = "boolean",
            tooltip = "IGUI_PhunZones_Scrap_tooltip",
            trueIsNil = true,
            group = "functionality"
        },
        destruction = {
            label = "IGUI_PhunZones_Destruction",
            type = "boolean",
            tooltip = "IGUI_PhunZones_Destruction_tooltip",
            trueIsNil = true,
            group = "functionality"
        },
        fire = {
            label = "IGUI_PhunZones_Fire",
            type = "boolean",
            tooltip = "IGUI_PhunZones_Fire_tooltip",
            trueIsNil = true,
            group = "functionality"
        },
        players = {
            label = "IGUI_PhunZones_Players",
            type = "boolean",
            tooltip = "IGUI_PhunZones_Players_tooltip",
            trueIsNil = true,
            group = "general"
        },
        order = {
            label = "IGUI_PhunZones_Order",
            type = "int",
            tooltip = "IGUI_PhunZones_Order_tooltip"
        }
    }
}

local Core = PhunZones
Core.isLocal = not isClient() and not isServer() and not isCoopHost()
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

-- ---------------------------------------------------------------------------
-- Cached module-level locals
-- ---------------------------------------------------------------------------
local excludedProps = {"x", "y", "vehicleId"}

-- ---------------------------------------------------------------------------
-- Zone override registry
--
-- Overrides allow any system to redirect a player's effective zone (PhunZones)
-- away from their physical zone (PhunZonesRaw). The RV interior system is one
-- consumer; other mods can register their own via Core.registerZoneOverride.
--
-- Override function signature:
--   fn(obj, physicalZone) -> string | table | nil
--
--   string  -> treated as a zone key; Core resolves it to a zone table.
--              If the key is unknown, a warning is logged and the override
--              is skipped.
--   table   -> used directly as the effective zone dataset. The override is
--              responsible for any merging it wants to do against physicalZone.
--   nil     -> no override; fall through to the next registered override.
--
-- Priority: lower number = higher priority. Defaults to 50.
-- ---------------------------------------------------------------------------
local zoneOverrides = {}

function Core.registerZoneOverride(name, fn, priority)
    for i, entry in ipairs(zoneOverrides) do
        if entry.name == name then
            table.remove(zoneOverrides, i)
            break
        end
    end
    table.insert(zoneOverrides, {
        name = name,
        fn = fn,
        priority = priority or 50
    })
    table.sort(zoneOverrides, function(a, b)
        return a.priority < b.priority
    end)
end

local function resolveEffectiveZone(obj, physicalZone)
    for _, entry in ipairs(zoneOverrides) do
        local ok, result = pcall(entry.fn, obj, physicalZone)
        if not ok then
            print("PhunZones: zone override '" .. entry.name .. "' errored: " .. tostring(result))
        elseif type(result) == "string" then
            local resolved = Core.getLocation(result)
            if resolved and resolved ~= Core.data.lookup._default then
                return resolved
            else
                print("PhunZones: zone override '" .. entry.name .. "' returned unknown key '" .. result ..
                          "', skipping")
            end
        elseif type(result) == "table" then
            return result
        end
    end
    return physicalZone
end

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

    self.players = ModData.getOrCreate(self.const.playerData)

    if (not isClient() and not isServer() and not isCoopHost()) or isServer() then
        print("PhunZones: Loading changes as server")
        self:updateZoneData(true)
        self.trackedVehicles = ModData.getOrCreate(self.const.trackedVehicles)
    else
        print("PhunZones: Loading changes as client")
        self:updateZoneData(true, ModData.getOrCreate(self.const.modifiedModData))
    end

    print("PhunZones: Triggering OnPhunZoneReady")
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
        xx, yy = x:getX(), x:getY()
    end

    if Core.data and Core.data.cells then
        local ckey = math.floor(xx / 300) .. "_" .. math.floor(yy / 300)
        for _, v in ipairs(Core.data.cells[ckey] or {}) do
            -- v[1]=region key, v[2]=zone key, v[3]=x1, v[4]=y1, v[5]=x2, v[6]=y2
            if xx >= v[3] and xx <= v[5] and yy >= v[4] and yy <= v[6] then
                return Core.data.lookup[v[1]][v[2]]
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
    local ldata = Core.getLocation(obj) or {}

    modData.PhunZones = Core.tools.shallowCopy(ldata)
    modData.PhunZones.id = Core.getZId(obj)

    local id = Core.getZId(obj)
    if triggerChangeEvent and (id ~= existing.id or ldata.key ~= existing.key) then
        triggerEvent(Core.events.OnPhunZonesObjectLocationChanged, obj, modData.PhunZones)
    end

    return ldata
end

-- ---------------------------------------------------------------------------
-- Zone access enforcement — client-side only, returns false if player ejected
-- ---------------------------------------------------------------------------

function Core.enforceZoneAccess(obj, effectiveZone, existing)
    if effectiveZone.players ~= false then
        return true
    end
    if not existing.last then
        return true
    end

    local vehicle = obj.getVehicle and obj:getVehicle() or nil
    local lx, ly, lz = existing.last.x, existing.last.y, existing.last.z

    if vehicle then
        Core.teleportVehicleToCoords(obj, vehicle, lx, ly, lz)
    else
        Core.portPlayer(obj, lx, ly, lz)
    end

    return false
end

-- ---------------------------------------------------------------------------
-- Player zone tracking
-- ---------------------------------------------------------------------------

function Core.updatePlayerZoneData(obj, triggerChangeEvent, force)
    local modData = obj:getModData()
    if not modData.PhunZones then
        modData.PhunZones = {}
    end

    local existingEffective = modData.PhunZones
    local existingRaw = modData.PhunZonesRaw or existingEffective
    local physicalZone = Core.getLocation(obj) or {}
    local effectiveZone = resolveEffectiveZone(obj, physicalZone)
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

    local physicalChanged = physicalZone.key ~= existingRaw.key
    local effectiveChanged = effectiveZone.key ~= existingEffective.key

    if force or physicalChanged or effectiveChanged then
        if not Core.enforceZoneAccess(obj, effectiveZone, existingEffective) then
            return
        end

        local prevEffective = Core.tools.shallowCopy(existingEffective, excludedProps)
        local prevRaw = Core.tools.shallowCopy(existingRaw, excludedProps)
        local newEffective = Core.tools.shallowCopy(effectiveZone, excludedProps)
        local newRaw = Core.tools.shallowCopy(physicalZone, excludedProps)

        local pos = currentPos()
        newEffective.modified = getTimestamp()
        newEffective.last = pos
        newRaw.last = pos

        modData.PhunZones = newEffective
        modData.PhunZonesRaw = newRaw

        if triggerChangeEvent then
            -- Raw data is bundled into .raw on each arg rather than passed as
            -- separate arguments — server-side triggerEvent is limited to 3
            -- args (eventName + 2) and will throw if given more.
            newEffective.raw = newRaw
            prevEffective.raw = prevRaw
            triggerEvent(Core.events.OnPhunZonesPlayerLocationChanged, obj, newEffective, prevEffective)
        end

        return prevEffective
    end

    -- No zone change — keep last position fresh in both datasets
    local pos = currentPos()
    existingEffective.last = pos
    existingRaw.last = pos

    return existingEffective
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
-- Player teleport (B42)
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
