require "BuildingObjects/ISBuildingObject"
local Core = PhunZones
if ISBuildingObject then
    local oldTryBuild = ISBuildingObject.tryBuild
    function ISBuildingObject:tryBuild(x, y, z)
        local playerObj = getSpecificPlayer(self.player)
        local zone = playerObj:getModData().PhunZones or {}
        if zone and zone.nobuilding == true and self.sledgehammer == nil and self.cacheObject == nil then
            playerObj:setHaloNote(getText("IGUI_PhunZones_NoBuild"), 255, 255, 0, 300);
            return false
        end
        return oldTryBuild(self, x, y, z)
    end
end
if ISMoveablesAction then
    local oldISMoveablesAction = ISMoveablesAction.isValid
    function ISMoveablesAction:isValid()
        local square = self.character:getSquare();

        if not square then
            return false
        end
        local zone = self.character:getModData().PhunZones or {}
        if zone and zone.noplacing == true and self.mode == "place" then
            self.character:setHaloNote(getText("IGUI_PhunZones_NoPlacing"), 255, 255, 0, 300);
            return false
        elseif zone and zone.nopickup == true and self.mode == "pickup" then
            self.character:setHaloNote(getText("IGUI_PhunZones_NoPickup"), 255, 255, 0, 300);
            return false
        elseif zone and zone.noscrap == true and self.mode == "scrap" then
            self.character:setHaloNote(getText("IGUI_PhunZones_NoScrap"), 255, 255, 0, 300);
            return false
        end
        return oldISMoveablesAction(self, square)
    end
end
