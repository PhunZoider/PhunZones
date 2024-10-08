if not isClient() then
    return
end
PhunZonesWelcome = ISPanel:derive("PhunZonesWelcome");
PhunZonesWelcome.instances = {}
local PhunZones = PhunZones
local PhunRunners = PhunRunners
local sandbox = SandboxVars.PhunZones

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)
local FONT_SCALE = FONT_HGT_SMALL / 14

function PhunZonesWelcome.OnOpenPanel(playerObj, location, oldLocation)
    if sandbox.PhunZones_ShowZoneChange then
        local core = getCore()
        local FONT_SCALE = getTextManager():getFontHeight(UIFont.Small) / 14
        local core = getCore()
        local width = 1 * FONT_SCALE
        local height = 1 * FONT_SCALE
        local x = (core:getScreenWidth() - width) / 2
        local y = ((core:getScreenHeight() - height) / 2) + 200

        local pIndex = playerObj:getPlayerNum()
        local instances = PhunZonesWelcome.instances
        if instances[pIndex] then
            local instance = instances[pIndex]
            if not instance:isVisible() then
                instances[pIndex]:addToUIManager();
                instances[pIndex]:setVisible(true);
            end
            return instance
        end
        PhunZonesWelcome.instances[pIndex] = PhunZonesWelcome:new(x, y - 200, width, height, playerObj, location,
            oldLocation);
        local instance = PhunZonesWelcome.instances[pIndex]
        instance:initialise();
        instance:instantiate();
        instance:addToUIManager();
        triggerEvent(PhunZones.events.OnPhunZoneWelcomeOpened, instance)
        return instance;
    end
end

function PhunZonesWelcome:initialise()
    ISPanel.initialise(self);
end

function PhunZonesWelcome:close()
    self:setVisible(false);
    self:removeFromUIManager();
    PhunZonesWelcome.instances[self.pIndex] = nil
end

function PhunZonesWelcome:render()
    ISPanel.prerender(self);
    if self.location then
        local location = self.location
        if location.title and location.title ~= "PhunZones" then
            -- etf?
            local y = 50
            self:drawTextCentre(location.title or "", self.width / 2, y, 1, 1, 1, self.alphaBits, UIFont.Large);
            y = y + FONT_HGT_LARGE + 10
            if location.subtitle then
                self:drawTextCentre(location.subtitle or "", self.width / 2, y, 1, 1, 1, self.alphaBits, UIFont.Medium);
                y = y + FONT_HGT_MEDIUM + 5
            end

            if PhunRunners then

                if sandbox.PhunZones_Pips then
                    local riskData = PhunZones:getRiskInfo(self.player)

                    if riskData then
                        local colors = {
                            r = 0.4,
                            g = 0.4,
                            b = 0.4,
                            a = 1.0
                        }
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

                        local l = (self.width / 2) - ((riskData.pips * 7) / 2)
                        for i = 1, riskData.pips do
                            self:drawRect(l + ((i - 1) * 7), y, 5, 5, self.alphaBits, colors.r, colors.g, colors.b);
                        end
                    end
                end

            elseif location.difficulty > 0 then
                local l = (self.width / 2) - ((location.difficulty * 25) / 2)
                local s = sandbox

                -- pips
                if sandbox.PhunZones_Pips then
                    for i = 1, self.location.difficulty do
                        self:drawRect(l, y, 20, 10, 255, self.alphaBits, 0.7, 0.7, 0.7);
                        l = l + 25
                    end
                    y = y + 20
                end

                -- PVP
                if (sandbox.PhunZones_ShowPvP and location.pvp == true or location.pvp == false) then
                    local txt = getText("IGUI_PhunZones_PvPOn")
                    local color = {
                        r = 255,
                        g = 1,
                        b = 1
                    }
                    if location.pvp == false then
                        txt = getText("IGUI_PhunZones_PvPOff")
                        color = {
                            r = 1,
                            g = 255,
                            b = 0
                        }
                    end
                    self:drawTextCentre(txt, self.width / 2, y, self.alphaBits, color.r, color.g, color.b, UIFont.small);
                end

            end
        end
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

function PhunZonesWelcome:instantiate()
    ISPanel.instantiate(self)
    self.javaObject:setConsumeMouseEvents(false)
end

function PhunZonesWelcome:new(x, y, width, height, player, location, oldLocation)
    local o = {};
    o = ISPanel:new(x, y, width, height, player);
    setmetatable(o, self);
    self.__index = self;
    o.autoCloseTimestamp = getTimestamp() + (5);
    o.alphaBits = 0
    o.variableColor = {
        r = 0.9,
        g = 0.55,
        b = 0.1,
        a = 1
    };
    o.borderColor = {
        r = 0.0,
        g = 0.0,
        b = 0.0,
        a = 0.0
    };
    o.backgroundColor = {
        r = 0,
        g = 0,
        b = 0,
        a = 0.0
    };
    o.buttonBorderColor = {
        r = 0.7,
        g = 0.7,
        b = 0.7,
        a = 0.5
    };
    o.player = player
    o.pIndex = player:getPlayerNum()
    o.location = location or {}
    o.oldLocation = oldLocation or {}
    o.zOffsetLargeFont = 25;
    o.zOffsetMediumFont = 20;
    o.zOffsetSmallFont = 6;
    o.moveWithMouse = false;
    return o;
end

