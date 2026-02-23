local Core = PhunZones
local sh = nil

function Core.iniSafehouses()
    if sh == nil then
        sh = SafeHouse.canBeSafehouse
        SafeHouse.canBeSafehouse = function(square, player)
            local md = Core.getLocation(square) or {}
            if md.safehouse == false then
                return getText("IGUI_PhunZones_SayNoSafeHouse")
            end

            return sh(square, player)
        end
    end
end
