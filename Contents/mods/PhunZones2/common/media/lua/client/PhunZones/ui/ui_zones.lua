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
local function sc(n)
    return math.floor(n * FONT_SCALE)
end
-- Combo option helpers: entries may be plain strings or {label, value} tables.
local function optLabel(opt)
    return type(opt) == "table" and tostring(opt.label) or tostring(opt)
end
local function optValue(opt)
    return type(opt) == "table" and opt.value or opt
end
local BUTTON_HGT = FONT_HGT_SMALL + sc(6)
local ROW_HGT = FONT_HGT_SMALL + sc(8)
local PAD = sc(8)
local LEFT_W = sc(260)
local SCROLLBAR_W = sc(5)
local BOTTOM_BAR_H = BUTTON_HGT + PAD * 2
local TREE_RATIO = 0.42

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

-- Pending value meaning "remove this field from the layer being edited".
local CLEAR = Core.const.clearField

local function copyPoints(points)
    local out = {}
    for i, p in ipairs(points or {}) do
        out[i] = {p[1], p[2], p[3], p[4]}
    end
    return out
end

local function clampScroll(scroll, contentH, viewH)
    return math.max(0, math.min(scroll, math.max(0, contentH - viewH)))
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

    -- Start on the zone the player is standing in, unless that is just the
    -- catch-all: opening on _default or void is never what anyone wants.
    local here = Core.getLocation(playerObj:getX(), playerObj:getY())
    local hereKey = here and (here.key or here.region)
    if hereKey == "_default" or hereKey == "void" then
        here = nil
    end
    instance:refreshData(here)

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
    -- Which layer property edits go to. nil = the base customisation layer,
    -- shown as "default". Independent of which profile is live for players.
    o.editProfile = nil
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

        local field = ISTextEntryBox:new("", 0, 0, 60, FONT_HGT_SMALL + sc(4))
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

    local treeFilter = ISTextEntryBox:new("", 0, 0, 100, FONT_HGT_SMALL + sc(4))
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
        self.data = Core.buildZoneData(self._filterActive, self.editProfile or false)
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

    local filterBox = ISTextEntryBox:new("", 0, 0, 100, FONT_HGT_SMALL + sc(2))
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
    propPanel.onRightMouseUp = function(s, x, y)
        self:onPropRightClick(s, x, y)
        return true
    end

    self:addChild(propPanel)
    self.controls.propPanel = propPanel

    -- -----------------------------------------------------------------------
    -- Inline property editor. It and the two pickers below float over the
    -- property panel; anchorPropEditors keeps them on their row every frame.
    -- -----------------------------------------------------------------------
    local inlineEdit = ISTextEntryBox:new("", 0, 0, 100, FONT_HGT_SMALL + sc(4))
    inlineEdit:initialise()
    inlineEdit:setVisible(false)
    inlineEdit.onTextChange = function()
        -- onTextChange may fire before PZ applies the keystroke to getText(),
        -- so comparing getText() to _inlineOrigValue can miss single-char edits.
        -- Use a simple dirty flag: any text-change event marks the field modified.
        self._inlineDirty = true
        self:updateSaveDiscardButtons()
    end
    inlineEdit.onCommandEntered = function()
        self:commitInlineEdit()
    end
    inlineEdit.onOtherKey = function(s, key)
        if key == Keyboard.KEY_ESCAPE then
            self:cancelInlineEdit()
            self:swallowEscRelease()
        elseif key == Keyboard.KEY_TAB then
            self:editAdjacentProp(isShiftKeyDown() and -1 or 1)
        elseif key == Keyboard.KEY_RETURN or key == Keyboard.KEY_NUMPADENTER then
            self:commitInlineEdit()
        end
    end
    -- Clicking anywhere else (the map, a button) keeps what was typed, the
    -- same as clicking another row does.
    inlineEdit.onLostFocus = function()
        self:commitInlineEdit()
    end
    self:addChild(inlineEdit)
    self.controls.inlineEdit = inlineEdit

    -- -----------------------------------------------------------------------
    -- Inherits picker
    -- -----------------------------------------------------------------------
    local inheritsPicker
    inheritsPicker = ISComboBox:new(0, 0, 100, FONT_HGT_SMALL + sc(4), self, function(owner)
        local selected = inheritsPicker:getSelectedText()
        local current = owner.selectedData and owner.selectedData.raw.inherits or "_default"
        if selected and selected ~= "" and selected ~= current then
            owner:saveProp("inherits", selected)
        end
        owner:closePropPickers()
    end)
    inheritsPicker:initialise()
    inheritsPicker:setVisible(false)
    self:addChild(inheritsPicker)
    self.controls.inheritsPicker = inheritsPicker

    -- -----------------------------------------------------------------------
    -- Generic field combo picker (for fdef.type == "combo" rows)
    -- -----------------------------------------------------------------------
    local fieldPicker
    fieldPicker = ISComboBox:new(0, 0, 100, FONT_HGT_SMALL + sc(4), self, function(owner)
        local field, opts = fieldPicker._rowKey, fieldPicker._opts
        if field and opts then
            local chosen = opts[fieldPicker.selected] and optValue(opts[fieldPicker.selected])
            local row = owner.propRows[owner:findPropRow(field) or 0]
            -- Picking what the row already owns changes nothing; picking the
            -- value it merely inherits pins it as an explicit override.
            local noop = row and row.override and row.value == chosen
            if chosen ~= nil and not noop then
                owner:saveProp(field, chosen)
            end
        end
        owner:closePropPickers()
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
        btn:setWidth(getTextManager():MeasureStringX(UIFont.Small, label) + sc(20))
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

    self.controls.btnDiscard = mkBtn(getText("IGUI_PhunZones_Discard"), getText("IGUI_PhunZones_DiscardTooltip"),
        function()
            self:confirmDiscardAll()
        end)
    self.controls.btnDiscard.enable = false

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

    -- -----------------------------------------------------------------------
    -- Profile bar
    --
    -- Two separate pieces of state, deliberately shown side by side: which
    -- layer property edits are written to (the combo), and which profile is
    -- live for players right now (the label). Selecting a profile here only
    -- changes what you are editing — Activate is what makes it live.
    -- -----------------------------------------------------------------------
    local lblProfile = ISLabel:new(0, 0, BUTTON_HGT, getText("IGUI_PhunZones_Profile_Editing"), 1, 1, 1, 1,
        UIFont.Small, true)
    lblProfile:initialise();
    lblProfile:instantiate()
    self:addChild(lblProfile)
    self.controls.lblProfile = lblProfile

    local cmbProfile
    cmbProfile = ISComboBox:new(0, 0, sc(140), BUTTON_HGT, self, function(owner)
        owner:onProfileComboChanged(cmbProfile:getOptionData(cmbProfile:getSelected()))
    end)
    cmbProfile:initialise()
    cmbProfile.tooltip = getText("IGUI_PhunZones_Profile_Editing_tooltip")
    self:addChild(cmbProfile)
    self.controls.cmbProfile = cmbProfile

    self.controls.btnActivate = mkBtn(getText("IGUI_PhunZones_Profile_Activate"),
        getText("IGUI_PhunZones_Profile_Activate_tooltip"), function()
            self:activateSelectedProfile()
        end)

    self.controls.btnNewProfile = mkBtn(getText("IGUI_PhunZones_Profile_New"),
        getText("IGUI_PhunZones_Profile_New_tooltip"), function()
            self:promptNewProfile()
        end)

    self.controls.btnDelProfile = mkBtn(getText("IGUI_PhunZones_Profile_Delete"),
        getText("IGUI_PhunZones_Profile_Delete_tooltip"), function()
            self:confirmDeleteProfile()
        end)
    if self.controls.btnDelProfile.enableCancelColor then
        self.controls.btnDelProfile:enableCancelColor()
    end

    local lblLive = ISLabel:new(0, 0, BUTTON_HGT, "", 1, 1, 1, 1, UIFont.Small, true)
    lblLive:initialise();
    lblLive:instantiate()
    self:addChild(lblLive)
    self.controls.lblLive = lblLive

    self:refreshProfileBar()

    self:doLayout()
end

-- ===========================================================================
-- PROFILES
--
-- self.editProfile is the layer edits are written to: nil means the base
-- customisation layer, shown in the combo as "default". It is independent of
-- Core.getActiveProfile(), which is what players are actually experiencing.
-- ===========================================================================
local DEFAULT_LAYER = "default"

function UI:editingProfileLabel()
    return self.editProfile or DEFAULT_LAYER
end

-- One-button dialog. _tipText is cleared every render frame (it is the property
-- hover tooltip), so it cannot carry an error the user needs to read.
function UI:notify(msg)
    local w = math.max(sc(300), getTextManager():MeasureStringX(UIFont.Small, msg) + sc(40))
    local h = sc(160)
    local modal = ISModalDialog:new(getCore():getScreenWidth() / 2 - w / 2, getCore():getScreenHeight() / 2 - h / 2, w,
        h, msg, false, self, nil)
    modal:initialise()
    modal:addToUIManager()
end

function UI:refreshProfileBar()
    local cmb = self.controls.cmbProfile
    if not cmb then
        return
    end

    -- clear() also replaces .tooltip with an empty per-option map, which would
    -- drop the combo's own tooltip string, so put that back afterwards.
    cmb:clear()
    cmb.tooltip = getText("IGUI_PhunZones_Profile_Editing_tooltip")
    cmb.selected = 1
    cmb:addOptionWithData(DEFAULT_LAYER, false)

    local selectedIdx = 1
    for i, name in ipairs(Core.getProfileNames()) do
        cmb:addOptionWithData(name, name)
        if name == self.editProfile then
            selectedIdx = i + 1
        end
    end

    -- The profile being edited may have been deleted by another admin.
    if self.editProfile and selectedIdx == 1 then
        self.editProfile = nil
    end
    cmb.selected = selectedIdx

    local active = Core.getActiveProfile()
    self.controls.lblLive.name = getText("IGUI_PhunZones_Profile_Live") .. " " .. (active or DEFAULT_LAYER)

    -- Activate is pointless when what you are editing is already live.
    local wouldActivate = self.editProfile or ""
    self.controls.btnActivate.enable = ((active or "") ~= wouldActivate)
    self.controls.btnDelProfile.enable = (self.editProfile ~= nil)

    -- Adding and deleting zones are structural edits to the base config; a
    -- profile can only override fields on zones that already exist. Rather
    -- than silently writing them to the wrong layer, they are disabled here.
    local base = (self.editProfile == nil)
    self.controls.btnNewRegion.enable = base
    self.controls.btnNewRegion.tooltip = base and getText("IGUI_PhunZones_AddZoneTooltip") or
                                             getText("IGUI_PhunZones_Profile_BaseOnly")
    if self.controls.btnDeleteZone.enable and not base then
        self.controls.btnDeleteZone.enable = false
    end
    self.controls.btnDeleteZone.tooltip = base and getText("IGUI_PhunZones_DelZoneTooltip") or
                                              getText("IGUI_PhunZones_Profile_BaseOnly")

    -- The live label's width feeds the bar's centring, so re-lay it out.
    self:doLayout()
end

-- Combo callback. Switching layers mid-edit would write pending changes into
-- whichever layer happened to be selected at save time, so the switch is gated
-- on those being resolved first.
function UI:onProfileComboChanged(data)
    local target = (type(data) == "string") and data or nil
    if target == self.editProfile then
        return
    end

    if self:hasPendingChanges() then
        self._pendingProfileSwitch = target
        local modal = ISModalDialog:new(0, 0, sc(320), sc(150), getText("IGUI_PhunZones_Profile_SwitchUnsaved"), true,
            self, UI.onProfileSwitchModalResult)
        modal:initialise()
        modal:addToUIManager()
        -- Put the combo back until the answer comes in, so what it shows and
        -- what is being edited never disagree.
        self:refreshProfileBar()
        return
    end

    self:setEditProfile(target)
end

function UI:onProfileSwitchModalResult(button)
    local target = self._pendingProfileSwitch
    self._pendingProfileSwitch = nil
    if button.internal == "YES" then
        -- Flush against the layer they were made on, before switching.
        self:flushPendingChanges()
    else
        self._pendingChanges = {}
        self:updateSaveDiscardButtons()
    end
    self:setEditProfile(target)
end

function UI:setEditProfile(name)
    self.editProfile = name
    self._pendingChanges = {}
    self:updateSaveDiscardButtons()
    local currentKey = self.selectedData and self.selectedData.key
    self:refreshData(currentKey and {
        key = currentKey
    } or nil)
end

function UI:activateSelectedProfile()
    local target = self.editProfile or DEFAULT_LAYER
    local ok, err = Core.requestSetProfile(target)
    if not ok then
        self:notify(tostring(err))
        return
    end
    -- On a client the change comes back via ModData; locally it has already
    -- applied. Either way the bar is repainted from Core on the next refresh.
    self:refreshProfileBar()
end

function UI:promptNewProfile()
    local sw = getCore():getScreenWidth()
    local sh = getCore():getScreenHeight()
    local w, h = sc(320), sc(120)
    local entry
    local modal = ISModalDialog:new(sw / 2 - w / 2, sh / 2 - h / 2, w, h, getText("IGUI_PhunZones_Profile_NewPrompt"),
        true, self, function(owner, button)
            if button.internal ~= "YES" then
                return
            end
            local name = entry and entry:getText() or ""
            name = name:match("^%s*(.-)%s*$")
            if name == "" then
                return
            end
            local ok, err = Core.requestCreateProfile(name)
            if not ok then
                owner:notify(tostring(err))
                return
            end
            -- Optimistic: switch to editing the new profile straight away. If
            -- the server refuses, the next transmit drops it from the combo
            -- and refreshProfileBar falls back to the base layer.
            owner:setEditProfile(name)
        end)
    modal:initialise()
    entry = ISTextEntryBox:new("", sc(10), sc(60), w - sc(20), FONT_HGT_SMALL + sc(6))
    entry:initialise()
    entry:instantiate()
    modal:addChild(entry)
    modal:addToUIManager()
    entry:focus()
end

function UI:confirmDeleteProfile()
    local name = self.editProfile
    if not name then
        return
    end

    local msg = string.format(getText("IGUI_PhunZones_Profile_DeleteConfirm"), name)
    if Core.getActiveProfile() == name then
        -- ISModalDialog splits on a literal backslash-n, not a real newline:
        -- CalcSize measures the pieces before the constructor converts them.
        msg = msg .. "\\n" .. getText("IGUI_PhunZones_Profile_DeleteActive")
    end

    local w = math.max(sc(320), getTextManager():MeasureStringX(UIFont.Small, msg) + sc(40))
    local h = sc(200)
    local modal = ISModalDialog:new(getCore():getScreenWidth() / 2 - w / 2, getCore():getScreenHeight() / 2 - h / 2, w,
        h, msg, true, self, function(owner, button)
            if button.internal ~= "YES" then
                return
            end
            Core.requestDeleteProfile(name)
            owner:setEditProfile(nil)
        end, nil)
    modal:initialise()
    modal:addToUIManager()
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
    local headerH = ROW_HGT + sc(4)
    local treeH = math.floor((contentH - headerH) * TREE_RATIO)
    local propLblH = ROW_HGT + sc(4)
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
    tp:setHeight(math.max(sc(20), treeH))

    -- Props header
    local propLblY = headerH + treeH + PAD
    self.controls.lblProps:setX(PAD);
    self.controls.lblProps:setY(th + propLblY)
    local propsLblW = getTextManager():MeasureStringX(UIFont.Small, "Properties") + sc(6)
    self.controls.propFilter:setX(PAD + propsLblW);
    self.controls.propFilter:setY(th + propLblY - 1)
    self.controls.propFilter:setWidth(lw - PAD * 2 - propsLblW)

    -- Property panel
    local pp = self.controls.propPanel
    pp:setX(PAD);
    pp:setY(th + propLblY + propLblH)
    pp:setWidth(lw - PAD * 2);
    pp:setHeight(math.max(sc(20), propH))

    -- Coord bar — in the headerH strip above the map (right side only)
    -- Layout: [ Add Rect ]  X1:[__] Y1:[__] X2:[__] Y2:[__]  W:## H:##  [ Del Rect ]
    local cf = self.controls.coordFields
    if cf then
        local fieldH = FONT_HGT_SMALL + sc(4)
        local btnH = BUTTON_HGT
        local cy = th + math.floor((headerH - fieldH) / 2)
        local btnCy = th + math.floor((headerH - btnH) / 2)
        local mx2 = lw + PAD
        local mw2 = self.width - mx2 - PAD
        local fieldW = sc(62)
        local lblPad = sc(3)
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

        -- Centre the fields + WH in the space left of Add Rect
        local available = addBtn.x - gap - cx2
        local fieldsOnlyW = 0
        for _, it in ipairs(items) do
            fieldsOnlyW = fieldsOnlyW + it.lblW + fieldW + gap
        end
        local showWH = (fieldsOnlyW + whW <= available)
        local usedFieldW = fieldW
        local totalW = showWH and (fieldsOnlyW + whW) or fieldsOnlyW
        if totalW > available then
            -- Shrink fieldW so coord fields fit
            local lblTotal = 0
            for _, it in ipairs(items) do
                lblTotal = lblTotal + it.lblW + gap
            end
            usedFieldW = math.max(sc(40), math.floor((available - lblTotal) / #items))
            totalW = 0
            for _, it in ipairs(items) do
                totalW = totalW + it.lblW + usedFieldW + gap
            end
        end
        local fx = cx2 + math.max(0, math.floor((available - totalW) / 2))

        for _, it in ipairs(items) do
            it.lbl:setX(fx);
            it.lbl:setY(cy + 1)
            fx = fx + it.lblW
            it.field:setX(fx);
            it.field:setY(cy)
            it.field:setWidth(usedFieldW);
            it.field:setHeight(fieldH)
            fx = fx + usedFieldW + gap
        end
        if self.controls.lblWH then
            if showWH then
                self.controls.lblWH:setX(fx);
                self.controls.lblWH:setY(cy + 1)
                self.controls.lblWH:setVisible(true)
            else
                self.controls.lblWH:setVisible(false)
            end
        end
    end

    -- Buttons (bottom bar) — Edit Rect removed; Add/Del Rect moved to coord bar
    local leftBtns = {self.controls.btnNewRegion, self.controls.btnSave, self.controls.btnDiscard,
                      self.controls.btnDeleteZone}
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

    -- Profile bar — fills the gap between the zone buttons and the right side.
    -- Hidden entirely when the window is too narrow to hold it, rather than
    -- letting it overlap the buttons on either side.
    local pb = {self.controls.lblProfile, self.controls.cmbProfile, self.controls.btnActivate,
                self.controls.btnNewProfile, self.controls.btnDelProfile, self.controls.lblLive}
    if pb[1] then
        local gap = math.floor(PAD / 2)
        local lblW = getTextManager():MeasureStringX(UIFont.Small, self.controls.lblProfile.name) + gap
        local liveW = getTextManager():MeasureStringX(UIFont.Small, self.controls.lblLive.name or "") + gap
        local cmbW = sc(130)
        local needed = lblW + cmbW + gap + self.controls.btnActivate.width + gap +
                           self.controls.btnNewProfile.width + gap + self.controls.btnDelProfile.width + gap + liveW

        local available = rx - lx - PAD
        local show = needed <= available
        for _, c in ipairs(pb) do
            c:setVisible(show)
        end

        if show then
            local px = lx + math.max(0, math.floor((available - needed) / 2))
            local cy = th + btnY
            local lblY = cy + math.floor((BUTTON_HGT - FONT_HGT_SMALL) / 2)

            self.controls.lblProfile:setX(px);
            self.controls.lblProfile:setY(lblY)
            px = px + lblW

            self.controls.cmbProfile:setX(px);
            self.controls.cmbProfile:setY(cy)
            self.controls.cmbProfile:setWidth(cmbW)
            self.controls.cmbProfile:setHeight(BUTTON_HGT)
            px = px + cmbW + gap

            for _, btn in ipairs({self.controls.btnActivate, self.controls.btnNewProfile, self.controls.btnDelProfile}) do
                btn:setX(px);
                btn:setY(cy)
                px = px + btn.width + gap
            end

            self.controls.lblLive:setX(px);
            self.controls.lblLive:setY(lblY)
        end
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

    -- Lists can shrink under a scroll offset (filtering, a refresh, a resize),
    -- which would otherwise leave them scrolled past their end.
    local tpanel, ppanel = self.controls.treePanel, self.controls.propPanel
    self.treeScroll = clampScroll(self.treeScroll, #self.treeNodes * ROW_HGT, tpanel.height)
    self.propScroll = clampScroll(self.propScroll, #self.propRows * ROW_HGT, ppanel.height)
    self:anchorPropEditors()

    -- Background fills
    self:drawRect(0, th, L.lw, L.usableH, 1, C.bg.r, C.bg.g, C.bg.b)
    self:drawRect(0, th + L.barY, self.width, L.barH, 1, C.bg.r, C.bg.g, C.bg.b)
    self:drawRect(L.lw, th, 1, L.barY, C.border.a, C.border.r, C.border.g, C.border.b)
    self:drawRect(0, th + L.barY, self.width, 1, C.border.a, C.border.r, C.border.g, C.border.b)

    -- Draw-mode banner above the map
    if self.overlay and self.overlay:isDrawMode() then
        local mx = L.lw + PAD
        local mw = self.width - mx - PAD
        local bannerH = FONT_HGT_SMALL + sc(6)
        self:drawRect(mx, th, mw, bannerH, 0.85, 0.20, 0.55, 0.10)
        local msg = "DRAW MODE — drag to define rect, Esc to cancel"
        local tw = getTextManager():MeasureStringX(UIFont.Small, msg)
        self:drawText(msg, mx + (mw - tw) / 2, th + sc(3), 0.20, 0.90, 0.40, 1.0, UIFont.Small)
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
            if row and row.resettable and self:isOverResetBox(row, pp:getMouseX()) then
                tipKey = "IGUI_PhunZones_ResetProp_tooltip"
            end
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

-- Greedy word wrap to maxW pixels. Some field tooltips run to a paragraph.
local function wrapText(text, maxW)
    local tm = getTextManager()
    local lines, line = {}, ""
    for word in text:gmatch("%S+") do
        local candidate = (line == "") and word or (line .. " " .. word)
        if line ~= "" and tm:MeasureStringX(UIFont.Small, candidate) > maxW then
            table.insert(lines, line)
            line = word
        else
            line = candidate
        end
    end
    if line ~= "" then
        table.insert(lines, line)
    end
    return lines
end

function UI:render()
    ISCollapsableWindowJoypad.render(self)
    if self._tipText then
        local mx, my = self._tipMX, self._tipMY
        local maxW = math.min(sc(420), self.width - sc(24))
        -- Wrapping measures every word, so only redo it when the text changes.
        if self._tipWrapFor ~= self._tipText or self._tipWrapW ~= maxW then
            self._tipWrapFor, self._tipWrapW = self._tipText, maxW
            self._tipLines = wrapText(self._tipText, maxW)
            local widest = 0
            for _, l in ipairs(self._tipLines) do
                widest = math.max(widest, getTextManager():MeasureStringX(UIFont.Small, l))
            end
            self._tipLinesW = widest
        end
        local lines = self._tipLines
        local tipW = self._tipLinesW + sc(16)
        local tipH = #lines * FONT_HGT_SMALL + sc(8)
        local tx = mx + sc(12)
        local ty = my - tipH - sc(4)
        if tx + tipW > self.width - sc(4) then
            tx = self.width - tipW - sc(4)
        end
        if ty < 0 then
            ty = my + sc(16)
        end
        self:drawRect(tx, ty, tipW, tipH, 0.95, 0.08, 0.08, 0.12)
        self:drawRectBorder(tx, ty, tipW, tipH, 1.0, C.border.r, C.border.g, C.border.b)
        for li, l in ipairs(lines) do
            self:drawText(l, tx + sc(8), ty + sc(4) + (li - 1) * FONT_HGT_SMALL, C.text.r, C.text.g, C.text.b, 1.0,
                UIFont.Small)
        end
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
            self:swallowEscRelease()
            return
        end
    end

    if key == Keyboard.KEY_ESCAPE and self:closePropPickers() then
        self:swallowEscRelease()
    end
end

-- Time-boxed, so a release that never arrives (the text box ate it) cannot
-- swallow a later, deliberate Escape.
function UI:swallowEscRelease()
    self._swallowEscUntil = getTimestampMs() + 500
end

-- Text fields that Escape should just leave, rather than close the window.
function UI:focusedTextField()
    local fields = {self.controls.treeFilter, self.controls.propFilter}
    for _, c in ipairs(self.controls.coordFields or {}) do
        table.insert(fields, c.field)
    end
    for _, f in ipairs(fields) do
        if f and f:isFocused() then
            return f
        end
    end
    return nil
end

function UI:onKeyRelease(key)
    if key ~= Keyboard.KEY_ESCAPE then
        return
    end
    -- The press already backed out of an edit or a picker. Without this the
    -- release that follows would go on to close the whole editor.
    if self._swallowEscUntil and getTimestampMs() < self._swallowEscUntil then
        self._swallowEscUntil = nil
        return
    end
    local focused = self:focusedTextField()
    if focused then
        focused:unfocus()
        return
    end
    if self.overlay and self.overlay:isDrawMode() then
        self:exitDrawMode()
    else
        self:close()
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
    local indent = sc(14)
    local toggleW = FONT_HGT_SMALL + sc(2)
    local totalH = #nodes * ROW_HGT
    local hasScroll = totalH > h
    local contentW = hasScroll and (w - SCROLLBAR_W - sc(2)) or w

    self:setStencilRect(ox, oy, w, h)
    for i, node in ipairs(nodes) do
        local ry = (i - 1) * ROW_HGT - scroll
        if ry >= h then
            break
        end
        if ry > -ROW_HGT then
            local ay = oy + ry
            do
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
                    local cx = ox + node.depth * indent - indent + sc(6)
                    self:drawRect(cx, ay, 1, ROW_HGT / 2, C.treeConn.a, C.treeConn.r, C.treeConn.g, C.treeConn.b)
                    self:drawRect(cx, ay + ROW_HGT / 2 - 1, indent - sc(6), 1, C.treeConn.a, C.treeConn.r, C.treeConn.g,
                        C.treeConn.b)
                end

                local toggleX = ox + node.depth * indent + sc(4)
                local labelX = toggleX + toggleW

                if node.hasKids then
                    local arrow = node.collapsed and "+" or "-"
                    self:drawText(arrow, toggleX, ay + sc(2), C.accentDim.r, C.accentDim.g, C.accentDim.b, 1.0,
                        UIFont.Small)
                end

                local tx = labelX
                local tr, tg, tb, ta = C.text.r, C.text.g, C.text.b, C.text.a
                if node.disabled then
                    tr, tg, tb, ta = C.textDim.r, C.textDim.g, C.textDim.b, 0.5
                end
                if node.orphan then
                    self:drawText("!", tx, ay + sc(2), C.warnBadge.r, C.warnBadge.g, C.warnBadge.b, 1.0, UIFont.Small)
                    tx = tx + FONT_HGT_SMALL + sc(2)
                end

                local label = node.title
                if node.key == "_default" then
                    label = "-- Default --"
                end

                if self._pendingChanges[node.key] then
                    tr, tg, tb, ta = C.accent.r, C.accent.g, C.accent.b, 1.0
                end
                self:drawText(label, tx, ay + sc(2), tr, tg, tb, ta, UIFont.Small)

                local rightKey = (node.key ~= node.title and node.key ~= "_default") and node.key or nil
                if rightKey then
                    local kw = getTextManager():MeasureStringX(UIFont.Small, rightKey)
                    local lw2 = getTextManager():MeasureStringX(UIFont.Small, label)
                    if tx + lw2 + sc(8) < ox + contentW - kw - sc(4) then
                        self:drawText(rightKey, ox + contentW - kw - sc(4), ay + sc(2), C.textDim.r, C.textDim.g,
                            C.textDim.b, 0.7, UIFont.Small)
                    end
                end
            end
        end
    end
    self:clearStencilRect()

    if hasScroll then
        local sbH = math.max(sc(20), h * (h / totalH))
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

    local toggleX = node.depth * sc(14) + sc(4)
    if node.hasKids and x >= toggleX and x <= toggleX + FONT_HGT_SMALL + sc(4) then
        self._treeCollapsed[node.key] = not self._treeCollapsed[node.key]
        self:buildTree()
        return
    end

    self:selectZone(node.key)
end

-- Re-selecting the zone already shown is a refresh (a save landed, another
-- admin's edit arrived): the property scroll, the selected rect, the map view
-- and any open editor all stay where the admin left them.
function UI:selectZone(key)
    local same = self.selectedData ~= nil and self.selectedData.key == key
    if not same then
        self:cancelInlineEdit()
        self.propHover = -1
        self.propScroll = 0
    end

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

    -- Deleting a zone is a base-layer edit (it tombstones the zone in the
    -- customisation file), so it stays off while a profile is being edited.
    self.controls.btnDeleteZone.enable = notDefault and (self.editProfile == nil)
    self.controls.btnAddRect.enable = notDefault

    self:refreshProperties()
    self:refreshZonePoints(raw.points or {}, same and self.selectedPtIdx or nil, same)

    -- Sync overlay
    if self.overlay then
        self.overlay:setSelectedZone(key)
        self.overlay:setZones(zoneData)
    end

    self:updateSaveDiscardButtons()
    if same then
        return
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
end

-- ===========================================================================
-- PROPERTIES
-- ===========================================================================

-- What the layer being edited sets on this zone, and nothing beneath it: the
-- custom layer for the base configuration, the profile's own sparse entry
-- otherwise. Resetting removes a field from exactly this table, so it is also
-- what decides whether a row reads as "set here".
function UI:layerEntry(key)
    if self.editProfile then
        return ((self.data and self.data.profileLayer) or {})[key] or {}
    end
    return (ModData.get(Core.const.modifiedModData) or {})[key] or {}
end
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

    -- layerRaw is what the layer currently being edited sets on this zone, so
    -- the override markers answer "does the thing I am editing set this?"
    -- rather than "does anything set this?". Values from the shipped data (or,
    -- under a profile, from the configuration beneath it) read as baseSet.
    local layerRaw = self:layerEntry(key)

    -- Marker state shared by every kind of row. A pending reset wins over
    -- whatever the layer currently holds: on save the field is gone.
    local function markers(k)
        local cleared = pending[k] == CLEAR
        local isOver = not cleared and (layerRaw[k] ~= nil or pending[k] ~= nil)
        return {
            cleared = cleared,
            override = isOver,
            baseSet = (not isOver) and (not cleared) and raw[k] ~= nil,
            -- Something to take back: a value this layer holds, or an unsaved
            -- edit to drop.
            resettable = isOver
        }
    end

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
            -- x ~= nil and x or y collapses when x is false, which matters for
            -- the boolean fields: an override that switches an inherited true
            -- back off is a real value, not an absent one.
            local val = merged[k]
            if pending[k] ~= nil and pending[k] ~= CLEAR then
                val = pending[k]
            end
            -- merged may not include a raw override if the zone data wasn't yet
            -- re-processed (e.g. modsRequired set in base data but not in lookup)
            if val == nil and raw[k] ~= nil then
                val = raw[k]
            end
            local m = markers(k)
            local displayVal = nil
            if fdef.type == "combo" then
                local opts = fdef.options or (fdef.getOptions and fdef.getOptions()) or {}
                for _, opt in ipairs(opts) do
                    if optValue(opt) == val then
                        displayVal = optLabel(opt)
                        break
                    end
                end
            end
            table.insert(self.propRows, {
                key = k,
                label = getText(fdef.label or k),
                value = val,
                displayVal = displayVal,
                override = m.override,
                baseSet = m.baseSet,
                cleared = m.cleared,
                resettable = m.resettable and fdef.type ~= "button",
                origin = fdef.mod or nil,
                fdef = fdef
            })
        end
    end

    -- Fields on the zone that no schema entry describes: typos, or settings
    -- from a mod that is not loaded. Shown read-only, but resettable, since
    -- clearing them out is usually the point of looking.
    local extraRows = {}
    for k, v in pairs(raw) do
        if not seen[k] and k ~= "inherits" and k ~= "disabled" and k ~= "isolated" and k ~= "_key" and k ~= "points" and
            k ~= "title" and k ~= "region" and k ~= "zone" then
            local displayVal = type(v) == "table" and ("[table]") or tostring(v)
            if filter == "" or k:lower():find(filter, 1, true) then
                local m = markers(k)
                table.insert(extraRows, {
                    key = k,
                    label = k,
                    value = displayVal,
                    override = m.override,
                    baseSet = m.baseSet,
                    cleared = m.cleared,
                    resettable = m.resettable,
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

    local dm = markers("disabled")
    local disabled = raw.disabled == true
    if pending.disabled ~= nil and pending.disabled ~= CLEAR then
        disabled = pending.disabled == true
    end
    table.insert(self.propRows, 1, {
        key = "disabled",
        label = "Disabled",
        value = disabled,
        override = dm.override,
        baseSet = dm.baseSet,
        cleared = dm.cleared,
        resettable = dm.resettable,
        special = true,
        danger = disabled
    })
    -- Not resettable: dropping inherits from a zone the admin created would
    -- make it a root with no parent at all, not put it back under _default.
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
        self:drawText(msg, ox + (w - mw) / 2, oy + h / 2 - sc(8), C.textDim.r, C.textDim.g, C.textDim.b, 1.0,
            UIFont.Small)
        return
    end

    local scroll = self.propScroll
    local totalH = #self.propRows * ROW_HGT
    local hasScroll = totalH > h
    local contentW = hasScroll and (w - SCROLLBAR_W - sc(2)) or w
    local valX = math.floor(contentW * 0.52)
    local tm = getTextManager()

    -- Clip to the panel so rows half scrolled out are cut off at its edge
    -- rather than drawn over the header or the button bar.
    self:setStencilRect(ox, oy, w, h)
    for i, row in ipairs(self.propRows) do
        local ry = (i - 1) * ROW_HGT - scroll
        if ry >= h then
            break
        end
        if ry > -ROW_HGT then
            local ay = oy + ry
            local editing = self:isEditingProp(row.key)
            do
                if row.isGroupHeader then
                    local lineY = ay + math.floor(ROW_HGT / 2)
                    self:drawRect(ox + sc(4), lineY, contentW - sc(8), 1, C.border.a, C.border.r, C.border.g, C.border.b)
                    local gw = getTextManager():MeasureStringX(UIFont.Small, row.label)
                    local gx = ox + math.floor((contentW - gw) / 2)
                    self:drawRect(gx - sc(4), ay + sc(2), gw + sc(8), ROW_HGT - sc(4), 1, C.panel.r, C.panel.g,
                        C.panel.b)
                    self:drawText(row.label, gx, ay + sc(2), C.textDim.r, C.textDim.g, C.textDim.b, 0.8, UIFont.Small)
                else
                    if i % 2 == 0 then
                        self:drawRect(ox, ay, contentW, ROW_HGT, C.rowAlt.a, C.rowAlt.r, C.rowAlt.g, C.rowAlt.b)
                    end
                    if self.propHover == i then
                        self:drawRect(ox, ay, contentW, ROW_HGT, C.rowHover.a, C.rowHover.r, C.rowHover.g, C.rowHover.b)
                    end
                    if editing then
                        self:drawRect(ox, ay, contentW, ROW_HGT, 0.15, C.accent.r, C.accent.g, C.accent.b)
                        self:drawRectBorder(ox, ay, contentW, ROW_HGT, 0.6, C.accent.r, C.accent.g, C.accent.b)
                    end

                    if row.cleared then
                        -- Will be removed on save: dim accent, "mine, going away".
                        self:drawRect(ox, ay + sc(1), sc(2), ROW_HGT - sc(2), 0.8, C.accentDim.r, C.accentDim.g,
                            C.accentDim.b)
                    elseif row.override and not (row.special and row.key == "inherits") then
                        local cr = row.danger and C.danger or C.accent
                        self:drawRect(ox, ay + sc(1), sc(2), ROW_HGT - sc(2), cr.a, cr.r, cr.g, cr.b)
                    elseif row.baseSet then
                        -- Set by a layer under the one being edited. A muted
                        -- bar so it reads as "comes from below", not "mine".
                        self:drawRect(ox, ay + sc(1), sc(2), ROW_HGT - sc(2), 0.7, C.textInherit.r, C.textInherit.g,
                            C.textInherit.b)
                    end

                    -- Right-hand furniture: the mod badge, and on hover the
                    -- reset box just left of it. The value text stops short
                    -- of whichever of the two is showing.
                    local valRight = contentW - sc(6)
                    local badgeW = self:propBadgeW(row)
                    if badgeW > 0 then
                        self:drawRect(ox + contentW - badgeW - sc(2), ay + sc(2), badgeW, ROW_HGT - sc(4), 0.8,
                            C.modBadge.r, C.modBadge.g, C.modBadge.b)
                        self:drawText(row.origin, ox + contentW - badgeW + sc(1), ay + sc(2), 1, 1, 1, 0.9, UIFont.Small)
                        valRight = contentW - badgeW - sc(6)
                    end
                    if row.resettable and self.propHover == i and not editing then
                        local bx, bsize = self:resetBoxRect(row, contentW)
                        local by = ay + math.floor((ROW_HGT - bsize) / 2)
                        local hot = self.controls.propPanel:isMouseOver() and
                                        self:isOverResetBox(row, self.controls.propPanel:getMouseX())
                        local bc = hot and C.danger or C.border
                        self:drawRect(ox + bx, by, bsize, bsize, hot and 0.35 or 0.6, bc.r, bc.g, bc.b)
                        self:drawRectBorder(ox + bx, by, bsize, bsize, 1.0, bc.r, bc.g, bc.b)
                        local xw = tm:MeasureStringX(UIFont.Small, "x")
                        self:drawText("x", ox + bx + math.floor((bsize - xw) / 2),
                            by + math.floor((bsize - FONT_HGT_SMALL) / 2), C.text.r, C.text.g, C.text.b, 1.0,
                            UIFont.Small)
                        valRight = bx - sc(4)
                    end

                    local lr, lg, lb, la
                    if row.special then
                        lr, lg, lb, la = C.textDim.r, C.textDim.g, C.textDim.b, 1.0
                    elseif row.override or row.baseSet then
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
                        self:drawText(row.label, ox + sc(6), ay + sc(2), C.accent.r, C.accent.g, C.accent.b, la,
                            UIFont.Small)
                        local hint = "[ click ]"
                        local hw = getTextManager():MeasureStringX(UIFont.Small, hint)
                        self:drawText(hint, ox + contentW - hw - sc(6), ay + sc(2), C.accentDim.r, C.accentDim.g,
                            C.accentDim.b, 0.8, UIFont.Small)
                    else
                        self:drawText(row.label, ox + sc(6), ay + sc(2), lr, lg, lb, la, UIFont.Small)

                        -- Same trap as above: a value of false is set, and has
                        -- to read as false rather than as the dash that means
                        -- nothing is set here.
                        local valStr
                        if row.cleared then
                            -- What it falls back to is only known once the
                            -- layers are rebuilt, which happens on save.
                            valStr = getText("IGUI_PhunZones_ResetPending")
                        elseif row.value == nil then
                            valStr = "--"
                        elseif isCombo then
                            valStr = row.displayVal or tostring(row.value)
                        else
                            valStr = tostring(row.value)
                        end
                        local vr, vg, vb, va
                        if row.cleared then
                            vr, vg, vb, va = C.accentDim.r, C.accentDim.g, C.accentDim.b, 1.0
                        elseif row.override then
                            vr, vg, vb, va = C.accent.r, C.accent.g, C.accent.b, 1.0
                        elseif row.baseSet then
                            -- A real value, just not one this layer owns.
                            vr, vg, vb, va = C.text.r, C.text.g, C.text.b, 1.0
                        else
                            vr, vg, vb, va = C.textDim.r, C.textDim.g, C.textDim.b, 0.9
                        end
                        if row.danger and row.value == true and not row.cleared then
                            vr, vg, vb = C.danger.r, C.danger.g, C.danger.b
                        end

                        -- Clip value text to available column width
                        local valColW = valRight - valX - sc(4)
                        if tm:MeasureStringX(UIFont.Small, valStr) > valColW then
                            while #valStr > 0 and tm:MeasureStringX(UIFont.Small, valStr .. "...") > valColW do
                                valStr = valStr:sub(1, -2)
                            end
                            valStr = valStr .. "..."
                        end

                        self:drawText(valStr, ox + valX + sc(4), ay + sc(2), vr, vg, vb, va, UIFont.Small)
                    end
                    self:drawRect(ox, ay + ROW_HGT - 1, contentW, 1, C.border.a * 0.4, C.border.r, C.border.g,
                        C.border.b)
                end
            end
        end
    end
    self:clearStencilRect()

    if hasScroll then
        local sbH = math.max(sc(20), h * (h / totalH))
        local sbY = oy + (scroll / math.max(1, totalH - h)) * (h - sbH)
        self:drawRect(ox + w - SCROLLBAR_W, oy, SCROLLBAR_W, h, 0.3, 0.15, 0.15, 0.18)
        self:drawRect(ox + w - SCROLLBAR_W, sbY, SCROLLBAR_W, sbH, C.accentDim.a, C.accentDim.r, C.accentDim.g,
            C.accentDim.b)
    end
end

-- ---------------------------------------------------------------------------
-- Property row geometry. Everything here is relative to the property panel,
-- so the click handlers, the renderer and the floating editors all agree.
-- ---------------------------------------------------------------------------
function UI:propContentW()
    local pp = self.controls.propPanel
    local hasScroll = (#self.propRows * ROW_HGT) > pp.height
    return hasScroll and (pp.width - SCROLLBAR_W - sc(2)) or pp.width
end

function UI:propBadgeW(row)
    if not row.origin then
        return 0
    end
    return getTextManager():MeasureStringX(UIFont.Small, row.origin) + sc(6)
end

-- x and size of the square reset box, which sits just left of the mod badge.
function UI:resetBoxRect(row, contentW)
    local size = ROW_HGT - sc(6)
    local right = contentW - sc(4)
    local badgeW = self:propBadgeW(row)
    if badgeW > 0 then
        right = contentW - badgeW - sc(6)
    end
    return right - size, size
end

function UI:isOverResetBox(row, panelX)
    local bx, size = self:resetBoxRect(row, self:propContentW())
    return panelX >= bx - sc(2) and panelX <= bx + size + sc(2)
end

function UI:findPropRow(key)
    for i, row in ipairs(self.propRows) do
        if row.key == key and not row.isGroupHeader then
            return i
        end
    end
    return nil
end

-- The value cell of row i, in window coordinates, and whether the whole row is
-- inside the panel's visible area.
function UI:propValueCell(i)
    local pp = self.controls.propPanel
    local contentW = self:propContentW()
    local valX = math.floor(contentW * 0.52)
    local ry = (i - 1) * ROW_HGT - self.propScroll
    local visible = ry >= 0 and ry + ROW_HGT <= pp.height
    return pp.x + valX, pp.y + ry, contentW - valX - sc(4), visible
end

function UI:ensurePropRowVisible(i)
    local pp = self.controls.propPanel
    local rowY = (i - 1) * ROW_HGT
    if rowY < self.propScroll then
        self.propScroll = rowY
    elseif rowY + ROW_HGT > self.propScroll + pp.height then
        self.propScroll = rowY + ROW_HGT - pp.height
    end
end

function UI:isEditingProp(key)
    if self._editingRow and self._editingRow.key == key then
        return true
    end
    local fp, ip = self.controls.fieldPicker, self.controls.inheritsPicker
    return (fp:isVisible() and fp._rowKey == key) or (ip:isVisible() and key == "inherits")
end

-- Keeps the floating editor on its row as the list scrolls, refreshes under
-- it, or the window is resized. One that has scrolled out of view is closed
-- (keeping what was typed) instead of being left hanging over other rows.
function UI:anchorPropEditors()
    local function place(widget, key, height)
        local i = self:findPropRow(key)
        if not i then
            return false
        end
        local x, y, w, visible = self:propValueCell(i)
        if not visible then
            return false
        end
        widget:setX(x)
        widget:setY(y + math.floor((ROW_HGT - height) / 2))
        widget:setWidth(w)
        return true
    end

    local ie = self.controls.inlineEdit
    if ie:isVisible() and self._editingRow then
        if not place(ie, self._editingRow.key, ie.height) then
            self:commitInlineEdit()
        end
    end

    local pickers = {{self.controls.fieldPicker, self.controls.fieldPicker._rowKey},
                     {self.controls.inheritsPicker, "inherits"}}
    for _, p in ipairs(pickers) do
        local picker, key = p[1], p[2]
        if picker:isVisible() then
            -- The dropdown closed without a choice (clicked away, clicked the
            -- box again): nothing left to keep the box open for. While it is
            -- open the dropdown holds the mouse, so the list cannot scroll
            -- under it; placing it just follows a refresh that moved the row.
            if not picker.expanded then
                self:closePropPickers()
            else
                place(picker, key, picker.height)
            end
        end
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

    if row.resettable and self:isOverResetBox(row, x) then
        self:resetProp(row.key)
        return
    end

    self:activatePropRow(i)
end

-- Does whatever clicking row i's value means: toggle, pick, run, or type.
function UI:activatePropRow(i)
    local row = self.propRows[i]
    local sd = self.selectedData
    if not row or not sd then
        return
    end

    if row.key == "disabled" then
        self:saveProp("disabled", not (row.value == true))
        return
    end
    if row.key == "inherits" then
        -- _default is the root of every chain; it has nothing to inherit.
        if sd.key ~= "_default" then
            self:ensurePropRowVisible(i)
            self:showInheritsPicker(row, i)
        end
        return
    end
    if row.special or row.extra or not row.fdef then
        return
    end

    local fdef = row.fdef
    if fdef.type == "boolean" then
        -- row.value already accounts for pending edits, which sd.raw does
        -- not when the pending edit is a reset.
        self:saveProp(row.key, not (row.value == true))
        return
    end

    if fdef.type == "combo" then
        local opts = fdef.options or (fdef.getOptions and fdef.getOptions()) or {}
        self:ensurePropRowVisible(i)
        self:showFieldPicker(row, i, opts)
        return
    end

    if fdef.type == "button" then
        if fdef.onClick then
            fdef.onClick(self, row.key, row.value)
        end
        return
    end

    self:openInlineEditor(i)
end

local function isTextRow(row)
    return row and not row.isGroupHeader and not row.special and not row.extra and row.fdef and
               (row.fdef.type == "string" or row.fdef.type == "int" or row.fdef.type == "double")
end

function UI:openInlineEditor(i)
    local row = self.propRows[i]
    if not isTextRow(row) then
        return
    end
    self:ensurePropRowVisible(i)

    local ie = self.controls.inlineEdit
    local ieH = FONT_HGT_SMALL + sc(4)
    local x, y, w = self:propValueCell(i)
    ie:setX(x)
    ie:setY(y + math.floor((ROW_HGT - ieH) / 2))
    ie:setWidth(w)
    ie:setHeight(ieH)

    local initText = row.value ~= nil and tostring(row.value) or ""
    ie:setText(initText)
    self._inlineOrigValue = initText
    self._inlineDirty = false
    self._editingRow = row
    ie:setVisible(true)
    ie:focus()
    ie:selectAll()
end

-- Tab / Shift+Tab: keep what was typed and move to the next text field.
function UI:editAdjacentProp(dir)
    local from = self._editingRow and self:findPropRow(self._editingRow.key)
    self:commitInlineEdit()
    if not from then
        return
    end
    local i = from + dir
    while i >= 1 and i <= #self.propRows do
        if isTextRow(self.propRows[i]) then
            self:openInlineEditor(i)
            return
        end
        i = i + dir
    end
end

function UI:onPropRightClick(panel, x, y)
    if not self.selectedData then
        return
    end
    local i = math.floor((y + self.propScroll) / ROW_HGT) + 1
    local row = self.propRows[i]
    if not row or row.isGroupHeader then
        return
    end
    self:commitInlineEdit()
    self:closePropPickers()

    local key = self.selectedData.key
    local pending = self._pendingChanges[key]
    local hasPending = pending ~= nil and pending[row.key] ~= nil
    local editable = not row.extra and row.fdef ~= nil and row.fdef.type ~= "button"
    if row.key == "disabled" or (row.key == "inherits" and key ~= "_default") then
        editable = true
    end
    if not (editable or row.resettable or hasPending) then
        return
    end

    local context = ISContextMenu.get(self.playerIndex, getMouseX(), getMouseY())
    if editable then
        context:addOption(getText("IGUI_PhunZones_EditProp"), self, function(owner)
            local idx = owner:findPropRow(row.key)
            if idx then
                owner:activatePropRow(idx)
            end
        end)
    end
    if row.resettable then
        local opt = context:addOption(getText("IGUI_PhunZones_ResetProp"), self, function(owner)
            owner:resetProp(row.key)
        end)
        local tip = ISToolTip:new()
        tip:initialise()
        tip.description = getText("IGUI_PhunZones_ResetProp_tooltip")
        opt.toolTip = tip
    end
    if hasPending then
        context:addOption(getText("IGUI_PhunZones_UndoProp"), self, function(owner)
            owner:discardPendingField(key, row.key)
        end)
    end
end

function UI:showInheritsPicker(row, rowIndex)
    local sd = self.selectedData
    if not sd or not sd.key then
        return
    end

    local picker = self.controls.inheritsPicker
    local x, y, w = self:propValueCell(rowIndex)
    picker:setX(x)
    picker:setY(y + math.floor((ROW_HGT - picker.height) / 2))
    picker:setWidth(w)

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

    -- ISComboBox:select() matches option text, not an index.
    picker.selected = selectedIdx
    self:openPicker(picker)
end

function UI:showFieldPicker(row, rowIndex, opts)
    local picker = self.controls.fieldPicker
    local x, y, w = self:propValueCell(rowIndex)
    picker:setX(x)
    picker:setY(y + math.floor((ROW_HGT - picker.height) / 2))
    picker:setWidth(w)
    picker:clear()
    picker._opts = opts
    picker._rowKey = row.key

    local currentIdx = 1
    for i, opt in ipairs(opts) do
        picker:addOption(optLabel(opt))
        if optValue(opt) == row.value then
            currentIdx = i
        end
    end
    picker.selected = math.max(1, math.min(currentIdx, #opts))
    self:openPicker(picker)
end

-- Shows a picker with its dropdown already open, so choosing a value takes
-- one click on the row and one on the option, not a third on the box between.
function UI:openPicker(picker)
    picker:setVisible(true)
    picker.expanded = true
    picker:showPopup()
end

-- Closes either picker. Returns true if one was open.
function UI:closePropPickers()
    local closed = false
    for _, picker in ipairs({self.controls.inheritsPicker, self.controls.fieldPicker}) do
        if picker and picker:isVisible() then
            if picker.expanded then
                picker.expanded = false
                picker:hidePopup()
            end
            picker:setVisible(false)
            closed = true
        end
    end
    local fp = self.controls.fieldPicker
    if fp then
        fp._rowKey = nil
        fp._opts = nil
    end
    return closed
end

function UI:commitInlineEdit()
    -- _editingRow is the guard, cleared first: hiding the box makes it lose
    -- focus, and onLostFocus calls straight back in here.
    local row = self._editingRow
    if not row then
        return
    end
    self._editingRow = nil
    local ie = self.controls.inlineEdit
    local text = ie:getText()
    local orig = self._inlineOrigValue
    ie:setVisible(false)
    self._inlineOrigValue = nil
    self._inlineDirty = false

    -- Opening a field and leaving it untouched must not pin its inherited
    -- value as an override.
    if not row.fdef or text == orig then
        self:updateSaveDiscardButtons()
        return
    end

    local fdef = row.fdef
    local val
    if fdef.type == "int" or fdef.type == "double" then
        val = tonumber(text)
        if val == nil then
            -- Not a number (or emptied). Use Reset to clear a value.
            self:updateSaveDiscardButtons()
            return
        end
    elseif fdef.type == "boolean" then
        val = (text == "true" or text == "1")
    else
        val = text
    end

    self:saveProp(row.key, val)
end

function UI:cancelInlineEdit()
    self._editingRow = nil
    self._inlineOrigValue = nil
    self._inlineDirty = false
    local ie = self.controls.inlineEdit
    if ie and ie:isVisible() then
        ie:setVisible(false)
    end
    self:closePropPickers()
    self:updateSaveDiscardButtons()
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
        if fdef.type == "int" or fdef.type == "double" then
            val = tonumber(newValue);
            if val == nil then
                return
            end
        elseif fdef.type == "boolean" then
            val = (newValue == true or newValue == "true" or newValue == 1)
        elseif fdef.type == "combo" then
            val = newValue
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

    -- The profile layer is deliberately left alone: it is the live runtime
    -- table, so writing an unsaved edit into it would leak into the game (and
    -- into the file on the next profile save) even if the edit is discarded.
    -- The pending entry is what marks the row as this layer's own until then.

    if fieldKey == "title" then
        self:buildTree()
    end
    if fieldKey == "inherits" then
        self:buildTree()
    end

    self:updateSaveDiscardButtons()
    self:refreshProperties()
end

-- Takes a field back out of the layer being edited, so whatever is underneath
-- applies again. Saved like any other edit. If the layer never held the field
-- and there is only an unsaved edit, that edit is simply dropped.
function UI:resetProp(fieldKey)
    local sd = self.selectedData
    if not sd or not sd.key then
        return
    end
    local key = sd.key
    if self:layerEntry(key)[fieldKey] == nil then
        self:discardPendingField(key, fieldKey)
        return
    end
    self._pendingChanges[key] = self._pendingChanges[key] or {}
    self._pendingChanges[key][fieldKey] = CLEAR
    self:updateSaveDiscardButtons()
    self:refreshProperties()
end

-- Drops one unsaved edit. The optimistic copy in self.data cannot be unpicked
-- field by field, so it is rebuilt and the remaining edits laid back on top.
function UI:discardPendingField(key, fieldKey)
    local pending = self._pendingChanges[key]
    if not pending or pending[fieldKey] == nil then
        return
    end
    pending[fieldKey] = nil
    if Core.tools.isEmpty(pending) then
        self._pendingChanges[key] = nil
    end
    self:refreshData(self.selectedData)
end

function UI:confirmDiscardAll()
    self:commitInlineEdit()
    if not self:hasPendingChanges() then
        return
    end
    local modal = ISModalDialog:new(0, 0, sc(300), sc(150), getText("IGUI_PhunZones_DiscardConfirm"), true, self,
        function(owner, button)
            if button.internal == "YES" then
                owner._pendingChanges = {}
                owner:refreshData(owner.selectedData)
            end
        end)
    modal:initialise()
    modal:setX(getCore():getScreenWidth() / 2 - modal.width / 2)
    modal:setY(getCore():getScreenHeight() / 2 - modal.height / 2)
    modal:addToUIManager()
end

-- Lays unsaved edits back over a freshly built self.data, so a rebuild (a
-- save landing, another admin's change arriving) does not visually undo them
-- while they still sit in the queue waiting for Save.
function UI:applyPendingToData()
    local zoneData, lookupData = zones(self), lookup(self)
    for key, fields in pairs(self._pendingChanges) do
        local zone = zoneData[key]
        if zone then
            for field, val in pairs(fields) do
                if field == "_points" then
                    zone.points = copyPoints(val)
                elseif val ~= CLEAR then
                    zone[field] = val
                    if lookupData[key] then
                        lookupData[key][field] = val
                    end
                end
            end
        end
    end
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
        local zoneChanges = {}

        -- Pending property changes — always include explicit user changes.
        -- Do NOT deduplicate against inherited values here: a user setting
        -- nobuilding=false must be saved even if the parent also has false,
        -- because the zone needs its own explicit override to differ from
        -- whatever the grandparent chain provides.
        for fieldKey, val in pairs(fields) do
            if fieldKey ~= "_points" then
                zoneChanges[fieldKey] = val
            end
        end

        -- Pending geometry — write via ModData (same path as the old savePoint).
        -- Only for the base layer: a profile's geometry belongs in the profile,
        -- and it travels in the change payload alone.
        if fields._points then
            if not self.editProfile then
                local md = ModData.getOrCreate(Core.const.modifiedModData)
                if not md[zoneKey] then
                    md[zoneKey] = {}
                end
                md[zoneKey].points = fields._points
            end
            -- Include points in the change payload so the save path persists them
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
        if self.editProfile then
            Core.requestProfileChanges(self.editProfile, changes)
        else
            Core.saveChanges(changes)
        end
        -- Both save paths have already applied the change to the local copy
        -- of the layer, so a rebuild shows real values straight away. That
        -- matters for resets in particular: what a reset falls back to is only
        -- known once the layers are merged again.
        self:refreshData(self.selectedData)
    end
end

function UI:updateSaveDiscardButtons()
    local ie = self.controls.inlineEdit
    local inlineDirty = ie and ie:isVisible() and self._inlineDirty
    local dirty = self:hasPendingChanges() or inlineDirty
    self.controls.btnSave.enable = dirty
    if self.controls.btnDiscard then
        self.controls.btnDiscard.enable = dirty
    end
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
    -- Always re-build self.data from scratch, respecting the current filter state
    -- and the layer being edited. This keeps Core.data untouched: the editor can
    -- show a profile that is not live without changing anything for players.
    self.data = Core.buildZoneData(self._filterActive or false, self.editProfile or false)

    -- Rect arrays come out of the merge shared with the layers they were read
    -- from: the shipped zone data and the custom layer in ModData. Dragging a
    -- rect edits its array in place, so without a private copy an unsaved,
    -- later discarded drag would already be in those tables.
    for _, z in pairs(self.data.zones or {}) do
        if z.points then
            z.points = copyPoints(z.points)
        end
    end
    self:applyPendingToData()

    self:refreshProfileBar()
    self:rebuildUI(zone)
end

function UI:rebuildUI(zone)
    self:buildTree()

    if zone then
        local targetKey = zone.key or zone.region
        if targetKey and zones(self)[targetKey] then
            self:selectZone(targetKey)
            return
        end
    end

    self:cancelInlineEdit()
    self.selectedData = nil
    self:refreshProperties()
end

-- keepView: same zone shown again, so leave the map where the admin put it.
function UI:refreshZonePoints(points, selectedIdx, keepView)
    self.selectedPoint = nil
    self.controls.btnDeleteRect.enable = false
    self:updateCoordBar(nil)

    if not points or #points == 0 then
        self.controls.mapui:setData(points or {}, nil, keepView)
    else
        local idx = selectedIdx or 1
        idx = math.max(1, math.min(idx, #points))
        self.selectedPoint = {
            x = points[idx][1],
            y = points[idx][2],
            x2 = points[idx][3],
            y2 = points[idx][4]
        }
        self.controls.btnDeleteRect.enable = true
        self.controls.mapui:setData(points, self.selectedPoint, keepView)
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
            final = (data[k] ~= nil and data[k] ~= "") and data[k] or nil
        elseif v.type == "combo" then
            final = (data[k] ~= nil and data[k] ~= "none") and data[k] or nil
        elseif v.type == "int" or v.type == "double" then
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
    self:refreshZonePoints(zone.points, ptIdx, true)
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
    local w, h = sc(300), sc(120)
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
    entry = ISTextEntryBox:new("", sc(10), sc(60), w - sc(20), FONT_HGT_SMALL + sc(6))
    entry:initialise()
    entry:instantiate()
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
    local w = math.max(sc(300), getTextManager():MeasureStringX(UIFont.Small, msg) + sc(40))
    local h = sc(200)
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
    self:refreshZonePoints(pts, #pts > 0 and newIdx or nil, true)
end

-- ===========================================================================
-- Window lifecycle
-- ===========================================================================
function UI:close()
    if self._closing then
        return
    end
    if self:hasPendingChanges() then
        local modal = ISModalDialog:new(0, 0, sc(300), sc(150), getText("IGUI_PhunZones_UnsavedChanges") or
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
