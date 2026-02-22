-- ui_map_overlay.lua
-- Handles all zone visualisation and interaction on top of the PZ map widget.
-- Kept separate from ui_zones.lua because the concerns are distinct:
--   • Coordinate transforms (world ↔ screen)
--   • Zone/rect rendering (colours, labels, highlights)
--   • Hit testing (click → zone/rect)
--   • Draw mode (drag to define a new rect)
--   • Point selection within a zone
--
-- USAGE (from ui_zones.lua):
--
--   local MapOverlay = require("PhunZones/ui/ui_map_overlay")
--
--   -- Create, parented to the mapui ISPanel:
--   self.overlay = MapOverlay:new(mapui)
--
--   -- Feed data:
--   self.overlay:setZones(Core.data.zones)
--   self.overlay:setSelectedZone("myZoneKey")
--   self.overlay:setSelectedPoint(2)            -- index within zone.points
--
--   -- Wire callbacks (set before use):
--   self.overlay.onZoneClicked  = function(key) ... end
--   self.overlay.onPointClicked = function(key, idx) ... end
--   self.overlay.onRectDrawn    = function(x1,y1,x2,y2) ... end
--
--   -- Draw mode:
--   self.overlay:enterDrawMode()   -- user drags to define a rect
--   self.overlay:exitDrawMode()    -- cancel without saving
if isServer() then
    return
end

-- ---------------------------------------------------------------------------
-- Colour palette — mirrors the C table in ui_zones.lua so visual language
-- stays consistent.  All values are 0-1 RGBA.
-- ---------------------------------------------------------------------------
local OC = {
    -- unselected zone fill / border
    zoneFill = {
        r = 0.35,
        g = 0.60,
        b = 0.85,
        a = 0.18
    },
    zoneBorder = {
        r = 0.45,
        g = 0.70,
        b = 0.95,
        a = 0.65
    },
    zoneLabel = {
        r = 0.75,
        g = 0.88,
        b = 1.00,
        a = 0.85
    },

    -- zone that is selected in the tree
    selFill = {
        r = 0.15,
        g = 0.35,
        b = 0.70,
        a = 0.40
    },
    selBorder = {
        r = 0.40,
        g = 0.70,
        b = 1.00,
        a = 1.00
    },
    selLabel = {
        r = 1.00,
        g = 1.00,
        b = 1.00,
        a = 1.00
    },

    -- active/selected rect within the selected zone (accent orange, matches UI)
    rectFill = {
        r = 0.90,
        g = 0.55,
        b = 0.10,
        a = 0.20
    },
    rectBorder = {
        r = 0.90,
        g = 0.55,
        b = 0.10,
        a = 0.90
    },

    -- hover highlight on an unselected zone
    hoverFill = {
        r = 0.45,
        g = 0.70,
        b = 0.95,
        a = 0.28
    },
    hoverBorder = {
        r = 0.65,
        g = 0.85,
        b = 1.00,
        a = 0.90
    },

    -- disabled/tombstone zone — greyed out
    disFill = {
        r = 0.50,
        g = 0.50,
        b = 0.55,
        a = 0.10
    },
    disBorder = {
        r = 0.50,
        g = 0.50,
        b = 0.55,
        a = 0.35
    },
    disLabel = {
        r = 0.55,
        g = 0.55,
        b = 0.60,
        a = 0.60
    },

    -- draw-mode preview rect
    drawFill = {
        r = 0.20,
        g = 0.85,
        b = 0.45,
        a = 0.20
    },
    drawBorder = {
        r = 0.25,
        g = 0.95,
        b = 0.50,
        a = 0.90
    },

    -- resize handle dots on the active rect
    handle = {
        r = 0.90,
        g = 0.55,
        b = 0.10,
        a = 1.00
    }
}

local FONT = UIFont.Small
local FONT_HGT = getTextManager():getFontHeight(FONT)
local HANDLE_R = 5 -- half-size of corner handle squares (slightly larger for easier grabbing)
local HANDLE_HIT_R = 8 -- hit-test radius for handle grabs (larger than visual)
local MIN_DRAW_PX = 6 -- minimum drag distance to register as a rect
local LABEL_PAD_X = 6 -- horizontal padding inside label background pill
local LABEL_PAD_Y = 3 -- vertical padding inside label background pill

