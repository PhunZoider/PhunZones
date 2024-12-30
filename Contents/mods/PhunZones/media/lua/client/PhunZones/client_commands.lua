if isServer() then
    return
end
local tableTools = require("PhunZones/table")
local PZ = PhunZones

local Commands = {}

Commands[PZ.commands.playerSetup] = function(data)
    -- send any exemption/changes to the client
    ModData.add(PZ.const.modifiedModData, data)
    PZ:getZones(true, data)

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
        local pz = PZ
        if not pz.players then
            pz.players = ModData.getOrCreate(PZ.const.playerData)
        end
        local old = pz:getPlayerData(p)
        local existing = tableTools:shallowCopyTable(old)
        if existing.title ~= args.title or existing.subtitle ~= args.subtitle and existing.isVoid ~= true then
            PZ.ui.welcome.OnOpenPanel(p, args)
        end
        if existing.pvp and p:getSafety():isEnabled() then
            getPlayerSafetyUI(p:getPlayerNum()):toggleSafety()
        elseif not p:getSafety():isEnabled() then
            getPlayerSafetyUI(p:getPlayerNum()):toggleSafety()
        end
        PZ:updatePlayerUI(p, args)
        PZ.players[name] = args
        triggerEvent(PZ.events.OnPhunZonesPlayerLocationChanged, p, args, existing)
    end
end

return Commands
