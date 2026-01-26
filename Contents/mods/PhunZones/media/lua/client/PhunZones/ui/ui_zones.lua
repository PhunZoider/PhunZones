if isServer() then
    return
end
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)
local FONT_SCALE = FONT_HGT_SMALL / 14
local HEADER_HGT = FONT_HGT_MEDIUM + 2 * 2
local BUTTON_HGT = FONT_HGT_SMALL + 6
local LABEL_HGT = FONT_HGT_MEDIUM + 6

local PZ = PhunZones
local PL = PhunLib
local mapui = require("PhunZones/ui/ui_map")
local tools = require("PhunZones/ui/tools")
local profileName = "PhunZonesUIList"
PZ.ui.zones = ISCollapsableWindowJoypad:derive(profileName);
PZ.ui.zones.instances = {}
local UI = PZ.ui.zones

function UI.OnOpenPanel(playerObj, key)

    if PL.isAdmin(getPlayer()) then

        local playerIndex = playerObj:getPlayerNum()

        local instance = UI:new(100, 100, 800, 500, playerObj, key);
        instance:initialise();
        instance:instantiate();
        -- ISLayoutManager.RegisterWindow(profileName, UI, UI.instances[playerIndex])

        instance:addToUIManager();
        instance:setVisible(true);
        instance:refreshData(PZ:getLocation(playerObj))

        for k, v in pairs(PZ.fields) do
            if v.initialize then
                v.initialize(instance, instance.data, playerObj)
            end
        end

        PZ.ui.zones.instances[playerIndex] = instance

        return instance
    end
end

function UI:refreshData(zone)

    self.controls.list:clear()
    self.controls.regions:clear()
    -- self.controls.regions:addOptionWithData(" -- Default --", {
    --     isDefault = true
    -- })
    local data = PZ:updateZoneData(not self.controls.chkAll:isSelected(1))

    local presort = {}
    local def = nil

    for k, v in pairs(data.lookup) do

        if k == "_default" then
            def = v
        else
            v.k = k
            table.insert(presort, v)
        end
    end
    table.sort(presort, function(a, b)
        if a.order and b.order then
            return a.order < b.order
        end
        if a.title and b.title then
            return a.title:lower() < b.title:lower()
        end
        return a.k < b.k
    end)

    local final = {}
    if def then
        final._default = def
    end
    for _, v in ipairs(presort) do
        final[v.k] = v
        final[v.k].k = nil
    end

    local selectedIndex = nil
    local index = 1
    self.data = data
    for k, v in pairs(final) do

        if zone and zone.region == k and zone.zone == "main" then
            selectedIndex = index
        end
        index = index + 1
        if k == "_default" then
            self.controls.regions:addOptionWithData(" -- Defaults --", v)
        else
            self.controls.regions:addOptionWithData(k, v.main)
            for zkey, zval in pairs(v) do
                if zkey ~= "main" then
                    index = index + 1
                    if zone and zone.region == k and zone.zone == zkey then
                        selectedIndex = index
                    end
                    self.controls.regions:addOptionWithData(("  |- " .. zkey), zval)
                end
            end

        end

    end
    self:setSelection(selectedIndex or 1)

end

function UI:setSelection(selection)

    self.controls.regions.selected = selection
    local opts = self.controls.regions.options[self.controls.regions.selected]
    local data = opts.data
    self:setData(data)
end

function UI:setData(data)

    self.selectedData = data
    if self.controls.btnNewSubRegion then
        self.controls.btnNewSubRegion.enable = data and data.zone == "main" and data.region ~= "_default"
        self.controls.btnNewRegion.enable = data and data.region ~= "_default"
        self.controls.btnNewZone.enable = data and data.region ~= "_default"
        self.controls.btnEditZone.enable = data and data.region ~= "_default"
        self.controls.deleteButton.enable = data and data.region ~= "_default"
    end
    self:refreshProperties(data)

end

