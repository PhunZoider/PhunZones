local allLocations = require("PhunZones/data")
local fileTools = require("PhunZones/files")
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
        modifiedModData = "PhunZone_Changes"
    },
    ui = {},
    data = {},
    commands = {
        playerSetup = "PhunZonesPlayerSetup",
        transmitChanges = "PhunZonesTransmitChanges",
        modifyZone = "PhunZonesModifyZone",
        killZombie = "PhunZonesKillZombie",
        cleanPlayersZeds = "PhunZonescleanPlayersZeds"
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

        if (not isClient() and not isServer() and not isCoopHost()) or isServer() then
            -- single player or a server so load changes from file
            print("PhunZones: Loading changes as server")
            self:getZones(true)
        elseif not isServer() then
            print("PhunZones: Loading changes as client")
            -- client so use cached version and then ask server for its changes
            self:getZones(true, ModData.getOrCreate(self.const.modifiedModData))
        end
        print("PhunZones: Triggering OnPhunZoneReady")
        triggerEvent(self.events.OnPhunZoneReady)
    end
end

function Core:updateModData(obj, skipEvent)
    if not obj or not obj.getModData then
        return
    end

    local existing = obj:getModData().PhunZones or {}

    -- commenting for now as its probably as expensive to do this as it is to just do the lookup

    -- if existing.xx then
    --     -- object hasn't moved more than 5 units so don't bother calculating
    --     if math.abs(obj:getX() - existing.xx) <= 5 or math.abs(obj:getY() - existing.yy) <= 5 then
    --         return
    --     end
    -- end
    -- existing.xx = obj:getX()
    -- existing.yy = obj:getY()

    local data = self:getLocation(obj) or {}

    if data.region ~= existing.region or data.zone ~= existing.zone then
        obj:getModData().PhunZones = data
        if instanceof(obj, "IsoPlayer") then
            if data.pvp then
                if obj:getSafety():isEnabled() then
                    getPlayerSafetyUI(obj:getPlayerNum()):toggleSafety()
                end
            else
                if not obj:getSafety():isEnabled() then
                    getPlayerSafetyUI(obj:getPlayerNum()):toggleSafety()
                end
            end
        end
        if not skipEvent then
            triggerEvent(self.events.OnPhunZonesPlayerLocationChanged, obj, data)
        end
    end
    return data
end

local sandbox = nil

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

-- local frequencyCheck = 30
-- Events.OnZombieUpdate.Add(function(zed)
--     local data = zed:getModData()
--     if not data.PZChecked or data.PZChecked < getTimestamp() then
--         print("Checcking zed " .. tostring(zed:getID()))
--         data.PZChecked = getTimestamp() + frequencyCheck
--         data.PhunZones = Core:getLocation(zed)
--         if data.PhunZones.zeds == false then
--             sendClientCommand(PhunSpawn.name, PhunSpawn.commands.killZombie, {
--                 id = onlineID
--             })
--             zed:removeFromWorld()
--             zed:removeFromSquare()
--         end
--     end
-- end)
