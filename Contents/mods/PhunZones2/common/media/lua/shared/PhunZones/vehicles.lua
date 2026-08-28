require "PhunZones/core"
local Core = PhunZones

-- ---------------------------------------------------------------------------
-- Vehicle relocation
--
-- B41 exposed Java reflection to Lua (getNumClassFields/getClassField/
-- getClassFieldVal), which let us reach BaseVehicle.jniTransform and move the
-- vehicle in physics space. B42 removed those globals, so that path is dead on
-- current builds -- and it died *silently*, because the old code just skipped
-- the teleport when the field lookup came up empty.
--
-- Everything below is therefore capability-probed and verified: each strategy
-- is tried under pcall, and the vehicle's actual position is checked afterwards
-- against the requested target. Nothing is assumed to have worked.
-- ---------------------------------------------------------------------------

-- How far (tiles) the vehicle may land from the requested target and still
-- count as a successful teleport. Catches both no-ops (didn't move) and bad
-- coordinate math (moved, but nowhere near where we asked).
local LANDING_TOLERANCE = 3

-- nil = not yet probed, false = unavailable on this build
local hasReflection = nil

local function reflectionAvailable()
    if hasReflection == nil then
        hasReflection = type(getNumClassFields) == "function" and type(getClassField) == "function" and
                            type(getClassFieldVal) == "function"
        if not hasReflection then
            Core.debugLn("vehicles: Java reflection unavailable on this build (B42+), using native transforms")
        end
    end
    return hasReflection
end

local function landedAt(vehicle, x, y)
    return math.abs(vehicle:getX() - x) <= LANDING_TOLERANCE and math.abs(vehicle:getY() - y) <= LANDING_TOLERANCE
end

-- Nudge the physics/network layers so the new position sticks and replicates.
local function resyncVehicle(vehicle)
    pcall(vehicle.setForceBrake, vehicle)
    pcall(vehicle.update, vehicle)
    pcall(vehicle.updateControls, vehicle)
    pcall(vehicle.updateBulletStats, vehicle)
    pcall(vehicle.updatePhysics, vehicle)
    pcall(vehicle.updatePhysicsNetwork, vehicle)
end

-- Strategy 1: freeze physics, move, thaw. This is the pattern vanilla's own
-- vehicle repositioning tool uses (ISVehicleAngles: setPhysicsActive(false,
-- false) while manipulating, setPhysicsActive(true, true) to drop). Without
-- the freeze the bullet physics step overwrites the new position on the very
-- next frame, which is why the plain setters alone look like they work and
-- then snap the vehicle back.
local function teleportFrozen(vehicle, x, y, z)
    if type(vehicle.setPhysicsActive) ~= "function" then
        return false
    end

    pcall(vehicle.setForceBrake, vehicle)
    pcall(vehicle.shutOff, vehicle)

    local ok = pcall(function()
        vehicle:setPhysicsActive(false, false)
        vehicle:setX(x)
        vehicle:setY(y)
        if z then
            vehicle:setZ(z)
        end
        -- Rebind the vehicle to the IsoGridSquare under its new position,
        -- otherwise it stays registered on the square it came from.
        pcall(vehicle.setCurrentSquareFromPosition, vehicle)
        vehicle:setPhysicsActive(true, true)
    end)

    -- Always try to thaw, even if the move threw partway through — a vehicle
    -- left with physics disabled is worse than one that failed to move.
    if not ok then
        pcall(vehicle.setPhysicsActive, vehicle, true, true)
        return false
    end

    resyncVehicle(vehicle)
    return landedAt(vehicle, x, y)
end

-- Strategy 2: native setters with no freeze. Retained for builds where
-- setPhysicsActive is absent or refuses; verified the same way.
local function teleportNative(vehicle, x, y, z)
    pcall(vehicle.setForceBrake, vehicle)
    local ok = pcall(function()
        vehicle:setX(x)
        vehicle:setY(y)
        if z then
            vehicle:setZ(z)
        end
    end)
    if not ok then
        return false
    end
    resyncVehicle(vehicle)
    return landedAt(vehicle, x, y)
end

-- Strategy 3: legacy B41 reflection into BaseVehicle.jniTransform.
-- Kept for older builds only; skipped entirely when reflection is gone.
local function teleportReflection(vehicle, x, y)
    if not reflectionAvailable() then
        return false
    end

    local transField = nil
    local ok = pcall(function()
        for i = 0, getNumClassFields(vehicle) - 1 do
            local field = getClassField(vehicle, i)
            -- Suffix match: the full signature string changed across builds
            -- (modifiers/declaring class), and an exact compare silently
            -- matched nothing.
            if tostring(field):find("BaseVehicle.jniTransform", 1, true) then
                transField = field
                break
            end
        end
    end)

    if not ok or not transField then
        Core.debugLn("vehicles: jniTransform field not found")
        return false
    end

    ok = pcall(function()
        vehicle:setForceBrake()
        local v_transform = getClassFieldVal(vehicle, transField)
        local w_transform = vehicle:getWorldTransform(v_transform)
        local origin_field = getClassField(w_transform, 1)
        local origin = getClassFieldVal(w_transform, origin_field)
        origin:set(origin:x() - x, origin:y(), origin:z() - y)
        vehicle:setWorldTransform(w_transform)
    end)

    if not ok then
        return false
    end

    if isClient() then
        resyncVehicle(vehicle)
    end
    return landedAt(vehicle, x, y)
end

-- Moves vehicle to (x, y, z). Returns true only if the vehicle actually ended
-- up at (or very near) the requested target -- callers must handle false.
function Core.teleportVehicleToCoords(player, vehicle, x, y, z)
    if not vehicle or not x or not y then
        return false
    end

    if teleportFrozen(vehicle, x, y, z) then
        Core.debugLn("vehicles: relocated via frozen-physics")
        return true
    end

    if teleportNative(vehicle, x, y, z) then
        Core.debugLn("vehicles: relocated via native setters")
        return true
    end

    if teleportReflection(vehicle, x, y) then
        Core.debugLn("vehicles: relocated via reflection")
        return true
    end

    Core.debugLn("vehicles: unable to relocate vehicle to " .. tostring(x) .. "," .. tostring(y))
    return false
end

-- Fallback for when the vehicle cannot be relocated on this build: stall it
-- where it stands. Deliberately brake only -- no shutOff, no ejecting the
-- driver -- so the player keeps control and can reverse back out under their
-- own power. Ejecting them would strand the vehicle inside the zone with no
-- way to retrieve it.
function Core.brakeVehicle(vehicle)
    if not vehicle then
        return
    end
    pcall(vehicle.setForceBrake, vehicle)
end
