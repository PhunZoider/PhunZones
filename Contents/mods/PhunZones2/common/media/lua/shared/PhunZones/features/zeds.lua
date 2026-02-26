if isServer() then
    return
end
local Core = PhunZones

local activeMods = getActivatedMods()
local bandits2Active = activeMods:contains("\\Bandits2")

-- Evicts (moves) zeds/bandits out of a zone. Called for zones with action=1 (Move).
-- Removal (action=2) is handled client-side in client_events via sendClientCommand.
Core.evictZeds = function(playerObj, zoneKey)
    if not playerObj or not zoneKey then
        return
    end

    local zone = Core.data.lookup[zoneKey] or {}
    local shouldEvictZeds = tonumber(zone.zeds) == 2
    local shouldEvictBandits = bandits2Active and tonumber(zone.bandits) == 2

    if not shouldEvictZeds and not shouldEvictBandits then
        return
    end

    local zombies = playerObj:getCell():getZombieList()
    for i = 0, zombies:size() - 1 do
        local zed = zombies:get(i)
        if instanceof(zed, "IsoZombie") then
            local zedZone = Core.getLocation(zed:getX(), zed:getY())
            if zedZone and zedZone.key == zoneKey then
                local isBandit = bandits2Active and zed:getModData().brain ~= nil
                local shouldEvict = (isBandit and shouldEvictBandits) or (not isBandit and shouldEvictZeds)
                if shouldEvict then
                    local ex, ey, ez = Core.findNearestSafePosition(zed:getX(), zed:getY(), zed:getZ(), zoneKey)
                    if ex then
                        zed:setX(ex + ZombRand(-2, 2))
                        zed:setY(ey + ZombRand(-2, 2))
                        zed:setZ(ez)
                    end
                end
            end
        end
    end
end

if bandits2Active then
    -- Prevent bandits mod from spawning bandits in zones with any bandit action set
    local BanditScheduler = BanditScheduler
    if BanditScheduler then
        local oldfn = BanditScheduler.GenerateSpawnPoint

        function BanditScheduler.GenerateSpawnPoint(player, d)

            local zone = Core.getLocation(player:getX(), player:getY())

            if zone and (tonumber(zone.bandits) or 0) > 1 then
                return false
            end

            return oldfn(player, d)

        end
    end
end
