if isServer() then
    return
end

local Core = PhunZones
local PL = PhunLib
local mapui = require("PhunZones/ui/ui_map")
local tools = require("PhunZones/ui/tools")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_SCALE = FONT_HGT_SMALL / 14
local BUTTON_HGT = FONT_HGT_SMALL + 6
local ROW_HGT = FONT_HGT_SMALL + 8
local PAD = 8
local LEFT_W = 260 * FONT_SCALE
local BOTTOM_BAR_H = BUTTON_HGT + PAD * 2
local TREE_RATIO = 0.42 -- tree takes 42% of left column height
local SCROLLBAR_W = 5

-- ---------------------------------------------------------------------------
-- Colour palette (B42-ish dark theme)
-- ---------------------------------------------------------------------------
local C = {
    bg = {
        r = 0.08,
        g = 0.08,
        b = 0.10,
        a = 0.97
    },
    panel = {
        r = 0.11,
        g = 0.11,
        b = 0.14,
        a = 1.0
    },
    border = {
        r = 0.25,
        g = 0.25,
        b = 0.30,
        a = 1.0
    },
    accent = {
        r = 0.90,
        g = 0.55,
        b = 0.10,
        a = 1.0
    }, -- orange
    accentDim = {
        r = 0.55,
        g = 0.33,
        b = 0.06,
        a = 1.0
    },
    danger = {
        r = 0.80,
        g = 0.15,
        b = 0.15,
        a = 1.0
    },
    text = {
        r = 0.90,
        g = 0.90,
        b = 0.90,
        a = 1.0
    },
    textDim = {
        r = 0.50,
        g = 0.50,
        b = 0.55,
        a = 1.0
    },
    textInherit = {
        r = 0.45,
        g = 0.55,
        b = 0.65,
        a = 1.0
    }, -- muted blue for inherited props
    rowSel = {
        r = 0.90,
        g = 0.55,
        b = 0.10,
        a = 0.18
    },
    rowAlt = {
        r = 1.0,
        g = 1.0,
        b = 1.0,
        a = 0.03
    },
    rowHover = {
        r = 1.0,
        g = 1.0,
        b = 1.0,
        a = 0.06
    },
    modBadge = {
        r = 0.20,
        g = 0.50,
        b = 0.80,
        a = 1.0
    }, -- blue for mod-origin props
    warnBadge = {
        r = 0.80,
        g = 0.60,
        b = 0.10,
        a = 1.0
    }, -- amber for orphan zones
    disabled = {
        r = 0.80,
        g = 0.15,
        b = 0.15,
        a = 0.25
    },
    treeConn = {
        r = 0.30,
        g = 0.30,
        b = 0.35,
        a = 1.0
    }
}

local profileName = "PhunZonesUIList"
Core.ui.zones = ISCollapsableWindowJoypad:derive(profileName)
Core.ui.zones.instances = {}
local UI = Core.ui.zones

-- ===========================================================================
-- PUBLIC: open the panel
-- ===========================================================================
function UI.OnOpenPanel(playerObj, key)
    if not PL.isAdmin(getPlayer()) then
        return
    end

    local playerIndex = playerObj:getPlayerNum()
    local sw = getCore():getScreenWidth()
    local sh = getCore():getScreenHeight()
    local w = math.min(math.floor(1100 * FONT_SCALE), sw - 20)
    local h = math.min(math.floor(680 * FONT_SCALE), sh - 20)
    -- Clamp to screen bounds
    local x = math.max(0, math.floor((sw - w) / 2))
    local y = math.max(0, math.floor((sh - h) / 2))

    print("[PhunZones] Opening at x=" .. x .. " y=" .. y .. " w=" .. w .. " h=" .. h .. " screen=" .. sw .. "x" .. sh)

    local instance = UI:new(x, y, w, h, playerObj, key)
    instance:initialise()
    instance:instantiate()
    instance:addToUIManager()
    instance:setVisible(true)
    instance:refreshData(Core.getLocation(playerObj))

    for k, v in pairs(Core.fields) do
        if v.initialize then
            v.initialize(instance, instance.data, playerObj)
        end
    end

    Core.ui.zones.instances[playerIndex] = instance
    return instance
end

-- ===========================================================================
-- CONSTRUCTOR
-- ===========================================================================
function UI:new(x, y, width, height, player, key)
    local o = ISCollapsableWindowJoypad:new(x, y, width, height, player)
    setmetatable(o, self)
    self.__index = self

    o.viewer = player
    o.player = player
    o.playerIndex = player:getPlayerNum()
    o.key = key
    o.moveWithMouse = false
    o.anchorRight = true
    o.anchorBottom = true
    o.zOffsetSmallFont = 25
    o.data = {}
    o.selectedData = nil
    o.selectedPoint = nil
    o.treeNodes = {} -- flat ordered list of rendered tree rows
    o.treeScroll = 0
    o.treeHover = -1
    o.propScroll = 0
    o.propHover = -1
    o.propRows = {} -- built in refreshProperties
    o.propFilter = ""
    o.treeFilter = "" -- zone filter text
    o._pendingChanges = {} -- fieldKey→value per zone, flushed on Save
    o:setWantKeyEvents(true)
    o:setTitle("PhunZones — Zone Editor")
    o.backgroundColor = {
        r = C.bg.r,
        g = C.bg.g,
        b = C.bg.b,
        a = 1.0
    }
    return o
end

