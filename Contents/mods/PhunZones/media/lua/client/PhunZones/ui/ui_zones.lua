if isServer() then
    return
end

local PZ = PhunZones

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)
local HEADER_HGT = FONT_HGT_MEDIUM + 2 * 2
local FONT_SCALE = FONT_HGT_SMALL / 14

local profileName = "PhunZonesUIList"
PZ.ui.zones = ISPanel:derive(profileName);
PZ.ui.zones.instances = {}
local UI = PZ.ui.zones

function UI.OnOpenPanel(playerObj, key)

    if isAdmin() or isDebugEnabled() then

        local playerIndex = playerObj:getPlayerNum()

        if not UI.instances[playerIndex] then
            UI.instances[playerIndex] = UI:new(100, 100, 400, 500, playerObj, key);
            UI.instances[playerIndex]:initialise();
            UI.instances[playerIndex]:instantiate();
            ISLayoutManager.RegisterWindow(profileName, UI, UI.instances[playerIndex])
        end

        UI.instances[playerIndex]:addToUIManager();
        UI.instances[playerIndex]:setVisible(true);
        UI.instances[playerIndex]:refreshData()
        return UI.instances[playerIndex];
    end
end

function UI:refreshData()

    self.list:clear()
    self.regions:clear()
    self.regions:addOption(" ")
    local data = PZ:getZones()
    self.data = data
    for k, v in pairs(data.lookup) do

        self.regions:addOptionWithData(k, v.main)

        for zkey, zval in pairs(v) do
            if zkey ~= "main" then
                self.regions:addOptionWithData(("  |- " .. zkey), zval)
            end
        end

    end
    self.regions:addOption(" ")
    self:setSelection(1)

end

function UI:setSelection(selection)

    self.regions.selected = selection
    local opts = self.regions.options[self.regions.selected]
    local data = opts.data
    self:setData(data)
end

function UI:setData(data)

    self.selectedData = data
    if self.btnNewSubRegion then
        self.btnNewSubRegion.enable = data and data.zone == "main"

    end
    self:refreshProperties(data)

end

function UI:refreshProperties(data, selected)
    self.selectedProperty = nil
    self.list:clear()
    if not data then
        return
    end
    local zone = self.data.zones[data.region].zones[data.zone]
    for k, v in pairs(data) do
        if k ~= "region" and k ~= "zone" then

            -- is this value overwriting the parent?

            self.list:addItem(k, {
                property = k,
                value = v,
                overwritten = data.zone ~= "main" and zone[k] == nil
            })
        end
    end
    if #self.list.items > 0 then
        self.list.selected = selected or 1
        self.list:ensureVisible(self.list.selected)
        self.selectedProperty = self.list.items[1].item
    end
    self:refreshZonePoints(zone.zones)
end

function UI:saveData(data)
    local md = ModData.get(PZ.const.modifiedModData)
    if not md[data.region] then
        md[data.region] = {}
    end
    if not md[data.region].zones then
        md[data.region].zones = {}
    end
    if not md[data.region].zones[data.zone] then
        md[data.region].zones[data.zone] = {}
    end
    if not md[data.region].zones[data.zone].zones then
        md[data.region].zones[data.zone].zones = {}
    end

    local fields = {"enabled", "pvp", "title", "subtitle", "difficulty", "mods", "rads", "zeds", "bandits"}

    for _, v in ipairs(fields) do
        md[data.region].zones[data.zone][v] = data[v]
    end
    -- -- reset any existing keys
    -- for k, v in pairs(md[data.region].zones[data.zone]) do
    --     if k ~= "region" and k ~= "zone" and k ~= "zones" then
    --         md[data.region].zones[data.zone][k] = nil
    --     end
    -- end

    -- -- copy over passed keys
    -- for k, v in pairs(data) do
    --     if k ~= "region" and k ~= "zone" and k ~= "zones" then
    --         md[data.region].zones[data.zone][k] = v
    --     end
    -- end

    PZ:saveChanges(md)
    self:refreshData()
end

function UI:savePoint(xy, pointIndex)
    local zone = self.data.zones[xy.region].zones[xy.zone]
    local point = zone.zones[xy.point]

    local md = ModData.getOrCreate(PZ.const.modifiedModData)
    if not md[xy.region] then
        md[xy.region] = {}
    end
    if not md[xy.region].zones then
        md[xy.region].zones = {}
    end
    if not md[xy.region].zones[xy.zone] then
        md[xy.region].zones[xy.zone] = {}
    end

    -- copy all existing points into modified data
    md[xy.region].zones[xy.zone].zones = zone.zones

    if pointIndex then
        zone.zones[pointIndex] = {xy.x, xy.y, xy.x2, xy.y2}
    else
        table.insert(zone.zones, {xy.x, xy.y, xy.x2, xy.y2})
    end

    PZ:saveChanges(md)
    -- probably need to rebuild everything too
    self:refreshZonePoints(zone.zones, self.points.selected)
