if not isServer() then
    return
end
local Core = PhunZones

Events.OnClientCommand.Add(function(module, command, playerObj, arguments)
    if module == "RVServer" then
        local modData = ModData.getOrCreate("modPROJECTRVInterior")
        Core.debug("RVServer Command", command, modData)
        if command == "UpdateVehPos" then
            Core.debug("Update Vehicle", arguments)
        elseif command == "enterRV" then
            Core.debug("Enter RV", arguments)
        end
    end
end)