-- ===========================================================================
-- createChildren
-- ===========================================================================
function UI:createChildren()
    ISCollapsableWindowJoypad.createChildren(self)

    self.controls = {}
    self._treeCollapsed = {}

    -- -----------------------------------------------------------------------
    -- Map (right side, full height minus bottom bar)
    -- -----------------------------------------------------------------------
    -- Positions computed in prerender; use placeholder values here
    local map = mapui:new(0, 0, 100, 100, self.player, "map")
    map:initialise()
    map:instantiate()
    -- Clip map rendering to its own bounds so it doesn't bleed over left column
    local origMapPrerender = map.prerender
    map.prerender = function(s)
        if origMapPrerender then
            origMapPrerender(s)
        end
        s:setStencilRect(0, 0, s.width, s.height)
    end
    local origMapRender = map.render
    map.render = function(s)
        if origMapRender then
            origMapRender(s)
        end
        s:clearStencilRect()
    end
    self:addChild(map)
    self.controls.mapui = map

    -- Wire map click -> zone select
    local outerSelf = self
    if map.map then
        map.map.onMouseDown = function(s, x, y)
            outerSelf._mapMouseDownX = x
            outerSelf._mapMouseDownY = y
        end
        map.map.onMouseUp = function(s, x, y)
            -- Only fire if mousedown also started on the map
            if outerSelf._mapMouseDownX == nil then
                return
            end
            local dx = math.abs(x - outerSelf._mapMouseDownX)
            local dy = math.abs(y - outerSelf._mapMouseDownY)
            outerSelf._mapMouseDownX = nil
            outerSelf._mapMouseDownY = nil
            if dx <= 4 and dy <= 4 then
                outerSelf:onMapClick(x, y, s)
            end
        end
    end

    -- -----------------------------------------------------------------------
    -- LEFT COLUMN HEADER: label + "show all" tick
    -- -----------------------------------------------------------------------
    local lblZones = ISLabel:new(0, 0, ROW_HGT, getText("IGUI_PhunZones_Regions"), 1, 1, 1, 1, UIFont.Small, true)
    lblZones:initialise();
    lblZones:instantiate()
    self:addChild(lblZones)
    self.controls.lblZones = lblZones

    -- Tree filter box
    local treeFilter = ISTextEntryBox:new("", 0, 0, 100, FONT_HGT_SMALL + 4)
    treeFilter:initialise();
    treeFilter:instantiate()
    treeFilter.onTextChange = function()
        -- Don't build here — off-by-one means getText() lags one char behind.
        -- prerender polls and rebuilds when the text actually changes.
    end
    self:addChild(treeFilter)
    self.controls.treeFilter = treeFilter

    local chkAll = ISTickBox:new(0, 0, BUTTON_HGT, BUTTON_HGT, getText("IGUI_PhunZones_AllZones"), self)
    chkAll:addOption(getText("IGUI_PhunZones_AllZones"), nil)
    chkAll:setSelected(1, true) -- default: show all zones
    chkAll:setWidthToFit()
    chkAll.tooltip = getText("IGUI_PhunZones_AllZones_tooltip")
    chkAll.onMouseUp = function(s, x, y)
        ISTickBox.onMouseUp(s, x, y)
        local filterActive = not s:isSelected(1)
        self.data = Core.buildZoneData(filterActive)
        self:rebuildUI()
    end
    self:addChild(chkAll)
    self.controls.chkAll = chkAll

    -- -----------------------------------------------------------------------
    -- TREE panel — mouse target only, drawn in window render
    -- -----------------------------------------------------------------------
    local treePanel = ISPanel:new(0, 0, 100, 100)
    treePanel:initialise();
    treePanel:instantiate()
    treePanel.backgroundColor = {
        r = 0,
        g = 0,
        b = 0,
        a = 0
    } -- fully transparent
    treePanel.drawBorder = false
    treePanel.onMouseUp = function(s, x, y)
        -- Only select if mouseup is on the same node as mousedown
        local i = math.floor((y + self.treeScroll) / ROW_HGT) + 1
        local upNode = self.treeNodes[i] and self.treeNodes[i].key
        if upNode and upNode == self._treeMouseDownNode then
            self:onTreeClick(s, x, y)
        end
        self._treeMouseDownNode = nil
    end
    treePanel.onMouseMove = function(s, x, y)
        self:onTreeHover(s, x, y)
    end
    treePanel.onMouseWheel = function(s, del)
        local totalH = #self.treeNodes * ROW_HGT
        self.treeScroll = math.max(0, math.min(self.treeScroll + del * ROW_HGT * 3, math.max(0, totalH - s.height)))
        return true
    end
    treePanel.onMouseDown = function(s, x, y)
        self:commitInlineEdit()
        -- Record which node was under the cursor on mousedown
        local i = math.floor((y + self.treeScroll) / ROW_HGT) + 1
        self._treeMouseDownNode = (self.treeNodes[i] and self.treeNodes[i].key) or nil
        local totalH = #self.treeNodes * ROW_HGT
        if totalH > s.height and x >= s.width - SCROLLBAR_W then
            self._treeScrDrag = true
            self._treeScrDragY = y
            self._treeScrDragStart = self.treeScroll
            s:setCapture(true)
        end
    end
    treePanel.onMouseMoveWhileCapture = function(s, x, y)
        if self._treeScrDrag then
            local totalH = #self.treeNodes * ROW_HGT
            self.treeScroll = math.max(0, math.min(
                self._treeScrDragStart + (y - self._treeScrDragY) * (totalH / s.height), totalH - s.height))
        end
    end
    treePanel.onMouseUpWhileCapture = function(s)
        self._treeScrDrag = false;
        s:setCapture(false)
    end
    self:addChild(treePanel)
    self.controls.treePanel = treePanel

    -- -----------------------------------------------------------------------
    -- PROPERTY panel header + filter
    -- -----------------------------------------------------------------------
    local lblProps = ISLabel:new(0, 0, ROW_HGT, "Properties", 1, 1, 1, 1, UIFont.Small, true)
    lblProps:initialise();
    lblProps:instantiate()
    self:addChild(lblProps)
    self.controls.lblProps = lblProps

    local filterBox = ISTextEntryBox:new("", 0, 0, 100, FONT_HGT_SMALL + 2)
    filterBox:initialise()
    filterBox.tooltip = "Filter properties..."
    filterBox.onTextChange = function()
        self.propFilter = filterBox:getText():lower()
        self:refreshProperties()
    end
    self:addChild(filterBox)
    self.controls.propFilter = filterBox

    -- -----------------------------------------------------------------------
    -- PROPERTY panel — mouse target only, drawn in window render
    -- -----------------------------------------------------------------------
    local propPanel = ISPanel:new(0, 0, 100, 100)
    propPanel:initialise();
    propPanel:instantiate()
    propPanel.backgroundColor = {
        r = 0,
        g = 0,
        b = 0,
        a = 0
    } -- fully transparent
    propPanel.drawBorder = false
    propPanel.onMouseUp = function(s, x, y)
        -- Only fire click if mouseup is on the same row as mousedown
        local i = math.floor((y + self.propScroll) / ROW_HGT) + 1
        if i == self._propMouseDownRow then
            self:onPropClick(s, x, y)
        end
        self._propMouseDownRow = nil
    end
    propPanel.onMouseMove = function(s, x, y)
        self:onPropHover(s, x, y)
    end
    propPanel.onMouseWheel = function(s, del)
        local totalH = #self.propRows * ROW_HGT
        self.propScroll = math.max(0, math.min(self.propScroll + del * ROW_HGT * 3, math.max(0, totalH - s.height)))
        return true
    end
    propPanel.onMouseDown = function(s, x, y)
        self:commitInlineEdit()
        -- Record which row was under cursor on mousedown
        local i = math.floor((y + self.propScroll) / ROW_HGT) + 1
        self._propMouseDownRow = (self.propRows[i] and not self.propRows[i].isGroupHeader) and i or nil
        local totalH = #self.propRows * ROW_HGT
        if totalH > s.height and x >= s.width - SCROLLBAR_W then
            self._propScrDrag = true
            self._propScrDragY = y
            self._propScrDragStart = self.propScroll
            s:setCapture(true)
        end
    end
    propPanel.onMouseMoveWhileCapture = function(s, x, y)
        if self._propScrDrag then
            local totalH = #self.propRows * ROW_HGT
            self.propScroll = math.max(0, math.min(
                self._propScrDragStart + (y - self._propScrDragY) * (totalH / s.height), totalH - s.height))
        end
    end
    propPanel.onMouseUpWhileCapture = function(s)
        self._propScrDrag = false;
        s:setCapture(false)
    end
    self:addChild(propPanel)
    self.controls.propPanel = propPanel

    -- -----------------------------------------------------------------------
    -- INLINE PROPERTY EDITOR — hidden text entry floated over value column
    -- -----------------------------------------------------------------------
    local inlineEdit = ISTextEntryBox:new("", 0, 0, 100, FONT_HGT_SMALL + 4)
    inlineEdit:initialise()
    inlineEdit:setVisible(false)
    self:addChild(inlineEdit)
    self.controls.inlineEdit = inlineEdit

    -- -----------------------------------------------------------------------
    -- INHERITS PICKER — hidden combo box floated over inherits row value
    -- -----------------------------------------------------------------------
    local inheritsPicker
    inheritsPicker = ISComboBox:new(0, 0, 100, FONT_HGT_SMALL + 4, self, function(owner)
        local selected = inheritsPicker:getSelectedText()
        if selected and selected ~= "" then
            owner:saveProp("inherits", selected)
        end
        inheritsPicker:setVisible(false)
    end)
    inheritsPicker:initialise()
    inheritsPicker:setVisible(false)
    self:addChild(inheritsPicker)
    self.controls.inheritsPicker = inheritsPicker
    -- -----------------------------------------------------------------------
    local function mkBtn(label, tooltip, cb)
        local btn = ISButton:new(0, 0, 0, BUTTON_HGT, label, self, cb)
        btn:initialise()
        btn.tooltip = tooltip or ""
        local tw = getTextManager():MeasureStringX(UIFont.Small, label)
        btn:setWidth(tw + 20)
        self:addChild(btn)
        return btn
    end

    self.controls.btnNewRegion = mkBtn("Add Region", "", function()
        self:promptNewZone()
    end)

    self.controls.btnSave = mkBtn("Save", "Save pending property changes", function()
        self:flushPendingChanges()
    end)
    self.controls.btnSave.enable = false

    self.controls.btnDeleteZone = mkBtn("Delete", "", function()
        self:confirmDelete()
    end)
    self.controls.btnDeleteZone.enable = false
    if self.controls.btnDeleteZone.enableCancelColor then
        self.controls.btnDeleteZone:enableCancelColor()
    end

    self.controls.btnAddRect = mkBtn(getText("IGUI_PhunZones_AddZone"), "Draw a new bounding rect on the map",
        function()
            if self.selectedData then
                self:enterDrawMode()
            end
        end)
    self.controls.btnAddRect.enable = false

    self.controls.btnEditRect = mkBtn(getText("IGUI_PhunZones_EditZone"), "", function()
        if self.selectedPoint and self.selectedData then
            Core.ui.xy.OnOpenPanel(self.player, {
                region = self.selectedData.region,
                zone = self.selectedData.zone,
                point = self.controls.mapui.selectedPointIndex,
                x = self.selectedPoint.x,
                y = self.selectedPoint.y,
                x2 = self.selectedPoint.x2,
                y2 = self.selectedPoint.y2
            }, function(nxy)
                self:savePoint(nxy, self.controls.mapui.selectedPointIndex)
            end)
        end
    end)
    self.controls.btnEditRect.enable = false

    self.controls.btnDeleteRect = mkBtn("Del Rect", "", function()
        self:confirmDeleteRect()
    end)
    self.controls.btnDeleteRect.enable = false

    self.controls.btnClose = mkBtn("Close", "", function()
        self:close()
    end)

    -- Run initial layout so panels have correct sizes before first render
    self:doLayout()