-- ---------------------------------------------------------------------------
local MapOverlay = {}
MapOverlay.__index = MapOverlay

-- ---------------------------------------------------------------------------
-- Constructor
-- mapui  : the ISPanel returned by ui_map.lua (has mapui.map = actual map widget)
-- ---------------------------------------------------------------------------
function MapOverlay:new(mapui)
    local o = setmetatable({}, self)

    o.mapui = mapui -- the wrapper panel
    o.zones = {} -- key → zone table (from Core.data.zones)
    o.selectedKey = nil -- currently selected zone key
    o.selectedPtIdx = nil -- index of selected rect inside selected zone
    o.hoverKey = nil -- zone key the cursor is over
    o.hoverPtIdx = nil -- rect index cursor is over

    -- Draw mode state
    o._drawMode = false
    o._drawStart = nil -- { wx, wy } world coords
    o._drawCurrent = nil -- { wx, wy } live world coords while dragging

    -- Handle drag state (resize active rect by dragging a handle)
    o._handleDrag = false
    o._handleIdx = nil -- which handle (1-8, see _handlePoints)
    o._handleOrigPt = nil -- original { x1,y1,x2,y2 } world coords before drag
    o._handleWx = nil -- live drag world x
    o._handleWy = nil -- live drag world y

    -- Body drag state (translate whole rect by dragging its interior)
    o._bodyDrag = false
    o._bodyOrigPt = nil -- original { x1,y1,x2,y2 } world coords before drag
    o._bodyStartWx = nil -- world x where drag started
    o._bodyStartWy = nil -- world y where drag started
    o._bodyWx = nil -- live drag world x
    o._bodyWy = nil -- live drag world y

    -- Callbacks — assign from ui_zones.lua
    o.onZoneClicked = nil -- function(key)
    o.onPointClicked = nil -- function(key, idx)
    o.onRectDrawn = nil -- function(x1,y1,x2,y2)
    o.onRectDragging = nil -- function(key, ptIdx, x1,y1,x2,y2) — fires every move frame during drag
    o.onRectResized = nil -- function(key, ptIdx, x1,y1,x2,y2) — fires on mouse up

    -- Hook into the map widget's render pipeline
    o:_hookMapWidget()

    return o
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

function MapOverlay:setZones(zones)
    self.zones = zones or {}
end

function MapOverlay:setSelectedZone(key)
    self.selectedKey = key
    self.selectedPtIdx = (key ~= nil) and 1 or nil
end

function MapOverlay:setSelectedPoint(idx)
    self.selectedPtIdx = idx
end

-- Enter draw mode: next mouse drag on the map defines a new rect.
-- The onRectDrawn callback fires when the user releases the mouse.
function MapOverlay:enterDrawMode()
    self._drawMode = true
    self._drawStart = nil
    self._drawCurrent = nil
end

function MapOverlay:exitDrawMode()
    self._drawMode = false
    self._drawStart = nil
    self._drawCurrent = nil
end

function MapOverlay:isDrawMode()
    return self._drawMode
end