function UI:refreshProperties(data, selected)
    self.selectedProperty = nil
    self.controls.list:clear()
    if not data then
        return
    end
    local zone = data.isDefault and self.data.zones._default or self.data.zones[data.region].zones[data.zone]
    for k, v in pairs(data) do
        if k ~= "region" and k ~= "zone" and k ~= "zones" then

            -- is this value overwriting the parent?

            self.controls.list:addItem(k, {
                property = k,
                value = v,
                overwritten = data.zone ~= "main" and zone[k] == nil
            })
        end
    end
    if #self.controls.list.items > 0 then
        self.controls.list.selected = selected or 1
        self.controls.list:ensureVisible(self.controls.list.selected)
        self.selectedProperty = self.controls.list.items[1].item
    end
    self:refreshZonePoints(zone.points or {})
end

function UI:saveData(data)

    local inherited = {}

    if data.region ~= "_default" then
        local zones = PZ.data.zones
        if data.zone ~= "main" then
            inherited = zones[data.region] or {}
        else
            inherited = zones._default or {}
        end
    end

    local md = ModData.get(PZ.const.modifiedModData)
    if not md[data.region] then
        md[data.region] = {}
    end
    if not md[data.region].subzones then
        md[data.region].subzones = {}
    end
    local segment = nil
    if data.zone ~= "main" then

        if not md[data.region].subzones[data.zone] then
            md[data.region].subzones[data.zone] = {}
        end
        if not md[data.region].subzones[data.zone].points then
            md[data.region].subzones[data.zone].points = {}
        end
        segment = md[data.region].subzones[data.zone]
    else
        if not md[data.region].points then
            md[data.region].points = {}
        end
        segment = md[data.region]
    end

    for k, v in pairs(PZ.fields) do
        -- these should already be cast to the correct type
        -- if data[k] ~= nil then
        local final
        if v.type == "string" then
            final = data[k]
        elseif v.type == "combo" then
            final = data[k] ~= "" and data[k] or nil
        elseif v.type == "int" then
            final = tonumber(data[k])
        elseif v.type == "boolean" then
            final = data[k]
        end

        local i = inherited[k]
        local f = final

        if k == "zone" or k == "region" or i ~= f then

            segment[k] = final
        else
            segment[k] = nil
        end
        -- end
    end

    PZ:saveChanges(md)
    self:refreshData({
        region = data.region,
        zone = data.zone
    })
end

function UI:savePoint(xy, pointIndex)
    local zone = self.data.zones[xy.region].zones[xy.zone]
    local point = zone.points[xy.point]

    local md = ModData.getOrCreate(PZ.const.modifiedModData)
    if not md[xy.region] then
        md[xy.region] = {}
    end
    if xy.zone ~= "main" then
        if not md[xy.region].subzones then
            md[xy.region].subzones = {}
        end
        if not md[xy.region].subzones[xy.zone] then
            md[xy.region].subzones[xy.zone] = {}
        end

        -- copy all existing points into modified data
        md[xy.region].subzones[xy.zone].points = zone.points

        if pointIndex then
            zone.points[pointIndex] = {xy.x, xy.y, xy.x2, xy.y2}
        else
            table.insert(zone.points, {xy.x, xy.y, xy.x2, xy.y2})
        end
    else

        if pointIndex then
            self.data.zones[xy.region].zones[xy.zone].points[pointIndex] = {xy.x, xy.y, xy.x2, xy.y2}
        else
            table.insert(self.data.zones[xy.region].zones[xy.zone].points, {xy.x, xy.y, xy.x2, xy.y2})
        end
        md[xy.region].points = self.data.zones[xy.region].zones[xy.zone].points
    end

    PZ:saveChanges(md)
    -- probably need to rebuild everything too
    self:refreshZonePoints(zone.points, self.controls.points.selected)
end

function UI:refreshZonePoints(points, selected)
    self.selectedPoint = nil
    self.controls.points:clear()
    for _, v in ipairs(points or {}) do
        self.controls.points:addItem("", {
            x = v[1],
            y = v[2],
            x2 = v[3],
            y2 = v[4]
        })
    end
    if self.controls.points.items and #self.controls.points.items > 0 then
        if not selected or selected == 0 then
            selected = 1
        end
        if selected > #self.controls.points.items then
            selected = #self.controls.points.items
        end
        self.controls.points.selected = selected or 1
        self.controls.points:ensureVisible(self.controls.points.selected)
        self.selectedPoint = self.controls.points.items[self.controls.points.selected].item
    end
    self.controls.mapui:setData(points, self.selectedPoint)
