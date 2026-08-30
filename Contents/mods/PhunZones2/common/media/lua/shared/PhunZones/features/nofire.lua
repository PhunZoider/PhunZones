local Core = PhunZones

-- NOTE: the staff exemption (Core.isExempt) deliberately does not apply here.
-- Every other "No ..." restriction blocks an action a specific player is taking,
-- so there is somebody to check. Fire is environmental: OnNewFire hands us the
-- fire and nothing else, with no way to tell who or what started it. Exempting
-- on "an exempt player is standing there" would suppress fire inconsistently
-- tile by tile as it spread, and exempting the whole zone while staff are in it
-- would hand any player who followed them in a free burn. A nofire zone is
-- therefore a nofire zone for everyone.
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