-- ---------------------------------------------------------------------------
-- Internal: hook render + mouse events on the underlying map widget
-- ---------------------------------------------------------------------------
function MapOverlay:_hookMapWidget()
    local mapWidget = self.mapui and self.mapui.map
    if not mapWidget then
        -- mapui may not have initialised yet; retry hook will be called from
        -- ui_zones.lua after initialise()
        return
    end

    local overlay = self

    -- ---- render ----
    -- Append our draw pass after the map's own render
    local origRender = mapWidget.render
    mapWidget.render = function(s)
        if origRender then
            origRender(s)
        end
        -- Clamp draw calls to the map's own stencil/clip region
        overlay:_render(s)
    end

    -- ---- mouse down ----
    local origDown = mapWidget.onMouseDown
    mapWidget.onMouseDown = function(s, x, y)
        -- x,y here are widget-relative absolute positions at mousedown
        overlay._mouseX = x
        overlay._mouseY = y
        overlay:_onMouseDown(s, x, y)
        -- Suppress map pan if we consumed the event (draw mode or handle/body drag)
        if not overlay._drawMode and not overlay._handleDrag and not overlay._bodyDrag and origDown then
            origDown(s, x, y)
        end
    end

    -- ---- mouse move ----
    -- IMPORTANT: PZ passes *deltas* (dx, dy) to onMouseMove, not absolute coords.
    -- We accumulate them ourselves so we always have a reliable absolute position.
    local origMove = mapWidget.onMouseMove
    mapWidget.onMouseMove = function(s, dx, dy)
        overlay._mouseX = (overlay._mouseX or 0) + dx
        overlay._mouseY = (overlay._mouseY or 0) + dy
        overlay:_onMouseMove(s, overlay._mouseX, overlay._mouseY)
        -- Suppress map pan during draw mode or handle/body drag
        if not overlay._drawMode and not overlay._handleDrag and not overlay._bodyDrag and origMove then
            origMove(s, dx, dy)
        end
    end

    -- ---- mouse move while captured (PZ routes captured drag here, not onMouseMove) ----
    local origMoveCapture = mapWidget.onMouseMoveWhileCapture
    mapWidget.onMouseMoveWhileCapture = function(s, dx, dy)
        overlay._mouseX = (overlay._mouseX or 0) + dx
        overlay._mouseY = (overlay._mouseY or 0) + dy
        overlay:_onMouseMove(s, overlay._mouseX, overlay._mouseY)
        -- Only forward to original handler if we're not consuming the drag
        if not overlay._drawMode and not overlay._handleDrag and not overlay._bodyDrag and origMoveCapture then
            origMoveCapture(s, dx, dy)
        end
    end

    -- ---- mouse up ----
    local origUp = mapWidget.onMouseUp
    mapWidget.onMouseUp = function(s, x, y)
        -- x,y at mouseup are also absolute widget-relative positions
        overlay._mouseX = x
        overlay._mouseY = y
        local consumed = overlay:_onMouseUp(s, x, y)
        if not consumed and origUp then
            origUp(s, x, y)
        end
    end

    -- ---- hover (mouse move without button) ----
    -- PZ uses onMouseMove for hover too; we update hoverKey there.
end

-- Call this from ui_zones.lua if mapui wasn't ready at construction time
function MapOverlay:hookNow()
    self:_hookMapWidget()
end

-- ---------------------------------------------------------------------------
-- Coordinate helpers
-- ---------------------------------------------------------------------------

-- Returns the mapAPI from the underlying widget, or nil
function MapOverlay:_api()
    return self.mapui and self.mapui.map and self.mapui.map.mapAPI
end

-- World coords → screen coords relative to the map widget's top-left
function MapOverlay:_wToS(wx, wy)
    local api = self:_api()
    if not api then
        return 0, 0
    end
    return api:worldToUIX(wx, wy), api:worldToUIY(wx, wy)
end

-- Screen coords (widget-relative) → world coords
function MapOverlay:_sToW(sx, sy)
    local api = self:_api()
    if not api then
        return 0, 0
    end
    return api:uiToWorldX(sx, sy), api:uiToWorldY(sx, sy)
end

-- Returns screen-space AABB for a zone point table entry {x1,y1,x2,y2}
-- Returns floored integers so integer mouse coords always compare cleanly.
function MapOverlay:_ptScreenRect(pt)
    local x1s, y1s = self:_wToS(pt[1], pt[2])
    local x2s, y2s = self:_wToS(pt[3], pt[4])
    if x1s > x2s then
        x1s, x2s = x2s, x1s
    end
    if y1s > y2s then
        y1s, y2s = y2s, y1s
    end
    return math.floor(x1s), math.floor(y1s), math.ceil(x2s), math.ceil(y2s)
end

-- ---------------------------------------------------------------------------
-- Hit testing
-- ---------------------------------------------------------------------------

