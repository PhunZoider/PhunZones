if isServer() then
    return
end
require("ISUI/Maps/ISMiniMap")
local PZ = PhunZones
local sandbox = SandboxVars.PhunZones
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)

local FONT_SCALE = FONT_HGT_SMALL / 14
local HEADER_HGT = FONT_HGT_MEDIUM + 2 * 2

local profileName = "PhunZonesUIXY"
PZ.ui.xy = ISPanel:derive(profileName);
PZ.ui.xy.instances = {}
local UI = PZ.ui.xy

function UI.OnOpenPanel(playerObj, xy, cb)

    local playerIndex = playerObj:getPlayerNum()

    if not UI.instances[playerIndex] then
        local core = getCore()
        local FONT_SCALE = getTextManager():getFontHeight(UIFont.Small) / 14
        local width = 220 * FONT_SCALE
        local height = 200 * FONT_SCALE

        local x = (core:getScreenWidth() - width) / 2
        local y = (core:getScreenHeight() - height) / 2

        UI.instances[playerIndex] = UI:new(x, y, width, height, playerObj, playerIndex);
        UI.instances[playerIndex]:initialise();
        -- ISLayoutManager.RegisterWindow(profileName, UI, UI.instances[playerIndex])
    end

    local instance = UI.instances[playerIndex]

    if not xy then
        xy = {}
    end

    instance:addToUIManager();
    instance:setVisible(true);
    instance.xy = {
        region = xy.region,
        zone = xy.zone,
        point = xy.point,
        x = xy.x,
        y = xy.y,
        x2 = xy.x2,
        y2 = xy.y2
    }
    instance.cb = cb
    instance.txtX:setText(tostring(instance.xy.x or ""))
    instance.txtY:setText(tostring(instance.xy.y or ""))
    instance.txtX2:setText(tostring(instance.xy.x2 or ""))
    instance.txtY2:setText(tostring(instance.xy.y2 or ""))

    return instance;

end

function UI:new(x, y, width, height, player, playerIndex)
    local o = {};
    o = ISPanel:new(x, y, width, height, player);
    setmetatable(o, self);
    self.__index = self;

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
    o.data = {}

    -- o.moveWithMouse = true;
    o.anchorRight = true
    o.anchorBottom = true
    o.player = player
    o.playerIndex = playerIndex
    o.zOffsetLargeFont = 25;
    o.zOffsetMediumFont = 20;
    o.zOffsetSmallFont = 6;
    -- o:setWantKeyEvents(true)
    return o;
end

function UI:RestoreLayout(name, layout)

    -- ISLayoutManager.DefaultRestoreWindow(self, layout)
    -- if name == profileName then
    --     ISLayoutManager.DefaultRestoreWindow(self, layout)
    --     self.userPosition = layout.userPosition == 'true'
    -- end
    -- self:recalcSize();
end

function UI:SaveLayout(name, layout)
    -- ISLayoutManager.DefaultSaveWindow(self, layout)
    -- if self.userPosition then
    --     layout.userPosition = 'true'
    -- else
    --     layout.userPosition = 'false'
    -- end
end

function UI:close()
    ISPanel.close(self);
    self:setVisible(false);
    self:removeFromUIManager();
    self.instances[self.playerIndex] = nil
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

function UI:createChildren()
    ISPanel.createChildren(self);

    local x = 10
    local y = 10
    local h = FONT_HGT_MEDIUM

    self.title = ISLabel:new(x, y, h, "Coordinates", 1, 1, 1, 1, UIFont.Small, true);
    self.title:initialise();
    self.title:instantiate();
    self:addChild(self.title);

    self.closeButton = ISButton:new(self.width - 25 - x, y, 25, 25, "X", self, function()
        self:close();
    end);
    self.closeButton:initialise();
    self:addChild(self.closeButton);

    y = y + self.closeButton.height + 10

    self.lblX = ISLabel:new(x, y, h, "X", 1, 1, 1, 1, UIFont.Small, true);
    self.lblX:initialise();
    self.lblX:instantiate();
    self:addChild(self.lblX);

    self.txtX = ISTextEntryBox:new("", x + 50, y, 200, h);
    self.txtX:initialise();
    self:addChild(self.txtX);

    y = y + h + 10

    self.lblY = ISLabel:new(x, y, h, "Y", 1, 1, 1, 1, UIFont.Small, true);
    self.lblY:initialise();
    self.lblY:instantiate();
    self:addChild(self.lblY);

    self.txtY = ISTextEntryBox:new("", x + 50, y, 200, h);
    self.txtY:initialise();
    self:addChild(self.txtY);

    y = y + h + 10

    self.lblX2 = ISLabel:new(x, y, h, "X2", 1, 1, 1, 1, UIFont.Small, true);
    self.lblX2:initialise();
    self.lblX2:instantiate();
    self:addChild(self.lblX2);

    self.txtX2 = ISTextEntryBox:new("", x + 50, y, 200, h);
    self.txtX2:initialise();
    self:addChild(self.txtX2);

    y = y + h + 10

    self.lblY2 = ISLabel:new(x, y, h, "Y2", 1, 1, 1, 1, UIFont.Small, true);
    self.lblY2:initialise();
    self.lblY2:instantiate();
    self:addChild(self.lblY2);

    self.txtY2 = ISTextEntryBox:new("", x + 50, y, 200, h);
    self.txtY2:initialise();
    self:addChild(self.txtY2);

    y = y + h + 10

    self.btnXYSet = ISButton:new(x, y, 80, h, "Set XY", self, function()
        self.txtX:setText(tostring(math.floor(self.player:getX() + 0.5)))
        self.txtY:setText(tostring(math.floor(self.player:getY() + 0.5)))
    end);
    self.btnXYSet:initialise();
    self:addChild(self.btnXYSet);

    x = self.btnXYSet.x + self.btnXYSet.width + 10

    self.btnXY2Set = ISButton:new(x, y, 80, h, "Set X2Y2", self, function()
        self.txtX2:setText(tostring(math.floor(self.player:getX() + 0.5)))
        self.txtY2:setText(tostring(math.floor(self.player:getY() + 0.5)))
    end);
    self.btnXY2Set:initialise();
    self:addChild(self.btnXY2Set);

    x = self.btnXY2Set.x + self.btnXY2Set.width + 10

    self.save = ISButton:new(x, y, 80, h, "Save", self, function()

        local x = tonumber(self.txtX:getText())
        local y = tonumber(self.txtY:getText())
        local x2 = tonumber(self.txtX2:getText())
        local y2 = tonumber(self.txtY2:getText())

        local xy = {
            region = self.xy.region,
            zone = self.xy.zone,
            point = self.xy.point,
            x = math.min(x, x2),
            y = math.min(y, y2),
            x2 = math.max(x, x2),
            y2 = math.max(y, y2)
        }
        if self.cb then
            self.cb(xy)
        end
        self:close()
    end);
    self.save.internal = "SAVE";
    self.save:initialise();
    self:addChild(self.save);

end

function UI:setData(data)

end

function UI:prerender()

    ISPanel.prerender(self);

end