end

-- ===========================================================================
-- doLayout — shared layout logic called from both createChildren and prerender
-- ===========================================================================
function UI:doLayout()
    local th = self:titleBarHeight()
    local rh = self:resizeWidgetHeight()
    local lw = LEFT_W

    local usableH = self.height - th - rh
    local barH = BOTTOM_BAR_H
    local contentH = usableH - barH
    local headerH = ROW_HGT + 4
    local treeH = math.floor((contentH - headerH) * TREE_RATIO)
    local propLblH = ROW_HGT + 4
    local propH = contentH - headerH - treeH - PAD - propLblH

    local barY = usableH - barH
    local btnY = barY + math.floor((barH - BUTTON_HGT) / 2)

    -- Store for render
    self._layout = {
        th = th,
        lw = lw,
        barY = barY,
        barH = barH,
        usableH = usableH
    }

    -- Map (right side, below header, above bottom bar)
    local mx = lw + PAD
    local mw = self.width - mx - PAD
    local m = self.controls.mapui
    m:setX(mx);
    m:setY(th + headerH);
    m:setWidth(mw);
    m:setHeight(contentH - headerH)
    if m.map then
        m.map:setWidth(mw)
        m.map:setHeight(contentH - headerH)
    end

    -- Header: label left, filter centre, chkAll right
    self.controls.lblZones:setX(PAD);
    self.controls.lblZones:setY(th + 2)
    self.controls.chkAll:setX(lw - self.controls.chkAll.width - PAD)
    self.controls.chkAll:setY(th + 2)
    local chkX = lw - self.controls.chkAll.width - PAD
    local lblW = getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_PhunZones_Regions")) + PAD
    self.controls.treeFilter:setX(lblW)
    self.controls.treeFilter:setY(th + 2)
    self.controls.treeFilter:setWidth(chkX - lblW - PAD)

    -- Tree panel (mouse target)
    local treeY = headerH
    local tp = self.controls.treePanel
    tp:setX(PAD);
    tp:setY(th + treeY)
    tp:setWidth(lw - PAD * 2);
    tp:setHeight(math.max(20, treeH))

    -- Properties header
    local propLblY = treeY + treeH + PAD
    self.controls.lblProps:setX(PAD);
    self.controls.lblProps:setY(th + propLblY)
    self.controls.propFilter:setX(PAD + 72);
    self.controls.propFilter:setY(th + propLblY - 1)
    self.controls.propFilter:setWidth(lw - PAD * 2 - 72)

    -- Property panel (mouse target)
    local pp = self.controls.propPanel
    pp:setX(PAD);
    pp:setY(th + propLblY + propLblH)
    pp:setWidth(lw - PAD * 2);
    pp:setHeight(math.max(20, propH))

    -- Buttons
    local leftBtns = {self.controls.btnNewRegion, self.controls.btnSave, self.controls.btnDeleteZone}
    local rightBtns = {self.controls.btnClose, self.controls.btnDeleteRect, self.controls.btnEditRect,
                       self.controls.btnAddRect}

    local lx = PAD
    for _, btn in ipairs(leftBtns) do
        btn:setX(lx);
        btn:setY(th + btnY)
        lx = lx + btn.width + PAD / 2
    end
    local rx = self.width - PAD
    for _, btn in ipairs(rightBtns) do
        rx = rx - btn.width
        btn:setX(rx);
        btn:setY(th + btnY)
        rx = rx - PAD / 2
    end
end

-- ===========================================================================
-- prerender — single source of truth for all positions
-- ===========================================================================
function UI:prerender()
    ISCollapsableWindowJoypad.prerender(self)
    if self.width ~= self._lastW or self.height ~= self._lastH then
        self._lastW = self.width
        self._lastH = self.height
        self:doLayout()
    end

    local L = self._layout
    if not L then
        return
    end
    local th = L.th

    -- Poll tree filter for changes (onTextChange lags one char, so we poll here)
    local tf = self.controls.treeFilter
    if tf then
        local current = tf:getText():lower()
        if current ~= (self._lastTreeFilter or "") then
            self._lastTreeFilter = current
            self.treeScroll = 0
            self:buildTree()
        end
    end

    -- All background/content drawing here — prerender runs BEFORE children,
    -- so child controls (buttons, filter box, labels) paint on top correctly
    self:drawRect(0, th, L.lw, L.usableH, 1, C.bg.r, C.bg.g, C.bg.b)
    self:drawRect(0, th + L.barY, self.width, L.barH, 1, C.bg.r, C.bg.g, C.bg.b)
    self:drawRect(L.lw, th, 1, L.barY, C.border.a, C.border.r, C.border.g, C.border.b)
    self:drawRect(0, th + L.barY, self.width, 1, C.border.a, C.border.r, C.border.g, C.border.b)

    local tp = self.controls.treePanel
    if tp then
        local ox, oy = tp.x, tp.y -- tp.y already includes th
        self:drawRect(ox, oy, tp.width, tp.height, 1, C.panel.r, C.panel.g, C.panel.b)
        self:drawRectBorder(ox, oy, tp.width, tp.height, C.border.a, C.border.r, C.border.g, C.border.b)
        self:renderTree(ox, oy, tp.width, tp.height)
    end

    local pp = self.controls.propPanel
    if pp then
        local ox, oy = pp.x, pp.y -- pp.y already includes th
        self:drawRect(ox, oy, pp.width, pp.height, 1, C.panel.r, C.panel.g, C.panel.b)
        self:drawRectBorder(ox, oy, pp.width, pp.height, C.border.a, C.border.r, C.border.g, C.border.b)
        self:renderProps(ox, oy, pp.width, pp.height)
    end
end

function UI:render()
    ISCollapsableWindowJoypad.render(self)
end

