local PZ = PhunZones

-- local oldISMiniMapInner_render = ISMiniMapInner.render

-- -- This gets called when the mini map is open (even if the world map is open)
-- function ISMiniMapInner.render(self)
--     oldISMiniMapInner_render(self)

--     if PZ.ui and PZ.ui.widget then
--         for k, v in pairs(PZ.ui.widget.instances) do
--             local outer = getPlayerMiniMap(v.playerIndex)
--             v.minimapInfo = {
--                 x = self.parent.x,
--                 y = self.parent.y,
--                 w = self.parent.width,
--                 visible = (ISWorldMap_instance and ISWorldMap_instance:isVisible()),
--                 handle = outer.titleBar:isVisible()
--             }
--         end
--     end

-- end

Events[PZ.events.OnPhunZonesPlayerLocationChanged].Add(function(playerObj, zone)
    if not zone.noAnnounce then
        if not zone.isVoid then
            playerObj:setHaloNote((zone.title or "") .. (zone.subtitle and " - " .. zone.subtitle or ""))
        end
    end
end)

Events.EveryOneMinute.Add(function()
    PZ:updatePlayers()
end)

Events[PZ.events.OnPhunZonesPlayerLocationChanged].Add(function(playerObj, zone)
    PZ:updatePlayerUI(playerObj, zone)
end)

Events.OnReceiveGlobalModData.Add(function(tableName, tableData)
    if tableName == PZ.name .. "_Changes" then
        ModData.add(PZ.name .. "_Changes", tableData)
        PZ:processDataSet(PZ.data)
    end
end)

local function setup()
    Events.OnTick.Remove(setup)
    PZ:ini()
    PZ:showWidgets()
    sendClientCommand(PZ.name, PZ.commands.playerSetup, {})

end

Events.OnTick.Add(setup)
