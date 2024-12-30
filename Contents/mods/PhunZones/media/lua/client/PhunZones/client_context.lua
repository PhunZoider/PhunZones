if isServer() then
    return
end

local PZ = PhunZones

function PZ:showContext(playerObj, context, worldobjects)

    if isAdmin() or isDebugEnabled() then
        -- is there a Phun option?
        local phun = nil
        for _, v in ipairs(context.options or {}) do
            if v and v.name == "PhunZoid" then
                phun = v
                break
            end
        end

        if not phun then
            phun = context:addOption("PhunZoid", worldobjects, nil)
        end

        local sub = ISContextMenu:getNew(context)
        sub:addOption(PZ.name .. " Admin", worldobjects, function()
            local player = playerObj and getSpecificPlayer(playerObj) or getPlayer()
            PZ.ui.zones.OnOpenPanel(player)
        end)
        context:addSubMenu(phun, sub)
    end

end
