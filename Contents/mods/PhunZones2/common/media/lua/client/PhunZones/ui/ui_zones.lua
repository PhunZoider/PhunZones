-- ui_zones.lua
-- Zone editor panel — tree, properties, map overlay.
-- Renamed from ui_list.lua; map zone rendering/interaction is now delegated
-- to ui_map_overlay.lua so this file stays focused on tree + property UI.
if isServer() then
    return
end

local Core = PhunZones

local mapui = require("PhunZones/ui/ui_map")
local MapOverlay = require("PhunZones/ui/ui_map_overlay")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_SCALE = FONT_HGT_SMALL / 14
local BUTTON_HGT = FONT_HGT_SMALL + 6
local ROW_HGT = FONT_HGT_SMALL + 8
local PAD = 8
local LEFT_W = 260 * FONT_SCALE
local BOTTOM_BAR_H = BUTTON_HGT + PAD * 2
local TREE_RATIO = 0.42
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
    },
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
    },
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
    },
    warnBadge = {
        r = 0.80,
        g = 0.60,
        b = 0.10,
        a = 1.0
    },
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

local profileName = "PhunZonesUIZones"
Core.ui.zones = ISCollapsableWindowJoypad:derive(profileName)
Core.ui.zones.instances = {}
local UI = Core.ui.zones

-- ---------------------------------------------------------------------------
-- Helper: returns the active zone/lookup tables, preferring self.data so that
-- filtering works in isolation without touching global Core.data.
-- ---------------------------------------------------------------------------
local function zones(self)
    return (self.data and self.data.zones) or (Core.data and Core.data.zones) or {}
end

local function lookup(self)
    return (self.data and self.data.lookup) or (Core.data and Core.data.lookup) or {}
end