-- Returns key, ptIdx for the topmost zone rect under screen point (sx,sy),
-- or nil,nil if nothing hit.
-- Preference order: selected zone first (allows clicking its rects even when
-- overlapping another zone), then remaining zones by draw order.
function MapOverlay:_hitTest(sx, sy)
    local function testZone(key)
        local z = self.zones[key]
        if not z or not z.points then
            return nil
        end
        for i, pt in ipairs(z.points) do
            local x1, y1, x2, y2 = self:_ptScreenRect(pt)
            if sx >= x1 and sx <= x2 and sy >= y1 and sy <= y2 then
                return i
            end
        end
        return nil
    end

    -- Check selected zone first
    if self.selectedKey then
        local idx = testZone(self.selectedKey)
        if idx then
            return self.selectedKey, idx
        end
    end

    -- Then all others
    for key in pairs(self.zones) do
        if key ~= self.selectedKey then
            local idx = testZone(key)
            if idx then
                return key, idx
            end
        end
    end

    return nil, nil
end

-- ---------------------------------------------------------------------------
-- Mouse event handlers
-- ---------------------------------------------------------------------------

function MapOverlay:_onMouseDown(widget, x, y)
    if self._drawMode then
        local wx, wy = self:_sToW(x, y)
        self._drawStart = {
            wx = wx,
            wy = wy,
            sx = x,
            sy = y
        }
        self._drawCurrent = {
            wx = wx,
            wy = wy
        }
        -- Capture so we get move events even outside widget bounds
        widget:setCapture(true)
        return
    end

    -- Check if clicking a resize handle on the active rect
    if self.selectedKey and self.selectedPtIdx then
        local z = self.zones[self.selectedKey]
        local pt = z and z.points and z.points[self.selectedPtIdx]
        if pt then
            local x1s, y1s, x2s, y2s = self:_ptScreenRect(pt)

            local hIdx = self:_hitTestHandle(x, y, pt)
            if hIdx then
                self._handleDrag = true
                self._handleIdx = hIdx
                self._handleOrigPt = {pt[1], pt[2], pt[3], pt[4]}
                self._handleWx, self._handleWy = self:_sToW(x, y)
                widget:setCapture(true)
                return
            end

            -- Check if clicking inside the body of the active rect → translate drag
            if x >= x1s and x <= x2s and y >= y1s and y <= y2s then
                self._bodyDrag = true
                self._bodyOrigPt = {pt[1], pt[2], pt[3], pt[4]}
                self._bodyStartWx, self._bodyStartWy = self:_sToW(x, y)
                self._bodyWx = self._bodyStartWx
                self._bodyWy = self._bodyStartWy
                widget:setCapture(true)
                return
            end
        end
    end

    -- Record click start for proper click-vs-drag discrimination
    self._clickStartX = x
    self._clickStartY = y
end

function MapOverlay:_onMouseMove(widget, x, y)
    if self._drawMode and self._drawStart then
        local wx, wy = self:_sToW(x, y)
        self._drawCurrent = {
            wx = wx,
            wy = wy
        }
        return
    end

    if self._handleDrag then
        local wx, wy = self:_sToW(x, y)
        self._handleWx = wx
        self._handleWy = wy
        self:_applyHandleDrag()
        -- Fire live callback so coord bar updates every frame
        if self.onRectDragging then
            local key = self.selectedKey
            local idx = self.selectedPtIdx
            local pt = key and self.zones[key] and self.zones[key].points and self.zones[key].points[idx]
            if pt then
                self.onRectDragging(key, idx, math.floor(pt[1]), math.floor(pt[2]), math.floor(pt[3]), math.floor(pt[4]))
            end
        end
        return
    end

    if self._bodyDrag then
        local wx, wy = self:_sToW(x, y)
        self._bodyWx = wx
        self._bodyWy = wy
        self:_applyBodyDrag()
        -- Fire live callback so coord bar updates every frame
        if self.onRectDragging then
            local key = self.selectedKey
            local idx = self.selectedPtIdx
            local pt = key and self.zones[key] and self.zones[key].points and self.zones[key].points[idx]
            if pt then
                self.onRectDragging(key, idx, math.floor(pt[1]), math.floor(pt[2]), math.floor(pt[3]), math.floor(pt[4]))
            end
        end
        return
    end

    -- Hover hit-test (only update if not dragging the map)
    local hk, hidx = self:_hitTest(x, y)
    self.hoverKey = hk
    self.hoverPtIdx = hidx
