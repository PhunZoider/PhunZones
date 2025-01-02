if isServer() then
    return
end

local PZ = PhunZones

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)
local HEADER_HGT = FONT_HGT_MEDIUM + 2 * 2
local FONT_SCALE = FONT_HGT_SMALL / 14
local BUTTON_HGT = FONT_HGT_SMALL + 6
local DEFAULT_SCALE = 3
local profileName = "PhunZonesUIMap"
local UI = ISPanel:derive(profileName);

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
    o.markerSelectedBackgroundColor = {
        r = 0.0,
        g = 0.9,
        b = 0,
        a = 1
    };
    o.markerSelectedBorderColour = {
        r = 0,
        g = 0,
        b = 0,
        a = 1
    };
    o.markerBackgroundColour = {
        r = 0,
        g = 0,
        b = 0.6,
        a = 0.5
    };
    o.markerBorderColour = {
        r = 0,
        g = 0,
        b = 1,
        a = 1
    };
    o.zOffsetSmallFont = 25;
    o.moveWithMouse = true;
    o.key = key;
    o.fill = 1.0;
    o.scale = DEFAULT_SCALE;
    o.data = {
        points = {},
        selected = nil
    }
    o.lineTex = "c"
    o:setWantKeyEvents(true)
    self.player = player
    self.playerIndex = player:getPlayerNum()
    return o;
end

function UI:createChildren()

    ISPanel.createChildren(self);

    local x = 0
    local y = 0
    local padding = 10
    local h = FONT_HGT_SMALL;
    local w = self.width;

    self.map = ISMiniMapInner:new(0, 0, self.width, self.height, self.playerIndex);
    self:addChild(self.map);
    self:InitPlayer()

end

function UI:drawLine(x, y, x2, y2)

    local limit = ISMap.SCALE * (2.4 * self.scale / DEFAULT_SCALE / self.fill);

    local worldX = self.map.mapAPI:uiToWorldX(x, y)
    local worldY = self.map.mapAPI:uiToWorldY(x, y)

    local lastWorldX = self.map.mapAPI:uiToWorldX(x2, y2)
    local lastWorldY = self.map.mapAPI:uiToWorldY(x2, y2)

    local diff = math.abs(worldX - lastWorldX) + math.abs(worldY - lastWorldY)

    local xDiff = worldX - lastWorldX;
    local yDiff = worldY - lastWorldY;

    local divisor = diff / limit;
    divisor = math.floor(divisor) + 1

    xDiff = xDiff / divisor;
    yDiff = yDiff / divisor;

    for i = 1, divisor do
        self:addSymbol(lastWorldX + xDiff * i, lastWorldY + yDiff * i);
    end

end

function UI:render()
    ISPanel.render(self);

    self:setStencilRect(self.map.x, self.map.y, self.map.width, self.map.height)
    local bgColor = self.markerBackgroundColour
    local borderColor = self.markerBorderColour
    for _, v in ipairs(self.data.points or {}) do

        local x = math.floor(self.map.mapAPI:worldToUIX(v[1], v[2]))
        local y = math.floor(self.map.mapAPI:worldToUIY(v[1], v[2]))
        local x2 = math.floor(self.map.mapAPI:worldToUIX(v[3], v[4]))
        local y2 = math.floor(self.map.mapAPI:worldToUIY(v[3], v[4]))

        self.map:drawRect(x, y, math.abs(x2 - x), math.abs(y2 - y), bgColor.a, bgColor.r, bgColor.g, bgColor.b);
        self.map:drawRectBorder(x, y, math.abs(x2 - x), math.abs(y2 - y), borderColor.a, borderColor.r, borderColor.g,
            borderColor.b);
    end

end

function UI:addSymbol(worldX, worldY)
    -- local tex = self.lineTex;
    -- if self.symbolsUI.selectedSymbol then
    --     tex = self.symbolsUI.selectedSymbol.tex;
    -- end
    if not ISWorldMap_instance then
        ISWorldMap.ShowWorldMap(self.playerIndex)
        ISWorldMap.HideWorldMap(self.playerIndex)
    end
    local textureSymbol = ISWorldMap_instance.mapAPI:getSymbolsAPI():addTexture("circle_orb", worldX, worldY)

    textureSymbol:setRGBA(1, .5, 1, 1.0)
    textureSymbol:setAnchor(0.5, 0.5)
    textureSymbol:setScale(ISMap.SCALE * self.scale / 10)
