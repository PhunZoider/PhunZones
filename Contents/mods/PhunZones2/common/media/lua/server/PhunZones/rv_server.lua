if not isServer() then
    return
end
local Core = PhunZones

local activeMods = getActivatedMods()
if not activeMods:contains("\\PROJECTRVInterior42") then
    print("[PhunZones]PROJECTRVInterior42 not active, skipping integration")
    return
else
    print("[PhunZones] PROJECTRVInterior42 active, loading integration")
end

require "RVServerMP_V3"

local oldGetInToRV = GetInToRV
function GetInToRV(player, vehicle)

    local result = oldGetInToRV(player, vehicle)

    local rvPlayerId = player:getModData().projectRV_playerId
    local modData = ModData.getOrCreate("modPROJECTRVInterior")

    local md = ModData.getOrCreate("PhunZonesRVInfo")

    md.players = md.players or {}
    md.players[player:getUsername()] = {}

    local p = modData.Players and modData.Players[rvPlayerId]
    if not p then
        return result
    end
    local v = modData.Vehicles[p.VehicleId]

    if v and v.x then
        md.players[player:getUsername()] = {
            vid = p.VehicleId,
            zone = (Core.getLocation(v.x, v.y) or {}).key
        }
    end

    return result
end

local oldRVServerGetOutFromRV = RVServer.GetOutFromRV
function RVServer.GetOutFromRV(player, vehicle)
    local result = oldRVServerGetOutFromRV(player, vehicle)
    local md = ModData.getOrCreate("PhunZonesRVInfo")
    md.players = md.players or {}
    md.players[player:getUsername()] = nil
    return result
end

local function processVehicleZoneChanges()
    local md = ModData.getOrCreate("PhunZonesRVInfo")
    local rvData = ModData.getOrCreate("modPROJECTRVInterior")

    for k, v in pairs(md.players or {}) do
        local vehicleData = rvData.Vehicles[v.vid]
        if vehicleData then
            local loc = Core.getLocation(vehicleData.x, vehicleData.y)
            if loc and loc.key and loc.key ~= v.zone then
                Core.debugLn(k .. "'s vehicle zone changed from " .. tostring(v.zone) .. " to " .. tostring(loc.key))
                local player = Core.tools.getPlayerByUsername(k)
                if player then
                    sendServerCommand(player, Core.name, Core.commands.updateEffectiveZone, {
                        player = k,
                        zone = loc.key
                    })
                end
                v.zone = loc.key
            end
        end
    end
end

Events[Core.events.OnPhunZoneReady].Add(function()

    local nextCheck = 0
    Events.OnTick.Add(function()
        if getTimestamp() >= nextCheck then
            nextCheck = getTimestamp() + (Core.settings.updateInterval or 2)
            processVehicleZoneChanges()
        end
    end)

end)