end

function UI:createChildren()
    ISCollapsableWindowJoypad.createChildren(self);
    local th = self:titleBarHeight()
    local rh = self:resizeWidgetHeight()

    local padding = 10
    local x = padding
    local y = th

    local h = self.height - rh - th
    local w = 440;

    local mapx = w + padding
    self.controls = {}

    local map = mapui:new(mapx, y, self.width - mapx - (padding), self.height - (padding * 2), self.player, "map");

    map:initialise();
    map:instantiate();
    self:addChild(map);
    self.controls.mapui = map

    local title = ISLabel:new(x, y, tools.BUTTON_HGT, getText("IGUI_PhunZones_Regions"), 1, 1, 1, 1, UIFont.Small, true);
    title:initialise();
    title:instantiate();
    self.controls.title = title
    self:addChild(title);

    local chkAll = ISTickBox:new(title.x + title.width + padding, y, tools.BUTTON_HGT, tools.BUTTON_HGT,
        getText("IGUI_PhunZones_AllZones"), self)
    chkAll:addOption(getText("IGUI_PhunZones_AllZones"), nil)
    chkAll:setWidthToFit()
    chkAll.onMouseUp = function(s, x, y)
        ISTickBox.onMouseUp(s, x, y)
        self:refreshData()
        return true
    end
    chkAll.tooltip = getText("IGUI_PhunZones_AllZones_tooltip")
    self:addChild(chkAll)
    self.controls.chkAll = chkAll

    y = y + chkAll.height + padding

    local regions = ISComboBox:new(padding, y, w - (padding * 2), tools.FONT_HGT_MEDIUM, self, function()
        self:setSelection(self.controls.regions.selected)
    end);
    regions:initialise()
    self:addChild(regions)
    self.controls.regions = regions

    y = regions.y + regions.height + 10

    local btnNewRegion = ISButton:new(x, y, 100, tools.BUTTON_HGT, getText("IGUI_PhunZones_AddRegion"), self, function()
        PZ.ui.editor.OnOpenPanel(self.player, {
            zone = "main"
        }, function(newData)
            self:saveData(newData)
        end)
    end);
    btnNewRegion:initialise();
    self:addChild(btnNewRegion);
    self.controls.btnNewRegion = btnNewRegion

    x = x + btnNewRegion.width + padding

    local btnNewSubRegion = ISButton:new(x, y, 100, tools.BUTTON_HGT, getText("IGUI_PhunZones_AddSub"), self, function()
        if self.selectedData then
            PZ.ui.editor.OnOpenPanel(self.player, {
                region = self.selectedData.region
            }, function(newData)
                self:saveData(newData)
            end)
        end
    end);
    btnNewSubRegion:initialise();
    btnNewSubRegion.enable = false
    self:addChild(btnNewSubRegion);
    self.controls.btnNewSubRegion = btnNewSubRegion

    x = x + btnNewSubRegion.width + padding

    local btnEditRegion = ISButton:new(x, y, 100, tools.BUTTON_HGT, getText("IGUI_PhunZones_EditRegion"), self,
        function()
            if self.selectedData then
                local data = self.selectedData
                PZ.ui.editor.OnOpenPanel(self.player, self.selectedData, function(newData)
                    self:saveData(newData)
                end)
            end
        end);
    btnEditRegion:initialise();
    self:addChild(btnEditRegion);
    self.controls.btnEditRegion = btnEditRegion

    x = x + btnEditRegion.width + padding

    local deleteButton = ISButton:new(x, y, 100, tools.BUTTON_HGT, "Delete Zone", self, function()
        local selected = self.selectedData
        local regionField = selected.region
        local subzone = selected.zone
        local message =
            "Are you sure you want to delete " .. tostring(regionField) .. " (" .. tostring(subzone) .. ")" ..
                " and any associated subzones? This action cannot be undone."
        local w = 300 * FONT_SCALE
        local h = 200 * FONT_SCALE

        local textWidth = getTextManager():MeasureStringX(UIFont.Small, message)
        if textWidth + 40 * FONT_SCALE > w then
            w = textWidth + 40 * FONT_SCALE
        end

        local modal = ISModalDialog:new(getCore():getScreenWidth() / 2 - w / 2, getCore():getScreenHeight() / 2 - h / 2,
            w, h, message, true, self, function(s, button)
                if button.internal == "YES" then
                    sendClientCommand(PZ.name, PZ.commands.deleteZone, {
                        key = selected.region,
                        subzone = selected.zone
                    })
                    PZ.ui.zones.instances[getPlayer():getPlayerNum()]:close()
                end
            end, nil);
        modal:initialise()
        modal:addToUIManager()
    end);
    deleteButton.enable = false
    deleteButton:initialise();

    if deleteButton.enableCancelColor then
        deleteButton:enableCancelColor()
    end

    self:addChild(deleteButton);
    self.controls.deleteButton = deleteButton

    x = 10
    y = deleteButton.y + deleteButton.height + tools.HEADER_HGT

    local title2 = ISLabel:new(x, y, 0, "Zones", 1, 1, 1, 1, UIFont.Small, true);
    title2:initialise();
    title2:instantiate();
    self:addChild(title2);
    self.controls.title2 = title2

    y = y + title2.height + tools.BUTTON_HGT

    local list = ISScrollingListBox:new(x, y, w - (x * 2), 100);
    list:initialise();
    list:instantiate();
    list.itemheight = tools.FONT_HGT_SMALL + 4 * 2
    list.selected = 0;
    list.joypadParent = self;
    list.font = UIFont.NewSmall;
    list.doDrawItem = self.drawDatas;

    list.onMouseUp = function(x, y)
        self.sekectedProperty = nil
        local row = self.controls.list:rowAt(x, y)
        if row == -1 then
            return
        end
        if self.selected ~= row then
            self.selected = row
            self.controls.list.selected = row
            self.controls.list:ensureVisible(self.controls.list.selected)
        end
        local item = self.controls.list.items[self.controls.list.selected].item
        self.sekectedProperty = item
    end

    list.onRightMouseUp = function(target, x, y, a, b)
        local row = self.controls.list:rowAt(x, y)
        if row == -1 then
            return
        end
        if self.selected ~= row then
            self.selected = row
            self.controls.list.selected = row
            self.controls.list:ensureVisible(self.controls.list.selected)
        end
        local item = self.controls.list.items[self.controls.list.selected].item

    end
    list.drawBorder = true;
    list:addColumn(getText("IGUI_PhunZones_Property"), 0);
    list:addColumn(getText("IGUI_PhunZones_Value"), 199);
    self:addChild(list);
    self.controls.list = list
    y = list.y + list.height + 50

    local points = ISScrollingListBox:new(x, y, w - (x * 2), 100);
    points:initialise();
    points:instantiate();
    points.itemheight = tools.FONT_HGT_SMALL + 4 * 2
    points.selected = 0;
    points.joypadParent = self;
    points.font = UIFont.NewSmall;
    points.doDrawItem = self.drawPoints;

    points.onMouseUp = function(_, x, y)
        self.selectedPoint = nil
        self.controls.btnEditZone.enable = false
        local row = self.controls.points:rowAt(x, y)
        if row == -1 then
            return
        end
        if self.selected ~= row then
            self.selected = row
            self.controls.points.selected = row
            self.controls.points:ensureVisible(self.controls.points.selected)
        end
        local item = self.controls.points.items[self.controls.points.selected].item
        self.selectedPoint = item
        self.controls.btnEditZone.enable = true
    end

    points.onRightMouseUp = function(target, x, y, a, b)
        local row = self.controls.points:rowAt(x, y)
        if row == -1 then
            return
        end
        if self.selected ~= row then
            self.selected = row
            self.controls.points.selected = row
            self.controls.points:ensureVisible(self.controls.points.selected)
        end
        local item = self.controls.points.items[self.controls.points.selected].item

    end
    points.drawBorder = true;
    points:addColumn("X", 0);
    points:addColumn("Y", 75);
    points:addColumn("X2", 150);
    points:addColumn("Y2", 225);
    self:addChild(points);
    self.controls.points = points
    y = points.y + points.height + 10

    local btnNewZone = ISButton:new(x, y, 100, tools.BUTTON_HGT, getText("IGUI_PhunZones_AddZone"), self, function()
        if self.selectedData then
            PZ.ui.xy.OnOpenPanel(self.player, {
                region = self.selectedData.region,
                zone = self.selectedData.zone
            }, function(newyx)
                self:savePoint(newyx)
            end)
        end
    end);
    btnNewZone:initialise();
    self:addChild(btnNewZone);
    self.controls.btnNewZone = btnNewZone
    x = x + btnNewZone.width + padding

    local btnEditZone = ISButton:new(x, y, 100, tools.BUTTON_HGT, getText("IGUI_PhunZones_EditZone"), self, function()
        if self.selectedPoint then
            PZ.ui.xy.OnOpenPanel(self.player, {
                region = self.selectedData.region,
                zone = self.selectedData.zone,
                point = self.controls.points.selected,
                x = self.selectedPoint.x,
                y = self.selectedPoint.y,
                x2 = self.selectedPoint.x2,
                y2 = self.selectedPoint.y2
            }, function(newyx)
                self:savePoint(newyx, self.controls.points.selected)
            end)
        end
    end);
    btnEditZone:initialise();
    self:addChild(btnEditZone);
    self.controls.btnEditZone = btnEditZone
    x = x + btnEditZone.width + padding

    local closeButton = ISButton:new(x, y, 100, tools.BUTTON_HGT, "Close", self, function()
        UI:close()
    end);
    closeButton:initialise();
    self:addChild(closeButton);

