if not isClient() then
    return
end
PhunZonesWidget = ISPanel:derive("PhunZonesWidget");
PhunZonesWidget.instances = {}
local PhunRunners = PhunRunners
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

local calculatPips = function(risk)
    -- Ensure the risk is within the valid range
    if risk < 0 then
        risk = 0
    end
    if risk > 100 then
        risk = 100
    end

    -- Calculate the number of pips
    local pips = math.ceil(risk / 10)

    return pips
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

    local zone = PhunZones.players[self.player:getUsername()] or {}

    local title = zone.title or ""
    if string.len(title) == 0 and zone.isVoid then
        title = "Hiding"
    elseif string.len(title) == 0 then
        title = "Wilderness"
    end

    local subtitle = zone.subtitle or ""
    local pvpTexture = (zone.pvp and self.pvpOnTexture) or nil

    local x = 10
    local cached = self.cached or {}
    if pvpTexture then
        self:drawTextureScaledAspect(pvpTexture, 1, 1, 30, 30, 1);
        x = 42
    end

    local width = getTextManager():MeasureStringX(UIFont.Medium, title or "") + 20
    if width > self.width then
        self.width = width
    end

    self:drawText(title or "", x, 1, 0.7, 0.7, 0.7, 1.0, UIFont.Medium);
    local y = FONT_HGT_MEDIUM + 1
    if subtitle and string.len(subtitle) > 0 then
        self:drawText(subtitle or "", x, y, 0.7, 0.7, 0.7, 1.0, UIFont.Small);
        local subWidth = getTextManager():MeasureStringX(UIFont.Small, title or "") + 20
        if subWidth > self.width then
            self.width = subWidth
        end
        y = y + FONT_HGT_SMALL + 1
    end
    -- for pips
    if sandbox.PhunZones_Widget and PhunRunners then
        local riskData = PhunZones:getRiskInfo(self.player, zone)

        if riskData then
            local colors = {
                r = 0.4,
                g = 0.4,
                b = 0.4,
                a = 1.0
            }
            if riskData then
                if riskData.modifier == nil then
                    -- assert old version
                    if riskData.restless == false or riskData.risk == 0 then
                        colors.g = 0.9
                    elseif riskData.risk <= 10 then
                        colors.g = 0.9
                        colors.r = 0.9
                    else
                        colors.r = 0.9
                    end
                else
                    -- new version which includes modifier
                    if riskData.modifier == 0 or riskData.risk == 0 then
                        colors.g = 0.9
                    elseif riskData.modifier and riskData.modifier < 90 then
                        colors.g = 0.9
                        colors.r = 0.9
                    else
                        colors.r = 0.9
                    end
                end

                for i = 1, riskData.pips do
                    self:drawRect(x + ((i - 1) * 7), y, 5, 5, colors.a, colors.r, colors.g, colors.b);
                end

                if self:isMouseOver() then
                    for i = riskData.pips + 1, 10 do
                        self:drawRectBorder(x + ((i - 1) * 7), y, 5, 5, 0.7, 0.4, 0.4, 0.4);
                    end
                end
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
    local pData = PhunZones.players[player:getUsername()]
    if not pData then
        return
    end
    if pData then
        local data = pData
        local title = data.title or ""
        if data.void then
            title = "Hiding"
        end
        local subtitle = data.subtitle or ""
        if string.len(subtitle) > 0 then
            title = title .. " (" .. subtitle .. ")"
        end
        local pvpTexture = (data.pvp and self.pvpOnTexture) or nil
        local difficulty = data.difficulty or 0
        local titleWidth = getTextManager():MeasureStringX(UIFont.Medium, title)
        local summary
        if PhunRunners and PhunRunners.getSummary then
            summary = PhunRunners:getSummary(player) or {}
            self.cached = {
                title = title,
                subtitle = subtitle,
                pvpTexture = pvpTexture,
                difficulty = difficulty,
                titleWidth = titleWidth,
                spawnSprinters = summary.spawnSprinters == true,
                restless = summary.restless == true,
                risk = summary.risk or 0,
                riskTitle = summary.title or "",
                riskTitleWidth = getTextManager():MeasureStringX(UIFont.Small, summary.title or ""),
                riskTitleHeight = getTextManager():MeasureStringY(UIFont.Small, summary.title or ""),
                riskDescription = summary.description or "",
                riskDescriptionWidth = getTextManager():MeasureStringX(UIFont.Small, summary.description or ""),
                riskDescriptionHeight = getTextManager():MeasureStringY(UIFont.Small, summary.description or "")
            }
            local text = "<H1>" .. self.cached.title
            text = text .. "<LINE> <TEXT>" .. self.cached.riskDescription or ""
        else
            self.cached = {
                title = title,
                subtitle = subtitle,
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

    local zone = PhunZones.players[self.player:getUsername()] or {}
    local runners = PhunRunners and PhunRunners:getPlayerData(self.player) or {}

    local title = zone.title or ""
    if zone.void then
        title = "Hiding"
    end
    local subtitle = zone.subtitle or ""
    local pvpTexture = (zone.pvp and self.pvpOnTexture) or nil
    local difficulty = zone.difficulty or 0
    local titleWidth = getTextManager():MeasureStringX(UIFont.Medium, title)
    local summary = PhunRunners and PhunRunners.getSummary and PhunRunners:getSummary(self.player, zone) or {}

    local cached = {
        title = title,
        subtitle = subtitle,
        pvpTexture = pvpTexture,
        difficulty = difficulty,
        titleWidth = titleWidth,
        spawnSprinters = summary.spawnSprinters == true,
        restless = summary.restless == true,
        risk = summary.risk or 0,
        riskTitle = summary.title or "",
        riskSubtitle = summary.subtitle or nil,
        riskTitleWidth = getTextManager():MeasureStringX(UIFont.Small, summary.title or ""),
        riskTitleHeight = getTextManager():MeasureStringY(UIFont.Small, summary.title or ""),
        riskSubTitleHeight = string.len(subtitle) > 0 and
            getTextManager():MeasureStringY(UIFont.Small, summary.subtitle or "") or 0,
        riskDescription = summary.description or "",
        riskDescriptionWidth = getTextManager():MeasureStringX(UIFont.Small, summary.description or ""),
        riskDescriptionHeight = getTextManager():MeasureStringY(UIFont.Small, summary.description or "")
    }

    local titleLength = cached.riskTitleWidth;
    local descriptionLength = cached.riskDescriptionWidth;
    local textLength = titleLength;
    if descriptionLength > textLength then
        textLength = descriptionLength
    end

    local titleHeight = cached.riskTitleHeight;
    local subTitleHeight = cached.riskSubTitleHeight;
    local descriptionHeight = cached.riskDescriptionHeight;
    local heightPadding = 2
    local rectHeight = titleHeight + subTitleHeight + descriptionHeight + (heightPadding * 3);

    local x = self:getMouseX() + 20;
    local y = self:getMouseY() + 20;

    self:drawRect(x, y, rectWidth + textLength, rectHeight, 1.0, 0.0, 0.0, 0.0);
    self:drawRectBorder(x, y, rectWidth + textLength, rectHeight, 0.7, 0.4, 0.4, 0.4);
    self:drawText(cached.riskTitle or "???", x + 2, y + 2, 1, 1, 1, 1);
    if self.cached.riskSubtitle then
        self:drawText(cached.riskSubtitle or "???", x + 2, y + titleHeight + heightPadding, 1, 1, 1, 0.7);
    end
    self:drawText(cached.riskDescription or "???", x + 2, y + titleHeight + subTitleHeight + (heightPadding * 3), 1, 1,
        1, 0.7);

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

function PhunZonesWidget:onRightMouseUp(x, y)
    if isAdmin() then
        local context = ISContextMenu.get(self.pIndex, getMouseX(), getMouseY());
        context = ISInventoryPaneContextMenu.createMenu(self.pIndex, true, {}, getMouseX(), getMouseY());
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
    o.player = player
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
