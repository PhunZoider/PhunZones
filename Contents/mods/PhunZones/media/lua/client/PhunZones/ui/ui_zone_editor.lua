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
local BUTTON_HGT = FONT_HGT_SMALL + 6
local LABEL_HGT = FONT_HGT_MEDIUM + 6

local profileName = "PhunZonesUIEditor"
PZ.ui.editor = ISPanel:derive(profileName);
PZ.ui.editor.instances = {}
local UI = PZ.ui.editor

function UI.OnOpenPanel(playerObj, data, cb)

    local playerIndex = playerObj:getPlayerNum()

    if not UI.instances[playerIndex] then
        local core = getCore()
        local width = 300 * FONT_SCALE
        local height = 350 * FONT_SCALE

        local x = (core:getScreenWidth() - width) / 2
        local y = (core:getScreenHeight() - height) / 2

        UI.instances[playerIndex] = UI:new(x, y, width, height, playerObj, playerIndex);
        UI.instances[playerIndex]:initialise();
        ISLayoutManager.RegisterWindow(profileName, UI, UI.instances[playerIndex])
    end

    local instance = UI.instances[playerIndex]

    if not data then
        data = {}
    end

    instance:addToUIManager();
    instance:setVisible(true);
    instance.data = {
        region = data.region,
        zone = data.zone,
        enabled = data.enabled ~= false,
        pvp = data.pvp == true,
        title = data.title,
        subtitle = data.subtitle,
        difficulty = data.difficulty,
        mods = data.mods,
        rads = data.rads,
        zeds = data.zeds ~= false,
        bandits = data.bandits ~= false,
        noAnnounce = data.noAnnounce == true,
        rv = data.rv == true,
        order = data.order or ""
    }
    instance.cb = cb

    instance.txtRegion:setText(tostring(instance.data.region or ""))
    instance.txtRegionDisabled:setName(tostring(instance.data.region or ""))

    if data and data.region then
        instance.txtRegion:setVisible(false)
        instance.txtRegionDisabled:setVisible(true)
    else
        instance.txtRegion:setVisible(true)
        instance.txtRegionDisabled:setVisible(false)
    end

    instance.txtZone:setText(tostring(instance.data.zone or "main"))
    instance.txtZoneDisabled:setName(tostring(instance.data.zone or "main"))

    if data and data.zone == "main" then
        instance.txtZone:setVisible(false)
        instance.txtZoneDisabled:setVisible(true)
    else
        instance.txtZone:setVisible(true)
        instance.txtZoneDisabled:setVisible(false)
    end

    instance.chkEnabled:setSelected(1, instance.data.enabled ~= false)
    instance.chkRv:setSelected(1, instance.data.rv == true)
    instance.chkZeds:setSelected(1, instance.data.zeds == true)
    instance.chkBandits:setSelected(1, instance.data.bandits == true)
    instance.chkPvP:setSelected(1, instance.data.pvp == true)
    instance.txtMods:setText(tostring(instance.data.mods or ""))
    instance.txtDifficulty:setText(tostring(instance.data.difficulty or 2))
    instance.txtSubtitle:setText(tostring(instance.data.subtitle or ""))
    instance.txtTitle:setText(tostring(instance.data.title or ""))
    instance.txtRads:setText(tostring(instance.data.rads or ""))
    instance.chkNoAnnounce:setSelected(1, instance.data.noAnnounce == true)
    instance.txtOrder:setText(tostring(instance.data.order or ""))
    return instance;

end

function UI:new(x, y, width, height, player, playerIndex)
    local o = {};
    o = ISPanel:new(x, y, width, height, player);
    setmetatable(o, self);
    self.__index = self;

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
    o.data = {}

    -- o.moveWithMouse = true;
    o.anchorRight = true
    o.anchorBottom = true
    o.player = player
    o.playerIndex = playerIndex
    o.zOffsetLargeFont = 25;
    o.zOffsetMediumFont = 20;
    o.zOffsetSmallFont = 6;
    o:setWantKeyEvents(true)
    return o;
