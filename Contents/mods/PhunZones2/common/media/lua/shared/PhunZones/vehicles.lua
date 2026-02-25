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
        vehicle:setForceBrake()
        local v_transform = getClassFieldVal(vehicle, transField)
        local w_transform = vehicle:getWorldTransform(v_transform)
        local origin_field = getClassField(w_transform, 1)
        local origin = getClassFieldVal(w_transform, origin_field)
        local lx = origin:x()
        local ly = origin:y()
        local lz = origin:z()
        origin:set(lx - x, ly, lz - y)
        -- origin:set(origin:x() - x, origin:y() - y, origin:z() - z)
        -- origin:set(x, y, z)

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

Events[Core.events.OnPhysicalZoneChanged].Add(function(obj, stored)
    if rvInterior == nil then
        rvInterior = RVInterior or false
    end
    if not rvInterior then
        return
    end

    local interior = rvInterior.calculatePlayerInteriorInstance(obj)
    if not interior then
        return
    end

    local tracked = Core.trackedVehicles and Core.trackedVehicles[interior.interiorInstance]
    if not tracked then
        return
    end

    local zone = Core.getLocation(tracked.x or 0, tracked.y or 0)
    if not zone or zone.key == stored.effective.zone then
        return
    end

    Core.setEffectiveZone(obj, zone.key, tracked.x, tracked.y, tracked.z or 0)
end)
