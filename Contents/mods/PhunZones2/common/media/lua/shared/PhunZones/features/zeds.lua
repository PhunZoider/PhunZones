local Core = PhunZones

local activeMods = getActivatedMods()
local bandits2Active = activeMods:contains("\\Bandits2")

Core.evictZeds = function(playerObj, zoneKey)
    if not playerObj or not zoneKey then
        return
    end

    if isClient() then
        local zone = Core.data.lookup[zoneKey] or {}
        if zone.zeds == false or (bandits2Active and zone.bandits == false) then
            sendClientCommand(Core.name, Core.commands.evictZeds, { zone = zoneKey })
        end
        return
    end

    if not isServer() and not Core.isLocal then return end

    local zone = Core.data.lookup[zoneKey] or {}
    local shouldEvictZeds    = zone.zeds    == false
    local shouldEvictBandits = bandits2Active and zone.bandits == false

    if not shouldEvictZeds and not shouldEvictBandits then return end

    local zombies = playerObj:getCell():getZombieList()
    for i = 0, zombies:size() - 1 do
        local zed = zombies:get(i)
        if instanceof(zed, "IsoZombie") then
            local zedZone = Core.getLocation(zed:getX(), zed:getY())
            if zedZone and zedZone.key == zoneKey then
                local isBandit = bandits2Active and zed:getModData().brain ~= nil
                local shouldEvict = (isBandit and shouldEvictBandits) or
                                    (not isBandit and shouldEvictZeds)
                if shouldEvict then
                    local ex, ey, ez = Core.findNearestSafePosition(
                        zed:getX(), zed:getY(), zed:getZ(), zoneKey)
                    if ex then
                        zed:setX(ex + math.random(-2, 2))
                        zed:setY(ey + math.random(-2, 2))
                        zed:setZ(ez)
                        zed:resetPath()
                    end
                end
            end
        end
    end
end
