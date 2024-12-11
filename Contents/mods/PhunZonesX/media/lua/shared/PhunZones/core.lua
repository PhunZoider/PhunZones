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
            ModData.getOrCreate(self.name .. "_Changes")
        end
    end
end

function Core:updateModData(obj)
    local existing = obj:getModData().PhunZones or {}
    local data = self:getLocation(obj:getX(), obj:getY()) or {}
    if data.zone ~= existing.zone or data.area ~= existing.area then
        obj:getModData().PhunZones = data
        triggerEvent(self.events.OnPhunZonesPlayerLocationChanged, obj, data)
        return data
    end
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
        title = sandbox.DefaultNoneTitle or "Wilderness"
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

if isServer() then
    Events.OnServerStarted.Add(function()
        Core:ini()
    end)

    print('- -- -- EVENTS --  - ')
    local e = {}
    for k, v in pairs(Events) do
        table.insert(e, k)
    end
    table.sort(e, function(a, b)
        return a < b
    end)
    PhunTools:printTable(e)
else

end
