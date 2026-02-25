if not isClient() then
    return
end
local Core = PhunZones

Events.EveryOneMinute.Add(function()

    local modData = ModData.getOrCreate("modPROJECTRVInterior")
    local player = getSpecificPlayer(0)

    if player then
        local md = player:getModData()

    end

end)

-- On physical zone change: if entering rv zone, pin effective to vehicle's zone
Events[Core.events.OnPhysicalZoneChanged].Add(function(obj, stored, oldPhysical)
    if not instanceof(obj, "IsoPlayer") then
        return
    end

    local physZone = Core.data.lookup[stored.physical.zone] or {}
    if not physZone.rv then
        return
    end -- not an RV interior, nothing to do

    local vi = obj:getModData().PhunZonesVehicleInfo or {}
    local vehicleId = vi.vehicleId
    if not vehicleId then
        return
    end

    -- Try live vehicle ref first; fall back to server-tracked position
    local vx, vy, vz
    local vehicle = obj:getVehicle()
    if vehicle then
        vx, vy, vz = vehicle:getX(), vehicle:getY(), vehicle:getZ()
    else
        local tracked = Core.trackedVehicles and Core.trackedVehicles[vehicleId]
        if not tracked then
            return
        end
        vx, vy, vz = tracked.x, tracked.y, tracked.z or 0
    end

    local zone = Core.getLocation(vx, vy)
    if zone and zone.key ~= stored.effective.zone then
        Core.setEffectiveZone(obj, zone.key, vx, vy, vz)
    end
end)

-- Periodic update: if player is in rv interior and vehicle has moved zones, push update
-- (this is the client side of the "vehicle moving while offmap" case)

