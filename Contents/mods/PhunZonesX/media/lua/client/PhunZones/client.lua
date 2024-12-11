if not isClient() then
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
    for i = 0, getOnlinePlayers():size() - 1 do
        local p = getOnlinePlayers():get(i)
        if p:isLocalPlayer() then
            self:showWidget(p)
            self:updatePlayerUI(p)
        end
    end
end

function PZ:showWidget(playerObj)
    self.ui.widget.OnOpenPanel(playerObj)
end

function PZ:updatePlayers()
    for i = 0, getOnlinePlayers():size() - 1 do
        local p = getOnlinePlayers():get(i)
        if p:isLocalPlayer() then
            self:updatePlayer(p)
        end
    end
end

function PZ:updatePlayer(playerObj)
    local result = PZ:updateModData(playerObj)
    if result then
        playerObj:setHaloNote("Welcome to " .. result.title .. (result.subtitle and " - " .. result.subtitle or ""))
    end
end
