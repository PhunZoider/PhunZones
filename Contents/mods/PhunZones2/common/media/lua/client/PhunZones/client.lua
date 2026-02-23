if not isClient() and isServer() then
    return
end
local PZ = PhunZones

local getSandboxOptions = getSandboxOptions

if ISSafetyUI and ISSafetyUI.prerender then

    local old_pvp_prerender = ISSafetyUI.prerender
    function ISSafetyUI:prerender()
        old_pvp_prerender(self)
        PZ:ISSafetyPrerender(self.character)
    end
end

function PZ:ISSafetyPrerender(player)

    if not getPlayerSafetyUI then
        -- newer versions have a different system for pvp. Disable for now
        return
    end

    local option = getSandboxOptions():getOptionByName("PhunZones.PvPMode"):getValue()

    if option == 3 then
        return
    end

    local data = player:getModData().PhunZones or {}
    if data.pvp == true then
        if option == 1 then
            if player.getSafety and player:getSafety():isEnabled() then
                getPlayerSafetyUI(player:getPlayerNum()):toggleSafety()
                player:getSafety():setEnabled(false)
            end
        end
    elseif data.pvp == false then
        if player.getSafety and not player:getSafety():isEnabled() then
            getPlayerSafetyUI(player:getPlayerNum()):toggleSafety()
            player:getSafety():setEnabled(true)
        end
    else
        player:getSafety():setEnabled(true)
    end
end

function PZ:updatePlayers()

    local players = self.tools.onlinePlayers(not self.settings.ProcessOnClient)
    for i = 0, players:size() - 1, 1 do
        local p = players:get(i)
        self:updatePlayer(p)
    end
end

function PZ:updatePlayer(playerObj)
    self.updateModData(playerObj, true)
end

function PZ:updatePlayerUI(playerObj, info, existing)

    local zone = info or playerObj:getModData().PhunZones or {}
    local existing = existing or {}
    PZ.ui.welcome.OnOpenPanel(playerObj, zone)

    if getPlayerSafetyUI and existing.pvp == true and playerObj.getSafety and playerObj:getSafety():isEnabled() then
        local a = self.safety
        local b = self.safetyBtn
        local ps = getPlayerSafetyUI
        local obj = ps(playerObj:getPlayerNum())
        obj:toggleSafety()
    elseif getPlayerSafetyUI and not existing.pvp and playerObj.getSafety and not playerObj:getSafety():isEnabled() then
        getPlayerSafetyUI(playerObj:getPlayerNum()):toggleSafety()
    end

    if self.settings.Widget then
        local panel = PZ.ui.widget.OnOpenPanel(playerObj)
        if panel then
            local data = {
                zone = zone
            }
            panel:setData(data)
        end
    end
end

function PZ:showWidgets()
    local players = self.tools.onlinePlayers()
    for i = 0, players:size() - 1, 1 do
        local p = players:get(i)
        self:showWidget(p)
        self:updatePlayerUI(p)
    end

end

function PZ:showWidget(playerObj)
    if self.settings.Widget then
        self.ui.widget.OnOpenPanel(playerObj)
    end
end

local isoBurning = nil
function PZ:checkFire(fire)
    if isoBurning == nil then
        isoBurning = IsoFlagType.burning
    end

    local square = fire:getSquare()
    local extinguish = self.getLocation(square).fire == false

    if extinguish then

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

        if square and square.Is and square:Is(isoBurning) then
            square:transmitStopFire()
            square:stopFire()
        elseif square and square.has and square:has(isoBurning) then
            if not isServer() then
                square:transmitStopFire()
                square:stopFire()
            else
                stopFire(square)
            end
        end

    end

end

function PZ:rvInteriorFlags(entering, args)
    if not self.settings.VehicleTracking then
        return
    end
    local player = nil
    local players = self.tools.onlinePlayers()
    for i = 0, players:size() - 1 do
        local p = players:get(i)
        if p:getOnlineID() == args.playerId then
            player = p
            break
        end
    end

    if player then
        local data = player:getModData().PhunZones

        if data then
            data.vehicleId = entering and data.lastVehicleId or nil
            data.inVehicleInterior = entering and args.interiorInstance or nil
        end
    end
end

-- Prevent bandits mod from spawning bandits in this zone
local BanditScheduler = BanditScheduler
if BanditScheduler then
    local oldfn = BanditScheduler.GenerateSpawnPoint

    function BanditScheduler.GenerateSpawnPoint(player, d)

        local zone = PZ.getLocation(player:getX(), player:getY())

        if zone and zone.bandits == false then
            return false
        end

        return oldfn(player, d)

    end
end