end

-- Returns true if the event was consumed (prevents forwarding to map)
function MapOverlay:_onMouseUp(widget, x, y)
    if self._drawMode then
        widget:setCapture(false)

        local ds = self._drawStart
        if not ds then
            self:exitDrawMode()
            return true
        end

        -- Check if the drag was large enough to be intentional
        local dx = math.abs(x - ds.sx)
        local dy = math.abs(y - ds.sy)

        if dx >= MIN_DRAW_PX or dy >= MIN_DRAW_PX then
            -- Finalise rect
            local wx2, wy2 = self:_sToW(x, y)
            local x1 = math.floor(math.min(ds.wx, wx2))
            local y1 = math.floor(math.min(ds.wy, wy2))
            local x2 = math.floor(math.max(ds.wx, wx2))
            local y2 = math.floor(math.max(ds.wy, wy2))

            self:exitDrawMode()

            if self.onRectDrawn then
                self.onRectDrawn(x1, y1, x2, y2)
            end
        else
            -- Tiny drag = user changed their mind; cancel
            self:exitDrawMode()
        end

        return true -- always consume in draw mode

    elseif self._handleDrag then
        widget:setCapture(false)

        self:_applyHandleDrag()
        local key = self.selectedKey
        local idx = self.selectedPtIdx
        local z = key and self.zones[key]
        local pt = z and z.points and z.points[idx]

        self._handleDrag = false
        self._handleIdx = nil
        self._handleOrigPt = nil

        if pt and self.onRectResized then
            self.onRectResized(key, idx, math.floor(pt[1]), math.floor(pt[2]), math.floor(pt[3]), math.floor(pt[4]))
        end

        return true

    elseif self._bodyDrag then
        widget:setCapture(false)

        self:_applyBodyDrag()
        local key = self.selectedKey
        local idx = self.selectedPtIdx
        local z = key and self.zones[key]
        local pt = z and z.points and z.points[idx]

        self._bodyDrag = false
        self._bodyOrigPt = nil
        self._bodyStartWx = nil
        self._bodyStartWy = nil

        -- Only fire if the rect actually moved (not just a click on body)
        local moved = pt and (math.abs(self._bodyWx - (self._bodyStartWx or self._bodyWx)) > 0.5 or
                          math.abs(self._bodyWy - (self._bodyStartWy or self._bodyWy)) > 0.5)
        if moved and self.onRectResized then
            self.onRectResized(key, idx, math.floor(pt[1]), math.floor(pt[2]), math.floor(pt[3]), math.floor(pt[4]))
        end

        return true

    else
        -- Normal click: only fire if mouse didn't move much (not a map pan)
        local dx = self._clickStartX and math.abs(x - self._clickStartX) or 999
        local dy = self._clickStartY and math.abs(y - self._clickStartY) or 999
        self._clickStartX = nil
        self._clickStartY = nil

        if dx <= 4 and dy <= 4 then
            local key, idx = self:_hitTest(x, y)
            if key then
                if key == self.selectedKey and idx ~= self.selectedPtIdx then
                    -- Clicked a different rect within the same zone
                    self.selectedPtIdx = idx
                    if self.onPointClicked then
                        self.onPointClicked(key, idx)
                    end
                else
                    -- Clicked a (possibly different) zone
                    if self.onZoneClicked then
                        self.onZoneClicked(key)
                    end
                end
                return false -- let the map also handle (pan stays working)
            end
        end

        return false
    end
end

-- ---------------------------------------------------------------------------
-- Handle helpers
-- ---------------------------------------------------------------------------