end

function UI:RestoreLayout(name, layout)

    -- ISLayoutManager.DefaultRestoreWindow(self, layout)
    -- if name == profileName then
    --     ISLayoutManager.DefaultRestoreWindow(self, layout)
    --     self.userPosition = layout.userPosition == 'true'
    -- end
    -- self:recalcSize();
end

function UI:SaveLayout(name, layout)
    -- ISLayoutManager.DefaultSaveWindow(self, layout)
    -- if self.userPosition then
    --     layout.userPosition = 'true'
    -- else
    --     layout.userPosition = 'false'
    -- end
end

function UI:close()
    ISPanel.close(self);
    self:setVisible(false);
    self:removeFromUIManager();
    self.instances[self.playerIndex] = nil
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
        if self.onClick then
            self:onClick()
        end
    else
        self.dragging = false
        self:setCapture(false)
    end
    return true
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

function UI:createChildren()
    ISPanel.createChildren(self);

    local x = 10
    local y = 10
    local h = FONT_HGT_MEDIUM

    self.title = ISLabel:new(x, y, h, getText("IGUI_PhunZones_Coordinates"), 1, 1, 1, 1, UIFont.Small, true);
    self.title:initialise();
    self.title:instantiate();
    self:addChild(self.title);

    self.closeButton = ISButton:new(self.width - 25 - x, y, 25, 25, "X", self, function()
        self:close();
    end);
    self.closeButton:initialise();
    self:addChild(self.closeButton);

    y = y + self.closeButton.height + 10

    self.lblRegion = ISLabel:new(x, y, h, getText("IGUI_PhunZones_Region"), 1, 1, 1, 1, UIFont.Small, true);
    self.lblRegion:initialise();
    self.lblRegion:instantiate();
    self:addChild(self.lblRegion);

    self.txtRegionDisabled = ISLabel:new(x + 75, y, h, getText("IGUI_PhunZones_Region"), 1, 1, 1, 1, UIFont.Small, true);
    self.txtRegionDisabled:initialise();
    self.txtRegionDisabled:instantiate();
    self:addChild(self.txtRegionDisabled);

    self.txtRegion = ISTextEntryBox:new("", x + 75, y, 200, h);
    self.txtRegion:initialise();
    self.txtRegion.tooltip = getText("IGUI_PhunZones_Region_tooltip")
    self:addChild(self.txtRegion);

    y = y + h + 10

    self.lblZone = ISLabel:new(x, y, h, getText("IGUI_PhunZones_Zone"), 1, 1, 1, 1, UIFont.Small, true);
    self.lblZone:initialise();
    self.lblZone:instantiate();
    self:addChild(self.lblZone);

    self.txtZoneDisabled = ISLabel:new(x + 75, y, h, getText("IGUI_PhunZones_Zone"), 1, 1, 1, 1, UIFont.Small, true);
    self.txtZoneDisabled:initialise();
    self.txtZoneDisabled:instantiate();
    self:addChild(self.txtZoneDisabled);

    self.txtZone = ISTextEntryBox:new("", x + 75, y, 200, h);
    self.txtZone:initialise();
    self.txtZone.tooltip = getText("IGUI_PhunZones_Zone_tooltip")
    self:addChild(self.txtZone);

    y = y + h + 10

    self.lblTitle = ISLabel:new(x, y, h, getText("IGUI_PhunZones_Title"), 1, 1, 1, 1, UIFont.Small, true);
    self.lblTitle:initialise();
    self.lblTitle:instantiate();
    self:addChild(self.lblTitle);

    self.txtTitle = ISTextEntryBox:new("", x + 75, y, 200, h);
    self.txtTitle:initialise();
    self.txtTitle.tooltip = getText("IGUI_PhunZones_Title_Tooltip")
    self:addChild(self.txtTitle);

    y = y + h + 10

    self.lblSubtitle = ISLabel:new(x, y, h, getText("IGUI_PhunZones_Subtitle"), 1, 1, 1, 1, UIFont.Small, true);
    self.lblSubtitle:initialise();
    self.lblSubtitle:instantiate();
    self:addChild(self.lblSubtitle);

    self.txtSubtitle = ISTextEntryBox:new("", x + 75, y, 200, h);
    self.txtSubtitle.tooltip = getText("IGUI_PhunZones_Subtitle_tooltip")
    self.txtSubtitle:initialise();

    self:addChild(self.txtSubtitle);

    y = y + h + 10

    self.lblDifficulty = ISLabel:new(x, y, h, getText("IGUI_PhunZones_Difficulty"), 1, 1, 1, 1, UIFont.Small, true);
    self.lblDifficulty:initialise();
    self.lblDifficulty:instantiate();
    self:addChild(self.lblDifficulty);

    self.txtDifficulty = ISTextEntryBox:new("", x + 75, y, 200, h);
    self.txtDifficulty:initialise();
    self.txtDifficulty.tooltip = getText("IGUI_PhunZones_Difficulty_tooltip")
    self:addChild(self.txtDifficulty);

    y = y + h + 10

    self.lblRads = ISLabel:new(x, y, h, getText("IGUI_PhunZones_Rads"), 1, 1, 1, 1, UIFont.Small, true);
    self.lblRads:initialise();
    self.lblRads:instantiate();
    self:addChild(self.lblRads);

    self.txtRads = ISTextEntryBox:new("", x + 75, y, 200, h);
    self.txtRads:initialise();
    self.txtRads.tooltip = getText("IGUI_PhunZones_Rads_tooltip")
    self:addChild(self.txtRads);

    y = y + h + 10

    self.lblMods = ISLabel:new(x, y, h, getText("IGUI_PhunZones_Mods"), 1, 1, 1, 1, UIFont.Small, true);
    self.lblMods:initialise();
    self.lblMods:instantiate();
    self:addChild(self.lblMods);

    self.txtMods = ISTextEntryBox:new("", x + 75, y, 200, h);
    self.txtMods:initialise();
    self.txtMods.tooltip = getText("IGUI_PhunZones_Mods_tooltip")
    self:addChild(self.txtMods);

    y = y + h + 10

    self.chkPvP = ISTickBox:new(x, y, BUTTON_HGT, BUTTON_HGT, getText("IGUI_PhunZones_PvP"), self)
    self.chkPvP:addOption(getText("IGUI_PhunZones_PvP"), nil)
    self.chkPvP:setSelected(1, true)
    self.chkPvP:setWidthToFit()
    self.chkPvP:setY(y)
    self.chkPvP.tooltip = getText("IGUI_PhunZones_PvP_tooltip")
    self:addChild(self.chkPvP)

    -- y = y + h + 10

    self.chkZeds = ISTickBox:new(self.width / 2, y, BUTTON_HGT, BUTTON_HGT, getText("IGUI_PhunZones_Zeds"), self)
    self.chkZeds:addOption(getText("IGUI_PhunZones_Zeds"), nil)
    self.chkZeds:setSelected(1, true)
    self.chkZeds:setWidthToFit()
    self.chkZeds:setY(y)
    self.chkZeds.tooltip = getText("IGUI_PhunZones_Zeds_tooltip")
    self:addChild(self.chkZeds)

    y = y + h + 10

    self.chkBandits = ISTickBox:new(x, y, BUTTON_HGT, BUTTON_HGT, getText("IGUI_PhunZones_Bandits"), self)
    self.chkBandits:addOption(getText("IGUI_PhunZones_Bandits"), nil)
    self.chkBandits:setSelected(1, true)
    self.chkBandits:setWidthToFit()
    self.chkBandits:setY(y)
    self.chkBandits.tooltip = getText("IGUI_PhunZones_Bandits_tooltip")
    self:addChild(self.chkBandits)

    -- y = y + h + 10

    self.chkRv = ISTickBox:new(self.width / 2, y, BUTTON_HGT, BUTTON_HGT, getText("IGUI_PhunZones_RVInteriors"), self)
    self.chkRv:addOption(getText("IGUI_PhunZones_RVInteriors"), nil)
    self.chkRv:setSelected(1, true)
    self.chkRv:setWidthToFit()
    self.chkRv:setY(y)
    self.chkRv.tooltip = getText("IGUI_PhunZones_RVInteriors_tooltip")
    self:addChild(self.chkRv)

    y = y + h + 10

    self.chkNoAnnounce = ISTickBox:new(x, y, BUTTON_HGT, BUTTON_HGT, getText("IGUI_PhunZones_NoWelcome"), self)
    self.chkNoAnnounce:addOption(getText("IGUI_PhunZones_NoWelcome"), nil)
    self.chkNoAnnounce:setSelected(1, true)
    self.chkNoAnnounce:setWidthToFit()
    self.chkNoAnnounce:setY(y)
    self.chkNoAnnounce.tooltip = getText("IGUI_PhunZones_NoWelcome_tooltip")
    self:addChild(self.chkNoAnnounce)

    -- y = y + h + 10

    self.chkEnabled = ISTickBox:new(self.width / 2, y, BUTTON_HGT, BUTTON_HGT, getText("IGUI_PhunZones_Enabled"), self)
    self.chkEnabled:addOption(getText("IGUI_PhunZones_Enabled"), nil)
    self.chkEnabled:setSelected(1, true)
    self.chkEnabled:setWidthToFit()
    self.chkEnabled:setY(y)
    self.chkEnabled.tooltip = getText("IGUI_PhunZones_Enabled_tooltip")
    self:addChild(self.chkEnabled)

    y = y + h + 10

    self.lblOrder = ISLabel:new(x, y, h, getText("IGUI_PhunZones_Order"), 1, 1, 1, 1, UIFont.Small, true);
    self.lblOrder:initialise();
    self.lblOrder:instantiate();
    self:addChild(self.lblOrder);

    self.txtOrder = ISTextEntryBox:new("", x + 75, y, 200, h);
    self.txtOrder:initialise();
    self.txtOrder.tooltip = getText("IGUI_PhunZones_Order_tooltip")
    self:addChild(self.txtOrder);

    y = y + h + 10

    -- x = self.btnXY2Set.x + self.btnXY2Set.width + 10

    self.save = ISButton:new(x, y, 80, h, getText("UI_btn_save"), self, function()

        local data = {
            region = self.txtRegion:getText(),
            zone = self.txtZone:getText()
        }

        if self.chkPvP:isSelected(1) then
            data.pvp = true
        end
        if self.txtTitle:getText() ~= "" then
            data.title = self.txtTitle:getText()
        end
        if self.txtSubtitle:getText() ~= "" then
            data.subtitle = self.txtSubtitle:getText()
        end
        if self.txtDifficulty:getText() ~= "" then
            data.difficulty = tonumber(self.txtDifficulty:getText())
        end
        if self.txtMods:getText() ~= "" then
            data.mods = self.txtMods:getText()
        end
        if not self.chkZeds:isSelected(1) then
            data.zeds = false
        end
        if not self.chkBandits:isSelected(1) then
            data.bandits = false
        end
        if not self.chkEnabled:isSelected(1) then
            data.enabled = false
        end
        if self.chkRv:isSelected(1) then
            data.rv = false
        end
        if not self.chkNoAnnounce:isSelected(1) then
            data.noAnnounce = true
        end
        if self.txtOrder:getText() ~= "" then
            data.txtOrder = tonumber(self.txtOrder:getText())
        end
        if self.cb then
            self.cb(data)
        end
        self:close()
    end);
    self.save.internal = "SAVE";
    self.save:initialise();
    self:addChild(self.save);

end

function UI:setData(data)

end

function UI:prerender()

    ISPanel.prerender(self);

end

--[[

    Keyboad stuff

]] -- ]   

function UI:isKeyConsumed(key)
    return key == Keyboard.KEY_ESCAPE
end

function UI:onKeyRelease(key)
    if key == Keyboard.KEY_ESCAPE then
        self:close()
    end
end
