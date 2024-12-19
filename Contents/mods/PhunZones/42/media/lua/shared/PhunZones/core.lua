local allLocations = require("PhunZones/data")
PhunZones = {
    name = 'PhunZones',
    events = {
        OnPhunZoneReady = "PhunZonesOnPhunZoneReady",
        OnPhunZonesPlayerLocationChanged = "PhunZonesOnPhunZonesPlayerLocationChanged",
        OnPhunZonesObjectLocationChanged = "PhunZonesOnPhunZonesObjectLocationChanged",
        OnPhunZoneWidgetClicked = "PhunZonesOnPhunZoneWidgetClicked"
    },
    ui = {},
    data = {},
    commands = {
        playerSetup = "PhunZonesPlayerSetup"
    }
}

local Core = PhunZones

for _, event in pairs(Core.events or {}) do
    if not Events[event] then
        LuaEventManager.AddEvent(event)
    end
end

function Core:debug(...)
    if self.settings.debug then
        local args = {...}
        PhunTools:debug(args)
    end
end

function Core:ini()
    if not self.inied then
        self.inied = true
        -- load existing data
        self.data = ModData.getOrCreate(self.name)
        ModData.getOrCreate(self.name .. "_Changes")
        -- process anything from the data file
        self.data = self:processDataSet(allLocations)
        if isServer() then
            self:refreshChanges()
        elseif isClient() then
            -- ask for any exceptions
            ModData.request(self.name .. "_Changes")
        end
    end
end

function Core:updateModData(obj, skipEvent)
    if not obj then
        return
    end
    local moddata = obj:getModData()
    local existing = obj:getModData().PhunZones or {}

    if existing.xx then
        if math.abs(obj:getX() - existing.xx) <= 5 or math.abs(obj:getY() - existing.yy) <= 5 then
            return
        end
    end
    existing.xx = obj:getX()
    existing.yy = obj:getY()

    local data = self:getLocation(obj:getX(), obj:getY()) or {}

    -- if math.abs(x - x2) <= 10 or math.abs(y - y2) <= 10 then
    -- end

    if data.zone ~= existing.zone or data.area ~= existing.area then
        obj:getModData().PhunZones = data
        if not skipEvent then
            triggerEvent(self.events.OnPhunZonesPlayerLocationChanged, obj, data)
        end
    end
    return data
end

local sandbox = nil

function Core:getLocation(x, y)

    if sandbox == nil then
        sandbox = SandboxVars.PhunZones
    end

    local xx, yy = x, y
    if not y and x.getX then
        -- passed an object
        xx, yy = x:getX(), x:getY()
    end
    local result = {
        zone = "none",
        area = "def",
        noAnnounce = true,
        difficulty = sandbox.DefaultNoneDifficulty or 2,
        title = sandbox.DefaultNoneTitle or "Kentucky"
    }

    local cx = math.floor(xx / 300)
    local cy = math.floor(yy / 300)
    local ckey = cx .. "_" .. cy
    local chunks = self.data.chunks or {}
    for _, v in ipairs(chunks[ckey] or {}) do
        if xx >= v.x and xx <= v.x2 and yy >= v.y and yy <= v.y2 then
            return self.data.zones[v.zone].areas[v.area]
        end
    end
    return result
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
            if getOnlinePlayers:get(i):isLocalPlayer() then
                onlinePlayers:add(getOnlinePlayers():get(i));
            end
        end
    end

    return onlinePlayers;
end

if isServer() then
    Events.OnServerStarted.Add(function()
        Core:ini()
    end)
end
-- print('- -- -- EVENTS! --  - ')
-- local e = {}
-- for k, v in pairs(Events) do
--     table.insert(e, k)
-- end
-- table.sort(e, function(a, b)
--     return a < b
-- end)
-- Core:printTable(e)