-- Returns the 8 handle screen positions for a rect (x1,y1,x2,y2).
-- Order: TL, TC, TR, ML, MR, BL, BC, BR  (matches _applyHandleDrag indices)
function MapOverlay:_handlePoints(x1, y1, x2, y2)
    local mx = math.floor((x1 + x2) / 2)
    local my = math.floor((y1 + y2) / 2)
    return {{
        mx = x1,
        my = y1
    }, -- 1 TL
    {
        mx = mx,
        my = y1
    }, -- 2 TC
    {
        mx = x2,
        my = y1
    }, -- 3 TR
    {
        mx = x1,
        my = my
    }, -- 4 ML
    {
        mx = x2,
        my = my
    }, -- 5 MR
    {
        mx = x1,
        my = y2
    }, -- 6 BL
    {
        mx = mx,
        my = y2
    }, -- 7 BC
    {
        mx = x2,
        my = y2
    } -- 8 BR
    }
end

-- Returns handle index (1-8) if screen point (sx,sy) is within HANDLE_HIT_R
-- of any handle on the given world-space point table entry, or nil.
function MapOverlay:_hitTestHandle(sx, sy, pt)
    local x1, y1, x2, y2 = self:_ptScreenRect(pt)
    local handles = self:_handlePoints(x1, y1, x2, y2)
    for i, h in ipairs(handles) do
        if math.abs(sx - h.mx) <= HANDLE_HIT_R and math.abs(sy - h.my) <= HANDLE_HIT_R then
            return i
        end
    end
    return nil
end

-- Apply the current handle drag world position to the live zone point.
-- Each handle controls which edges move:
--   1=TL(x1,y1)  2=TC(y1)  3=TR(x2,y1)
--   4=ML(x1)              5=MR(x2)
--   6=BL(x1,y2) 7=BC(y2)  8=BR(x2,y2)
function MapOverlay:_applyHandleDrag()
    local key = self.selectedKey
    local idx = self.selectedPtIdx
    local z = key and self.zones[key]
    if not z or not z.points or not z.points[idx] then
        return
    end

    local orig = self._handleOrigPt
    local wx = self._handleWx
    local wy = self._handleWy
    local h = self._handleIdx
    local pt = z.points[idx]

    -- Copy original, then apply axis constraints per handle
    local nx1, ny1, nx2, ny2 = orig[1], orig[2], orig[3], orig[4]

    if h == 1 then
        nx1 = wx;
        ny1 = wy
    elseif h == 2 then
        ny1 = wy
    elseif h == 3 then
        nx2 = wx;
        ny1 = wy
    elseif h == 4 then
        nx1 = wx
    elseif h == 5 then
        nx2 = wx
    elseif h == 6 then
        nx1 = wx;
        ny2 = wy
    elseif h == 7 then
        ny2 = wy
    elseif h == 8 then
        nx2 = wx;
        ny2 = wy
    end

    -- Ensure min size of 1 world unit and keep min < max
    if nx1 > nx2 - 1 then
        nx1 = nx2 - 1
    end
    if ny1 > ny2 - 1 then
        ny1 = ny2 - 1
    end

    pt[1], pt[2], pt[3], pt[4] = nx1, ny1, nx2, ny2
end

-- Translate the active rect by the delta between drag start and current position
function MapOverlay:_applyBodyDrag()
    local key = self.selectedKey
    local idx = self.selectedPtIdx
    local z = key and self.zones[key]
    if not z or not z.points or not z.points[idx] then
        return
    end

    local orig = self._bodyOrigPt
    local dx = (self._bodyWx or 0) - (self._bodyStartWx or 0)
    local dy = (self._bodyWy or 0) - (self._bodyStartWy or 0)
    local pt = z.points[idx]

    pt[1] = orig[1] + dx
    pt[2] = orig[2] + dy
    pt[3] = orig[3] + dx
    pt[4] = orig[4] + dy
end