end

function UI:drawDatas(y, item, alt)
    if y + self:getYScroll() + self.itemheight < 0 or y + self:getYScroll() >= self.height then
        return y + self.itemheight
    end

    local a = 0.9;

    if self.selected == item.index then
        self:drawRect(0, (y), self:getWidth(), self.itemheight, 0.3, 0.7, 0.35, 0.15);
    end

    if alt then
        self:drawRect(0, (y), self:getWidth(), self.itemheight, 0.3, 0.6, 0.5, 0.5);
    end

    self:drawRectBorder(0, (y), self:getWidth(), self.itemheight, a, self.borderColor.r, self.borderColor.g,
        self.borderColor.b);

    local iconX = 4
    local iconSize = tools.FONT_HGT_SMALL;
    local xoffset = 10;

    local clipX = self.columns[1].size
    local clipX2 = self.columns[2].size
    local clipY = math.max(0, y + self:getYScroll())
    local clipY2 = math.min(self.height, y + self:getYScroll() + self.itemheight)

    self:setStencilRect(clipX, clipY, clipX2 - clipX, clipY2 - clipY)
    self:drawText(item.text .. (item.item.overwritten and " *" or ""), xoffset, y + 4, 1, 1, 1, a, self.font);
    self:clearStencilRect()

    local value = tostring(item.item.value)

    local valueWidth = getTextManager():MeasureStringX(self.font, value)
    local w = self.width
    local cw = self.columns[2].size
    self:drawText(value, clipX2 + 4, y + 4, 1, 1, 1, a, self.font);
    self.itemsHeight = y + self.itemheight;
    return self.itemsHeight;
