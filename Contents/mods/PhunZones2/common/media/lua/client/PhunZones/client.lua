if isServer() then
    return
end

local Core = PhunZones

function Core:updatePlayers()

    local players = self.tools.onlinePlayers(not self.settings.ProcessOnClient)
    for i = 0, players:size() - 1, 1 do
        local p = players:get(i)
        self:updatePlayer(p)
    end
end

function Core:updatePlayer(playerObj)
    self.updateModData(playerObj, true)
end

function Core:updatePlayerUI(playerObj, info, existing)

    local zone = info or playerObj:getModData().PhunZones or {}
    local existing = existing or {}
    Core.ui.welcome.OnOpenPanel(playerObj, zone)

    if self.settings.Widget then
        local panel = Core.ui.widget.OnOpenPanel(playerObj)
        if panel then
            local data = {
                zone = zone
            }
            panel:setData(data)
        end
    end
end

function Core:showWidgets()
    local players = self.tools.onlinePlayers()
    for i = 0, players:size() - 1, 1 do
        local p = players:get(i)
        self:showWidget(p)
        self:updatePlayerUI(p)
    end

end

function Core:showWidget(playerObj)
    if self.settings.Widget then
        self.ui.widget.OnOpenPanel(playerObj)
    end
end

function Core:rvInteriorFlags(entering, args)
    if not self.settings.VehicleTracking then
        return
    end
    local player = nil
    local players = self.tools.onlinePlayers()
    for i = 0, players:size() - 1 do
        local p = players:get(i)
        if p:getOnlineID() == args.playerId then
            player = p
            break
        end
    end

    if player then
        local data = player:getModData().PhunZones

        if data then
            data.vehicleId = entering and data.lastVehicleId or nil
            data.inVehicleInterior = entering and args.interiorInstance or nil
        end
    end
end

-- Prevent bandits mod from spawning bandits in this zone
local BanditScheduler = BanditScheduler
if BanditScheduler then
    local oldfn = BanditScheduler.GenerateSpawnPoint

    function BanditScheduler.GenerateSpawnPoint(player, d)

        local zone = Core.getLocation(player:getX(), player:getY())

        if zone and zone.bandits == false then
            return false
        end

        return oldfn(player, d)

    end
end
