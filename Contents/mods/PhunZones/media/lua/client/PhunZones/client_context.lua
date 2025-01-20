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

    local md = getSpecificPlayer(playerObj):getModData().PhunZones

    if md.sledgehammer == false then
        for i, option in ipairs(context.options) do
            if option.name == getText("ContextMenu_Destroy") and option.notAvailable == false then
                option.notAvailable = true
                option.toolTip = getText("Tooltip_NoSledgehammerHere")
            elseif option.name == getText("ContextMenu_Dismantle") or option.name == getText("ContextMenu_Disassemble") and
                option.notAvailable == false then
                option.notAvailable = true
                option.toolTip = getText("Tooltip_NoDissasembleHere")
            end
        end
    end

    if md.safehouse == false then
        for i, option in ipairs(context.options) do
            if option.name == getText("ContextMenu_SafehouseClaim") and option.notAvailable == false then
                option.noAvailable = true
                option.toolTip = getText("Tooltip_NoClaimHere")
            end
        end
    end

end