end

function UI:zoomAndCentreMapToBounds(x, y, x2, y2)

    local map = self.map
    local api = map.mapAPI

    local wx = x - 10
    local wy = y - 10
    local wx2 = x2 + 10
    local wy2 = y2 + 10

    local width = wx2 - wx
    local height = wy2 - wy

    local bound = math.max(width, height)
    local mapWidth = map:getWidth()
    local mapHeight = map:getHeight()
    local viewport = math.max(mapWidth, mapHeight)

    api:centerOn(wx + (width / 2), wy + (height / 2))
    -- kludge to get the zoom level right
    for zoom = 24, 10, -.5 do
        api:setZoom(zoom)
        local lw = map:getWidth()
        local lh = map:getHeight()

        local scale = api:getWorldScale()
        local check = bound * scale
        if check < viewport then
            -- box now fits in viewport at this zoom level
            api:centerOn(wx + (width / 2), wy + (height / 2))
            return zoom
        end
    end
    api:centerOn(wx + (width / 2), wy + (height / 2))
    -- api:setZoom(mapFunctions.zoomMax)
    return map.zoomMax

end

function UI:setData(data, selectedPoint)

    self.data = {
        points = data,
        selected = nil
    }

    local points = data
    local selectedPoint = selectedPoint

    local minx = 100000
    local miny = 100000
    local maxx = 0
    local maxy = 0

    for _, v in ipairs(points) do

        -- local x = math.floor(self.map.mapAPI:worldToUIX(v[1], v[2]))
        -- local y = math.floor(self.map.mapAPI:worldToUIY(v[1], v[2]))
        -- local x2 = math.floor(self.map.mapAPI:worldToUIX(v[3], v[4]))
        -- local y2 = math.floor(self.map.mapAPI:worldToUIY(v[3], v[4]))
        -- table.insert(self.data.points, {x, y, x2, y2})
        minx = math.min(minx, v[1])
        miny = math.min(miny, v[2])
        maxx = math.max(maxx, v[3])
        maxy = math.max(maxy, v[4])
        -- self:drawLine(v[1], v[2], v[3], v[4])
    end

    self:zoomAndCentreMapToBounds(minx, miny, maxx, maxy)
    -- self.map.mapAPI:centerOn(math.abs(minx + maxx) / 2, math.abs(miny + maxy) / 2)

    -- remove existing points

end

--[[

    MiniMap

]] --
function UI:InitPlayer()
    local mini = self.map
    local api = mini.mapAPI

    local dirs = getLotDirectories()
    for i = 1, dirs:size() do

        local file = 'media/maps/' .. dirs:get(i - 1) .. '/worldmap.xml'
        if fileExists(file) then
            mini.mapAPI:addData(file)
        end

        api:endDirectoryData()

        api:addImages('media/maps/' .. dirs:get(i - 1))
    end
    api:setBoundsFromWorld()
    api:setZoom(11.5)

    api:setBoolean("HideUnvisited", false)
    api:setBoolean("CellGrid", true)
    api:setBoolean("Players", true)
    api:setBoolean("Symbols", false)
    api:setBoolean("MiniMapSymbols", true)
    api:setBoolean("Isometric", false)
    api:setBoolean("RemotePlayers", true)
    api:setBoolean("PlayerNames", true)
    api:centerOn(api:getMaxXInSquares() / 2, api:getMaxYInSquares() / 2)

    function mini:onMouseUp(x, y)
        -- ISMiniMapInner.onMouseUp(self, x, y)
        if mini.dragging then
            mini.dragging = false
            if mini.dragMoved then
                return
            end

        end

    end

    function mini:onMouseWheel(del)
        local res = ISMiniMapInner.onMouseWheel(self, del)
        return res
    end

    MapUtils.initDefaultStyleV1(mini)

end

return UI
