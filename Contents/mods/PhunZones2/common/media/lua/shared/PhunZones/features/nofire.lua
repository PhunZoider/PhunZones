local Core = PhunZones

local isoBurning = nil
function Core.checkFire(fire)

    local square = fire:getSquare()
    local extinguish = Core.getLocation(square).nofire == true

    if extinguish then
        local fireSpread = getSandboxOptions():getOptionByName("FireSpread"):getValue()
        getSandboxOptions():set("FireSpread", false)
        Core.debugLn("NoFire zone detected, extinguishing fire. Fire spread is currently set to " ..
                         tostring(fireSpread))
        for i = 1, square:getMovingObjects():size() do
            local chr = square:getMovingObjects():get(i - 1)
            if instanceof(chr, "IsoGameCharacter") and chr:isOnFire() then
                if not isServer() then
                    if chr.sendStopBurning then
                        chr:sendStopBurning()
                    end
                    chr:StopBurning()
                else
                    stopFire(chr)
                end
            end
        end

        if not isServer() then
            square:transmitStopFire()
            square:stopFire()
        else
            stopFire(square)
        end
        getSandboxOptions():set("FireSpread", fireSpread)
    end

end