-- ===========================================================================
-- PUBLIC: open the panel
-- ===========================================================================
function UI.OnOpenPanel(playerObj, key)

    local playerIndex = playerObj:getPlayerNum()
    local sw = getCore():getScreenWidth()
    local sh = getCore():getScreenHeight()
    local w = math.min(math.floor(1100 * FONT_SCALE), sw - 20)
    local h = math.min(math.floor(680 * FONT_SCALE), sh - 20)
    local x = math.max(0, math.floor((sw - w) / 2))
    local y = math.max(0, math.floor((sh - h) / 2))

    print("[PhunZones] Opening at x=" .. x .. " y=" .. y .. " w=" .. w .. " h=" .. h .. " screen=" .. sw .. "x" .. sh)

    local instance = UI:new(x, y, w, h, playerObj, key)
    instance:initialise()
    instance:instantiate()
    instance:addToUIManager()
    ISLayoutManager.RegisterWindow(profileName, UI, instance)
    instance:setVisible(true)
    instance:refreshData(Core.getLocation(playerObj:getX(), playerObj:getY()))

    -- After refreshData, explicitly zoom the map to the selected zone's full bounds.
    -- refreshZonePoints → setData already calls zoomAndCentreMapToBounds, but the
    -- map widget may not be fully laid-out yet at that point. Calling it here
    -- (after the window is visible) ensures the zoom/centre actually takes effect.
    local mapui = instance.controls.mapui
    if mapui then
        local sd = instance.selectedData
        if sd and sd.raw and sd.raw.points and #sd.raw.points > 0 then
            local minx, miny, maxx, maxy = 1e9, 1e9, -1e9, -1e9
            for _, p in ipairs(sd.raw.points) do
                minx = math.min(minx, p[1]);
                miny = math.min(miny, p[2])
                maxx = math.max(maxx, p[3]);
                maxy = math.max(maxy, p[4])
            end
            mapui:zoomAndCentreMapToBounds(minx, miny, maxx, maxy)
        else
            -- No zone selected (or zone has no points): centre on the player
            local px, py = playerObj:getX(), playerObj:getY()
            mapui:zoomAndCentreMapToBounds(px - 150, py - 150, px + 150, py + 150)
        end
    end

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
    o._filterActive = true
    o.selectedData = nil
    o.selectedPoint = nil
    o.treeNodes = {}
    o.treeScroll = 0
    o.treeHover = -1
    o.propScroll = 0
    o.propHover = -1
    o.propRows = {}
    o.propFilter = ""
    o.treeFilter = ""
    o._pendingChanges = {}
    o.overlay = nil -- created in createChildren after mapui is ready

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
    -- Map (right side)
    -- -----------------------------------------------------------------------
    local map = mapui:new(0, 0, 100, 100, self.player, "map")
    map:initialise()
    map:instantiate()

    -- Clip map to its own bounds
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

    -- -----------------------------------------------------------------------
    -- MapOverlay — created after mapui is initialised so the hook can attach
    -- to map.map immediately.  If map.map isn't ready yet, hookNow() is safe
    -- to call again from doLayout once the widget exists.
    -- -----------------------------------------------------------------------
    local overlay = MapOverlay:new(map)
    self.overlay = overlay

    -- Wire overlay callbacks → zone list logic
    overlay.onZoneClicked = function(key)
        self:selectZone(key)
    end

    overlay.onPointClicked = function(key, idx)
        self.selectedPtIdx = idx
        local z = zones(self)[key]
        if z and z.points and z.points[idx] then
            local pt = z.points[idx]
            self.selectedPoint = {
                x = pt[1],
                y = pt[2],
                x2 = pt[3],
                y2 = pt[4]
            }
            self.controls.mapui.selectedPointIndex = idx
            self:updateCoordBar(pt)
        end
        self.controls.btnDeleteRect.enable = (self.selectedPoint ~= nil)
    end

    overlay.onRectDrawn = function(x1, y1, x2, y2)
        -- Open the XY fine-tune popup pre-filled with the drawn coords
        if not self.selectedData then
            return
        end
        Core.ui.xy.OnOpenPanel(self.player, {
            region = self.selectedData.region,
            zone = self.selectedData.zone,
            x = x1,
            y = y1,
            x2 = x2,
            y2 = y2
        }, function(nxy)
            self:savePoint(nxy)
        end)
    end

    overlay.onRectResized = function(key, ptIdx, x1, y1, x2, y2)
        self:queuePointChange(key, ptIdx, x1, y1, x2, y2)
    end

    overlay.onRectDragging = function(key, ptIdx, x1, y1, x2, y2)
        -- Update coord bar live every frame during drag without queuing a pending change
        self:updateCoordBar({x1, y1, x2, y2})
    end

    -- -----------------------------------------------------------------------
    -- Coord bar — sits in the header strip above the map.
    -- Shows X1/Y1/X2/Y2 of the active rect; W/H are read-only derived labels.
    -- Typing a value and pressing Enter/Tab commits it to the pending queue.
    -- -----------------------------------------------------------------------
    local coordFields = {} -- ordered: x1, y1, x2, y2
    local coordNames = {"X1", "Y1", "X2", "Y2"}

    local function makeCoordField(name)
        local lbl = ISLabel:new(0, 0, ROW_HGT, name .. ":", 1, 1, 1, 1, UIFont.Small, true)
        lbl:initialise();
        lbl:instantiate()
        self:addChild(lbl)

        local field = ISTextEntryBox:new("", 0, 0, 60, FONT_HGT_SMALL + 4)
        field:initialise()
        field._coordName = name
        field.onOtherKey = function(s, key)
            if key == Keyboard.KEY_RETURN or key == Keyboard.KEY_NUMPADENTER then
                self:commitCoordField()
            elseif key == Keyboard.KEY_TAB then
                -- Advance focus to the next coord field
                local cf2 = self.controls.coordFields
                if cf2 then
                    for i, c in ipairs(cf2) do
                        if c.field == s then
                            local next = cf2[(i % #cf2) + 1]
                            if next then
                                next.field:focus()
                            end
                            break
                        end
                    end
                end
                self:commitCoordField()
            end
        end
        self:addChild(field)
        return {
            lbl = lbl,
            field = field,
            name = name
        }
    end

    for _, name in ipairs(coordNames) do
        table.insert(coordFields, makeCoordField(name))
    end
    self.controls.coordFields = coordFields

    -- W and H are plain read-only labels
    local lblWH = ISLabel:new(0, 0, ROW_HGT, "W: –   H: –", 1, 1, 1, 0.6, UIFont.Small, true)
    lblWH:initialise();
    lblWH:instantiate()
    self:addChild(lblWH)
    self.controls.lblWH = lblWH
    local lblZones = ISLabel:new(0, 0, ROW_HGT, getText("IGUI_PhunZones_Zones"), 1, 1, 1, 1, UIFont.Small, true)
    lblZones:initialise();
    lblZones:instantiate()
    self:addChild(lblZones)
    self.controls.lblZones = lblZones

    local treeFilter = ISTextEntryBox:new("", 0, 0, 100, FONT_HGT_SMALL + 4)
    treeFilter:initialise();
    treeFilter:instantiate()
    treeFilter.onTextChange = function()
    end -- polled in prerender to avoid off-by-one
    self:addChild(treeFilter)
    self.controls.treeFilter = treeFilter

    local chkAll = ISTickBox:new(0, 0, BUTTON_HGT, BUTTON_HGT, getText("IGUI_PhunZones_AllZones"), self)
    chkAll:addOption(getText("IGUI_PhunZones_AllZones"), nil)
    chkAll:setSelected(1, false)
    chkAll:setWidthToFit()
    chkAll.tooltip = getText("IGUI_PhunZones_AllZones_tooltip")
    chkAll.onMouseUp = function(s, x, y)
        ISTickBox.onMouseUp(s, x, y)
        self._filterActive = not s:isSelected(1)
        self.data = Core.buildZoneData(self._filterActive)
        self:rebuildUI()
    end
    self:addChild(chkAll)
    self.controls.chkAll = chkAll

    -- -----------------------------------------------------------------------
    -- Tree panel (transparent mouse target; drawn in prerender)
    -- -----------------------------------------------------------------------
    local treePanel = ISPanel:new(0, 0, 100, 100)
    treePanel:initialise();
    treePanel:instantiate()
    treePanel.backgroundColor = {
        r = 0,
        g = 0,
        b = 0,
        a = 0
    }
    treePanel.drawBorder = false

    treePanel.onMouseUp = function(s, x, y)
        local i = math.floor((y + self.treeScroll) / ROW_HGT) + 1
        local upNode = self.treeNodes[i] and self.treeNodes[i].key
        if upNode and upNode == self._treeMouseDownNode then
            self:onTreeClick(s, x, y)
        end
        self._treeMouseDownNode = nil
    end
    treePanel.onMouseWheel = function(s, del)
        local totalH = #self.treeNodes * ROW_HGT
        self.treeScroll = math.max(0, math.min(self.treeScroll + del * ROW_HGT * 3, math.max(0, totalH - s.height)))
        return true
    end
    treePanel.onMouseDown = function(s, x, y)
        self:commitInlineEdit()
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
    -- Property panel header + filter
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
    -- Property panel (transparent mouse target; drawn in prerender)
    -- -----------------------------------------------------------------------
    local propPanel = ISPanel:new(0, 0, 100, 100)
    propPanel:initialise();
    propPanel:instantiate()
    propPanel.backgroundColor = {
        r = 0,
        g = 0,
        b = 0,
        a = 0
    }
    propPanel.drawBorder = false

    propPanel.onMouseUp = function(s, x, y)
        local i = math.floor((y + self.propScroll) / ROW_HGT) + 1
        if i == self._propMouseDownRow then
            self:onPropClick(s, x, y)
        end
        self._propMouseDownRow = nil
    end
    propPanel.onMouseWheel = function(s, del)
        local totalH = #self.propRows * ROW_HGT
        self.propScroll = math.max(0, math.min(self.propScroll + del * ROW_HGT * 3, math.max(0, totalH - s.height)))
        return true
    end
    propPanel.onMouseDown = function(s, x, y)
        self:commitInlineEdit()
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
    -- Inline property editor
    -- -----------------------------------------------------------------------
    local inlineEdit = ISTextEntryBox:new("", 0, 0, 100, FONT_HGT_SMALL + 4)
    inlineEdit:initialise()
    inlineEdit:setVisible(false)
    inlineEdit.onTextChange = function()
        -- onTextChange may fire before PZ applies the keystroke to getText(),
        -- so comparing getText() to _inlineOrigValue can miss single-char edits.
        -- Use a simple dirty flag: any text-change event marks the field modified.
        self._inlineDirty = true
        self:updateSaveDiscardButtons()
    end
    self:addChild(inlineEdit)
    self.controls.inlineEdit = inlineEdit

    -- -----------------------------------------------------------------------
    -- Inherits picker
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
    -- Generic field combo picker (for fdef.type == "combo" rows)
    -- -----------------------------------------------------------------------
    local fieldPicker
    fieldPicker = ISComboBox:new(0, 0, 100, FONT_HGT_SMALL + 4, self, function(owner)
        if fieldPicker._pendingField and fieldPicker._opts then
            local text = fieldPicker:getSelectedText()
            local idx = nil
            for i, opt in ipairs(fieldPicker._opts) do
                if tostring(opt) == text then
                    idx = i
                    break
                end
            end
            if idx then
                owner:saveProp(fieldPicker._pendingField, idx)
            end
        end
        fieldPicker._pendingField = nil
        fieldPicker._opts = nil
        fieldPicker:setVisible(false)
    end)
    fieldPicker:initialise()
    fieldPicker:setVisible(false)
    self:addChild(fieldPicker)
    self.controls.fieldPicker = fieldPicker

    -- -----------------------------------------------------------------------
    -- Buttons
    -- -----------------------------------------------------------------------
    local function mkBtn(label, tooltip, cb)
        local btn = ISButton:new(0, 0, 0, BUTTON_HGT, label, self, cb)
        btn:initialise()
        btn.tooltip = tooltip or ""
        btn:setWidth(getTextManager():MeasureStringX(UIFont.Small, label) + 20)
        self:addChild(btn)
        return btn
    end

    self.controls.btnNewRegion = mkBtn(getText("IGUI_PhunZones_AddZone"), getText("IGUI_PhunZones_AddZoneTooltip"),
        function()
            self:promptNewZone()
        end)

    self.controls.btnSave = mkBtn(getText("Save"), getText("IGUI_PhunZones_SavePending"), function()
        self:flushPendingChanges()
    end)
    self.controls.btnSave.enable = false

    self.controls.btnDeleteZone = mkBtn(getText("Delete"), getText("IGUI_PhunZones_DelZoneTooltip"), function()
        self:confirmDelete()
    end)
    self.controls.btnDeleteZone.enable = false
    if self.controls.btnDeleteZone.enableCancelColor then
        self.controls.btnDeleteZone:enableCancelColor()
    end

    self.controls.btnAddRect = mkBtn(getText("IGUI_PhunZones_AddRect"), getText("IGUI_PhunZones_AddRectTooltip"),
        function()
            if self.selectedData then
                self:dropRectAtViewportCentre()
            end
        end)
    self.controls.btnAddRect.enable = false
    self.controls.btnAddRect:enableAcceptColor()

    self.controls.btnDeleteRect = mkBtn(getText("IGUI_PhunZones_DelRect"), getText("IGUI_PhunZones_DelRectTooltip"),
        function()
            self:confirmDeleteRect()
        end)
    self.controls.btnDeleteRect.enable = false
    if self.controls.btnDeleteRect.enableCancelColor then
        self.controls.btnDeleteRect:enableCancelColor()
    end

    self.controls.btnFileEditor = mkBtn(getText("IGUI_PhunZones_File"), getText("IGUI_PhunZones_FileTooltip"),
        function()
            self:openImportModal()
        end)

    self.controls.btnClose = mkBtn(getText("Close"), "", function()
        self:close()
    end)

    self:doLayout()
end

-- ===========================================================================
-- Add Rect — drop a default-sized rect at the current map viewport centre
-- ===========================================================================
local DEFAULT_RECT_HALF = 25 -- half-size in world units → 50×50 total

function UI:dropRectAtViewportCentre()
    if not self.selectedData then
        return
    end

    local mapPanel = self.controls.mapui
    local map = mapPanel and mapPanel.map
    local api = map and map.mapAPI
    if not api then
        return
    end

    local wx, wy

    -- When the zone has no existing rects, anchor to the player's world
    -- position so the rect doesn't land in some remote corner of the map.
    local zone = zones(self)[self.selectedData.key]
    local hasPoints = zone and zone.points and #zone.points > 0
    if not hasPoints and self.player then
        wx = math.floor(self.player:getX())
        wy = math.floor(self.player:getY())
    else
        -- Use the current viewport centre (works well when the map is already
        -- centred on the zone's existing rects).
        local cx = math.floor(map.width / 2)
        local cy = math.floor(map.height / 2)
        wx = math.floor(api:uiToWorldX(cx, cy))
        wy = math.floor(api:uiToWorldY(cx, cy))
    end

    local x1 = wx - DEFAULT_RECT_HALF
    local y1 = wy - DEFAULT_RECT_HALF
    local x2 = wx + DEFAULT_RECT_HALF
    local y2 = wy + DEFAULT_RECT_HALF

    self:savePoint({
        region = self.selectedData.region,
        zone = self.selectedData.zone,
        x = x1,
        y = y1,
        x2 = x2,
        y2 = y2
    })
end

-- ===========================================================================
-- Queue a rect geometry change into pending (used by handle drag resize).
-- Updates local data optimistically; committed to server on Save.
-- ===========================================================================
function UI:queuePointChange(key, ptIdx, x1, y1, x2, y2)
    local zone = zones(self)[key]
    if not zone then
        return
    end

    -- Update local zone data so the overlay reflects the new position immediately
    if not zone.points then
        zone.points = {}
    end
    zone.points[ptIdx] = {x1, y1, x2, y2}

    -- Also update selectedPoint so Edit Rect popup gets the current coords
    if self.selectedData and self.selectedData.key == key then
        self.selectedPoint = {
            x = x1,
            y = y1,
            x2 = x2,
            y2 = y2
        }
        self:updateCoordBar({x1, y1, x2, y2})
    end

    -- Queue into _pendingChanges using a "points" sub-table per zone.
    -- flushPendingChanges will serialise this alongside any property changes.
    if not self._pendingChanges[key] then
        self._pendingChanges[key] = {}
    end
    if not self._pendingChanges[key]._points then
        -- Snapshot the full points array so we send the complete list on save
        self._pendingChanges[key]._points = {}
        for i, p in ipairs(zone.points) do
            self._pendingChanges[key]._points[i] = {p[1], p[2], p[3], p[4]}
        end
    else
        -- Update just this point in the already-pending snapshot
        self._pendingChanges[key]._points[ptIdx] = {x1, y1, x2, y2}
    end

    self:updateSaveDiscardButtons()
end

-- ===========================================================================
-- Draw mode — kept for potential future use (e.g. a "draw" toolbar option)
-- ===========================================================================
function UI:enterDrawMode()
    if not self.overlay then
        return
    end
    self.overlay:enterDrawMode()
end

function UI:exitDrawMode()
    if self.overlay then
        self.overlay:exitDrawMode()
    end
end

-- ===========================================================================
-- doLayout
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

    self._layout = {
        th = th,
        lw = lw,
        barY = barY,
        barH = barH,
        usableH = usableH
    }

    -- Map
    local mx = lw + PAD
    local mw = self.width - mx - PAD
    local m = self.controls.mapui
    m:setX(mx);
    m:setY(th + headerH)
    m:setWidth(mw);
    m:setHeight(contentH - headerH)
    if m.map then
        m.map:setWidth(mw)
        m.map:setHeight(contentH - headerH)
        -- If overlay didn't hook earlier (map.map wasn't ready), hook now
        if self.overlay and not self.overlay._hooked then
            self.overlay:hookNow()
            self.overlay._hooked = true
        end
    end

    -- Header
    self.controls.lblZones:setX(PAD);
    self.controls.lblZones:setY(th + 2)
    self.controls.chkAll:setX(lw - self.controls.chkAll.width - PAD)
    self.controls.chkAll:setY(th + 2)
    local chkX = lw - self.controls.chkAll.width - PAD
    local lblW = getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_PhunZones_Zones")) + PAD
    self.controls.treeFilter:setX(lblW)
    self.controls.treeFilter:setY(th + 2)
    self.controls.treeFilter:setWidth(chkX - lblW - PAD)

    -- Tree panel
    local tp = self.controls.treePanel
    tp:setX(PAD);
    tp:setY(th + headerH)
    tp:setWidth(lw - PAD * 2);
    tp:setHeight(math.max(20, treeH))

    -- Props header
    local propLblY = headerH + treeH + PAD
    self.controls.lblProps:setX(PAD);
    self.controls.lblProps:setY(th + propLblY)
    self.controls.propFilter:setX(PAD + 72);
    self.controls.propFilter:setY(th + propLblY - 1)
    self.controls.propFilter:setWidth(lw - PAD * 2 - 72)

    -- Property panel
    local pp = self.controls.propPanel
    pp:setX(PAD);
    pp:setY(th + propLblY + propLblH)
    pp:setWidth(lw - PAD * 2);
    pp:setHeight(math.max(20, propH))

    -- Coord bar — in the headerH strip above the map (right side only)
    -- Layout: [ Add Rect ]  X1:[__] Y1:[__] X2:[__] Y2:[__]  W:## H:##  [ Del Rect ]
    local cf = self.controls.coordFields
    if cf then
        local fieldH = FONT_HGT_SMALL + 4
        local btnH = BUTTON_HGT
        local cy = th + math.floor((headerH - fieldH) / 2)
        local btnCy = th + math.floor((headerH - btnH) / 2)
        local mx2 = lw + PAD
        local mw2 = self.width - mx2 - PAD
        local fieldW = 62
        local lblPad = 3
        local gap = PAD

        local cx2 = mx2

        -- Four labelled coord fields
        local items = {}
        for _, c in ipairs(cf) do
            local lw2 = getTextManager():MeasureStringX(UIFont.Small, c.name .. ":") + lblPad
            table.insert(items, {
                lbl = c.lbl,
                field = c.field,
                lblW = lw2
            })
        end

        -- W/H label width
        local whText = "W: 99999  H: 99999"
        local whW = getTextManager():MeasureStringX(UIFont.Small, whText) + gap

        -- Del Rect on the right
        local delBtn = self.controls.btnDeleteRect
        local delX = mx2 + mw2 - delBtn.width
        delBtn:setX(delX);
        delBtn:setY(btnCy)

        -- Add Rect on the left of the bar
        local addBtn = self.controls.btnAddRect
        addBtn:setX(delBtn.x - gap - addBtn.width);
        addBtn:setY(delBtn.y)

        -- Centre the fields + WH between addBtn right edge and delBtn left edge
        local available = delX - cx2 - gap
        local fieldsW = whW
        for _, it in ipairs(items) do
            fieldsW = fieldsW + it.lblW + fieldW + gap
        end
        local fx = cx2 + math.max(0, math.floor((available - fieldsW) / 2))

        for _, it in ipairs(items) do
            it.lbl:setX(fx);
            it.lbl:setY(cy + 1)
            fx = fx + it.lblW
            it.field:setX(fx);
            it.field:setY(cy)
            it.field:setWidth(fieldW);
            it.field:setHeight(fieldH)
            fx = fx + fieldW + gap
        end
        if self.controls.lblWH then
            self.controls.lblWH:setX(fx);
            self.controls.lblWH:setY(cy + 1)
        end
    end

    -- Buttons (bottom bar) — Edit Rect removed; Add/Del Rect moved to coord bar
    local leftBtns = {self.controls.btnNewRegion, self.controls.btnSave, self.controls.btnDeleteZone}
    local rightBtns = {self.controls.btnClose, self.controls.btnFileEditor}

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
-- prerender
-- ===========================================================================
function UI:prerender()
    ISCollapsableWindowJoypad.prerender(self)
    if self.width ~= self._lastW or self.height ~= self._lastH then
        self._lastW, self._lastH = self.width, self.height
        self:doLayout()
    end

    local L = self._layout
    if not L then
        return
    end
    local th = L.th

    -- Poll tree filter
    local tf = self.controls.treeFilter
    if tf then
        local current = tf:getText():lower()
        if current ~= (self._lastTreeFilter or "") then
            self._lastTreeFilter = current
            self.treeScroll = 0
            self:buildTree()
        end
    end

    -- Background fills
    self:drawRect(0, th, L.lw, L.usableH, 1, C.bg.r, C.bg.g, C.bg.b)
    self:drawRect(0, th + L.barY, self.width, L.barH, 1, C.bg.r, C.bg.g, C.bg.b)
    self:drawRect(L.lw, th, 1, L.barY, C.border.a, C.border.r, C.border.g, C.border.b)
    self:drawRect(0, th + L.barY, self.width, 1, C.border.a, C.border.r, C.border.g, C.border.b)

    -- Draw-mode banner above the map
    if self.overlay and self.overlay:isDrawMode() then
        local mx = L.lw + PAD
        local mw = self.width - mx - PAD
        local bannerH = FONT_HGT_SMALL + 6
        self:drawRect(mx, th, mw, bannerH, 0.85, 0.20, 0.55, 0.10)
        local msg = "DRAW MODE — drag to define rect, Esc to cancel"
        local tw = getTextManager():MeasureStringX(UIFont.Small, msg)
        self:drawText(msg, mx + (mw - tw) / 2, th + 3, 0.20, 0.90, 0.40, 1.0, UIFont.Small)
    end

    -- Tree
    local tp = self.controls.treePanel
    if tp then
        if tp:isMouseOver() then
            local i = math.floor((tp:getMouseY() + self.treeScroll) / ROW_HGT) + 1
            self.treeHover = (i >= 1 and i <= #self.treeNodes) and i or -1
        else
            self.treeHover = -1
        end
        local ox, oy = tp.x, tp.y
        self:drawRect(ox, oy, tp.width, tp.height, 1, C.panel.r, C.panel.g, C.panel.b)
        self:drawRectBorder(ox, oy, tp.width, tp.height, C.border.a, C.border.r, C.border.g, C.border.b)
        self:renderTree(ox, oy, tp.width, tp.height)
    end

    -- Props
    local pp = self.controls.propPanel
    self._tipText = nil
    self._tipMX = 0
    self._tipMY = 0
    if pp then
        if pp:isMouseOver() then
            local i = math.floor((pp:getMouseY() + self.propScroll) / ROW_HGT) + 1
            self.propHover = (i >= 1 and i <= #self.propRows) and i or -1
            local row = self.propRows[self.propHover]
            local tipKey = row and row.fdef and row.fdef.tooltip
            if tipKey then
                self._tipText = getText(tipKey)
                self._tipMX = pp.x + pp:getMouseX()
                self._tipMY = pp.y + pp:getMouseY()
            end
        else
            self.propHover = -1
        end
        local ox, oy = pp.x, pp.y
        self:drawRect(ox, oy, pp.width, pp.height, 1, C.panel.r, C.panel.g, C.panel.b)
        self:drawRectBorder(ox, oy, pp.width, pp.height, C.border.a, C.border.r, C.border.g, C.border.b)
        self:renderProps(ox, oy, pp.width, pp.height)
    end
end

function UI:render()
    ISCollapsableWindowJoypad.render(self)
    if self._tipText then
        local mx, my = self._tipMX, self._tipMY
        local tipW = getTextManager():MeasureStringX(UIFont.Small, self._tipText) + 16
        local tipH = FONT_HGT_SMALL + 8
        local tx = mx + 12
        local ty = my - tipH - 4
        if tx + tipW > self.width - 4 then
            tx = self.width - tipW - 4
        end
        if ty < 0 then
            ty = my + 16
        end
        self:drawRect(tx, ty, tipW, tipH, 0.95, 0.08, 0.08, 0.12)
        self:drawRectBorder(tx, ty, tipW, tipH, 1.0, C.border.r, C.border.g, C.border.b)
        self:drawText(self._tipText, tx + 8, ty + 2, C.text.r, C.text.g, C.text.b, 1.0, UIFont.Small)
    end
end

-- Keep Esc cancelling draw mode before closing
function UI:onKeyPressed(key)
    -- Cancel draw mode first
    if self.overlay and self.overlay:isDrawMode() and key == Keyboard.KEY_ESCAPE then
        self:exitDrawMode()
        return
    end

    local ie = self.controls.inlineEdit
    if ie and ie:isVisible() then
        if key == Keyboard.KEY_RETURN or key == Keyboard.KEY_NUMPADENTER then
            self:commitInlineEdit();
            return
        elseif key == Keyboard.KEY_ESCAPE then
            self:cancelInlineEdit();
            return
        end
    end
end

function UI:onKeyRelease(key)
    if key == Keyboard.KEY_ESCAPE then
        if self.overlay and self.overlay:isDrawMode() then
            self:exitDrawMode()
        else
            self:close()
        end
    end
end

-- ===========================================================================
-- TREE: build
-- ===========================================================================
function UI:buildTree()
    local zoneData = zones(self)
    local byKey = {}
    local children = {}

    for k, v in pairs(zoneData) do
        byKey[k] = v
        local parent = v.inherits
        if parent then
            if not children[parent] then
                children[parent] = {}
            end
            table.insert(children[parent], k)
        end
    end

    for _, list in pairs(children) do
        table.sort(list, function(a, b)
            local ta = (byKey[a] and byKey[a].title) or a
            local tb = (byKey[b] and byKey[b].title) or b
            return ta:lower() < tb:lower()
        end)
    end

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

    self.treeNodes = {}
    local collapsed = self._treeCollapsed or {}
    self._treeCollapsed = collapsed
    local filter = self.controls.treeFilter and self.controls.treeFilter:getText():lower() or ""
    self.treeFilter = filter

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
        local isDis = v.disabled == true

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
            disabled = isDis,
            zone = v
        })

        if hasKids and not collapsed[key] then
            for _, ck in ipairs(children[key]) do
                if filter == "" or hasMatch[ck] then
                    walk(ck, depth + 1)
                end
            end
        end
    end

    for _, rk in ipairs(roots) do
        walk(rk, 0)
    end

    -- Keep overlay zone data in sync with the active (possibly filtered) dataset
    if self.overlay then
        self.overlay:setZones(zoneData)
    end
end

-- ===========================================================================
-- TREE: render
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
                local isSel = self.selectedData and self.selectedData.key == node.key
                local isHov = self.treeHover == i

                if isSel then
                    self:drawRect(ox, ay, contentW, ROW_HGT, C.rowSel.a, C.rowSel.r, C.rowSel.g, C.rowSel.b)
                elseif isHov then
                    self:drawRect(ox, ay, contentW, ROW_HGT, C.rowHover.a, C.rowHover.r, C.rowHover.g, C.rowHover.b)
                elseif i % 2 == 0 then
                    self:drawRect(ox, ay, contentW, ROW_HGT, C.rowAlt.a, C.rowAlt.r, C.rowAlt.g, C.rowAlt.b)
                end

                if node.depth > 0 then
                    local cx = ox + node.depth * indent - indent + 6
                    self:drawRect(cx, ay, 1, ROW_HGT / 2, C.treeConn.a, C.treeConn.r, C.treeConn.g, C.treeConn.b)
                    self:drawRect(cx, ay + ROW_HGT / 2 - 1, indent - 6, 1, C.treeConn.a, C.treeConn.r, C.treeConn.g,
                        C.treeConn.b)
                end

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

    self:selectZone(node.key)
end

function UI:selectZone(key)
    self:cancelInlineEdit()
    self.propHover = -1
    self.propScroll = 0

    local zoneData = zones(self)
    local lookupData = lookup(self)
    local raw = zoneData[key] or {}
    local merged = lookupData[key] or {}

    self.selectedData = {
        key = key,
        region = raw.region or key,
        zone = raw.zone or "main",
        inherits = raw.inherits,
        raw = raw,
        merged = merged
    }

    local notDefault = key ~= "_default"

    self.controls.btnDeleteRect.enable = notDefault
    self.controls.btnAddRect.enable = notDefault

    self.selectedPoint = nil
    self.controls.btnDeleteRect.enable = false

    self:refreshProperties()
    self:refreshZonePoints(raw.points or {})

    -- Sync overlay
    if self.overlay then
        self.overlay:setSelectedZone(key)
        self.overlay:setZones(zoneData)
    end

    -- Scroll tree to show selection
    for i, node in ipairs(self.treeNodes) do
        if node.key == key then
            local tp = self.controls.treePanel
            local rowY = (i - 1) * ROW_HGT
            if rowY < self.treeScroll then
                self.treeScroll = rowY
            elseif rowY + ROW_HGT > self.treeScroll + tp.height then
                self.treeScroll = rowY + ROW_HGT - tp.height
            end
            break
        end
    end

    self:updateSaveDiscardButtons()
end

-- ===========================================================================
-- PROPERTIES
-- ===========================================================================
function UI:refreshProperties()
    self.propRows = {}
    if not self.selectedData then
        return
    end

    local key = self.selectedData.key
    local raw = self.selectedData.raw or {}
    local merged = self.selectedData.merged or {}

    local mergedIsEmpty = true
    for _ in pairs(merged) do
        mergedIsEmpty = false;
        break
    end
    if key == "_default" and mergedIsEmpty then
        local lookupData = lookup(self)
        merged = lookupData["_default"] or lookupData["default"] or raw
    end

    local filter = self.propFilter
    local pending = self._pendingChanges[key] or {}
    local seen = {}
    local groups = {}
    local groupFields = {}
    local UNGROUPED = "other"

    for k, fdef in pairs(Core.fields) do
        if k ~= "region" and k ~= "zone" and k ~= "key" and k ~= "_key" then
            if filter == "" or k:lower():find(filter, 1, true) or
                (fdef.label and getText(fdef.label):lower():find(filter, 1, true)) then
                local g = fdef.group or UNGROUPED
                if not groupFields[g] then
                    groupFields[g] = {};
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

    table.sort(groups, function(a, b)
        if a == UNGROUPED then
            return false
        end
        if b == UNGROUPED then
            return true
        end
        local ga = Core.groups[a];
        local gb = Core.groups[b]
        local oa = ga and ga.order or 999;
        local ob = gb and gb.order or 999
        if oa ~= ob then
            return oa < ob
        end
        return a < b
    end)

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
        table.sort(fields, function(a, b)
            local oa = a.fdef.order or 999;
            local ob = b.fdef.order or 999
            if oa ~= ob then
                return oa < ob
            end
            return getText(a.fdef.label or a.k) < getText(b.fdef.label or b.k)
        end)
        for _, f in ipairs(fields) do
            local k, fdef = f.k, f.fdef
            local val = pending[k] ~= nil and pending[k] or merged[k]
            -- merged may not include a raw override if the zone data wasn't yet
            -- re-processed (e.g. modsRequired set in base data but not in lookup)
            if val == nil and raw[k] ~= nil then
                val = raw[k]
            end
            local isOver = raw[k] ~= nil or pending[k] ~= nil
            local displayVal = nil
            if fdef.type == "combo" then
                local opts = fdef.options or (fdef.getOptions and fdef.getOptions()) or {}
                local idx = tonumber(val)
                displayVal = idx and tostring(opts[idx]) or nil
            end
            table.insert(self.propRows, {
                key = k,
                label = getText(fdef.label or k),
                value = val,
                displayVal = displayVal,
                override = isOver,
                origin = fdef.mod or nil,
                fdef = fdef
            })
        end
    end

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
            -- If the schema "other" group was already emitted, label these
            -- unrecognised fields differently to avoid two headers with the same name
            local extraLabel
            if groupFields["other"] then
                extraLabel = "Unknown"
            else
                local otherDef = Core.groups and Core.groups["other"]
                extraLabel = otherDef and otherDef.label or "Other"
            end
            table.insert(self.propRows, {
                isGroupHeader = true,
                label = extraLabel
            })
        end
        table.sort(extraRows, function(a, b)
            return a.key < b.key
        end)
        for _, r in ipairs(extraRows) do
            table.insert(self.propRows, r)
        end
    end

    table.insert(self.propRows, 1, {
        key = "disabled",
        label = "Disabled",
        value = raw.disabled == true,
        override = raw.disabled ~= nil,
        special = true,
        danger = raw.disabled == true
    })
    table.insert(self.propRows, 1, {
        key = "inherits",
        label = "Inherits from",
        value = raw.inherits or "(none)",
        override = true,
        special = true
    })
end

-- ===========================================================================
-- PROPERTIES: render
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

                    local isButton = row.fdef and row.fdef.type == "button"
                    local isCombo = row.fdef and row.fdef.type == "combo"

                    if isButton then
                        -- Label spans the full row; right side shows a clickable hint
                        self:drawText(row.label, ox + 6, ay + 2, C.accent.r, C.accent.g, C.accent.b, la, UIFont.Small)
                        local hint = "[ click ]"
                        local hw = getTextManager():MeasureStringX(UIFont.Small, hint)
                        self:drawText(hint, ox + contentW - hw - 6, ay + 2, C.accentDim.r, C.accentDim.g, C.accentDim.b,
                            0.8, UIFont.Small)
                    else
                        self:drawText(row.label, ox + 6, ay + 2, lr, lg, lb, la, UIFont.Small)

                        local valStr
                        if isCombo then
                            valStr = row.displayVal or tostring(row.value ~= nil and row.value or "--")
                        else
                            valStr = tostring(row.value ~= nil and row.value or "--")
                        end
                        local vr, vg, vb, va
                        if row.override then
                            vr, vg, vb, va = C.accent.r, C.accent.g, C.accent.b, 1.0
                        else
                            vr, vg, vb, va = C.textDim.r, C.textDim.g, C.textDim.b, 0.9
                        end
                        if row.danger and row.value == true then
                            vr, vg, vb = C.danger.r, C.danger.g, C.danger.b
                        end

                        -- Clip value text to available column width
                        local valColW = contentW - valX - 6
                        local tm = getTextManager()
                        if tm:MeasureStringX(UIFont.Small, valStr) > valColW then
                            while #valStr > 0 and tm:MeasureStringX(UIFont.Small, valStr .. "...") > valColW do
                                valStr = valStr:sub(1, -2)
                            end
                            valStr = valStr .. "..."
                        end

                        self:drawText(valStr, ox + valX + 4, ay + 2, vr, vg, vb, va, UIFont.Small)
                    end
                    self:drawRect(ox, ay + ROW_HGT - 1, contentW, 1, C.border.a * 0.4, C.border.r, C.border.g,
                        C.border.b)
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
-- PROPERTY: click handler
-- ===========================================================================
function UI:onPropClick(panel, x, y)
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

    self:cancelInlineEdit()

    local sd = self.selectedData
    if not sd then
        return
    end

    if row.key == "disabled" then
        self:saveProp("disabled", not (sd.raw.disabled == true));
        return
    end
    if row.key == "inherits" then
        self:showInheritsPicker(row, i);
        return
    end
    if row.special or row.extra or not row.fdef then
        return
    end

    local fdef = row.fdef
    if fdef.type == "boolean" then
        local cur = sd.raw[row.key]
        if cur == nil then
            cur = sd.merged[row.key]
        end
        self:saveProp(row.key, not cur);
        return
    end

    if fdef.type == "combo" then
        local opts = fdef.options or (fdef.getOptions and fdef.getOptions()) or {}
        self:showFieldPicker(row, i, opts)
        return
    end

    if fdef.type == "button" then
        if fdef.onClick then
            fdef.onClick(self, row.key, row.value)
        end
        return
    end

    -- Inline text editor
    local pp = self.controls.propPanel
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
    local initText = curVal ~= nil and tostring(curVal) or ""
    ie:setText(initText)
    self._inlineOrigValue = initText
    self._inlineDirty = false
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
    local hasScroll = (#self.propRows * ROW_HGT) > pp.height
    local contentW = hasScroll and (pp.width - SCROLLBAR_W - 2) or pp.width
    local valX = math.floor(contentW * 0.52)
    local rowScreenY = pp.y + (rowIndex - 1) * ROW_HGT - self.propScroll

    local picker = self.controls.inheritsPicker
    picker:setX(pp.x + valX)
    picker:setY(rowScreenY)
    picker:setWidth(contentW - valX - 4)

    local selfKey = sd.key
    local descendants = {}
    local function collectDesc(k)
        for _, node in ipairs(self.treeNodes) do
            if node.zone and node.zone.inherits == k and node.key ~= selfKey then
                descendants[node.key] = true;
                collectDesc(node.key)
            end
        end
    end
    collectDesc(selfKey)

    picker:clear()
    local current = sd.raw.inherits or "_default"
    local selectedIdx = 1
    local idx = 1
    picker:addOption("_default")
    if current == "_default" then
        selectedIdx = idx
    end
    idx = idx + 1

    local options = {}
    for k, v in pairs(zones(self)) do
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

function UI:showFieldPicker(row, rowIndex, opts)
    local pp = self.controls.propPanel
    local hasScroll = (#self.propRows * ROW_HGT) > pp.height
    local contentW = hasScroll and (pp.width - SCROLLBAR_W - 2) or pp.width
    local valX = math.floor(contentW * 0.52)
    local rowScreenY = pp.y + (rowIndex - 1) * ROW_HGT - self.propScroll

    local picker = self.controls.fieldPicker
    picker:setX(pp.x + valX)
    picker:setY(rowScreenY)
    picker:setWidth(contentW - valX - 4)
    picker:clear()
    picker._opts = opts
    picker._pendingField = row.key

    local currentIdx = tonumber(row.value) or 1
    for _, opt in ipairs(opts) do
        picker:addOption(tostring(opt))
    end
    picker:select(math.max(1, math.min(currentIdx, math.max(1, #opts))))
    picker:setVisible(true)
end

function UI:commitInlineEdit()
    local ie = self.controls.inlineEdit
    if not ie:isVisible() then
        return
    end
    ie:setVisible(false)
    self._inlineOrigValue = nil
    self._inlineDirty = false

    local row = self._editingRow
    self._editingRow = nil
    if not row or not row.fdef then
        return
    end

    local raw = ie:getText()
    local fdef = row.fdef
    local val

    if fdef.type == "int" then
        val = tonumber(raw);
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
    self._inlineOrigValue = nil
    self._inlineDirty = false
    local ie = self.controls.inlineEdit
    if ie and ie:isVisible() then
        ie:setVisible(false)
    end
    local ip = self.controls.inheritsPicker
    if ip and ip:isVisible() then
        ip:setVisible(false)
    end
    local fp = self.controls.fieldPicker
    if fp and fp:isVisible() then
        fp:setVisible(false)
        fp._pendingField = nil
        fp._opts = nil
    end
    self._editingRow = nil
end

-- ===========================================================================
-- PROP SAVE / PENDING CHANGES
-- ===========================================================================
function UI:saveProp(fieldKey, newValue)
    local sd = self.selectedData
    if not sd or not sd.key then
        return
    end

    local fdef = Core.fields[fieldKey]
    local val = newValue
    if fdef then
        if fdef.type == "int" then
            val = tonumber(newValue);
            if val == nil then
                return
            end
        elseif fdef.type == "boolean" then
            val = (newValue == true or newValue == "true" or newValue == 1)
        elseif fdef.type == "combo" then
            val = tonumber(newValue) or nil
        end
        if fdef.normalize then
            val = fdef.normalize(val)
        end
    end

    local key = sd.key
    if not self._pendingChanges[key] then
        self._pendingChanges[key] = {}
    end
    self._pendingChanges[key][fieldKey] = val

    -- Optimistically update self.data so the UI reflects the change immediately,
    -- without touching Core.data global state.
    local zoneData = zones(self)
    if zoneData[key] then
        zoneData[key][fieldKey] = val
    end
    local lookupData = lookup(self)
    if lookupData[key] then
        lookupData[key][fieldKey] = val
    end
    sd.raw[fieldKey] = val
    sd.merged[fieldKey] = val

    if fieldKey == "title" then
        self:buildTree()
    end
    if fieldKey == "inherits" then
        self:buildTree()
    end

    self:updateSaveDiscardButtons()
    self:refreshProperties()
end

function UI:hasPendingChanges()
    for _ in pairs(self._pendingChanges) do
        return true
    end
    return false
end

function UI:flushPendingChanges()
    self:commitInlineEdit()
    if not self:hasPendingChanges() then
        return
    end

    local changes = {}
    for zoneKey, fields in pairs(self._pendingChanges) do
        local zoneData = zones(self)
        local raw = zoneData[zoneKey] or {}
        local inherited = {}
        if zoneKey ~= "_default" then
            local parentKey = raw.inherits
            local lookupData = lookup(self)
            inherited = lookupData[parentKey or "_default"] or {}
        end

        local zoneChanges = {}

        -- Pending property changes
        for fieldKey, val in pairs(fields) do
            if fieldKey ~= "_points" then
                if inherited[fieldKey] ~= val then
                    zoneChanges[fieldKey] = val
                end
            end
        end

        -- Pending geometry — write via ModData (same path as the old savePoint)
        if fields._points then
            local md = ModData.getOrCreate(Core.const.modifiedModData)
            if not md[zoneKey] then
                md[zoneKey] = {}
            end
            md[zoneKey].points = fields._points
            -- Include points in the change payload so Core.saveChanges persists them
            zoneChanges.points = fields._points
        end

        local hasData = false
        for _ in pairs(zoneChanges) do
            hasData = true;
            break
        end
        if hasData then
            changes[zoneKey] = zoneChanges
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
        Core.saveChanges(changes)
        local currentKey = self.selectedData and self.selectedData.key
        self:rebuildUI(currentKey and {
            key = currentKey
        } or nil)
    end
end

function UI:updateSaveDiscardButtons()
    local ie = self.controls.inlineEdit
    local inlineDirty = ie and ie:isVisible() and self._inlineDirty
    self.controls.btnSave.enable = self:hasPendingChanges() or inlineDirty
end

-- ===========================================================================
-- COORD BAR
-- ===========================================================================

-- Update the X1/Y1/X2/Y2 fields and W/H label from the given point table {x1,y1,x2,y2}
-- or clear them if pt is nil.
function UI:updateCoordBar(pt)
    local cf = self.controls.coordFields
    if not cf then
        return
    end

    if pt then
        local vals = {pt[1], pt[2], pt[3], pt[4]}
        for i, c in ipairs(cf) do
            c.field:setText(tostring(math.floor(vals[i])))
        end
        local w = math.abs(math.floor(pt[3]) - math.floor(pt[1]))
        local h = math.abs(math.floor(pt[4]) - math.floor(pt[2]))
        if self.controls.lblWH then
            self.controls.lblWH.name = "W: " .. w .. "  H: " .. h
        end
    else
        for _, c in ipairs(cf) do
            c.field:setText("")
        end
        if self.controls.lblWH then
            self.controls.lblWH.name = "W: –   H: –"
        end
    end
end

-- Called when user presses Enter/Tab in a coord field.
-- Reads all four fields, validates, and queues a point change.
function UI:commitCoordField()
    local cf = self.controls.coordFields
    if not cf or not self.selectedData or not self.selectedPtIdx then
        return
    end

    local vals = {}
    for _, c in ipairs(cf) do
        local n = tonumber(c.field:getText())
        if not n then
            return
        end -- invalid input — silently ignore
        table.insert(vals, math.floor(n))
    end

    local x1, y1, x2, y2 = vals[1], vals[2], vals[3], vals[4]
    -- Normalise so x1<x2, y1<y2
    if x1 > x2 then
        x1, x2 = x2, x1
    end
    if y1 > y2 then
        y1, y2 = y2, y1
    end

    local key = self.selectedData.key
    local ptIdx = self.selectedPtIdx

    local zone = zones(self)[key]
    if not zone or not zone.points or not zone.points[ptIdx] then
        return
    end

    self:queuePointChange(key, ptIdx, x1, y1, x2, y2)

    -- Refresh the coord bar with normalised values
    self:updateCoordBar({x1, y1, x2, y2})
end

-- ===========================================================================
-- DATA
-- ===========================================================================
function UI:refreshData(zone)
    -- Always re-build self.data from scratch, respecting the current filter state.
    -- This keeps Core.data untouched.
    self.data = Core.buildZoneData(self._filterActive or false)
    self:rebuildUI(zone)
end

function UI:rebuildUI(zone)
    self:buildTree()

    if zone then
        local targetKey = zone.key or zone.region
        local zoneData = zones(self)
        if targetKey and targetKey ~= "_default" and targetKey ~= "void" and zoneData[targetKey] then
            self:selectZone(targetKey)
            return
        end
    end

    self.selectedData = nil
    self:refreshProperties()
end

function UI:refreshZonePoints(points, selectedIdx)
    self.selectedPoint = nil
    self.controls.btnDeleteRect.enable = false
    self:updateCoordBar(nil)

    self.controls.mapui:setData(points, nil)

    if points and #points > 0 then
        local idx = selectedIdx or 1
        idx = math.max(1, math.min(idx, #points))
        self.selectedPoint = {
            x = points[idx][1],
            y = points[idx][2],
            x2 = points[idx][3],
            y2 = points[idx][4]
        }
        self.controls.btnDeleteRect.enable = true
        self.controls.mapui:setData(points, self.selectedPoint)
        self.controls.mapui.selectedPointIndex = idx
        self.selectedPtIdx = idx

        self:updateCoordBar(points[idx])

        if self.overlay then
            self.overlay:setSelectedPoint(idx)
        end
    end
end

function UI:saveData(data)
    local inherited = {}
    local lookupData = lookup(self)
    if data.key and data.key ~= "_default" then
        local parentKey = data.inherits
        if parentKey then
            inherited = lookupData[parentKey] or {}
        else
            inherited = lookupData["_default"] or {}
        end
    end

    local zoneChanges = {}
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
        if k ~= "key" and inherited[k] ~= final then
            zoneChanges[k] = final
        end
    end

    local key = data.key or data.region
    if not key then
        return
    end

    Core.saveChanges({
        [key] = zoneChanges
    })
    self:rebuildUI({
        key = key
    })
end

function UI:savePoint(xy, pointIndex)
    -- Route through queuePointChange so all geometry goes via pending,
    -- not directly to the server. The caller (dropRectAtViewportCentre,
    -- Edit Rect popup, etc.) doesn't need to know the difference.
    local key = xy.region
    local zone = zones(self)[key]
    if not zone then
        return
    end

    -- Build the updated points list locally
    if not zone.points then
        zone.points = {}
    end
    local ptIdx
    if pointIndex then
        zone.points[pointIndex] = {xy.x, xy.y, xy.x2, xy.y2}
        ptIdx = pointIndex
    else
        table.insert(zone.points, {xy.x, xy.y, xy.x2, xy.y2})
        ptIdx = #zone.points
    end

    self:queuePointChange(key, ptIdx, xy.x, xy.y, xy.x2, xy.y2)

    -- Re-select zone and point so handles appear immediately
    self:selectZone(key)
    self:refreshZonePoints(zone.points, ptIdx)
end

function UI:openImportModal()
    Core.ui.configEditor:open(false)
end

-- ===========================================================================
-- NEW ZONE
-- ===========================================================================
function UI:promptNewZone()
    local sw = getCore():getScreenWidth()
    local sh = getCore():getScreenHeight()
    local w, h = 300, 120
    local entry
    local modal = ISModalDialog:new(sw / 2 - w / 2, sh / 2 - h / 2, w, h, "Enter zone name:", true, self,
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

    local zoneData = zones(self)
    if zoneData[key] then
        local i = 2
        local candidate = key .. tostring(i)
        while zoneData[candidate] do
            i = i + 1;
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
-- DELETE
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

    local key = self.selectedData.key
    local zone = zones(self)[key]
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

    -- Update local data immediately so the overlay stops rendering the rect
    zone.points = pts

    -- Queue the deletion as pending (committed on Save)
    if not self._pendingChanges[key] then
        self._pendingChanges[key] = {}
    end
    self._pendingChanges[key]._points = {}
    for _, p in ipairs(pts) do
        table.insert(self._pendingChanges[key]._points, {p[1], p[2], p[3], p[4]})
    end
    self:updateSaveDiscardButtons()

    -- Sync overlay zones and clear point selection
    if self.overlay then
        self.overlay:setZones(zones(self))
        self.overlay:setSelectedPoint(nil)
    end

    -- Refresh point list UI, selecting adjacent point if one exists
    local newIdx = math.min(idx, #pts)
    self:refreshZonePoints(pts, #pts > 0 and newIdx or nil)
end

-- ===========================================================================
-- Window lifecycle
-- ===========================================================================
function UI:close()
    if self._closing then
        return
    end
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
    self._tipText = nil
    self:setVisible(false)
    ISCollapsableWindowJoypad.close(self)
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
