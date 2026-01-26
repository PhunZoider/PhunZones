require "PhunLib/core"
local PL = PhunLib
local allLocations = require("PhunZones/data")
local fileTools = PL.file
local tableTools = PL.table
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
        updatePlayerZone = "PhunZonesUpdatePlayerZone",
        playerTeleport = "PhunZonesPlayerTeleport",
        teleportVehicle = "PhunZonesTeleportVehicle",
        deleteZone = "PhunZonesDeleteZone"
    },
    fields = {
        region = {
            label = "IGUI_PhunZones_Region",
            type = "string",
            tooltip = "IGUI_PhunZones_Region_tooltip",
            disableOnEdit = true
        },
        zone = {
            label = "IGUI_PhunZones_Zone",
            type = "string",
            tooltip = "IGUI_PhunZones_Zone_tooltip",
            disableOnEdit = true
        },
        title = {
            label = "IGUI_PhunZones_Title",
            type = "string",
            tooltip = "IGUI_PhunZones_Title_Tooltip"
        },
        subtitle = {
            label = "IGUI_PhunZones_Subtitle",
            type = "string",
            tooltip = "IGUI_PhunZones_Subtitle_tooltip"
        },
        difficulty = {
            label = "IGUI_PhunZones_Difficulty",
            type = "int",
            tooltip = "IGUI_PhunZones_Difficulty_tooltip"
        },
        mods = {
            label = "IGUI_PhunZones_Mods",
            type = "string",
            tooltip = "IGUI_PhunZones_Mods_tooltip"
        },
        pvp = {
            label = "IGUI_PhunZones_PvP",
            type = "boolean",
            tooltip = "IGUI_PhunZones_PvP_tooltip"
        },
        zeds = {
            label = "IGUI_PhunZones_Zeds",
            type = "boolean",
            tooltip = "IGUI_PhunZones_Zeds_tooltip",
            trueIsNil = true
        },
        bandits = {
            label = "IGUI_PhunZones_Bandits",
            type = "boolean",
            tooltip = "IGUI_PhunZones_Bandits_tooltip",
            trueIsNil = true
        },
        rv = {
            label = "IGUI_PhunZones_RVInteriors",
            type = "boolean",
            tooltip = "IGUI_PhunZones_RVInteriors_tooltip"
        },
        noAnnounce = {
            label = "IGUI_PhunZones_NoWelcome",
            type = "boolean",
            tooltip = "IGUI_PhunZones_NoWelcome_tooltip",
            trueIsNil = true
        },
        enabled = {
            label = "IGUI_PhunZones_Enabled",
            type = "boolean",
            tooltip = "IGUI_PhunZones_Enabled_tooltip",
            trueIsNil = true
        },
        safehouse = {
            label = "IGUI_PhunZones_SafeHouse",
            type = "boolean",
            tooltip = "IGUI_PhunZones_Safehouse_tooltip",
            trueIsNil = true
        },
        building = {
            label = "IGUI_PhunZones_Building",
            type = "boolean",
            tooltip = "IGUI_PhunZones_Building_tooltip",
            trueIsNil = true
        },
        placing = {
            label = "IGUI_PhunZones_Placing",
            type = "boolean",
            tooltip = "IGUI_PhunZones_Placing_tooltip",
            trueIsNil = true
        },
        pickup = {
            label = "IGUI_PhunZones_Pickup",
            type = "boolean",
            tooltip = "IGUI_PhunZones_Pickup_tooltip",
            trueIsNil = true
        },
        scrap = {
            label = "IGUI_PhunZones_Scrap",
            type = "boolean",
            tooltip = "IGUI_PhunZones_Scrap_tooltip",
            trueIsNil = true
        },
        destruction = {
            label = "IGUI_PhunZones_Destruction",
            type = "boolean",
            tooltip = "IGUI_PhunZones_Destruction_tooltip",
            trueIsNil = true
        },
        fire = {
            label = "IGUI_PhunZones_Fire",
            type = "boolean",
            tooltip = "IGUI_PhunZones_Fire_tooltip",
            trueIsNil = true
        },
        players = {
            label = "IGUI_PhunZones_Players",
            type = "boolean",
            tooltip = "IGUI_PhunZones_Players_tooltip",
            trueIsNil = true
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
for _, event in pairs(Core.events or {}) do
    if not Events[event] then
        LuaEventManager.AddEvent(event)
    end
end

Core.isB42 = _G.IsoLightSource ~= nil

if Core.isB42 then
    Core.fields.pvp = nil
end

function Core:debug(...)

    PL.debug(self.name, ...)

end

function Core:printTable(t, indent)
    indent = indent or ""
    for key, value in pairs(t or {}) do
        if type(value) == "table" then
            print(indent .. key .. ":")
            Core:printTable(value, indent .. "  ")
        elseif type(value) ~= "function" then
            print(indent .. key .. ": " .. tostring(value))
        end
    end
end

function Core:ini()
    if not self.inied then
        self.inied = true
        self.players = ModData.getOrCreate(self.const.playerData)
        if (not isClient() and not isServer() and not isCoopHost()) or isServer() then
            -- single player or a server so load changes from file
            print("PhunZones: Loading changes as server")
            self:updateZoneData(true)
            self.trackedVehicles = ModData.getOrCreate(self.const.trackedVehicles)
        elseif not isServer() then
            print("PhunZones: Loading changes as client")
            -- client so use cached version and then ask server for its changes
            self:updateZoneData(true, ModData.getOrCreate(self.const.modifiedModData))
        end
        print("PhunZones: Triggering OnPhunZoneReady")
        triggerEvent(self.events.OnPhunZoneReady)
    end
end

function Core:getPlayerData(player)
    local key = nil
    if type(player) == "string" then
        key = player
    else
        key = player:getUsername()
    end
    if key then
        if not self.players then
            self.players = {}
        end
        if not self.players[key] then
            self.players[key] = {}
        end
        return self.players[key]
    end
end

function Core.getOption(name, default)
    local n = Core.name .. "." .. name
    local val = getSandboxOptions():getOptionByName(n) and getSandboxOptions():getOptionByName(n):getValue()
    if val == nil then
        return default
    end
    return val
end

function Core:addExtendedData(data)
    self.extended = tableTools.merge(self.extended or {}, data)
end

function Core:updatePlayers()

    if isServer() and self.settings.ProcessOnClient then
        return
    end

    local players = PL.onlinePlayers(not self.settings.ProcessOnClient)
    for i = 0, players:size() - 1, 1 do
        local p = players:get(i)
        self:updatePlayer(p)
    end
end

function Core:updatePlayer(playerObj)
    self:updateModData(playerObj, true)
end

local excludedProps = nil
local excludedTrackingProps = nil
local rvInterior = nil
local playersInitialized = {}
function Core:updateModData(obj, triggerChangeEvent, force)
    if not obj or not obj.getModData then
        return
    end

    if not excludedTrackingProps then
        -- cache excluded properties we don't want to duplicate
        excludedProps = ArrayList.new()
        excludedProps:add("x")
        excludedProps:add("y")
        excludedProps:add("vehicleId")

        excludedTrackingProps = ArrayList.new()
        excludedTrackingProps:add("rv")
        excludedTrackingProps:add("isVoid")
        excludedTrackingProps:add("bandits")
        excludedTrackingProps:add("zeds")
        excludedTrackingProps:add("zones")
        excludedTrackingProps:add("zone")
        excludedTrackingProps:add("region")
        excludedTrackingProps:add("x")
        excludedTrackingProps:add("y")
        excludedTrackingProps:add("vehicleId")
    end
    if rvInterior == nil then
        -- cache for rv interiors support
        rvInterior = RVInterior or false
    end

    local modData = obj:getModData()

    if not modData.PhunZones then
        modData.PhunZones = {}
    end
    local existing = modData.PhunZones
    local new = existing
    local ldata = self:getLocation(obj) or {}
    local doEvent = false

    if not instanceof(obj, "IsoPlayer") then
        -- most likely a zed or bandit
        modData.PhunZones = tableTools.shallowCopy(ldata)
        modData.PhunZones.id = Core.getZId(obj)
        local id = Core.getZId(obj)
        if triggerChangeEvent and (id ~= existing.id or ldata.region ~= existing.region or ldata.zone ~= existing.zone) then
            triggerEvent(self.events.OnPhunZonesObjectLocationChanged, obj, modData.PhunZones)
        end
        return ldata
    else
        -- player
        local vehicle = obj.getVehicle and obj:getVehicle() or nil
        if force or (ldata.region ~= existing.region or ldata.zone ~= existing.zone) then

            if ldata.players == false and existing.last then
                -- player is not allowed here!
                if isServer() then
                    if vehicle then
                        self:portVehicle(obj, vehicle, existing.last.x, existing.last.y, existing.last.z)
                        sendServerCommand(obj, self.name, self.commands.teleportVehicle, {
                            id = vehicle:getId(),
                            username = obj:getUsername(),
                            x = existing.last.x,
                            y = existing.last.y,
                            z = existing.last.z
                        })
                    else
                        sendServerCommand(obj, self.name, self.commands.playerTeleport, {
                            username = obj:getUsername(),
                            x = existing.last.x,
                            y = existing.last.y,
                            z = existing.last.z
                        })
                    end

                else

                    if vehicle then
                        self:portVehicle(obj, vehicle, existing.last.x, existing.last.y, existing.last.z)
                    else
                        self:portPlayer(obj, existing.last.x, existing.last.y, existing.last.z)
                    end

                end
                return
            end

            -- Shallow copy the existing data
            existing = tableTools.shallowCopy(existing, excludedProps)
            -- Shallow copy the new data
            new = tableTools.shallowCopy(ldata, excludedProps)
            -- flag that there has been a material change to the zone
            doEvent = true
        end

        if self.settings.VehicleTracking and ldata.rv and rvInterior then
            -- current zone is an rvInteriors zone. Merge cars location
            local interior = rvInterior.calculatePlayerInteriorInstance(obj)
            if interior and self.trackedVehicles and self.trackedVehicles[interior.interiorInstance] then

                local zone = self:getLocation(self.trackedVehicles[interior.interiorInstance].x or 0,
                    self.trackedVehicles[interior.interiorInstance].y or 0)

                if zone.region ~= existing.mregion or zone.zone ~= existing.mzone then
                    -- Shallow copy the new data
                    for k, v in pairs(zone) do
                        if not excludedTrackingProps:contains(k) then
                            existing[k] = v
                        end
                    end
                    new.mregion = zone.region
                    new.mzone = zone.zone
                    doEvent = true
                end
            end
        end

        if not new.modified then
            doEvent = true
        end

        if not playersInitialized[obj:getOnlineID()] then
            playersInitialized[obj:getOnlineID()] = true
            doEvent = true
            triggerChangeEvent = true
        end

        if doEvent then
            new.modified = getTimestamp()
            obj:getModData().PhunZones = new
        end

        if vehicle then
            -- store last known vehicle location
            obj:getModData().PhunZones.last = {
                x = vehicle:getX(),
                y = vehicle:getY(),
                z = vehicle:getZ()
            }
        else
            -- store last known location
            obj:getModData().PhunZones.last = {
                x = obj:getX(),
                y = obj:getY(),
                z = obj:getZ()
            }
        end

        if doEvent and isServer() and not self.settings.ProcessOnClient then
            new.pid = obj:getOnlineID()
            sendServerCommand(obj, self.name, self.commands.updatePlayerZone, new, existing)
        end

        if triggerChangeEvent and doEvent then
            triggerEvent(self.events.OnPhunZonesPlayerLocationChanged, obj, new, existing)
        end
    end

    return existing
end

function Core:getLocation(x, y)

    if not self.inied then
        self:ini()
    end

    local xx, yy = x, y
    if not y and x.getX then
        -- passed an object
        xx, yy = x:getX(), x:getY()
    end

    if self.data and self.data.cells then

        local ckey = math.floor(xx / 300) .. "_" .. math.floor(yy / 300)
        for _, v in ipairs(self.data.cells[ckey] or {}) do
            -- 1 = region key
            -- 2 = zone key
            -- 3 = x1
            -- 4 = y1
            -- 5 = x2
            -- 6 = y2
            if xx >= v[3] and xx <= v[5] and yy >= v[4] and yy <= v[6] then
                return self.data.lookup[v[1]][v[2]]
            end
        end
    end
    return self.data.lookup._default
end

function Core:portVehicle(player, vehicle, x, y, z)

    if not vehicle then
        return
    end
    local fieldCount = getNumClassFields(vehicle)
    local transField = nil
    local fieldName = 'public final zombie.core.physics.Transform zombie.vehicles.BaseVehicle.jniTransform'
    for i = 0, fieldCount - 1 do
        local field = getClassField(vehicle, i)
        if tostring(field) == fieldName then
            transField = field
        end
    end

    if transField then
        local v_transform = getClassFieldVal(vehicle, transField)
        local w_transform = vehicle:getWorldTransform(v_transform)
        local origin_field = getClassField(w_transform, 1)
        local origin = getClassFieldVal(w_transform, origin_field)
        origin:set(origin:x() - x, origin:y(), origin:z() - y)
        vehicle:setWorldTransform(w_transform)
        if isClient() then
            pcall(vehicle.update, vehicle)
            pcall(vehicle.updateControls, vehicle)
            pcall(vehicle.updateBulletStats, vehicle)
            pcall(vehicle.updatePhysics, vehicle)
            pcall(vehicle.updatePhysicsNetwork, vehicle)
        end
    end

end

function Core.getZId(zedObj)
    if zedObj then
        if instanceof(zedObj, "IsoZombie") then
            if zedObj:isZombie() then
                if isClient() or isServer() then
                    return tostring(zedObj:getOnlineID())
                else
                    return tostring(zedObj:getID())
                end
            end
        end
    end
end

if isServer() then
    Events.OnServerStarted.Add(function()
        Core:ini()
    end)
end
