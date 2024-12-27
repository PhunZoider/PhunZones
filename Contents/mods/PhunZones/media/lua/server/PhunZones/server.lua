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
        print("Clearing zeds for " .. player:getUsername())
        self:clearPlayerZeds(player)
    end
end
function PZ:clearPlayerZeds(player)

    local zombies = player:getCell():getZombieList()
    print("There are " .. tostring(zombies:size()) .. " zombies in the player's cell")
    if zombie ~= nil then
        for i = zombies:size() - 1, 0, -1 do
            local zombie = zombies:get(i)
            if instanceof(zombie, "IsoZombie") then
                print("Removing zombie " .. tostring(zombie:getOnlineID()))
                zombie:removeFromWorld()
                zombie:removeFromSquare()
            end
        end
    end
end