end

function UI:refreshZonePoints(points, selected)
    self.selectedPoint = nil
    self.points:clear()
    for _, v in ipairs(points or {}) do
        self.points:addItem("", {
            x = v[1],
            y = v[2],
            x2 = v[3],
            y2 = v[4]
        })
    end
    if self.points.items and #self.points.items > 0 then
        self.points.selected = selected or 1
        self.points:ensureVisible(self.points.selected)
        self.selectedPoint = self.points.items[self.points.selected].item
    end
end

function UI:createChildren()

    ISPanel.createChildren(self);

    local x = 10
    local y = 10
    local padding = 10
    local h = FONT_HGT_SMALL;
    local w = self.width - 20;

    self.title = ISLabel:new(x, y, h, "Regions", 1, 1, 1, 1, UIFont.Small, true);
    self.title:initialise();
    self.title:instantiate();
    self:addChild(self.title);

    self.closeButton = ISButton:new(self.width - 25 - x, y, 25, 25, "X", self, function()
        self:setVisible(false);
        self:removeFromUIManager();
        self.instances[self.playerIndex] = nil
    end);
    self.closeButton:initialise();
    self:addChild(self.closeButton);

    y = y + self.closeButton.height + padding

    self.regions = ISComboBox:new(padding, y, self:getWidth() - (padding * 2), FONT_HGT_MEDIUM, self, function()
        self:setSelection(self.regions.selected)
    end);
    self.regions:initialise()
    self:addChild(self.regions)

    y = self.regions.y + self.regions.height + 10

    self.btnNewRegion = ISButton:new(x, y, 100, h, "Add Region", self, function()
        PZ.ui.editor.OnOpenPanel(self.player, {
            zone = "main"
        }, function(newData)
            self:saveData(newData)
        end)
    end);
    self.btnNewRegion:initialise();
    self:addChild(self.btnNewRegion);

    x = x + self.btnNewRegion.width + padding

    self.btnNewSubRegion = ISButton:new(x, y, 100, h, "Add Sub", self, function()
        if self.selectedData then
            PZ.ui.editor.OnOpenPanel(self.player, {
                region = self.selectedData.region
            }, function(newData)
                self:saveData(newData)
            end)
        end
    end);
    self.btnNewSubRegion:initialise();
    self.btnNewSubRegion.enable = false
    self:addChild(self.btnNewSubRegion);

    x = x + self.btnNewSubRegion.width + padding

    self.btnEditRegion = ISButton:new(x, y, 100, h, "Edit Region", self, function()
        if self.selectedData then
            PZ.ui.editor.OnOpenPanel(self.player, self.selectedData, function(newData)
                self:saveData(newData)
            end)
        end
    end);
    self.btnEditRegion:initialise();
    self:addChild(self.btnEditRegion);

    x = 10

    y = self.btnEditRegion.y + self.btnEditRegion.height + HEADER_HGT

    self.title2 = ISLabel:new(x, y, h, "Zones", 1, 1, 1, 1, UIFont.Small, true);
    self.title2:initialise();
    self.title2:instantiate();
    self:addChild(self.title2);

    self.list = ISScrollingListBox:new(x, y, self:getWidth() - (x * 2), 100);
    self.list:initialise();
    self.list:instantiate();
    self.list.itemheight = FONT_HGT_SMALL + 4 * 2
    self.list.selected = 0;
    self.list.joypadParent = self;
    self.list.font = UIFont.NewSmall;
    self.list.doDrawItem = self.drawDatas;

    self.list.onMouseUp = function(x, y)
        self.sekectedProperty = nil
        local row = self.list:rowAt(x, y)
        if row == -1 then
            return
        end
        if self.selected ~= row then
            self.selected = row
            self.list.selected = row
            self.list:ensureVisible(self.list.selected)
        end
        local item = self.list.items[self.list.selected].item
        self.sekectedProperty = item
    end

    self.list.onRightMouseUp = function(target, x, y, a, b)
        local row = self.list:rowAt(x, y)
        if row == -1 then
            return
        end
        if self.selected ~= row then
            self.selected = row
            self.list.selected = row
            self.list:ensureVisible(self.list.selected)
        end
        local item = self.list.items[self.list.selected].item

    end
    self.list.drawBorder = true;
    self.list:addColumn("Property", 0);
    self.list:addColumn("Value", 199);
    self:addChild(self.list);

    y = self.list.y + self.list.height + 50

    self.points = ISScrollingListBox:new(x, y, self:getWidth() - (x * 2), 100);
    self.points:initialise();
    self.points:instantiate();
    self.points.itemheight = FONT_HGT_SMALL + 4 * 2
    self.points.selected = 0;
    self.points.joypadParent = self;
    self.points.font = UIFont.NewSmall;
    self.points.doDrawItem = self.drawPoints;

    self.points.onMouseUp = function(x, y)
        self.selectedPoint = nil
        local row = self.points:rowAt(x, y)
        if row == -1 then
            return
        end
        if self.selected ~= row then
            self.selected = row
            self.points.selected = row
            self.points:ensureVisible(self.points.selected)
        end
        local item = self.points.items[self.points.selected].item
        self.selectedPoint = item
    end

    self.points.onRightMouseUp = function(target, x, y, a, b)
        local row = self.list:rowAt(x, y)
        if row == -1 then
            return
        end
        if self.selected ~= row then
            self.selected = row
            self.points.selected = row
            self.points:ensureVisible(self.points.selected)
        end
        local item = self.points.items[self.points.selected].item

    end
    self.points.drawBorder = true;
    self.points:addColumn("X", 0);
    self.points:addColumn("Y", 100);
    self.points:addColumn("X2", 200);
    self.points:addColumn("Y2", 300);
    self:addChild(self.points);

    y = self.points.y + self.points.height + 10

    self.btnNewZone = ISButton:new(x, y, 100, h, "Add Zone", self, function()
        if self.selectedData then
            PZ.ui.xy.OnOpenPanel(self.player, {
                region = self.selectedData.region,
                zone = self.selectedData.zone
            }, function(newyx)
                self:savePoint(newyx)
            end)
        end
    end);
    self.btnNewZone:initialise();
    self:addChild(self.btnNewZone);

    x = x + self.btnNewZone.width + padding

    self.btnEditZone = ISButton:new(x, y, 100, h, "Edit Zone", self, function()
        if self.selectedPoint then
            PZ.ui.xy.OnOpenPanel(self.player, {
                region = self.selectedData.region,
                zone = self.selectedData.zone,
                point = self.points.selected,
                x = self.selectedPoint.x,
                y = self.selectedPoint.y,
                x2 = self.selectedPoint.x2,
                y2 = self.selectedPoint.y2
            }, function(newyx)
                self:savePoint(newyx, self.points.selected)
            end)
        end
    end);
    self.btnEditZone:initialise();
    self:addChild(self.btnEditZone);

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
    local iconSize = FONT_HGT_SMALL;
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
    local iconSize = FONT_HGT_SMALL;
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
    self:setVisible(false);
    self:removeFromUIManager();
    UI.instances[self.playerIndex] = nil
