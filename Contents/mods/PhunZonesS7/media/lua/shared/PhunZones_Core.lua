local modList = nil

PhunZones = {
    inied = false,
    name = "PhunZones",
    settings = {
        show_widget = true
    },
    commands = {
        dataLoaded = "dataLoaded",
        reload = "reload",
        requestData = "requestData"
    },
    players = {},
    events = {
        OnPhunZonesPlayerLocationChanged = "OnPhunZonesPlayerLocationChanged",
        OnPhunZoneWelcomeOpened = "OnPhunZoneWelcomeOpened",
        OnPhunZoneWidgetClicked = "OnPhunZoneWidgetClicked",
        OnPhunZoneReady = "OnPhunZoneReady"
    },
    bounds = {},
    zones = {}
}

for _, event in pairs(PhunZones.events) do
    if not Events[event] then
        LuaEventManager.AddEvent(event)
    end
end

local calculatePips = function(risk)
    -- Ensure the risk is within the valid range
    if risk < 0 then
        risk = 0
    end
    if risk > 100 then
        risk = 100
    end
    -- Calculate the number of pips
    local pips = math.ceil(risk / 10)
    return pips
end

function PhunZones:getRiskInfo(playerObj)

    if playerObj and PhunRunners then
        local riskData = PhunRunners:getPlayerData(playerObj)
        return {
            risk = riskData.risk or 0,
            pips = calculatePips(riskData.risk or 0),
            modifier = riskData.modifier,
            restless = riskData.restless == true,
            spawnSprinters = riskData.spawnSprinters == true
        }
    end

end

-- iterate through all bounds and create an internal key
function PhunZones:buildBoundKeys()
    for _, v in ipairs(self.bounds) do
        if not v._key then
            v._key = v.x .. "_" .. v.x2 .. "_" .. v.y .. "_" .. v.y2
        end
    end
end

-- updates an objects locations and tries to store within global and/or moddata
function PhunZones:updateLocation(obj)

    local location = self:getLocation(obj:getX(), obj:getY())
    local old = nil
    local isPlayer = false
    if instanceof(obj, "IsoPlayer") then
        old = self.players[obj:getUsername()]
        isPlayer = true
    elseif instanceof(obj, "IsoZombie") then
        old = obj:getModData().PhunZones
    end
    if location and ((not old) or (old._key ~= location._key)) then
        -- we now have a location or have changed location
        if isPlayer then
            self.players[obj:getUsername()] = location
            if not obj:getModData().PhunZones then
                obj:getModData().PhunZones = {}
            end
            obj:getModData().PhunZones = {
                current = location,
                previous = old
            }
            triggerEvent(self.events.OnPhunZonesPlayerLocationChanged, obj, location, old)
        else
            obj:getModData().PhunZones = location
        end

    elseif old and not location then
        -- we have left a location for nothing
        if isPlayer then
            self.players[obj:getUsername()] = location
            if not obj:getModData().PhunZones then
                obj:getModData().PhunZones = {}
            end
            obj:getModData().PhunZones = {
                current = location,
                previous = old
            }
            triggerEvent(self.events.OnPhunZonesPlayerLocationChanged, obj, location, old)
        else
            obj:getModData().PhunZones = location
        end
    end
    return location
end

function PhunZones:getLocation(x, y)
    local xx, yy = x, y
    if not y and x.getX then
        -- passed an object
        xx, yy = x:getX(), x:getY()
    end
    local result = {
        isDefault = true,
        x = 0,
        y = 0,
        x2 = 0,
        y2 = 0,
        _key = "0_0_0_0",
        key = "none",
        title = "",
        subtitle = "",
        noAnnounce = true,
        difficulty = 1
    }
    for _, v in ipairs(self.bounds or {}) do
        if xx >= v.x and xx <= v.x2 and yy >= v.y and yy <= v.y2 then
            result = v
            break
        end
    end
    return result
end

function PhunZones:ini()
    if not self.inied then
        self.inied = true
        -- load cached data
        self.zones = ModData.getOrCreate(self.name .. "_zones")
        self.bounds = ModData.getOrCreate(self.name .. "_bounds")
        if isServer() then
            -- trigger redoing cached data from file
            self:reload()
        elseif isClient() then
            -- request new data so we have the latest
            ModData.request(self.name .. "_zones")
            ModData.request(self.name .. "_bounds")
        end

        -- print('- -- -- EVENTS --  - ')
        -- local e = {}
        -- for k, v in pairs(Events) do
        --     table.insert(e, k)
        -- end
        -- table.sort(e, function(a, b)
        --     return a < b
        -- end)
        -- PhunTools:printTable(e)
    end

end

Events.OnInitGlobalModData.Add(function()
    PhunZones:ini()
end)
