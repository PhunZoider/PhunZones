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

local profielName = "PhunZonesUIWelcome"
PZ.ui.welcome = ISPanel:derive(profielName);
PZ.ui.welcome.instances = {}
local UI = PZ.ui.welcome

function UI.OnOpenPanel(playerObj, zone)

    local playerIndex = playerIndex or playerObj:getPlayerNum()
    local instance = UI.instances[playerIndex]
    if not instance then
        local core = getCore()
        local FONT_SCALE = getTextManager():getFontHeight(UIFont.Small) / 14
        local width = 1
        local height = 1

        local x = core:getScreenWidth() / 2
        local y = core:getScreenHeight() / 3

        instance = UI:new(x, y, width, height, playerObj, playerIndex);
        instance:initialise();

        UI.instances[playerIndex] = instance
    end
    instance:addToUIManager();
    instance:setVisible(true);
    instance.javaObject:setConsumeMouseEvents(false)
    instance.alphaBits = 0
    instance.autoCloseTimestamp = getTimestamp() + 5;
    instance.zone = zone;

    return instance;

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
    o.alphaBits = 0
    o.autoCloseTimestamp = getTimestamp() + 5;
    -- o.moveWithMouse = true;
    o.anchorRight = true
    o.anchorBottom = true
    o.player = player
    o.playerIndex = playerIndex
    o.zOffsetLargeFont = 25;
    o.zOffsetMediumFont = 20;
    o.zOffsetSmallFont = 6;
    -- o:setWantKeyEvents(true)
    o.pvpOnTexture = getTexture("media/ui/pvpicon_on.png")
    return o;
end

function UI:close()
    ISPanel.close(self);
    self:removeFromUIManager();
    UI.instances[self.playerIndex] = nil
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

function UI:render()
    ISPanel.render(self);
    local title = self.zone.noAnnounce ~= true and self.zone.title or nil
    local subtitle = self.zone.noAnnounce ~= true and self.zone.title and self.zone.subtitle or nil

    if not title then
        self:close()
    end

    local y = 50
    self:drawTextCentre(title or "", self.width / 2, y, 1, 1, 1, self.alphaBits, UIFont.Large);
    y = y + FONT_HGT_LARGE + 10
    if subtitle then
        self:drawTextCentre(subtitle or "", self.width / 2, y, 1, 1, 1, self.alphaBits, UIFont.Medium);
        y = y + FONT_HGT_MEDIUM + 5
    end
    if getTimestamp() > self.autoCloseTimestamp then
        self.alphaBits = self.alphaBits - 0.05
        if self.alphaBits <= 0 then
            self:close()
        end
    else
        self.alphaBits = self.alphaBits + 0.05
        if self.alphaBits >= 1 then
            self.alphaBits = 1
        end
    end
end
