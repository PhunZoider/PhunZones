if isServer() then
    return
end
local PZ = PhunZones
local mainName = "PhunZones"
function PZ:showContext(playerIndex, context, worldobjects)

    if isAdmin() or isDebugEnabled() then
        local player = getSpecificPlayer(playerIndex) or getPlayer()
        local option = context:addOptionOnTop(PZ.name, context, function()
            PZ.ui.zones.OnOpenPanel(player)
        end, playerIndex)
    end

end

function PZ:appendContext(context, mainMenu, playerObj, worldobjects)

    -- local sub = ISContextMenu:getNew(context)
    -- context:addSubMenu(mainMenu, sub)
    -- sub:addOption(PZ.name, nil, function()
    --     local player = playerObj and getSpecificPlayer(playerObj) or getPlayer()
    --     PZ.ui.zones.OnOpenPanel(player)
    -- end)

end
