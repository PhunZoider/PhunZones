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
            UI.instances[playerIndex] = UI:new(100, 100, 400, 400, playerObj, key);
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
    local data = PZ:getZones()
    for k, v in pairs(PZ.data.zones) do

        local areas = {}
        for kk, vv in pairs(v) do
            table.insert(areas, k)
        end

        table.sort(areas)

        table.insert(data, {
            title = v.title,
            areas = table.concat(areas, ", "),
            region = k
        })

    end
    table.sort(data, function(a, b)
        return a.title < b.title
    end)

    for _, v in ipairs(data) do
        self.list:addItem(v.title, v)
    end

end

function UI:refreshAreas()
    self.areas:clear()

    local selectedIndex = self.list.selected
    local selected = selectedIndex and self.list.items[selectedIndex] or nil
    if selected == nil then
        return
    end
    local data = PZ.data
    local region = data.zones[selected.item.region]
    local areas = region.areas

    for k, v in pairs(region.areas) do
        self.areas:addItem(k, {
            title = v.title,
            points = #v.points,
            region = region.key,
            areaKey = k
        })
    end
end

function UI:createChildren()

    ISPanel.createChildren(self);

    local x = 10
    local y = 10
    local padding = 10
    local h = FONT_HGT_SMALL;
    local w = self.width - 20;

    self.title = ISLabel:new(x, y, h, "Zones", 1, 1, 1, 1, UIFont.Small, true);
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

    y = y + h + x + 20

    self.list = ISScrollingListBox:new(x, y, self:getWidth() - (x * 2), 100);
    self.list:initialise();
    self.list:instantiate();
    self.list.itemheight = FONT_HGT_SMALL + 4 * 2
    self.list.selected = 0;
    self.list.joypadParent = self;
    self.list.font = UIFont.NewSmall;
    self.list.doDrawItem = self.drawDatas;

    self.list.onMouseUp = function(x, y)
        self:refreshAreas()
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
    self.list:addColumn("Region", 0);
    self.list:addColumn("Areas", 199);
    self:addChild(self.list);

    y = self.list.y + self.list.height + 50
    self.areas = ISScrollingListBox:new(x, y, self:getWidth() - (x * 2), 150);
    self.areas:initialise();
    self.areas:instantiate();
    self.areas.itemheight = FONT_HGT_SMALL + 4 * 2
    self.areas.selected = 0;
    self.areas.joypadParent = self;
    self.areas.font = UIFont.NewSmall;
    self.areas.doDrawItem = self.drawAreas;

    self.areas.onRightMouseUp = function(target, x, y, a, b)
        local row = self.list:rowAt(x, y)
        if row == -1 then
            return
        end
        if self.selected ~= row then
            self.selected = row
            self.areas.selected = row
            self.areas:ensureVisible(self.areas.selected)
        end
        local item = self.list.items[self.areas.selected].item

    end
    self.areas.drawBorder = true;
    self.areas:addColumn("Area", 0);
    self.areas:addColumn("Zones", 199);
    self:addChild(self.areas);
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
    self:drawText(item.text, xoffset, y + 4, 1, 1, 1, a, self.font);
    self:clearStencilRect()

    local value = item.item.areas

    local valueWidth = getTextManager():MeasureStringX(self.font, value)
    local w = self.width
    local cw = self.columns[2].size
    self:drawText(value, clipX2 + 4, y + 4, 1, 1, 1, a, self.font);
    self.itemsHeight = y + self.itemheight;
    return self.itemsHeight;
end

function UI:drawAreas(y, item, alt)
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
    self:drawText(item.text, xoffset, y + 4, 1, 1, 1, a, self.font);
    self:clearStencilRect()

    local value = tostring(item.item.points)

    local valueWidth = getTextManager():MeasureStringX(self.font, value)
    local w = self.width
    local cw = self.columns[2].size
    self:drawText(value, clipX2 + 4, y + 4, 1, 1, 1, a, self.font);
    self.itemsHeight = y + self.itemheight;
    return self.itemsHeight;
end

function UI:tabsRender()
    local inset = 1
    local x = inset + self.scrollX
    local widthOfAllTabs = self:getWidthOfAllTabs()
    local overflowLeft = self.scrollX < 0
    local overflowRight = x + widthOfAllTabs > self.width
    if widthOfAllTabs > self:getWidth() then
        self:setStencilRect(0, 0, self:getWidth(), self.tabHeight)
    end
    for i, viewObject in ipairs(self.viewList) do
        local tabWidth = (self.equalTabWidth and self.maxLength or viewObject.tabWidth) + 4
        if viewObject == self.activeView then
            self:drawRect(x, 0, tabWidth, self.tabHeight, 1, 0.4, 0.4, 0.4, 0.7)
        else
            self:drawRect(x + tabWidth, 0, 1, self.tabHeight, 1, 0.4, 0.4, 0.4, 0.9)
            if self:getMouseY() >= 0 and self:getMouseY() < self.tabHeight and self:isMouseOver() and
                self:getTabIndexAtX(self:getMouseX()) == i then
                viewObject.fade:setFadeIn(true)
            else
                viewObject.fade:setFadeIn(false)
            end
            viewObject.fade:update()
            self:drawRect(x, 0, tabWidth, self.tabHeight, 0.2 * viewObject.fade:fraction(), 1, 1, 1, 0.9)
        end
        self:drawTextCentre(viewObject.name, x + (tabWidth / 2), 3, 1, 1, 1, 1, self.tabFont)
        x = x + tabWidth
    end
    self:drawRect(0, self.tabHeight - 1, self:getWidth(), 1, 1, 0.4, 0.4, 0.4)
    local butPadX = 3
    if overflowLeft then
        local tex = getTexture("media/ui/ArrowLeft.png")
        local butWid = tex:getWidthOrig() + butPadX * 2
        self:drawRect(inset, 0, butWid, self.tabHeight - 1, 1, 0, 0, 0)
        self:drawRectBorder(inset, -1, butWid, self.tabHeight + 1, 1, 0.4, 0.4, 0.4)
        self:drawTexture(tex, inset + butPadX, (self.tabHeight - tex:getHeightOrig()) / 2, 1, 1, 1, 1)
    end
    if overflowRight then
        local tex = getTexture("media/ui/ArrowRight.png")
        local butWid = tex:getWidthOrig() + butPadX * 2
        self:drawRect(self:getWidth() - inset - butWid, 0, butWid, self.tabHeight - 1, 1, 0, 0, 0)
        self:drawRectBorder(self:getWidth() - inset - butWid, -1, butWid, self.tabHeight + 1, 1, 0.4, 0.4, 0.4)
        self:drawTexture(tex, self:getWidth() - butWid + butPadX, (self.tabHeight - tex:getHeightOrig()) / 2, 1, 1, 1, 1)
    end
    if widthOfAllTabs > self:getWidth() then
        self:clearStencilRect()
    end
    self:drawRect(0, self.height, self.width, 1, 1, 0.4, 0.4, 0.4)

end

function UI:save()
    local pm = PhunMart
    local current = pm:getShop(self.key)
    local changes = {}
    local doSave = false
    if self.box.selected > 0 then
        local item = self.box.options[self.box.selected].data
        local key = item.key
        if key ~= self.key then
            changes.shop = key
            doSave = true
        end
    end

    if doSave then
        changes.key = self.key
        sendClientCommand(PhunMart.name, PhunMart.commands.updateShop, changes)
    end

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
