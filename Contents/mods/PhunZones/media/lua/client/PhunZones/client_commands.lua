if isServer() then
    return
end
local PZ = PhunZones

local Commands = {}

Commands[PZ.commands.playerSetup] = function(data)
    print("================")
    print("playerSetup")
    print("================")
    -- send any exemption/changes to the client
    ModData.add(PZ.const.modifiedModData, data)
    PZ:getZones(true, data)

end

return Commands
