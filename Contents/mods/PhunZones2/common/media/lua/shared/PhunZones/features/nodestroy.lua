local Core = PhunZones

local oldDestroyStuffAction = ISDestroyStuffAction["isValid"];

ISDestroyStuffAction["isValid"] = function(self)

    if self.character then

        local p = self.character
        local md = p:getModData().PhunZones

        if md.nodestruction == true then
            p:setHaloNote(getText("IGUI_PhunZones_SayNoDestruction"), 255, 255, 0, 300);
            return false
        end

    end
    return oldDestroyStuffAction(self)

end

if ISDestroyCursor then
    local oldISDestroyIsValid = ISDestroyCursor.isValid
    function ISDestroyCursor:isValid(square)
        if not square then
            return false
        end
        local noDestroy = Core.getLocation(square).nodestruction == true
        if noDestroy then
            self.character:setHaloNote(getText("IGUI_PhunZones_SayNoDestruction"), 255, 255, 0, 300);
            return false
        end
        return oldISDestroyIsValid(self, square)
    end
end
