if isServer() then
    return
end

local Core = PhunZones
Core.ui = Core.ui or {}

local getTimestamp = getTimestamp
local getTextManager = getTextManager
local getCore = getCore

-- =========================================================
-- UI: Welcome Marquee (B42+)
-- - Non-interactive (won't consume mouse / keys)
-- - Per-player instance safe (split-screen)
-- - Fade in -> hold -> fade up & out (FPS-independent)
-- =========================================================

local profileName = "PhunZonesUIWelcome"
Core.ui.welcome = ISPanel:derive(profileName)

local UI = Core.ui.welcome
UI.instances = UI.instances or {}

-- Cache last shown title/subtitle per player (avoid table ref mutation)
local lastValuesByPlayer = {}

-- Font heights
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)

-- Tunables (feel free to tweak)
local FADE_IN_SEC = 0.20
local HOLD_SEC = 3.00
local FADE_OUT_SEC = 0.70
local FLOAT_PX_TOTAL = 32
local TOP_Y = 50

-- Frame-time helper (B42+)
local function getDT()
    local ms = (UIManager and UIManager.getMillisSinceLastRender and UIManager.getMillisSinceLastRender()) or 16
    local dt = ms / 1000
    if dt < 0 then
        dt = 0
    end
    if dt > 0.1 then
        dt = 0.1
    end -- clamp hitch spikes
    return dt
end

function UI.OnOpenPanel(playerObj, zone)
    if not Core.settings or not Core.settings.ShowZoneChange then
        return
    end
    if not playerObj or not zone then
        return
    end
    if zone.Announce == false then
        return
    end

    local title = zone.title
    local subtitle = zone.subtitle

    if not title or title == "" then
        return
    end

    local playerIndex = playerObj:getPlayerNum()

    -- Prevent re-showing identical content
    local existing = lastValuesByPlayer[playerIndex]
    if existing and title == existing.title and subtitle == existing.subtitle then
        return
    end
    lastValuesByPlayer[playerIndex] = {
        title = title,
        subtitle = subtitle
    }

    local instance = UI.instances[playerIndex]
    local core = getCore()

    if not instance then
        -- Full-width, shallow height panel for correct coordinate space
        local w = core:getScreenWidth()
        local h = TOP_Y + FONT_HGT_LARGE + FONT_HGT_MEDIUM + 30

        instance = UI:new(0, 0, w, h, playerObj, playerIndex)
        instance:initialise()
        instance:instantiate() -- REQUIRED in B42+ to create javaObject

        -- Ensure it never steals input
        if instance.javaObject then
            instance.javaObject:setConsumeMouseEvents(false)
        end

        UI.instances[playerIndex] = instance
    else
        -- Handle resolution / UI scale changes
        local w = core:getScreenWidth()
        local h = TOP_Y + FONT_HGT_LARGE + FONT_HGT_MEDIUM + 30
        instance:setX(0)
        instance:setY(0)
        instance:setWidth(w)
        instance:setHeight(h)

        -- Belt + braces
        if instance.javaObject then
            instance.javaObject:setConsumeMouseEvents(false)
        end
    end

    -- Reset animation state
    instance.zoneTitle = title
    instance.zoneSubtitle = subtitle

    instance.startTs = getTimestamp()
    instance.alpha = 0
    instance.floatY = 0

    instance:addToUIManager()
    instance:setVisible(true)

    return instance
end

function UI:new(x, y, width, height, player, playerIndex)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    -- Invisible panel; text only
    o.borderColor = {
        r = 0,
        g = 0,
        b = 0,
        a = 0
    }
    o.backgroundColor = {
        r = 0,
        g = 0,
        b = 0,
        a = 0
    }

    o.player = player
    o.playerIndex = playerIndex

    o.zoneTitle = nil
    o.zoneSubtitle = nil

    o.startTs = 0
    o.alpha = 0
    o.floatY = 0

    return o
end

function UI:close()
    ISPanel.close(self)
    self:removeFromUIManager()
    UI.instances[self.playerIndex] = nil
end

function UI:prerender()
    -- Keep it non-interactive even if something changes upstream
    if self.javaObject then
        self.javaObject:setConsumeMouseEvents(false)
    end
    ISPanel.prerender(self)
end

function UI:render()
    ISPanel.render(self)

    if not self.zoneTitle then
        self:close()
        return
    end

    local now = getTimestamp()
    local dt = getDT()

    -- Phase boundaries
    local fadeInEnd = self.startTs + FADE_IN_SEC
    local holdEnd = fadeInEnd + HOLD_SEC
    local fadeOutEnd = holdEnd + FADE_OUT_SEC

    -- Fade in -> hold -> fade out + float up
    if now < self.startTs then
        self.alpha = 0

    elseif now < fadeInEnd then
        local t = (now - self.startTs) / FADE_IN_SEC
        if t < 0 then
            t = 0
        end
        if t > 1 then
            t = 1
        end
        self.alpha = t
        self.floatY = 0

    elseif now < holdEnd then
        self.alpha = 1
        self.floatY = 0

    elseif now < fadeOutEnd then
        local t = (fadeOutEnd - now) / FADE_OUT_SEC -- 1 -> 0
        if t < 0 then
            t = 0
        end
        if t > 1 then
            t = 1
        end
        self.alpha = t

        local floatRate = FLOAT_PX_TOTAL / FADE_OUT_SEC
        self.floatY = math.min(FLOAT_PX_TOTAL, self.floatY + floatRate * dt)

    else
        self.alpha = 0
        self:close()
        return
    end

    -- Draw (panel-relative)
    local centerX = self.width / 2
    local y = TOP_Y - self.floatY

    self:drawTextCentre(self.zoneTitle, centerX, y, 1, 1, 1, self.alpha, UIFont.Large)
    y = y + FONT_HGT_LARGE + 1

    if self.zoneSubtitle and self.zoneSubtitle ~= "" then
        self:drawTextCentre(self.zoneSubtitle, centerX, y, 1, 1, 1, self.alpha, UIFont.Medium)
    end
end