end

function UI:drawPoints(y, item, alt)
    if y + self:getYScroll() + self.itemheight < 0 or y + self:getYScroll() >= self.height then
        return y + self.itemheight
    end

    local a = 0.9;

    if self.selected == item.index then
        self:drawRect(0, (y), self:getWidth(), self.itemheight, 0.3, 0.7, 0.35, 0.15);
    end

    if alt then
        self:drawRect(0, (y), self:getWidth(), self.itemheight, 0.3, 0.6, 0.5, 0.5);
    end

    self:drawRectBorder(0, (y), self:getWidth(), self.itemheight, a, self.borderColor.r, self.borderColor.g,
        self.borderColor.b);

    local iconX = 4
    local iconSize = tools.FONT_HGT_SMALL;
    local xoffset = 10;

    local clipX = self.columns[1].size
    local clipX2 = self.columns[2].size
    local clipX3 = self.columns[3].size
    local clipX4 = self.columns[4].size
    local clipY = math.max(0, y + self:getYScroll())
    local clipY2 = math.min(self.height, y + self:getYScroll() + self.itemheight)
    local clipY3 = math.min(self.height, y + self:getYScroll() + self.itemheight)
    local clipY4 = math.min(self.height, y + self:getYScroll() + self.itemheight)

    local val = item.item

    self:setStencilRect(clipX, clipY, clipX2 - clipX, clipY2 - clipY)
    self:drawText(tostring(val.x), xoffset, y + 4, 1, 1, 1, a, self.font);
    self:clearStencilRect()

    self:setStencilRect(clipX2, clipY, clipX3 - clipX2, clipY2 - clipY)
    self:drawText(tostring(val.y), clipX2 + 4, y + 4, 1, 1, 1, a, self.font);
    self:clearStencilRect()

    self:setStencilRect(clipX3, clipY, clipX4 - clipX3, clipY2 - clipY)
    self:drawText(tostring(val.x2), clipX3 + 4, y + 4, 1, 1, 1, a, self.font);
    self:clearStencilRect()

    self:setStencilRect(clipX4, clipY, clipX4 - clipX3, clipY2 - clipY)
    self:drawText(tostring(val.y2), clipX4 + 4, y + 4, 1, 1, 1, a, self.font);
    self:clearStencilRect()

    self.itemsHeight = y + self.itemheight;
    return self.itemsHeight;
