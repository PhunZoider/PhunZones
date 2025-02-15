require "PhunZones/core"
local PZ = PhunZones
-- From RVinteriors mod
local modDataName = "rvInteriorMod"
local function checkModData(vehicleName)
    if not PZ.settings.VehicleTracking then
        return
    end
    if not ModData.exists(modDataName) then
        ModData.add(modDataName, {
            interiors = {}
        })
    end
    if vehicleName and ModData.get(modDataName).interiors[vehicleName] == nil then
        ModData.get(modDataName).interiors[vehicleName] = {
            interiorCount = 0,
            interiorData = {}
        }
    end
end

local function getInteriorModData(vehicleName, interiorInstance, create)
    if not PZ.settings.VehicleTracking then
        return
    end
    checkModData(vehicleName)
    if not interiorInstance then
        return ModData.get(modDataName).interiors[vehicleName]
    else
        local interiorData = ModData.get(modDataName).interiors[vehicleName].interiorData[interiorInstance]
        if interiorData or not create then
            return interiorData
        else
            return {}
        end
    end
end

function PZ:setTrackedVehicleData(vehicleId)

    if RVInterior and self.settings.VehicleTracking then
        if not self.trackedVehicles then
            self.trackedVehicles = {}
        end
        print("getting vehicle by id " .. tostring(vehicleId))
        local vehicle = getVehicleById(vehicleId)
        if vehicle and vehicle.getX then
            if RVInterior.interior[vehicle:getScript():getFullName()] then
                local vehicleModData = RVInterior.getVehicleModData(vehicle)
                if vehicleModData then
                    local interiorInstance = vehicleModData.interiorInstance
                    if not self.trackedVehicles[interiorInstance] then
                        self.trackedVehicles[interiorInstance] = {}
                    end
                    self.trackedVehicles[interiorInstance] = self:getLocation(vehicle)
                    self.trackedVehicles[interiorInstance].vehicleId = vehicleId
                    self.trackedVehicles[interiorInstance].x = vehicle:getX()
                    self.trackedVehicles[interiorInstance].y = vehicle:getY()
                end
            end
        end
    end
end
