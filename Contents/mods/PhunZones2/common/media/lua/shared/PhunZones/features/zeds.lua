if isServer() then
    return
end
local Core = PhunZones

local bandits2Active = getActivatedMods():contains("Bandits2")

-- Evicts (moves) zeds/bandits out of a zone. Called for zones set to Move.
-- Removal is handled client-side in client_events via sendClientCommand.
-- Bandits are stopped from spawning in the first place in features/bandits.
Core.evictZeds = function(playerObj, zoneKey)
    if not playerObj or not zoneKey then
        return
    end

    local zone = Core.data.lookup[zoneKey] or {}
    local shouldEvictZeds = Core.zedAction(zone, "zeds") == "move"
    local shouldEvictBandits = bandits2Active and Core.banditAction(zone) == "move"

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