end

function UI:new(x, y, width, height, player, key)
    local o = {};
    o = ISPanel:new(x, y, width, height, player);
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
    o.moveWithMouse = true;
    o.key = key;
    self.player = player
    self.playerIndex = player:getPlayerNum()
    return o;
end

function UI:onMouseDown(x, y)
    self.downX = self:getMouseX()
    self.downY = self:getMouseY()
    return true
end
function UI:onMouseUp(x, y)
    self.downY = nil
    self.downX = nil
    if not self.dragging then
        if self.onClick then
            self:onClick()
        end
    else
        self.dragging = false
        self:setCapture(false)
    end
    return true
end

function UI:onMouseMove(dx, dy)

    if self.downY and self.downX and not self.dragging then
        if math.abs(self.downX - dx) > 4 or math.abs(self.downY - dy) > 4 then
            self.dragging = true
            self:setCapture(true)
        end
    end

    if self.dragging then
        local dx = self:getMouseX() - self.downX
        local dy = self:getMouseY() - self.downY
        self.userPosition = true
        self:setX(self.x + dx)
        self:setY(self.y + dy)
    end
end

function UI:RestoreLayout(name, layout)
    if name == profileName then
        ISLayoutManager.DefaultRestoreWindow(self, layout)
        self.userPosition = layout.userPosition == 'true'
    end
end

function UI:SaveLayout(name, layout)
    ISLayoutManager.DefaultSaveWindow(self, layout)
    layout.width = nil
    layout.height = nil
    if self.userPosition then
        layout.userPosition = 'true'
    else
        layout.userPosition = 'false'
    end
end
