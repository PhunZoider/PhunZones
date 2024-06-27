if isServer() then
    return
end
local PhunZones = PhunZones
local sandbox = SandboxVars.PhunZones

local function updatePlayer(playerObj)
    PhunZones:updateLocation(playerObj)
end

local function updatePlayers()
    for i = 0, getOnlinePlayers():size() - 1 do
        local p = getOnlinePlayers():get(i)
        updatePlayer(p)
    end
end

-- throttle the checks
local throttleCount = 0
local pcache = {}
local function throttleUpdatePlayer(playerObj)

    if throttleCount < 50 then
        throttleCount = throttleCount + 1
        return
    end
    throttleCount = 0
    local name = playerObj:getUsername()
    local p = pcache[name] or {}
    if (p.x or 0) == playerObj:getX() and (p.y or 0) == playerObj:getY() then
        return
    end

    pcache[name] = {
        x = playerObj:getX(),
        y = playerObj:getY()
    }
    updatePlayer(playerObj)

end

local Commands = {}

Commands[PhunZones.commands.dataLoaded] = function(data)
    PhunZones.bounds = data
    updatePlayers()
end

Events.OnServerCommand.Add(function(module, command, arguments)
    if module == PhunZones.name and Commands[command] then
        Commands[command](arguments)
    end
end)

local function setup()
    Events.EveryOneMinute.Remove(setup)
    if sandbox.PhunZones_Widget then
        for i = 1, getOnlinePlayers():size() do
            local p = getOnlinePlayers():get(i - 1)
            PhunZonesWidget.OnOpenPanel(p)
        end
    end
    PhunZones:ini()
    updatePlayers(true)
    Events.OnPlayerUpdate.Add(throttleUpdatePlayer)
end

Events.EveryOneMinute.Add(setup)

local initialized = false
Events.OnReceiveGlobalModData.Add(function(tableName, tableData)

    if isClient() then
        if tableName == PhunZones.name .. "_zones" and type(tableData) == "table" then
            PhunZones.zones = tableData
        elseif tableName == PhunZones.name .. "_bounds" and type(tableData) == "table" then
            PhunZones.bounds = tableData
        end
    end
end)

Events.OnInitGlobalModData.Add(function()
    -- ModData.request(PhunZones.name)
end)

Events.EveryTenMinutes.Add(function()
    updatePlayers()
end)

Events.OnGameStart.Add(function()
    if sandbox.PhunZones_Widget then
        for i = 1, getOnlinePlayers():size() do
            local p = getOnlinePlayers():get(i - 1)
            PhunZonesWidget.OnOpenPanel(p):rebuild()
        end
    end
end)

Events[PhunZones.events.OnPhunZonesPlayerLocationChanged].Add(
    function(playerObj, location, old)
        if location.pvp == true and playerObj:getSafety():isEnabled() then
            getPlayerSafetyUI(playerObj:getPlayerNum()):toggleSafety()
        elseif location.pvp == false and not playerObj:getSafety():isEnabled() then
            getPlayerSafetyUI(playerObj:getPlayerNum()):toggleSafety()
        end

        if sandbox.PhunZones_Widget then
            PhunZonesWidget.OnOpenPanel(playerObj):rebuild()
        end
    end)

if PhunRunners then
    Events[PhunRunners.events.OnPhunRunnersPlayerUpdated].Add(function(playerObj)
        if sandbox.PhunZones_Widget then
            for i = 1, getOnlinePlayers():size() do
                local p = getOnlinePlayers():get(i - 1)
                local instance = PhunZonesWidget.OnOpenPanel(p)
                instance:rebuild()
            end
        end
    end)
end

if PhunStats then
    Events[PhunStats.events.OnPhunStatsInied].Add(function(playerObj)
        if sandbox.PhunZones_Widget then
            for i = 1, getOnlinePlayers():size() do
                local p = getOnlinePlayers():get(i - 1)
                PhunZonesWidget.OnOpenPanel(p):rebuild()
            end
        end
    end)
end

Events[PhunZones.events.OnPhunZonesPlayerLocationChanged].Add(
    function(playerObj, location, oldLocation)
        if instanceof(playerObj, "IsoPlayer") then
            if not location then
                return
            end
            if location.key == "void" then
                return
            end
            if location.noAnnounce then
                return
            end
            -- if sandbox.PhunZones_ShowPvP then
            oldLocation = oldLocation or {}
            if location.title ~= oldLocation.title or location.subtitle ~= oldLocation.subtitle then
                PhunZonesWelcome.OnOpenPanel(playerObj, location, oldLocation)
            end
            -- end
        end
    end)
