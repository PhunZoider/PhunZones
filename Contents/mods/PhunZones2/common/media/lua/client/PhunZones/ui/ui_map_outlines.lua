-- ui_map_outlines.lua
-- Draws zones on the player's world map and minimap, using each zone's
-- mapBorder / mapFill / mapOpacity. A zone with neither colour set is not drawn.
--
-- The admin editor's map is an ISMiniMapInner too; it sets phunZonesNoOutlines
-- because it draws zones itself.
if isServer() then
    return
end

require("ISUI/Maps/ISMiniMap")
require("ISUI/Maps/ISWorldMap")

local Core = PhunZones

local DEFAULT_OPACITY = 30 -- fill opacity (percent) when a fill is set without one

-- Zones to draw, rebuilt whenever the zone data is. Each entry:
-- { rects = zone.points, border = {r,g,b} | nil, fill = {r,g,b,a} | nil }
local drawList = {}

local function rebuild()
    drawList = {}
    local lookup = Core.data and Core.data.lookup
    if not lookup then
        return
    end
    for key, zone in pairs(lookup) do
        if key ~= "_default" and zone.points and #zone.points > 0 then
            local entry = {
                rects = zone.points
            }
            local r, g, b = Core.parseColour(zone.mapBorder)
            if r then
                entry.border = {r, g, b}
            end
            r, g, b = Core.parseColour(zone.mapFill)
            if r then
                local opacity = tonumber(zone.mapOpacity) or DEFAULT_OPACITY
                local a = math.max(0, math.min(100, opacity)) / 100
                if a > 0 then
                    entry.fill = {r, g, b, a}
                end
            end
            if entry.border or entry.fill then
                -- Lowest order first, so the zone that wins an overlap is drawn on top
                entry.order = zone.order or 0
                table.insert(drawList, entry)
            end
        end
    end
    table.sort(drawList, function(a, b)
        return a.order < b.order
    end)
end

Events[Core.events.OnDataBuilt].Add(rebuild)

-- Draws every outlined zone onto a map UI element (anything with a mapAPI).
-- Corners are projected individually, so this is right in isometric view too.
local function drawZones(ui)
    if #drawList == 0 then
        return
    end
    local api = ui.mapAPI
    if not api then
        return
    end

    local w, h = ui:getWidth(), ui:getHeight()

    for _, entry in ipairs(drawList) do
        local fill, border = entry.fill, entry.border
        for _, rect in ipairs(entry.rects) do
            -- +1: a rect's far edge is inclusive (see Core.getLocation)
            local x1, y1, x2, y2 = rect[1], rect[2], rect[3] + 1, rect[4] + 1
            local ax, ay = api:worldToUIX(x1, y1), api:worldToUIY(x1, y1)
            local bx, by = api:worldToUIX(x2, y1), api:worldToUIY(x2, y1)
            local cx, cy = api:worldToUIX(x2, y2), api:worldToUIY(x2, y2)
            local dx, dy = api:worldToUIX(x1, y2), api:worldToUIY(x1, y2)

            local minX, maxX = math.min(ax, bx, cx, dx), math.max(ax, bx, cx, dx)
            local minY, maxY = math.min(ay, by, cy, dy), math.max(ay, by, cy, dy)
            if maxX >= 0 and minX <= w and maxY >= 0 and minY <= h then
                if fill then
                    ui:drawTextureAllPoint(nil, ax, ay, bx, by, cx, cy, dx, dy, fill[1], fill[2], fill[3], fill[4])
                end
                if border then
                    local r, g, b = border[1], border[2], border[3]
                    ui:drawLine2(ax, ay, bx, by, 1, r, g, b)
                    ui:drawLine2(bx, by, cx, cy, 1, r, g, b)
                    ui:drawLine2(cx, cy, dx, dy, 1, r, g, b)
                    ui:drawLine2(dx, dy, ax, ay, 1, r, g, b)
                end
            end
        end
    end
end

-- prerender runs after the engine has drawn the map but before child
-- elements (buttons, symbol palette), so outlines sit on the map under the UI.
local origWorldPrerender = ISWorldMap.prerender
function ISWorldMap:prerender()
    origWorldPrerender(self)
    drawZones(self)
end

local origMiniPrerender = ISMiniMapInner.prerender
function ISMiniMapInner:prerender()
    origMiniPrerender(self)
    if self.phunZonesNoOutlines or #drawList == 0 then
        return
    end
    -- The minimap is small and the map behind it isn't clipped for us
    self:setStencilRect(0, 0, self:getWidth(), self:getHeight())
    drawZones(self)
    self:clearStencilRect()
end

-- The data may already have been built before this file loaded
rebuild()
