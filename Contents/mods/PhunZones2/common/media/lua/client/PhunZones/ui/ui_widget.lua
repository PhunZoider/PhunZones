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

local profileName = "PhunZonesUIWidgety"
PZ.ui.widget = ISPanel:derive(profileName);
PZ.ui.widget.instances = {}
local UI = PZ.ui.widget

function UI.OnOpenPanel(playerObj, playerIndex)

    playerIndex = playerIndex or playerObj:getPlayerNum()

    if not UI.instances[playerIndex] then
        local core = getCore()
        local FONT_SCALE = getTextManager():getFontHeight(UIFont.Small) / 14
        local width = 200 * FONT_SCALE
        local height = 50 * FONT_SCALE

        local x = (core:getScreenWidth() - width) / 2
        local y = (core:getScreenHeight() - height) / 2

        UI.instances[playerIndex] = UI:new(x, y, width, height, playerObj, playerIndex);
        UI.instances[playerIndex]:initialise();
        ISLayoutManager.RegisterWindow(profileName, PZ.ui.widget, PZ.ui.widget.instances[playerIndex])
    end

    UI.instances[playerIndex]:addToUIManager();
    UI.instances[playerIndex]:setVisible(true);
    return UI.instances[playerIndex];

end

function UI:new(x, y, width, height, player, playerIndex)
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
    o.normalTextColor = {
        r = 0.2,
        g = 0.2,
        b = 0.2,
        a = 0.7
    };
    o.hoverTextColor = {
        r = 1,
        g = 1,
        b = 1,
        a = .9
    }
    o.data = {}
    o.coverMap = false

    o.moveWithMouse = true;
    o.anchorRight = true
    o.anchorBottom = true
    o.player = player
    o.playerIndex = playerIndex
    o.zOffsetLargeFont = 25;
    o.zOffsetMediumFont = 20;
    o.zOffsetSmallFont = 6;
    return o;
end

function UI:onClick()
    triggerEvent(PZ.events.OnPhunZoneWidgetClicked, self.player)
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

function UI:onMouseDown(x, y)
    self.downX = self:getMouseX()
    self.downY = self:getMouseY()
    return true
end

function UI:onMouseUp(x, y)
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

function UI:RestoreLayout(name, layout)

    if name == profileName then
        ISLayoutManager.DefaultRestoreWindow(self, layout)
        self.userPosition = layout.userPosition == 'true'
    end
    self:recalcSize();
end

function UI:SaveLayout(name, layout)
    ISLayoutManager.DefaultSaveWindow(self, layout)
    if self.userPosition then
        layout.userPosition = 'true'
    else
        layout.userPosition = 'false'
    end
end

function UI:close()
    if not self.locked then
        ISPanel.close(self);
    end
end

function UI:createChildren()
    ISPanel.createChildren(self);
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

function UI:setData(data)

    if data.zone then

        if data.zone.title then
            self.data.title = data.zone.title
            self.data.titleWidth = getTextManager():MeasureStringX(UIFont.Medium, data.zone.title) + 20
            if self.data.titleWidth > self.width then
                self.data.titleWidth = self.width
            end
            self.data.titleHeight = FONT_HGT_MEDIUM + 10
        else
            self.data.title = nil
            self.data.titleWidth = 0
            self.data.titleHeight = 0
        end

        if data.zone.subtitle then
            self.data.subtitle = data.zone.subtitle
            self.data.subtitleWidth = getTextManager():MeasureStringX(UIFont.Small, data.zone.subtitle) + 20
            if self.data.subtitleWidth > self.width then
                self.data.subtitleWidth = self.width
            end
            self.data.subtitleHeight = FONT_HGT_SMALL
        else
            self.data.subtitle = nil
            self.data.subtitleWidth = 0
            self.data.subtitleHeight = 0
        end

        self.data.difficulty = nil

        if data.zone.difficulty then
            local maxDifficulty = PZ.getOption("MaxDifficulty", 0)
            if maxDifficulty > 0 then
                self.data.difficulty = data.zone.difficulty
                self.data.maxDifficulty = maxDifficulty
            end
        end
    end

end