-- ===========================================================================
-- TREE: build from Core.data.zones
-- ===========================================================================
function UI:buildTree()
    -- Build parent→children map from raw zones
    local zones = Core.data and Core.data.zones or {}
    local byKey = {}
    local children = {}

    for k, v in pairs(zones) do
        byKey[k] = v
        -- do NOT mutate v with _key — store separately in node
        local parent = v.inherits
        if parent then
            if not children[parent] then
                children[parent] = {}
            end
            table.insert(children[parent], k)
        end
    end

    -- Sort children alphabetically at each level for determinism
    for _, list in pairs(children) do
        table.sort(list, function(a, b)
            local ta = (byKey[a] and byKey[a].title) or a
            local tb = (byKey[b] and byKey[b].title) or b
            return ta:lower() < tb:lower()
        end)
    end

    -- Find roots (no inherits, or inherits points to missing key)
    local roots = {}
    local hasParent = {}
    for k, v in pairs(byKey) do
        if v.inherits and byKey[v.inherits] then
            hasParent[k] = true
        end
    end
    for k in pairs(byKey) do
        if not hasParent[k] then
            table.insert(roots, k)
        end
    end
    table.sort(roots, function(a, b)
        if a == "_default" then
            return true
        end
        if b == "_default" then
            return false
        end
        local ta = (byKey[a] and byKey[a].title) or a
        local tb = (byKey[b] and byKey[b].title) or b
        return ta:lower() < tb:lower()
    end)

    -- DFS to build flat ordered node list with depth
    self.treeNodes = {}
    local collapsed = self._treeCollapsed or {}
    self._treeCollapsed = collapsed
    -- Read filter directly from control to avoid onTextChange off-by-one
    local filter = self.controls.treeFilter and self.controls.treeFilter:getText():lower() or ""
    self.treeFilter = filter

    -- Pre-compute which keys directly match or have a matching descendant
    local hasMatch = {}
    local directMatch = {}
    if filter ~= "" then
        local function checkMatch(key)
            local v = byKey[key] or {}
            local title = (v.title or key):lower()
            if title:find(filter, 1, true) or key:lower():find(filter, 1, true) then
                directMatch[key] = true
                hasMatch[key] = true
            end
            if children[key] then
                for _, ck in ipairs(children[key]) do
                    if checkMatch(ck) then
                        hasMatch[key] = true
                    end
                end
            end
            return hasMatch[key] == true
        end
        for _, rk in ipairs(roots) do
            checkMatch(rk)
        end
    end

    local function walk(key, depth)
        local v = byKey[key] or {}
        local isOrphan = v.inherits and not byKey[v.inherits]
        local hasKids = children[key] and #children[key] > 0
        local isDisabled = v.disabled == true

        -- Skip if filtered and neither this node nor any descendant matches
        if filter ~= "" and not hasMatch[key] then
            return
        end

        table.insert(self.treeNodes, {
            key = key,
            depth = depth,
            title = v.title or key,
            hasKids = hasKids,
            collapsed = collapsed[key] == true,
            orphan = isOrphan,
            disabled = isDisabled,
            zone = v
        })

        if hasKids and not collapsed[key] then
            for _, ck in ipairs(children[key]) do
                -- When filtering: only walk children that match or have matching descendants
                -- (prevents unmatched siblings from showing under a matched parent)
                if filter == "" or hasMatch[ck] then
                    walk(ck, depth + 1)
                end
            end
        end
    end

    for _, rk in ipairs(roots) do
        walk(rk, 0)
    end
end

-- ===========================================================================
-- TREE: render at absolute window coords ox,oy,w,h
-- ===========================================================================
function UI:renderTree(ox, oy, w, h)
    local nodes = self.treeNodes
    local scroll = self.treeScroll
    local indent = 14
    local toggleW = FONT_HGT_SMALL + 2
    local totalH = #nodes * ROW_HGT
    local hasScroll = totalH > h
    local contentW = hasScroll and (w - SCROLLBAR_W - 2) or w

    for i, node in ipairs(nodes) do
        local ry = (i - 1) * ROW_HGT - scroll
        if ry >= h then
            break
        end
        if ry + ROW_HGT > 0 then
            local ay = oy + ry
            if ay + ROW_HGT > oy and ay < oy + h then
                local isSelected = self.selectedData and self.selectedData.key == node.key
                local isHover = self.treeHover == i

                if isSelected then
                    self:drawRect(ox, ay, contentW, ROW_HGT, C.rowSel.a, C.rowSel.r, C.rowSel.g, C.rowSel.b)
                elseif isHover then
                    self:drawRect(ox, ay, contentW, ROW_HGT, C.rowHover.a, C.rowHover.r, C.rowHover.g, C.rowHover.b)
                elseif i % 2 == 0 then
                    self:drawRect(ox, ay, contentW, ROW_HGT, C.rowAlt.a, C.rowAlt.r, C.rowAlt.g, C.rowAlt.b)
                end

                -- Tree connector lines for child nodes
                if node.depth > 0 then
                    local cx = ox + node.depth * indent - indent + 6
                    self:drawRect(cx, ay, 1, ROW_HGT / 2, C.treeConn.a, C.treeConn.r, C.treeConn.g, C.treeConn.b)
                    self:drawRect(cx, ay + ROW_HGT / 2 - 1, indent - 6, 1, C.treeConn.a, C.treeConn.r, C.treeConn.g,
                        C.treeConn.b)
                end

                -- Toggle arrow drawn in fixed slot; label always starts at consistent column
                local toggleX = ox + node.depth * indent + 4
                local labelX = toggleX + toggleW

                if node.hasKids then
                    local arrow = node.collapsed and "+" or "-"
                    self:drawText(arrow, toggleX, ay + 2, C.accentDim.r, C.accentDim.g, C.accentDim.b, 1.0, UIFont.Small)
                end

                local tx = labelX
                local tr, tg, tb, ta = C.text.r, C.text.g, C.text.b, C.text.a
                if node.disabled then
                    tr, tg, tb, ta = C.textDim.r, C.textDim.g, C.textDim.b, 0.5
                end
                if node.orphan then
                    self:drawText("!", tx, ay + 2, C.warnBadge.r, C.warnBadge.g, C.warnBadge.b, 1.0, UIFont.Small)
                    tx = tx + FONT_HGT_SMALL + 2
                end

                local label = node.title
                if node.key == "_default" then
                    label = "-- Default --"
                end

                -- Pending changes: shift name to accent colour instead of adding a character
                if self._pendingChanges[node.key] then
                    tr, tg, tb, ta = C.accent.r, C.accent.g, C.accent.b, 1.0
                end
                self:drawText(label, tx, ay + 2, tr, tg, tb, ta, UIFont.Small)

                local rightKey = (node.key ~= node.title and node.key ~= "_default") and node.key or nil
                if rightKey then
                    local kw = getTextManager():MeasureStringX(UIFont.Small, rightKey)
                    local lw2 = getTextManager():MeasureStringX(UIFont.Small, label)
                    if tx + lw2 + 8 < ox + contentW - kw - 4 then
                        self:drawText(rightKey, ox + contentW - kw - 4, ay + 2, C.textDim.r, C.textDim.g, C.textDim.b,
                            0.7, UIFont.Small)
                    end
                end
            end
        end
    end

    if hasScroll then
        local sbH = math.max(20, h * (h / totalH))
        local sbY = oy + (scroll / math.max(1, totalH - h)) * (h - sbH)
        self:drawRect(ox + w - SCROLLBAR_W, oy, SCROLLBAR_W, h, 0.3, 0.15, 0.15, 0.18)
        self:drawRect(ox + w - SCROLLBAR_W, sbY, SCROLLBAR_W, sbH, C.accentDim.a, C.accentDim.r, C.accentDim.g,
            C.accentDim.b)
    end
end

-- ===========================================================================
-- TREE: interaction
-- ===========================================================================
function UI:onTreeClick(panel, x, y)
    local i = math.floor((y + self.treeScroll) / ROW_HGT) + 1
    if i < 1 or i > #self.treeNodes then
        return
    end
    local node = self.treeNodes[i]
    if not node then
        return
    end

    local toggleX = node.depth * 14 + 4
    if node.hasKids and x >= toggleX and x <= toggleX + FONT_HGT_SMALL + 4 then
        self._treeCollapsed[node.key] = not self._treeCollapsed[node.key]
        self:buildTree()
        return
    end

    -- Suppress map click for next 200ms to prevent map repositioning from re-selecting
    self._suppressMapSelectUntil = getTimestampMs() + 200
    self:selectZone(node.key)