-- ---------------------------------------------------------------------------
-- Label helper — draws text with a dark background pill for readability
-- regardless of what's behind it on the map.
-- ---------------------------------------------------------------------------
function MapOverlay:_drawLabel(widget, label, x1, y1, x2, y2, col, bold)
    local w = x2 - x1
    local h = y2 - y1
    local lw = getTextManager():MeasureStringX(FONT, label)

    if lw <= w - LABEL_PAD_X * 2 then
        -- Label fits inside rect: centre it
        local lx = x1 + math.floor((w - lw) / 2)
        local ly = y1 + math.floor((h - FONT_HGT) / 2)
        -- Background pill
        local bx = lx - LABEL_PAD_X
        local by = ly - LABEL_PAD_Y
        local bw = lw + LABEL_PAD_X * 2
        local bh = FONT_HGT + LABEL_PAD_Y * 2
        widget:drawRect(bx, by, bw, bh, 0.78, 0.05, 0.05, 0.08)
        widget:drawRectBorder(bx, by, bw, bh, col.a * 0.45, col.r, col.g, col.b)
        widget:drawText(label, lx, ly, col.r, col.g, col.b, col.a, FONT)
    elseif w >= 20 and h >= 20 then
        -- Rect too narrow: draw label outside, above the rect
        local lx = x1 + math.floor((w - lw) / 2)
        -- Clamp so it doesn't go off the left edge of the widget
        lx = math.max(0, lx)
        local ly = y1 - FONT_HGT - LABEL_PAD_Y * 2 - 2
        if ly < 0 then
            ly = y2 + 2
        end -- flip below if no space above
        local bx = lx - LABEL_PAD_X
        local by = ly - LABEL_PAD_Y
        local bw = lw + LABEL_PAD_X * 2
        local bh = FONT_HGT + LABEL_PAD_Y * 2
        widget:drawRect(bx, by, bw, bh, 0.85, 0.05, 0.05, 0.08)
        widget:drawRectBorder(bx, by, bw, bh, col.a * 0.55, col.r, col.g, col.b)
        -- Small tick line connecting label to rect
        local tickX = x1 + math.floor(w / 2)
        widget:drawRect(tickX, math.min(y1, by + bh), 1, math.abs(y1 - (by + bh)), col.a * 0.3, col.r, col.g, col.b)
        widget:drawText(label, lx, ly, col.r, col.g, col.b, col.a, FONT)
    end
    -- Rect smaller than 20px: skip label entirely (too small to matter)
end

-- ---------------------------------------------------------------------------
-- Rendering
-- ---------------------------------------------------------------------------

function MapOverlay:_render(widget)
    local api = widget.mapAPI
    if not api then
        return
    end

    self:_renderZones(widget)
    if self._drawMode and self._drawStart and self._drawCurrent then
        self:_renderDrawPreview(widget)
    end
end

-- Draw all zone rects
function MapOverlay:_renderZones(widget)
    -- Determine draw order: selected zone drawn last so it's on top
    local order = {}
    for key in pairs(self.zones) do
        if key ~= self.selectedKey then
            table.insert(order, key)
        end
    end
    table.sort(order) -- deterministic
    if self.selectedKey and self.zones[self.selectedKey] then
        table.insert(order, self.selectedKey)
    end

    for _, key in ipairs(order) do
        local z = self.zones[key]
        if z and z.points then
            local isSel = (key == self.selectedKey)
            local isHov = (key == self.hoverKey and not isSel)
            local isDis = (z.disabled == true)

            for ptIdx, pt in ipairs(z.points) do
                local x1, y1, x2, y2 = self:_ptScreenRect(pt)
                local w = x2 - x1
                local h = y2 - y1

                -- Skip rects that are too small to see at current zoom
                if w >= 2 and h >= 2 then
                    local isActivePt = isSel and (ptIdx == self.selectedPtIdx)

                    local fill, border, lblCol
                    if isDis then
                        fill, border, lblCol = OC.disFill, OC.disBorder, OC.disLabel
                    elseif isActivePt then
                        fill, border, lblCol = OC.rectFill, OC.rectBorder, OC.selLabel
                    elseif isSel then
                        fill, border, lblCol = OC.selFill, OC.selBorder, OC.selLabel
                    elseif isHov then
                        fill, border, lblCol = OC.hoverFill, OC.hoverBorder, OC.zoneLabel
                    else
                        fill, border, lblCol = OC.zoneFill, OC.zoneBorder, OC.zoneLabel
                    end

                    -- Fill
                    widget:drawRect(x1, y1, w, h, fill.a, fill.r, fill.g, fill.b)

                    -- Border (2px for selected, 1px otherwise)
                    if isSel or isHov then
                        widget:drawRectBorder(x1, y1, w, h, border.a, border.r, border.g, border.b)
                        widget:drawRectBorder(x1 + 1, y1 + 1, w - 2, h - 2, border.a * 0.5, border.r, border.g, border.b)
                    else
                        widget:drawRectBorder(x1, y1, w, h, border.a, border.r, border.g, border.b)
                    end

                    -- Resize handles (corner dots) on the active rect
                    if isActivePt then
                        self:_drawHandles(widget, x1, y1, x2, y2)
                    end

                    -- Label: zone title, drawn once per zone on the first (or selected) rect
                    local showLabel = (ptIdx == 1) or isActivePt
                    if showLabel then
                        local label = z.title or key
                        if isDis then
                            label = "[X] " .. label
                        end
                        self:_drawLabel(widget, label, x1, y1, x2, y2, lblCol, isSel or isActivePt)
                    end
                end
            end
        end
    end
