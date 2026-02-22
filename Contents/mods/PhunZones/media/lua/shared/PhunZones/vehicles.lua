require "PhunZones/core"
local Core = PhunZones
local getNumClassFields = getNumClassFields
local getClassField = getClassField
local getClassFieldVal = getClassFieldVal

local fieldName = 'public final zombie.core.physics.Transform zombie.vehicles.BaseVehicle.jniTransform'

function Core.teleportVehicleToCoords(player, vehicle, x, y, z)

    if not vehicle then
        return
    end
    local fieldCount = getNumClassFields(vehicle)
    local transField = nil

    for i = 0, fieldCount - 1 do
        local field = getClassField(vehicle, i)
        if tostring(field) == fieldName then
            transField = field
        end
    end

    if transField then
        local v_transform = getClassFieldVal(vehicle, transField)
        local w_transform = vehicle:getWorldTransform(v_transform)
        local origin_field = getClassField(w_transform, 1)
        local origin = getClassFieldVal(w_transform, origin_field)
        origin:set(origin:x() - x, origin:y(), origin:z() - y)
        vehicle:setWorldTransform(w_transform)
        if isClient() then
            pcall(vehicle.update, vehicle)
            pcall(vehicle.updateControls, vehicle)
            pcall(vehicle.updateBulletStats, vehicle)
            pcall(vehicle.updatePhysics, vehicle)
            pcall(vehicle.updatePhysicsNetwork, vehicle)
        end
    end

end

local rvInterior
local excludedTrackingProps = {"rv", "isVoid", "bandits", "zeds", "zones", "zone", "region", "x", "y", "vehicleId"}

Core.registerZoneOverride("rv", function(obj, physicalZone)
    if not physicalZone.rv then
        return nil
    end
    -- ... resolve vehicle position, return merged table or nil

    if rvInterior == nil then
        rvInterior = RVInterior or false
    end
    if not rvInterior then
        return false
    end
    local interior = rvInterior.calculatePlayerInteriorInstance(obj)
    if not interior then
        return false
    end

    local tracked = Core.trackedVehicles and Core.trackedVehicles[interior.interiorInstance]
    if not tracked then
        return false
    end

    local zone = Core.getLocation(tracked.x or 0, tracked.y or 0)
    if not zone or zone.key == existing.mkey then
        return false
    end

    for k, v in pairs(zone) do
        local excluded = false
        for _, ek in ipairs(excludedTrackingProps) do
            if ek == k then
                excluded = true;
                break
            end
        end
        if not excluded then
            existing[k] = v
        end
    end

    new.mkey = zone.key
    return true
end, 10)
