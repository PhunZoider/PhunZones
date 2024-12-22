if not isClient() and isServer() then
    return
end
local PZ = PhunZones

function PZ:updatePlayerUI(playerObj, info)
    local zone = info or playerObj:getModData().PhunZones or {}
    local panel = PZ.ui.widget.OnOpenPanel(playerObj)
    if panel then
        local data = {
            zone = {
                title = zone.title or nil,
                subtitle = zone.subtitle or nil
            }
        }
        -- if zone.isVoid then
        --     data.title = "Hiding"
        -- end
        panel:setData(data)
    end
end

function PZ:showWidgets()
    local players = self:onlinePlayers()
    for i = 0, players:size() - 1, 1 do
        local p = players:get(i)
        self:showWidget(p)
        self:updatePlayerUI(p)
    end
end

function PZ:showWidget(playerObj)
    self.ui.widget.OnOpenPanel(playerObj)
end

function PZ:updatePlayers()
    local players = self:onlinePlayers()
    for i = 0, players:size() - 1, 1 do
        local p = players:get(i)
        self:updatePlayer(p)
    end
end

function PZ:updatePlayer(playerObj)
    if not (UIManager.getSpeedControls() and UIManager.getSpeedControls():getCurrentGameSpeed() == 0) then
        self:updateModData(playerObj)
    else
        print("is paused")
    end
end