end

-- Corner + midpoint resize handles on the active rect
function MapOverlay:_drawHandles(widget, x1, y1, x2, y2)
    local handles = self:_handlePoints(x1, y1, x2, y2)
    local r, g, b, a = OC.handle.r, OC.handle.g, OC.handle.b, OC.handle.a
    for _, h in ipairs(handles) do
        -- Dark fill so handle is visible over both light and dark map tiles
        widget:drawRect(h.mx - HANDLE_R, h.my - HANDLE_R, HANDLE_R * 2, HANDLE_R * 2, 0.90, 0.06, 0.06, 0.08)
        widget:drawRectBorder(h.mx - HANDLE_R, h.my - HANDLE_R, HANDLE_R * 2, HANDLE_R * 2, a, r, g, b)
    end
end

-- Live preview of the rect being drawn
function MapOverlay:_renderDrawPreview(widget)
    local ds = self._drawStart
    local dc = self._drawCurrent
    if not ds or not dc then
        return
    end

    local x1s, y1s = self:_wToS(ds.wx, ds.wy)
    local x2s, y2s = self:_wToS(dc.wx, dc.wy)
    if x1s > x2s then
        x1s, x2s = x2s, x1s
    end
    if y1s > y2s then
        y1s, y2s = y2s, y1s
    end
    local w = x2s - x1s
    local h = y2s - y1s

    if w < 1 or h < 1 then
        return
    end

    local f = OC.drawFill
    local b = OC.drawBorder
    widget:drawRect(x1s, y1s, w, h, f.a, f.r, f.g, f.b)
    widget:drawRectBorder(x1s, y1s, w, h, b.a, b.r, b.g, b.b)
    widget:drawRectBorder(x1s + 1, y1s + 1, w - 2, h - 2, b.a * 0.4, b.r, b.g, b.b)

    -- Show dimensions in world units while drawing
    local ww = math.abs(math.floor(dc.wx) - math.floor(ds.wx))
    local wh = math.abs(math.floor(dc.wy) - math.floor(ds.wy))
    local dimStr = string.format("%d × %d", ww, wh)
    local dw = getTextManager():MeasureStringX(FONT, dimStr)
    local dx = x1s + math.floor((w - dw) / 2)
    local dy = y1s + math.floor((h - FONT_HGT) / 2)
    if dx >= x1s and dy >= y1s then
        widget:drawText(dimStr, dx + 1, dy + 1, 0, 0, 0, 0.7, FONT)
        widget:drawText(dimStr, dx, dy, b.r, b.g, b.b, 1.0, FONT)
    end

    -- Corner handles while drawing
    self:_drawHandles(widget, x1s, y1s, x2s, y2s)
end

-- ---------------------------------------------------------------------------
return MapOverlay
