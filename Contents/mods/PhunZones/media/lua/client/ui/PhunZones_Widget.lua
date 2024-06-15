if not isClient() then
    return
end
PhunZonesWidget = ISPanel:derive("PhunZonesWidget");
PhunZonesWidget.instances = {}

local PhunZones = PhunZones
local sandbox = SandboxVars.PhunZones

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)
local FONT_SCALE = FONT_HGT_SMALL / 14

function PhunZonesWidget.OnOpenPanel(playerObj)

    local core = getCore()
    local FONT_SCALE = getTextManager():getFontHeight(UIFont.Small) / 14
    local core = getCore()
    local width = 200 * FONT_SCALE
    local height = 50 * FONT_SCALE
    local x = (core:getScreenWidth() - width) / 2
    local y = 20
    local pIndex = playerObj:getPlayerNum()
    local instances = PhunZonesWidget.instances
    if instances[pIndex] then
        local instance = instances[pIndex]
        if not instance:isVisible() then
            instances[pIndex]:addToUIManager();
            instances[pIndex]:setVisible(true);
        end
        if instance.rebuild then
            instance:rebuild()
        end
        return instance
    end
    PhunZonesWidget.instances[pIndex] = PhunZonesWidget:new(x, y, width, height, playerObj);
    local instance = PhunZonesWidget.instances[pIndex]
    ISLayoutManager.RegisterWindow('PhunZonesWidget', PhunZonesWidget, instance)
    instance:initialise();
    instance:instantiate();
    instance:addToUIManager();
    instance:rebuild()
    return instance;

end

function PhunZonesWidget:initialise()
    ISPanel.initialise(self);
end

function PhunZonesWidget:close()
    self:setVisible(false);
    self:removeFromUIManager();
    PhunZonesWidget.instances[self.pIndex] = nil
end

function PhunZonesWidget:prerender()
    ISPanel.prerender(self);

    -- highlight box if we are hovering over it
    if self:isMouseOver() then
        self.borderColor = self.hoverBorderColor
        self.backgroundColor = self.hoverBackgroundColor
    else
        self.borderColor = self.normalBorderColor
        self.backgroundColor = self.normalBackgroundColor
    end

    local x = 1
    local cached = self.cached or {}
    if cached.pvpTexture then
        self:drawTextureScaledAspect(self.cached.pvpTexture, 1, 1, 30, 30, 1);
        x = 32
    end

    self:drawText(cached.title or "", x, 1, 0.7, 0.7, 0.7, 1.0, UIFont.Medium);

    local y = FONT_HGT_MEDIUM + 1
    -- for pips
    if sandbox.PhunZones_Widget and cached.risk then
        local colors = {
            r = 0.4,
            g = 0.4,
            b = 0.4,
            a = 1.0
        }
        if cached.restless ~= nil then
            if not cached.restless then
                colors.g = 0.9
            elseif cached.risk < 20 then
                colors.g = 0.9
                colors.r = 0.9
            else
                colors.r = 0.9
            end
        end
        for i = 1, 10 do
            if (i * 10) < cached.risk then
                self:drawRect(x + ((i - 1) * 7), y, 5, 5, colors.a, colors.r, colors.g, colors.b);
            else
                break
            end
        end
    end

end

function PhunZonesWidget:render()
    if self:isMouseOver() then
        self:doTooltip()
    end
end

function PhunZonesWidget:rebuild()

    local player = getSpecificPlayer(self.pIndex)
    local pData = player:getModData().PhunZones

    if pData and pData.current then
        local data = pData.current
        local title = data.title or ""
        local subtitle = data.subtitle or ""
        if string.len(subtitle) > 0 then
            title = title .. " (" .. subtitle .. ")"
        end
        local pvpTexture = (data.pvp and self.pvpOnTexture) or nil
        local difficulty = data.difficulty or 0
        local titleWidth = getTextManager():MeasureStringX(UIFont.Medium, title)
        local summary
        if PhunRunners then
            summary = PhunRunners:getSummary(player)
            self.cached = {
                title = title,
                pvpTexture = pvpTexture,
                difficulty = difficulty,
                titleWidth = titleWidth,
                spawnSprinters = summary.spawnSprinters,
                restless = summary.restless,
                risk = summary.risk,
                riskTitle = summary.title,
                riskTitleWidth = getTextManager():MeasureStringX(UIFont.Small, summary.title),
                riskTitleHeight = getTextManager():MeasureStringY(UIFont.Small, summary.title),
                riskDescription = summary.description,
                riskDescriptionWidth = getTextManager():MeasureStringX(UIFont.Small, summary.description),
                riskDescriptionHeight = getTextManager():MeasureStringY(UIFont.Small, summary.description)
            }
            local text = "<H1>" .. self.cached.title .. "</H1>"
            text = text .. "<LINE> <TEXT>" .. self.cached.riskDescription
        else
            self.cached = {
                title = title,
                pvpTexture = pvpTexture,
                difficulty = difficulty,
                titleWidth = titleWidth
            }

        end
        return self.cached
    end
