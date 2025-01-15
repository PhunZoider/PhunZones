if isClient() then
    return
end
local PZ = PhunZones

function PZ:updatePlayers()
    local players = self:onlinePlayers(true)
    for i = 0, players:size() - 1, 1 do
        local p = players:get(i)
        self:updatePlayer(p)
    end
end

function PZ:updatePlayer(playerObj)
    self:updateModData(playerObj, true)
end

