require "BuildingObjects/ISBuildingObject"
local Core = PhunZones
local oldIsValid = ISBuildingObject.isValid
function ISBuildingObject:isValid(square)
    if not square then
        return false
    end
    local zone = Core:getLocation(square)
    if zone and zone.build == false then
        return false
    end
    return oldIsValid(self, square)
end
