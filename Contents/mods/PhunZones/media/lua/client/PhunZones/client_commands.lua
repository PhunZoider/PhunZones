if isServer() then
    return
end
local tableTools = require("PhunZones/table")
local PZ = PhunZones
local PL = PhunLib
local Commands = {}

Commands[PZ.commands.playerSetup] = function(data)
    -- send any exemption/changes to the client
    ModData.add(PZ.const.modifiedModData, data)
    PZ:updateZoneData(true, data)

end

Commands[PZ.commands.playerTeleport] = function(data)
    PZ:portPlayer(PL.getPlayerByUsername(data.username), data.x, data.y, data.z)
end

Commands[PZ.commands.updatePlayerZone] = function(args)
    local p = nil
    for i = 0, getOnlinePlayers():size() - 1 do
        local player = getOnlinePlayers():get(i)
        if player:getOnlineID() == args.pid then
            p = player
            break
        end
    end

    if p then
        args.pid = nil
        local name = p:getUsername()
        if not PZ.players then
            PZ.players = ModData.getOrCreate(PZ.const.playerData)
        end
        local old = PZ:getPlayerData(p)
        local existing = old
        -- if PZ.settings.ShowZoneChange then
        --     if existing.title ~= args.title or existing.subtitle ~= args.subtitle and existing.isVoid ~= true then
        --         PZ.ui.welcome.OnOpenPanel(p, args)
        --     end
        -- end
        -- if existing.pvp and p.getSafety and p:getSafety():isEnabled() then
        --     getPlayerSafetyUI(p:getPlayerNum()):toggleSafety()
        -- elseif not p.getSafety and p:getSafety():isEnabled() then
        --     getPlayerSafetyUI(p:getPlayerNum()):toggleSafety()
        -- end
        PZ.players[name] = args
        p:getModData().PhunZones = args
        triggerEvent(PZ.events.OnPhunZonesPlayerLocationChanged, p, args, existing)
    end
end

return Commands