end

function UI:save()

end

function UI:close()
    ISCollapsableWindowJoypad.close(self);
    self:setVisible(false);
    self:removeFromUIManager();
    self.instances[self.playerIndex] = nil
end

function UI:new(x, y, width, height, player, key)
    local o = {};
    o = ISCollapsableWindowJoypad:new(x, y, width, height, player);
    setmetatable(o, self);
    self.__index = self;
    o.viewer = player
    o.variableColor = {
        r = 0.9,
        g = 0.55,
        b = 0.1,
        a = 1
    };
    o.borderColor = {
        r = 0.4,
        g = 0.4,
        b = 0.4,
        a = 1
    };
    o.backgroundColor = {
        r = 0,
        g = 0,
        b = 0,
        a = 0.8
    };
    o.buttonBorderColor = {
        r = 0.7,
        g = 0.7,
        b = 0.7,
        a = 0.5
    };
    o.zOffsetSmallFont = 25;
    o.moveWithMouse = false;
    o.key = key;
    o:setWantKeyEvents(true)
    o:setTitle("PhunZones - Editor");
    self.player = player
    self.playerIndex = player:getPlayerNum()
    return o;
end

-- function UI:onMouseDown(x, y)
--     self.downX = self:getMouseX()
--     self.downY = self:getMouseY()
--     return true
-- end
-- function UI:onMouseUp(x, y)
--     -- self.downY = nil
--     -- self.downX = nil
--     -- if not self.dragging then
--     --     if self.onClick then
--     self:onClick()
--     --     end
--     -- else
--     --     self.dragging = false
--     --     self:setCapture(false)
--     -- end
--     return true
-- end

-- function UI:onMouseMove(dx, dy)

--     if self.downY and self.downX and not self.dragging then
--         if math.abs(self.downX - dx) > 4 or math.abs(self.downY - dy) > 4 then
--             self.dragging = true
--             self:setCapture(true)
--         end
--     end

--     if self.dragging then
--         local dx = self:getMouseX() - self.downX
--         local dy = self:getMouseY() - self.downY
--         self.userPosition = true
--         self:setX(self.x + dx)
--         self:setY(self.y + dy)
--     end
-- end

-- function UI:RestoreLayout(name, layout)
--     if name == profileName then
--         ISLayoutManager.DefaultRestoreWindow(self, layout)
--         self.userPosition = layout.userPosition == 'true'
--     end
-- end

-- function UI:SaveLayout(name, layout)
--     ISLayoutManager.DefaultSaveWindow(self, layout)
--     layout.width = nil
--     layout.height = nil
--     if self.userPosition then
--         layout.userPosition = 'true'
--     else
--         layout.userPosition = 'false'
--     end
-- end

function UI:isKeyConsumed(key)
    return key == Keyboard.KEY_ESCAPE
end

function UI:onKeyRelease(key)
    if key == Keyboard.KEY_ESCAPE then
        self:close()
    end
end