end

function UI:onTreeHover(panel, x, y)
    local i = math.floor((y + self.treeScroll) / ROW_HGT) + 1
    self.treeHover = (i >= 1 and i <= #self.treeNodes) and i or -1
end

function UI:selectZone(key)
    self:cancelInlineEdit()
    self.propHover = -1
    self.propScroll = 0 -- reset scroll when switching zones

    local zones = Core.data and Core.data.zones or {}
    local lookup = Core.data and Core.data.lookup or {}
    local raw = zones[key] or {}
    local merged = lookup[key] or {}

    self.selectedData = {
        key = key,
        region = raw.region or key,
        zone = raw.zone or "main",
        inherits = raw.inherits,
        raw = raw,
        merged = merged
    }

    -- Update button states
    local notDefault = key ~= "_default"
    self.controls.btnDeleteZone.enable = notDefault
    self.controls.btnAddRect.enable = notDefault

    -- Deselect rect
    self.selectedPoint = nil
    self.controls.btnEditRect.enable = false
    self.controls.btnDeleteRect.enable = false

    self:refreshProperties()
    self:refreshZonePoints((raw.points or {}))

    -- Scroll tree to show selection
    for i, node in ipairs(self.treeNodes) do
        if node.key == key then
            local panel = self.controls.treePanel
            local rowY = (i - 1) * ROW_HGT
            if rowY < self.treeScroll then
                self.treeScroll = rowY
            elseif rowY + ROW_HGT > self.treeScroll + panel.height then
                self.treeScroll = rowY + ROW_HGT - panel.height
            end
            break
        end
    end
    self:updateSaveDiscardButtons()
end

-- ===========================================================================
-- PROPERTIES: build row list
-- ===========================================================================
function UI:refreshProperties()
    self.propRows = {}
    -- Note: propScroll intentionally NOT reset here — preserved across refreshes
    -- so inline edits don't jump the view. Reset happens in selectZone instead.
    if not self.selectedData then
        return
    end

    local key = self.selectedData.key
    local raw = self.selectedData.raw or {}
    local merged = self.selectedData.merged or {}

    -- For _default, merged may be keyed differently — try fallbacks
    local mergedIsEmpty = true
    for _ in pairs(merged) do
        mergedIsEmpty = false;
        break
    end
    if key == "_default" and mergedIsEmpty then
        local lookup = Core.data and Core.data.lookup or {}
        merged = lookup["_default"] or lookup["default"] or raw
    end

    local filter = self.propFilter
    local pending = self._pendingChanges[key] or {}
    local seen = {}

    -- Collect fields into groups
    local groups = {}
    local groupFields = {}
    local UNGROUPED = "other"

    for k, fdef in pairs(Core.fields) do
        if k ~= "region" and k ~= "zone" and k ~= "key" and k ~= "_key" then
            if filter == "" or k:lower():find(filter, 1, true) or
                (fdef.label and getText(fdef.label):lower():find(filter, 1, true)) then
                local g = fdef.group or UNGROUPED
                if not groupFields[g] then
                    groupFields[g] = {}
                    table.insert(groups, g)
                end
                table.insert(groupFields[g], {
                    k = k,
                    fdef = fdef
                })
            end
            seen[k] = true
        end
    end

    -- Sort groups by Core.groups order, ungrouped "other" always last
    table.sort(groups, function(a, b)
        if a == UNGROUPED then
            return false
        end
        if b == UNGROUPED then
            return true
        end
        local ga = Core.groups[a]
        local gb = Core.groups[b]
        local oa = ga and ga.order or 999
        local ob = gb and gb.order or 999
        if oa ~= ob then
            return oa < ob
        end
        return a < b
    end)

    -- Build propRows: header then fields per group
    for _, g in ipairs(groups) do
        local fields = groupFields[g]
        if #groups > 1 then
            local gdef = Core.groups[g]
            local glabel = gdef and gdef.label or g
            table.insert(self.propRows, {
                isGroupHeader = true,
                label = glabel
            })
        end
        -- Sort fields by fdef.order then label
        table.sort(fields, function(a, b)
            local oa = a.fdef.order or 999
            local ob = b.fdef.order or 999
            if oa ~= ob then
                return oa < ob
            end
            return getText(a.fdef.label or a.k) < getText(b.fdef.label or b.k)
        end)
        for _, f in ipairs(fields) do
            local k, fdef = f.k, f.fdef
            local val = pending[k] ~= nil and pending[k] or merged[k]
            local isOver = raw[k] ~= nil or pending[k] ~= nil
            table.insert(self.propRows, {
                key = k,
                label = getText(fdef.label or k),
                value = val,
                override = isOver,
                origin = fdef.mod or nil,
                fdef = fdef
            })
        end
    end

    -- Extra keys not in Core.fields (mod data, unknown fields)
    local extraRows = {}
    for k, v in pairs(raw) do
        if not seen[k] and k ~= "inherits" and k ~= "disabled" and k ~= "isolated" and k ~= "_key" and k ~= "points" and
            k ~= "title" and k ~= "region" and k ~= "zone" then
            local displayVal = type(v) == "table" and ("[table]") or tostring(v)
            if filter == "" or k:lower():find(filter, 1, true) then
                table.insert(extraRows, {
                    key = k,
                    label = k,
                    value = displayVal,
                    override = true,
                    fdef = nil,
                    extra = true
                })
            end
        end
    end
    if #extraRows > 0 then
        if #groups > 0 then
            local otherDef = Core.groups and Core.groups["other"]
            local otherLabel = otherDef and otherDef.label or "Other"
            table.insert(self.propRows, {
                isGroupHeader = true,
                label = otherLabel
            })
        end
        table.sort(extraRows, function(a, b)
            return a.key < b.key
        end)
        for _, r in ipairs(extraRows) do
            table.insert(self.propRows, r)
        end
    end

    -- Special rows at top: inherits, disabled
    table.insert(self.propRows, 1, {
        key = "disabled",
        label = "Disabled (tombstone)",
        value = raw.disabled == true,
        override = raw.disabled ~= nil,
        special = true,
        danger = raw.disabled == true
    })
    table.insert(self.propRows, 1, {
        key = "inherits",
        label = "Inherits from",
        value = raw.inherits or "(none — root)",
        override = true,
        special = true
    })
end

function UI:renderPropRows()
    self:refreshProperties()
end

-- ===========================================================================
-- PROPERTIES: render into propPanel
-- ===========================================================================
function UI:renderProps(ox, oy, w, h)
    if not self.selectedData then
        local msg = "Select a zone to view properties"
        local mw = getTextManager():MeasureStringX(UIFont.Small, msg)
        self:drawText(msg, ox + (w - mw) / 2, oy + h / 2 - 8, C.textDim.r, C.textDim.g, C.textDim.b, 1.0, UIFont.Small)
        return
    end

    local scroll = self.propScroll
    local totalH = #self.propRows * ROW_HGT
    local hasScroll = totalH > h
    local contentW = hasScroll and (w - SCROLLBAR_W - 2) or w
    local valX = math.floor(contentW * 0.52)

    for i, row in ipairs(self.propRows) do
        local ry = (i - 1) * ROW_HGT - scroll
        if ry >= h then
            break
        end
        if ry + ROW_HGT > 0 then
            local ay = oy + ry
            if ay + ROW_HGT > oy and ay < oy + h then

                -- Group header row: divider line + label, no value column
                if row.isGroupHeader then
                    local lineY = ay + math.floor(ROW_HGT / 2)
                    self:drawRect(ox + 4, lineY, contentW - 8, 1, C.border.a, C.border.r, C.border.g, C.border.b)
                    local gw = getTextManager():MeasureStringX(UIFont.Small, row.label)
                    local gx = ox + math.floor((contentW - gw) / 2)
                    self:drawRect(gx - 4, ay + 2, gw + 8, ROW_HGT - 4, 1, C.panel.r, C.panel.g, C.panel.b)
                    self:drawText(row.label, gx, ay + 2, C.textDim.r, C.textDim.g, C.textDim.b, 0.8, UIFont.Small)
                else
                    if i % 2 == 0 then
                        self:drawRect(ox, ay, contentW, ROW_HGT, C.rowAlt.a, C.rowAlt.r, C.rowAlt.g, C.rowAlt.b)
                    end
                    if self.propHover == i then
                        self:drawRect(ox, ay, contentW, ROW_HGT, C.rowHover.a, C.rowHover.r, C.rowHover.g, C.rowHover.b)
                    end
                    if self._editingRow and self._editingRow.key == row.key then
                        self:drawRect(ox, ay, contentW, ROW_HGT, 0.15, C.accent.r, C.accent.g, C.accent.b)
                        self:drawRectBorder(ox, ay, contentW, ROW_HGT, 0.6, C.accent.r, C.accent.g, C.accent.b)
                    end

                    if row.override and not row.special then
                        local cr = row.danger and C.danger or C.accent
                        self:drawRect(ox, ay + 1, 2, ROW_HGT - 2, cr.a, cr.r, cr.g, cr.b)
                    end

                    local badgeW = 0
                    if row.origin then
                        badgeW = getTextManager():MeasureStringX(UIFont.Small, row.origin) + 6
                        self:drawRect(ox + contentW - badgeW - 2, ay + 2, badgeW, ROW_HGT - 4, 0.8, C.modBadge.r,
                            C.modBadge.g, C.modBadge.b)
                        self:drawText(row.origin, ox + contentW - badgeW + 1, ay + 2, 1, 1, 1, 0.9, UIFont.Small)
                    end

                    local lr, lg, lb, la
                    if row.special then
                        lr, lg, lb, la = C.textDim.r, C.textDim.g, C.textDim.b, 1.0
                    elseif row.override then
                        lr, lg, lb, la = C.text.r, C.text.g, C.text.b, 1.0
                    else
                        lr, lg, lb, la = C.textInherit.r, C.textInherit.g, C.textInherit.b, 1.0
                    end
                    if row.danger then
                        lr, lg, lb = C.danger.r, C.danger.g, C.danger.b
                    end

                    self:drawText(row.label, ox + 6, ay + 2, lr, lg, lb, la, UIFont.Small)

                    local valStr = tostring(row.value ~= nil and row.value or "--")
                    local vr, vg, vb, va
                    if row.override then
                        vr, vg, vb, va = C.accent.r, C.accent.g, C.accent.b, 1.0
                    else
                        vr, vg, vb, va = C.textDim.r, C.textDim.g, C.textDim.b, 0.9
                    end
                    if row.danger and row.value == true then
                        vr, vg, vb = C.danger.r, C.danger.g, C.danger.b
                    end

                    self:drawText(valStr, ox + valX + 4, ay + 2, vr, vg, vb, va, UIFont.Small)

                    self:drawRect(ox, ay + ROW_HGT - 1, contentW, 1, C.border.a * 0.4, C.border.r, C.border.g,
                        C.border.b)
                end -- end if/else isGroupHeader
            end -- bounds check
        end
    end

    if hasScroll then
        local sbH = math.max(20, h * (h / totalH))
        local sbY = oy + (scroll / math.max(1, totalH - h)) * (h - sbH)
        self:drawRect(ox + w - SCROLLBAR_W, oy, SCROLLBAR_W, h, 0.3, 0.15, 0.15, 0.18)
        self:drawRect(ox + w - SCROLLBAR_W, sbY, SCROLLBAR_W, sbH, C.accentDim.a, C.accentDim.r, C.accentDim.g,
            C.accentDim.b)
    end
end

function UI:onPropClick(panel, x, y)
    -- Always suppress map click when interacting with prop panel
    self._suppressMapSelectUntil = getTimestampMs() + 300

    if not self.selectedData then
        return
    end

    local i = math.floor((y + self.propScroll) / ROW_HGT) + 1
    if i < 1 or i > #self.propRows then
        return
    end
    local row = self.propRows[i]
    if not row or row.isGroupHeader then
        return
    end

    -- Cancel any existing edit first
    self:cancelInlineEdit()

    local sd = self.selectedData
    if not sd then
        return
    end

    -- Special: disabled tombstone toggle
    if row.key == "disabled" then
        self:saveProp("disabled", not (sd.raw.disabled == true))
        return
    end

    -- Special: inherits — show zone picker combo
    if row.key == "inherits" then
        self:showInheritsPicker(row, i)
        return
    end

    -- Other special rows (disabled handled above) — not editable
    if row.special then
        return
    end

    -- Extra unknown fields — not editable
    if row.extra or not row.fdef then
        return
    end

    local fdef = row.fdef

    -- Boolean: toggle immediately
    if fdef.type == "boolean" then
        local cur = sd.raw[row.key]
        if cur == nil then
            cur = sd.merged[row.key]
        end
        self:saveProp(row.key, not cur)
        return
    end

    -- String/int/combo: show inline text entry over the value column
    local pp = self.controls.propPanel
    local th = self._layout and self._layout.th or 0
    local hasScroll = (#self.propRows * ROW_HGT) > pp.height
    local contentW = hasScroll and (pp.width - SCROLLBAR_W - 2) or pp.width
    local valX = math.floor(contentW * 0.52)
    local rowScreenY = pp.y + (i - 1) * ROW_HGT - self.propScroll

    local ie = self.controls.inlineEdit
    local ieH = FONT_HGT_SMALL + 4
    ie:setX(pp.x + valX)
    ie:setY(rowScreenY + math.floor((ROW_HGT - ieH) / 2))
    ie:setWidth(contentW - valX - 4)
    ie:setHeight(ieH)

    local curVal = sd.raw[row.key]
    if curVal == nil then
        curVal = sd.merged[row.key]
    end
    ie:setText(curVal ~= nil and tostring(curVal) or "")
    ie:setVisible(true)
    ie:focus()
    ie:selectAll()

    self._editingRow = row
end

function UI:showInheritsPicker(row, rowIndex)
    local sd = self.selectedData
    if not sd or not sd.key then
        return
    end

    local pp = self.controls.propPanel
    local th = self._layout and self._layout.th or 0
    local hasScroll = (#self.propRows * ROW_HGT) > pp.height
    local contentW = hasScroll and (pp.width - SCROLLBAR_W - 2) or pp.width
    local valX = math.floor(contentW * 0.52)
    local rowScreenY = pp.y + (rowIndex - 1) * ROW_HGT - self.propScroll

    local picker = self.controls.inheritsPicker
    picker:setX(pp.x + valX)
    picker:setY(rowScreenY)
    picker:setWidth(contentW - valX - 4)

    -- Build options: _default plus all zones except self and its descendants
    local selfKey = sd.key
    -- Collect all descendants to exclude (prevent circular inheritance)
    local descendants = {}
    local function collectDesc(k)
        for _, node in ipairs(self.treeNodes) do
            if node.zone and node.zone.inherits == k and node.key ~= selfKey then
                descendants[node.key] = true
                collectDesc(node.key)
            end
        end
    end
    collectDesc(selfKey)

    picker:clear()
    local current = sd.raw.inherits or "_default"
    local selectedIdx = 1
    local idx = 1
    -- _default always first
    picker:addOption("_default")
    if current == "_default" then
        selectedIdx = idx
    end
    idx = idx + 1

    -- Add all other zones sorted by title
    local options = {}
    for k, v in pairs(Core.data.zones or {}) do
        if k ~= selfKey and k ~= "_default" and not descendants[k] then
            table.insert(options, {
                key = k,
                title = v.title or k
            })
        end
    end
    table.sort(options, function(a, b)
        return a.title:lower() < b.title:lower()
    end)
    for _, opt in ipairs(options) do
        picker:addOption(opt.key)
        if opt.key == current then
            selectedIdx = idx
        end
        idx = idx + 1
    end

    picker:select(selectedIdx)
    picker:setVisible(true)
end

function UI:commitInlineEdit()
    local ie = self.controls.inlineEdit
    if not ie:isVisible() then
        return
    end
    ie:setVisible(false)

    local row = self._editingRow
    self._editingRow = nil
    if not row or not row.fdef then
        return
    end

    -- Read directly from the text box at commit time
    local raw = ie:getText()
    local fdef = row.fdef
    local val

    if fdef.type == "int" then
        val = tonumber(raw)
        if val == nil then
            return
        end
    elseif fdef.type == "boolean" then
        val = (raw == "true" or raw == "1")
    else
        val = raw
    end

    self:saveProp(row.key, val)
end

function UI:cancelInlineEdit()
    local ie = self.controls.inlineEdit
    if ie and ie:isVisible() then
        ie:setVisible(false)
    end
    local ip = self.controls.inheritsPicker
    if ip and ip:isVisible() then
        ip:setVisible(false)
    end
    self._editingRow = nil
end

-- Save a single property field — accumulates into _pendingChanges, no server call yet
function UI:saveProp(fieldKey, newValue)
    local sd = self.selectedData
    if not sd or not sd.key then
        return
    end

    local fdef = Core.fields[fieldKey]
    local val = newValue
    if fdef then
        if fdef.type == "int" then
            val = tonumber(newValue)
            if val == nil then
                return
            end
        elseif fdef.type == "boolean" then
            val = (newValue == true or newValue == "true" or newValue == 1)
        elseif fdef.type == "combo" then
            val = (newValue ~= "" and newValue or nil)
        end
    end

    -- Track pending change per zone
    local key = sd.key
    if not self._pendingChanges[key] then
        self._pendingChanges[key] = {}
    end
    self._pendingChanges[key][fieldKey] = val

    -- Optimistic local update so UI reflects change immediately
    if Core.data.zones[key] then
        Core.data.zones[key][fieldKey] = val
    end
    if Core.data.lookup[key] then
        Core.data.lookup[key][fieldKey] = val
    end
    sd.raw[fieldKey] = val
    sd.merged[fieldKey] = val

    -- If title changed, rebuild tree so label updates immediately
    if fieldKey == "title" then
        self:buildTree()
    end
    -- If inherits changed, rebuild tree so hierarchy updates immediately
    if fieldKey == "inherits" then
        self:buildTree()
    end

    -- Enable Save button based on pending state
    self:updateSaveDiscardButtons()
    self:refreshProperties()
end

-- Returns true if there are any pending changes across any zone
function UI:hasPendingChanges()
    for _ in pairs(self._pendingChanges) do
        return true
    end
    return false
end

-- Flush all pending changes across all zones
function UI:flushPendingChanges()
    self:commitInlineEdit()
    if not self:hasPendingChanges() then
        return
    end

    local changes = {}
    for zoneKey, fields in pairs(self._pendingChanges) do
        local zones = Core.data and Core.data.zones or {}
        local raw = zones[zoneKey] or {}
        local inherited = {}
        if zoneKey ~= "_default" then
            local parentKey = raw.inherits
            inherited = Core.data.lookup[parentKey or "_default"] or {}
        end

        local zoneData = {}
        for fieldKey, val in pairs(fields) do
            if inherited[fieldKey] ~= val then
                zoneData[fieldKey] = val
            end
        end

        local hasData = false
        for _ in pairs(zoneData) do
            hasData = true;
            break
        end
        if hasData then
            changes[zoneKey] = zoneData
        end
    end

    self._pendingChanges = {}
    self:updateSaveDiscardButtons()

    local hasChanges = false
    for _ in pairs(changes) do
        hasChanges = true;
        break
    end
    if hasChanges then
        Core.saveChanges(changes) -- single batch call for all zones
        -- Re-sync UI with updated data, preserving current selection
        local currentKey = self.selectedData and self.selectedData.key
        self:rebuildUI(currentKey and {
            key = currentKey
        } or nil)
    end
end

-- Update Save button enabled state
function UI:updateSaveDiscardButtons()
    self.controls.btnSave.enable = self:hasPendingChanges()
end

function UI:onPropHover(panel, x, y)
    local i = math.floor((y + self.propScroll) / ROW_HGT) + 1
    self.propHover = (i >= 1 and i <= #self.propRows) and i or -1
end

-- ===========================================================================
-- MAP: click to select zone
-- ===========================================================================
function UI:onMapClick(x, y, mapPanel)
    -- Suppress if tree/prop click just happened, or if inline edit is open
    if self._suppressMapSelectUntil and getTimestampMs() < self._suppressMapSelectUntil then
        return
    end
    if self.controls.inlineEdit and self.controls.inlineEdit:isVisible() then
        return
    end

    local api = self.controls.mapui.map and self.controls.mapui.map.mapAPI
    if not api then
        return
    end
    local wx = api:uiToWorldX(x, y)
    local wy = api:uiToWorldY(x, y)

    -- Find which zone's rect contains this world point
    local zones = Core.data and Core.data.zones or {}
    for key, z in pairs(zones) do
        for _, pt in ipairs(z.points or {}) do
            if wx >= pt[1] and wy >= pt[2] and wx <= pt[3] and wy <= pt[4] then
                self:selectZone(key)
                return
            end
        end
    end
end

-- ===========================================================================
-- MAP DRAW MODE (for adding rects)
-- ===========================================================================
function UI:enterDrawMode()
    self._drawMode = true
    self._drawStart = nil
    -- Visual hint: override map mouse handlers temporarily
    local map = self.controls.mapui
    if not map or not map.map then
        return
    end

    local origDown = map.map.onMouseDown
    local origMove = map.map.onMouseMove
    local origUp = map.map.onMouseUp

    map.map.onMouseDown = function(s, mx, my)
        local api = s.mapAPI
        self._drawStart = {
            wx = api:uiToWorldX(mx, my),
            wy = api:uiToWorldY(mx, my)
        }
    end

    map.map.onMouseMove = function(s, dx, dy)
        if self._drawStart then
            -- Could draw a live preview rect here via map:setData overlay
        end
    end

    map.map.onMouseUp = function(s, mx, my)
        if not self._drawStart then
            return
        end
        local api = s.mapAPI
        local wx2 = api:uiToWorldX(mx, my)
        local wy2 = api:uiToWorldY(mx, my)
        local x1 = math.min(self._drawStart.wx, wx2)
        local y1 = math.min(self._drawStart.wy, wy2)
        local x2 = math.max(self._drawStart.wx, wx2)
        local y2 = math.max(self._drawStart.wy, wy2)

        self._drawMode = false
        self._drawStart = nil

        -- Restore original handlers
        map.map.onMouseDown = origDown
        map.map.onMouseMove = origMove
        map.map.onMouseUp = origUp

        -- Open XY popup pre-filled with drawn coords
        Core.ui.xy.OnOpenPanel(self.player, {
            region = self.selectedData.region,
            zone = self.selectedData.zone,
            x = math.floor(x1),
            y = math.floor(y1),
            x2 = math.floor(x2),
            y2 = math.floor(y2)
        }, function(nxy)
            self:savePoint(nxy)
        end)
    end
end

-- ===========================================================================
-- DATA: refresh all
-- ===========================================================================
-- Called by the OnZonesUpdated event — Core.data is already current by the time this fires
function UI:refreshData(zone)
    self.data = Core.data
    self:rebuildUI(zone)
end

-- Called internally after saves — Core.data is already up to date, no updateZoneData needed
function UI:rebuildUI(zone)
    self:buildTree()

    -- Re-select previously selected zone if possible, skip _default/void
    if zone then
        local targetKey = zone.key or zone.region
        if targetKey and targetKey ~= "_default" and targetKey ~= "void" and Core.data.zones[targetKey] then
            self:selectZone(targetKey)
            return
        end
    end

    -- No location match - leave nothing selected
    self.selectedData = nil
    self:refreshProperties()
end

-- ===========================================================================
-- DATA: zone points
-- ===========================================================================
function UI:refreshZonePoints(points, selectedIdx)
    self.selectedPoint = nil
    self.controls.btnEditRect.enable = false
    self.controls.btnDeleteRect.enable = false

    -- Pass points to map for rendering
    self.controls.mapui:setData(points, nil)

    if points and #points > 0 then
        local idx = selectedIdx or 1
        self.selectedPoint = {
            x = points[idx][1],
            y = points[idx][2],
            x2 = points[idx][3],
            y2 = points[idx][4]
        }
        self.controls.btnEditRect.enable = true
        self.controls.btnDeleteRect.enable = true
        self.controls.mapui:setData(points, self.selectedPoint)
    end
end

-- ===========================================================================
-- DATA: save zone properties
-- ===========================================================================
function UI:saveData(data)
    -- Compute inherited baseline to diff against
    local inherited = {}
    local zones = Core.data.zones or {}
    if data.key and data.key ~= "_default" then
        local parentKey = data.inherits
        if parentKey then
            inherited = Core.data.lookup[parentKey] or {}
        else
            inherited = Core.data.lookup["_default"] or {}
        end
    end

    -- Build zoneData diff and save with correct signature
    local zoneData = {}
    for k, v in pairs(Core.fields) do
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
        -- Only include if different from inherited
        if k ~= "key" and inherited[k] ~= final then
            zoneData[k] = final
        end
    end

    local key = data.key or data.region
    if not key then
        return
    end

    Core.saveChanges({
        [key] = zoneData
    })
    self:rebuildUI({
        key = key
    })
end

-- ===========================================================================
-- DATA: save rect point
-- ===========================================================================
function UI:savePoint(xy, pointIndex)
    local zones = Core.data.zones or {}
    local key = xy.region -- legacy compat; ideally xy.key
    local zone = zones[key]
    if not zone then
        return
    end

    local md = ModData.getOrCreate(Core.const.modifiedModData)
    if not md[key] then
        md[key] = {}
    end
    if not md[key].points then
        md[key].points = {}
        -- copy existing
        for _, p in ipairs(zone.points or {}) do
            table.insert(md[key].points, p)
        end
    end

    if pointIndex then
        md[key].points[pointIndex] = {xy.x, xy.y, xy.x2, xy.y2}
    else
        table.insert(md[key].points, {xy.x, xy.y, xy.x2, xy.y2})
    end

    Core.saveChanges({
        [key] = md[key]
    })
    -- Reload raw data and re-render
    self.data = Core.buildZoneData(not self.controls.chkAll:isSelected(1))
    local updatedZone = Core.data.zones[key]
    self:refreshZonePoints(updatedZone and updatedZone.points or {}, pointIndex)
end

-- ===========================================================================
-- NEW ZONE: name prompt
-- ===========================================================================
function UI:promptNewZone()
    local sw = getCore():getScreenWidth()
    local sh = getCore():getScreenHeight()
    local w, h = 300, 120
    local entry
    local modal =
        ISModalDialog:new(sw / 2 - w / 2, sh / 2 - h / 2, w, h, "Enter zone name:", true, self, -- true = has cancel button
            function(owner, button)
                if button.internal ~= "YES" then
                    return
                end
                local name = entry and entry:getText() or ""
                name = name:match("^%s*(.-)%s*$")
                if name == "" then
                    return
                end
                owner:createNewZone(name)
            end)
    modal:initialise()
    entry = ISTextEntryBox:new("", 10, 60, w - 20, FONT_HGT_SMALL + 6)
    entry:initialise()
    modal:addChild(entry)
    modal:addToUIManager()
    entry:focus()
end

function UI:createNewZone(name)
    local key = name:gsub("[^%w]", "")
    if key == "" then
        return
    end

    -- Ensure key is unique — append incrementing number if taken
    local zones = Core.data and Core.data.zones or {}
    if zones[key] then
        local i = 2
        local candidate = key .. tostring(i)
        while zones[candidate] do
            i = i + 1
            candidate = key .. tostring(i)
        end
        key = candidate
    end

    Core.saveChanges({
        [key] = {
            title = name,
            inherits = "_default"
        }
    })
    self:rebuildUI({
        key = key
    })
end

-- ===========================================================================
-- DELETE zone
-- ===========================================================================
function UI:confirmDelete()
    local selected = self.selectedData
    if not selected then
        return
    end

    local key = selected.key
    local msg = string.format("Delete '%s' and all its children? This cannot be undone.", key)
    local w = math.max(300 * FONT_SCALE, getTextManager():MeasureStringX(UIFont.Small, msg) + 40 * FONT_SCALE)
    local h = 200 * FONT_SCALE
    local modal = ISModalDialog:new(getCore():getScreenWidth() / 2 - w / 2, getCore():getScreenHeight() / 2 - h / 2, w,
        h, msg, true, self, function(s, button)
            if button.internal == "YES" then
                sendClientCommand(Core.name, Core.commands.deleteZone, {
                    key = key
                })
                self:close()
            end
        end, nil)
    modal:initialise()
    modal:addToUIManager()
end

function UI:confirmDeleteRect()
    if not self.selectedPoint or not self.selectedData then
        return
    end
    -- For now: save with the point removed
    local key = self.selectedData.key
    local zones = Core.data.zones or {}
    local zone = zones[key]
    if not zone then
        return
    end

    local idx = self.controls.mapui.selectedPointIndex or 1
    local pts = {}
    for i, p in ipairs(zone.points or {}) do
        if i ~= idx then
            table.insert(pts, p)
        end
    end

    local md = ModData.getOrCreate(Core.const.modifiedModData)
    if not md[key] then
        md[key] = {}
    end
    md[key].points = pts
    Core.saveChanges({
        [key] = md[key]
    })

    self.data = Core.buildZoneData(not self.controls.chkAll:isSelected(1))
    local updated = Core.data.zones[key]
    self:refreshZonePoints(updated and updated.points or {})
end

-- ===========================================================================
-- Window lifecycle
-- ===========================================================================
function UI:close()
    if self._closing then
        return
    end -- prevent re-entry from ISCollapsableWindowJoypad.close
    if self:hasPendingChanges() then
        local modal = ISModalDialog:new(0, 0, 300, 150, getText("IGUI_PhunZones_UnsavedChanges") or
            "You have unsaved changes. Save before closing?", true, self, UI.onCloseModalResult)
        modal:initialise()
        modal:addToUIManager()
        return
    end
    self:doClose()
end

function UI:onCloseModalResult(button)
    if button.internal == "YES" then
        self:flushPendingChanges()
    end
    self:doClose()
end

function UI:doClose()
    self._closing = true
    ISCollapsableWindowJoypad.close(self)
    self:setVisible(false)
    self:removeFromUIManager()
    self.instances[self.playerIndex] = nil
end

function UI:isKeyConsumed(key)
    if self.controls.inlineEdit and self.controls.inlineEdit:isVisible() then
        if key == Keyboard.KEY_RETURN or key == Keyboard.KEY_NUMPADENTER or key == Keyboard.KEY_ESCAPE then
            return true
        end
    end
    return key == Keyboard.KEY_ESCAPE
end

function UI:onKeyPressed(key)
    local ie = self.controls.inlineEdit
    if ie and ie:isVisible() then
        if key == Keyboard.KEY_RETURN or key == Keyboard.KEY_NUMPADENTER then
            self:commitInlineEdit()
            return
        elseif key == Keyboard.KEY_ESCAPE then
            self:cancelInlineEdit()
            return
        end
    end
end

function UI:onKeyRelease(key)
    if key == Keyboard.KEY_ESCAPE then
        self:close()
    end
end