function UI:prerender()

    if (ISWorldMap_instance and ISWorldMap_instance:isVisible()) then
        return
    end

    ISPanel.prerender(self);

    local x = 5
    local y = 5
    local txtColor = self.normalTextColor

    if self.downX == nil and self.userPosition ~= true then
        local minimap = getPlayerMiniMap(self.playerIndex)

        if not minimap then
            -- player does not minimap
            local width = getTextManager():MeasureStringX(UIFont.Small, self.data.title or "") + x
            self.borderColor = self.hoverBorderColor
            self.backgroundColor = self.hoverBackgroundColor
            self:setWidth(self.data.titleWidth + 40)
            self:setHeight(self.data.titleHeight + self.data.subtitleHeight + 2)

            self:setX(getCore():getScreenWidth() - self.width - 2)
            self:setY(getCore():getScreenHeight() - self.height - 40)
            self:bringToTop()

            txtColor = self.hoverTextColor

        elseif self.coverMap then
            -- draw over the map
            self:setX(minimap.x)
            self:setY(minimap.y)
            self:bringToTop()

            self:setWidth(0)
            self:setHeight(0)

            local title = minimap.titleBar

            if title:isVisible() then
                return
            end
        else

            -- Draw behind/over the map?
            if minimap.titleBar:isVisible() then
                self.y = minimap.y - 50
            else
                self.y = minimap.y - 50 - minimap.titleBar.height
            end

            self.borderColor = self.hoverBorderColor
            self.backgroundColor = self.hoverBackgroundColor
            self:setWidth(minimap.width)
            self:setHeight(50 + minimap.titleBar.height)
            -- self:setHeight(self.data.titleHeight + self.data.subtitleHeight + 2)
            self.x = minimap.x

            -- self:setX(minimap.x)
            -- self:setY(minimap.y - self.height - 2)
            -- self:bringToTop()

            txtColor = self.hoverTextColor

        end
    else
        txtColor = self.hoverTextColor
        self.borderColor = self.hoverBorderColor
        self.backgroundColor = self.hoverBackgroundColor
    end

    self:drawText(self.data.title or "", x, y, txtColor.r, txtColor.g, txtColor.b, txtColor.a, UIFont.Medium);
    y = y + FONT_HGT_SMALL + 1

    if self.data.subtitle then
        self:drawText(self.data.subtitle or "", x, y, txtColor.r, txtColor.g, txtColor.b, txtColor.a, UIFont.Small);
        y = y + FONT_HGT_SMALL + 1
    end

    local difficulty = tonumber(self.data.difficulty)
    local maxDifficulty = tonumber(self.data.maxDifficulty)

    if difficulty and maxDifficulty and maxDifficulty > 0 then
        local pad = 5
        local pipHeight = 5
        local gap = 2

        local x0 = pad
        local innerW = self.width - pad * 2
        local y = self.height - pad - pipHeight

        -- width of each pip so everything fits perfectly
        local totalGaps = gap * (maxDifficulty - 1)
        local pipWidth = (innerW - totalGaps) / maxDifficulty
        if pipWidth < 1 then
            pipWidth = 1
        end

        local fill = {
            r = 0.4,
            g = 0.4,
            b = 0.4,
            a = 1.0
        }
        local borderA, borderRGB = 0.7, 0.4

        -- If you only ever have whole-number difficulty, this still works.
        local full = math.floor(difficulty)
        local frac = difficulty - full -- 0..1

        for i = 1, maxDifficulty do
            local px = x0 + (i - 1) * (pipWidth + gap)

            -- empty pip outline
            self:drawRectBorder(px, y, pipWidth, pipHeight, borderA, borderRGB, borderRGB, borderRGB)

            -- filled portion
            if i <= full then
                self:drawRect(px, y, pipWidth, pipHeight, fill.a, fill.r, fill.g, fill.b)
            elseif i == full + 1 and frac > 0 then
                -- optional partial fill for fractional difficulty (e.g. 2.5)
                self:drawRect(px, y, pipWidth * frac, pipHeight, fill.a, fill.r, fill.g, fill.b)
            end
        end
    end

end
