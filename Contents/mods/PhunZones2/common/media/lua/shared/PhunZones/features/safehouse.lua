local Core = PhunZones
local sh = nil

function Core.iniSafehouses()
    if sh == nil then

        sh = ISWorldObjectContextMenu.onTakeSafeHouse

        ISWorldObjectContextMenu.onTakeSafeHouse = function(worldobjects, square, player)
            local playerObj = getSpecificPlayer(player)
            local md = Core.getLocation(square) or {}
            if md.nosafehouse == true then
                playerObj:setHaloNote(getText("IGUI_PhunZones_SayNoSafeHouse"), 255, 255, 0, 300);
                return false
            end

            return sh(worldobjects, square, player)
        end

    end
end