end

function PhunZonesWidget:doTooltip()
    local rectWidth = 10;
    local cached = self.cached or {}
    if cached and cached.riskTitle then
        local titleLength = cached.riskTitleWidth;
        local descriptionLength = cached.riskDescriptionWidth;
        local textLength = titleLength;
        if descriptionLength > textLength then
            textLength = descriptionLength
        end

        local titleHeight = cached.riskTitleHeight;
        local descriptionHeight = cached.riskDescriptionHeight;
        local heightPadding = 2
        local rectHeight = titleHeight + descriptionHeight + (heightPadding * 3);

        local x = self:getMouseX() + 20;
        local y = self:getMouseY() + 20;

        self:drawRect(x, y, rectWidth + textLength, rectHeight, 1.0, 0.0, 0.0, 0.0);
        self:drawRectBorder(x, y, rectWidth + textLength, rectHeight, 0.7, 0.4, 0.4, 0.4);
        self:drawText(self.cached.riskTitle or "???", x + 2, y + 2, 1, 1, 1, 1);
        self:drawText(self.cached.riskDescription or "???", x + 2, y + titleHeight + (heightPadding * 2), 1, 1, 1, 0.7);
    end
end

function PhunZonesWidget:onClick()
    local player = getSpecificPlayer(self.pIndex)
    triggerEvent(PhunZones.events.OnPhunZoneWidgetClicked, player)
end

function PhunZonesWidget:onMouseDown(x, y)
    self.downX = self:getMouseX()
    self.downY = self:getMouseY()
    return true
end
function PhunZonesWidget:onMouseUp(x, y)
    self.downY = nil
    self.downX = nil
    if not self.dragging then
        self:onClick()
    else
        self.dragging = false
        self:setCapture(false)
    end
    return true
end

function PhunZonesWidget:onMouseMove(dx, dy)

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
    else
        if self:isMouseOver() then
            self:doTooltip()
        end
    end
end

function PhunZonesWidget:new(x, y, width, height, player)
    local o = {};
    o = ISPanel:new(x, y, width, height, player);
    setmetatable(o, self);
    self.__index = self;
    o.borderColor = {
        r = 0.7,
        g = 0.7,
        b = 0.7,
        a = 0.0
    };
    o.normalBorderColor = {
        r = 0.7,
        g = 0.7,
        b = 0.7,
        a = 0.0
    };
    o.hoverBorderColor = {
        r = 0.7,
        g = 0.7,
        b = 0.7,
        a = 0.5
    };
    o.backgroundColor = {
        r = 0,
        g = 0,
        b = 0,
        a = 0.0
    };
    o.normalBackgroundColor = {
        r = 0,
        g = 0,
        b = 0,
        a = 0.0
    };    
    o.hoverBackgroundColor = {
        r = 0.0,
        g = 0.0,
        b = 0.0,
        a = 0.5
    };
    o.cached = {}
    o.userPosition = false
    o.pIndex = player:getPlayerNum()
    o.zOffsetLargeFont = 25;
    o.zOffsetMediumFont = 20;
    o.zOffsetSmallFont = 6;
    o.moveWithMouse = true;
    o.dragging = false
    o.downX = nil;
    o.downY = nil;
    o.pvpOnTexture = getTexture("media/ui/pvpicon_on.png")
    return o;
end

function PhunZonesWidget:RestoreLayout(name, layout)
    ISLayoutManager.DefaultRestoreWindow(self, layout)
    self.userPosition = layout.userPosition == 'true'
    self:setVisible(true)
end

function PhunZonesWidget:SaveLayout(name, layout)
    ISLayoutManager.DefaultSaveWindow(self, layout)
    layout.width = nil
    layout.height = nil
    if self.userPosition then
        layout.userPosition = 'true'
    else
        layout.userPosition = 'false'
    end
end

