if isClient() then
    return
end
local PZ = PhunZones

PZ.playersWithinZedlessZone = {}

function PZ:checkPlayersInZedlessZone()
    for k, v in pairs(self.playersWithinZedlessZone or {}) do
        if v then
            self:checkPlayerZedClear(v)
        end
    end
end

function PZ:checkPlayerZedClear(player)
    local data = player and player.getModData and player:getModData().PhunZones or {}
    if data and data.zeds == false then
        self:clearPlayerZeds(player, data)
    end
end
function PZ:clearPlayerZeds(player)

    local zombies = player:getCell():getZombieList()
    -- print("There are " .. tostring(zombies:size()) .. " zombies in " .. player:getUsername() .. " cell " ..
    --           tostring(player:getX()) .. ", " .. tostring(player:getY()))
    if zombies ~= nil then
        for i = zombies:size() - 1, 0, -1 do
            local zombie = zombies:get(i)
            local x, y = zombie:getX(), zombie:getY()
            if instanceof(zombie, "IsoZombie") then
                local zone = self:getLocation(zombie)
                if zone.zeds == false then
                    -- print("Removing zombie " .. tostring(zombie:getOnlineID()))
                    zombie:removeFromWorld()
                    zombie:removeFromSquare()
                end
            end
        end
    end
end

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

