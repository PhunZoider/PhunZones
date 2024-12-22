if isServer() then
    return
end

local PZ = PhunZones

function PZ:showContext(playerObj, context, worldobjects)

    if isAdmin() or isDebugEnabled() then
        context:addOption("PhunZones", worldobjects, function()
            local player = playerObj and getSpecificPlayer(playerObj) or getPlayer()
            PZ.ui.zones.OnOpenPanel(player)
        end)
    end

end
