if isServer() then
    return
end
local Core = PhunZones

local activeMods = getActivatedMods()
local bandits2Active = activeMods:contains("\\Bandits2")

Core.evictZeds = function(playerObj, zoneKey)
    if not playerObj or not zoneKey then
        return
    end

    local zone = Core.data.lookup[zoneKey] or {}
    if not zone.nozeds and not (bandits2Active and zone.nobandits) then
        return
    end
    local shouldEvictZeds = zone.nozeds == true
    local shouldEvictBandits = bandits2Active and zone.nobandits == true

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
                        local offset = ZombRand(-2, 2)
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
    -- Prevent bandits mod from spawning bandits in this zone
    local BanditScheduler = BanditScheduler
    if BanditScheduler then
        local oldfn = BanditScheduler.GenerateSpawnPoint

        function BanditScheduler.GenerateSpawnPoint(player, d)

            local zone = Core.getLocation(player:getX(), player:getY())

            if zone and zone.nobandits then
                return false
            end

            return oldfn(player, d)

        end
    end
end
