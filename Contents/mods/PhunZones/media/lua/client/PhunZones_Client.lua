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
        if PhunZones.settings.show_widget then
            for i = 1, getOnlinePlayers():size() do
                local p = getOnlinePlayers():get(i - 1)

                PhunZonesWidget.OnOpenPanel(p)
            end
        end
    end
    sendClientCommand(PhunZones.name, PhunZones.commands.requestData, {})
end

Events.EveryOneMinute.Add(setup)

local initialized = false
Events.OnReceiveGlobalModData.Add(function(tableName, tableData)

    if tableName == PhunZones.name and type(tableData) == "table" then
        PhunZones:ini()
        PhunZones.bounds = tableData.bounds
        if not initialized then
            initialized = true
            updatePlayers(true)
            Events.OnPlayerUpdate.Add(throttleUpdatePlayer)

        end
    end
end)

Events.OnInitGlobalModData.Add(function()
    ModData.request(PhunZones.name)
end)

Events[PhunZones.events.OnPhunZonesPlayerLocationChanged].Add(
    function(playerObj, location, old)
        if location.pvp == true and playerObj:getSafety():isEnabled() then
            getPlayerSafetyUI(playerObj:getPlayerNum()):toggleSafety()
        elseif location.pvp == false and not playerObj:getSafety():isEnabled() then
            getPlayerSafetyUI(playerObj:getPlayerNum()):toggleSafety()
        end
        local p = playerObj:getModData().PhunZones
        p = p or {}
        p.location = location
        playerObj:getModData().PhunZones = p
        if sandbox.PhunZones_Widget then
            for i = 0, getOnlinePlayers():size() - 1 do
                local instance = PhunZonesWidget.OnOpenPanel(getOnlinePlayers():get(i))
                if instance and instance.rebuild then
                    instance:rebuild()
                end
            end
        end
    end)

if PhunRunners then
    Events[PhunRunners.events.OnPhunRunnersPlayerUpdated].Add(function(playerObj)
        if sandbox.PhunZones_Widget then
            PhunZonesWidget.OnOpenPanel(playerObj)
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
            if sandbox.PhunZones_ShowZoneChange then
                oldLocation = oldLocation or {}
                if location.title ~= oldLocation.title or location.subtitle ~= oldLocation.subtitle then
                    PhunZonesWelcome.OnOpenPanel(playerObj, location, oldLocation)
                end
            end
        end
    end)
