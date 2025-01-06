if not isClient() and isServer() then
    return
end
local PZ = PhunZones

function PZ:updatePlayerUI(playerObj, info)
    local zone = info or playerObj:getModData().PhunZones or {}

    -- self:debug("UPDATE PLAYER UI", zone)

    local panel = PZ.ui.widget.OnOpenPanel(playerObj)
    if panel then
        local data = {
            zone = {
                title = zone.title or nil,
                subtitle = zone.subtitle or nil
            }
        }
        panel:setData(data)
    end
end

function PZ:showWidgets()

    local players = self:onlinePlayers()
    for i = 0, players:size() - 1, 1 do
        local p = players:get(i)
        self:showWidget(p)
        self:updatePlayerUI(p)
    end

end

function PZ:showWidget(playerObj)
    if self.settings.Widget then
        self.ui.widget.OnOpenPanel(playerObj)
    end
end

function PZ:rvInteriorFlags(entering, args)
    if not self.settings.VehicleTracking then
        return
    end
    local player = nil
    for i = 0, getOnlinePlayers():size() - 1 do
        local p = getOnlinePlayers():get(i)
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

        -- self:debug("new data", data)
    end
end

-- Prevent bandits mod from spawning bandits in this zone
local BanditScheduler = BanditScheduler
if BanditScheduler then
    local oldfn = BanditScheduler.GenerateSpawnPoint

    function BanditScheduler.GenerateSpawnPoint(player, d)

        local zone = PZ:getLocation(player:getX(), player:getY())

        if zone and zone.bandits == false then
            return false
        end

        return oldfn(player, d)

    end
end
