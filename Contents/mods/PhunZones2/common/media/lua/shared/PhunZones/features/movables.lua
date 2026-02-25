require "BuildingObjects/ISBuildingObject"
local Core = PhunZones

if ISMoveablesAction then
    local oldISMoveablesAction = ISMoveablesAction.isValid
    function ISMoveablesAction:isValid()
        local square = self.character:getSquare();

        if not square then
            return false
        end
        local zone = Core.getEffectiveZone(self.character)
        if zone and zone.noplacing == true and self.mode == "place" then
            self.character:setHaloNote(getText("IGUI_PhunZones_SayNoPlacing"), 255, 255, 0, 300);
            return false
        elseif zone and zone.nopickup == true and self.mode == "pickup" then
            self.character:setHaloNote(getText("IGUI_PhunZones_SayNoPickup"), 255, 255, 0, 300);
            return false
        elseif zone and zone.noscrap == true and self.mode == "scrap" then
            self.character:setHaloNote(getText("IGUI_PhunZones_SayNoScrap"), 255, 255, 0, 300);
            return false
        end
        return oldISMoveablesAction(self, square)
    end
end
