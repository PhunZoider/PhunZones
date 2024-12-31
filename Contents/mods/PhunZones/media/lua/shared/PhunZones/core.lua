local allLocations = require("PhunZones/data")
local fileTools = require("PhunZones/files")
local tableTools = require("PhunZones/table")
PhunZones = {
    name = 'PhunZones',
    events = {
        OnPhunZoneReady = "PhunZonesOnPhunZoneReady",
        OnPhunZonesPlayerLocationChanged = "PhunZonesOnPhunZonesPlayerLocationChanged",
        OnPhunZonesObjectLocationChanged = "PhunZonesOnPhunZonesObjectLocationChanged",
        OnPhunZoneWidgetClicked = "PhunZonesOnPhunZoneWidgetClicked"
    },
    const = {
        modifiedLuaFile = "PhunZone_Changes.lua",
        modifiedModData = "PhunZone_Changes",
        playerData = "PhunZonesPlayers",
        trackedVehicles = "PhunZonesTrackedVehicles"
    },
    ui = {},
    data = {},
    commands = {
        playerSetup = "PhunZonesPlayerSetup",
        transmitChanges = "PhunZonesTransmitChanges",
        modifyZone = "PhunZonesModifyZone",
        cleanPlayersZeds = "PhunZonescleanPlayersZeds",
        updatePlayerZone = "PhunZonesUpdatePlayerZone"
    }
}

local Core = PhunZones
Core.settings = SandboxVars[Core.name] or {}
for _, event in pairs(Core.events or {}) do
    if not Events[event] then
        LuaEventManager.AddEvent(event)
    end
end

function Core:debug(...)

    local args = {...}
    for i, v in ipairs(args) do
        if type(v) == "table" then
            self:printTable(v)
        else
            print(tostring(v))
        end
    end

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
            self:getZones(true)
            self.trackedVehicles = ModData.getOrCreate(self.const.trackedVehicles)
        elseif not isServer() then
            print("PhunZones: Loading changes as client")
            -- client so use cached version and then ask server for its changes
            self:getZones(true, ModData.getOrCreate(self.const.modifiedModData))
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

local excludedProps = nil
local excludedTrackingProps = nil
local rvInterior = nil
function Core:updateModData(obj, triggerChangeEvent)
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
    local ldata = self:getLocation(obj) or {}
    local doEvent = false

    if not instanceof(obj, "IsoPlayer") then
        -- most likely a zed or bandit
        modData.PhunZones = tableTools:shallowCopyTable(ldata)
        modData.PhunZones.id = obj:getOnlineID()
        local id = obj:getOnlineID()
        if triggerChangeEvent and (id ~= existing.id or ldata.region ~= existing.region or ldata.zone ~= existing.zone) then
            triggerEvent(self.events.OnPhunZonesObjectLocationChanged, obj, modData.PhunZones)
        end
        return ldata
    else
        -- player
        if ldata.region ~= existing.region or ldata.zone ~= existing.zone then
            -- Shallow copy the new data
            existing = tableTools:shallowCopyTable(ldata, excludedProps)
            -- flag that there has been a material change to the zone
            doEvent = true
        end

        if ldata.rv and rvInterior then
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
                    existing.mregion = zone.region
                    existing.mzone = zone.zone
                    doEvent = true
                end
            end
        end

        if doEvent then
            existing.modified = getTimestamp()
            obj:getModData().PhunZones = existing
        end

        if doEvent and isServer() then
            -- self:debug("SEND UPDATE TO CLIENT", existing)
            existing.pid = obj:getOnlineID()
            sendServerCommand(obj, self.name, self.commands.updatePlayerZone, existing)
        end

        if triggerChangeEvent and doEvent then
            triggerEvent(self.events.OnPhunZonesPlayerLocationChanged, obj, existing)
        end
    end

    return existing
end

function Core:getLocation(x, y)

    local xx, yy = x, y
    if not y and x.getX then
        -- passed an object
        xx, yy = x:getX(), x:getY()
    end

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

    return {
        region = "none",
        zone = "main",
        noAnnounce = true,
        difficulty = self.settings.DefaultNoneDifficulty or 2,
        title = self.settings.DefaultNoneTitle or "Kentucky"
    }
end

function Core:onlinePlayers(all)

    local onlinePlayers;

    if not isClient() and not isServer() and not isCoopHost() then
        onlinePlayers = ArrayList.new();
        local p = getPlayer()
        onlinePlayers:add(p);
    elseif all then
        onlinePlayers = getOnlinePlayers();

    else
        onlinePlayers = ArrayList.new();
        for i = 0, getOnlinePlayers():size() - 1 do
            local player = getOnlinePlayers():get(i);
            if player:isLocalPlayer() then
                onlinePlayers:add(player);
            end
        end
    end

    return onlinePlayers;
end

function Core:saveChanges(data)
    ModData.add(self.const.modifiedModData, data)
    if isClient() then
        sendClientCommand(getPlayer(), self.name, self.commands.modifyZone, data)
    else
        fileTools:saveTable(self.const.modifiedLuaFile, data)
    end

    self:getZones(true, data)
end

if isServer() then
    Events.OnServerStarted.Add(function()
        Core:ini()
    end)
end
