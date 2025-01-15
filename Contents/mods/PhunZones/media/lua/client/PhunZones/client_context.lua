if isServer() then
    return
end
local PZ = PhunZones
local mainName = "PhunZones"
function PZ:showContext(playerObj, context, worldobjects)

    if isAdmin() or isDebugEnabled() then

        local mainMenu = nil
        local contextoptions = context:getMenuOptionNames()
        local mainMenu = contextoptions[mainName]

        if not mainMenu then
            -- there isn't one so create it
            mainMenu = context:addOption(mainName)
        end

        local sub = context:getNew(context)
        context:addSubMenu(mainMenu, sub)
        sub:addOption(PZ.name .. " Admin", worldobjects, function()
            local player = playerObj and getSpecificPlayer(playerObj) or getPlayer()
            PZ.ui.zones.OnOpenPanel(player)
        end)

    end

end
