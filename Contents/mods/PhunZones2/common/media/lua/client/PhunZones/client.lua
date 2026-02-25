if isServer() then
    return
end

local Core = PhunZones

function Core:updatePlayers()

    local players = self.tools.onlinePlayers(not self.settings.ProcessOnClient)
    for i = 0, players:size() - 1, 1 do
        local p = players:get(i)
        self:updatePlayer(p)
    end
end

function Core:updatePlayer(playerObj)
    self.updateModData(playerObj, true)
end

function Core:updatePlayerUI(playerObj, zone)
    zone = zone or Core.getEffectiveZone(playerObj)
    Core.ui.welcome.OnOpenPanel(playerObj, zone)

    if self.settings.Widget then
        local panel = Core.ui.widget.OnOpenPanel(playerObj)
        if panel then
            local data = {
                zone = zone
            }
            panel:setData(data)
        end
    end
end

function Core:showWidgets()
    local players = self.tools.onlinePlayers()
    for i = 0, players:size() - 1, 1 do
        local p = players:get(i)
        self:showWidget(p)
        self:updatePlayerUI(p)
    end

end

function Core:showWidget(playerObj)
    if self.settings.Widget then
        self.ui.widget.OnOpenPanel(playerObj)
    end
end
