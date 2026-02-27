local Core = PhunZones
Core.iniBuilding = function()
    if ISBuildingObject then
        local oldTryBuild = ISBuildingObject.tryBuild
        function ISBuildingObject:tryBuild(x, y, z)
            local playerObj = getSpecificPlayer(self.player)
            local zone = Core.getLocation(x, y) or {}
            if zone and zone.nobuilding == true and self.sledgehammer == nil and self.cacheObject == nil then
                playerObj:setHaloNote(getText("IGUI_PhunZones_SayNoBuild"), 255, 255, 0, 300);
                return false
            end
            return oldTryBuild(self, x, y, z)
        end

        local oldFn = ISBuildingObject.isValid
        function ISBuildingObject:isValid(square)
            local playerObj = getSpecificPlayer(self.player)
            local zone = Core.getLocation(square) or {}
            if zone and zone.nobuilding == true and self.sledgehammer == nil and self.cacheObject == nil then
                playerObj:setHaloNote(getText("IGUI_PhunZones_SayNoBuild"), 255, 255, 0, 300);
                return false
            end
            return oldFn(self, square)
        end
    end
    if ISBuildIsoEntity then
        local oldIsoEntityIsValid = ISBuildIsoEntity.isValid
        function ISBuildIsoEntity:isValid(square)
            local playerObj = getSpecificPlayer(self.player)
            local zone = Core.getLocation(square) or {}
            if zone and zone.nobuilding == true and self.sledgehammer == nil and self.cacheObject == nil then
                playerObj:setHaloNote(getText("IGUI_PhunZones_SayNoBuild"), 255, 255, 0, 300);
                return false
            end
            return oldIsoEntityIsValid(self, square)
        end
    end

    if ISMoveableCursor then
        local oldISMoveableCursorIsValid = ISMoveableCursor.isValid
        function ISMoveableCursor:isValid(square)
            if not square then
                return false
            end
            local zone = Core.getLocation(square) or {}
            if zone and zone.noplacing == true then
                getSpecificPlayer(0):setHaloNote(getText("IGUI_PhunZones_SayNoPlacing"), 255, 255, 0, 300);
                return false
            end
            return oldISMoveableCursorIsValid(self, square)
        end
    end

    if buildUtil then
        local oldBuildUtilCanBePlace = buildUtil.canBePlace
        function buildUtil.canBePlace(...)
            local playerObj = getSpecificPlayer(0)
            local zone = Core.getEffectiveZone(playerObj)
            if zone and zone.nobuilding == true then
                playerObj:setHaloNote(getText("IGUI_PhunZones_SayNoBuild"), 255, 255, 0, 300);
                return false
            end
            return oldBuildUtilCanBePlace(...)
        end

    end

end
