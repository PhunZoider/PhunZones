if isServer() then
    return
end
require "DebugUIs/DebugMenu/ISDebugMenu"
local Core = PhunZones

local function showPhunZonesConfigs()
    if isAdmin() or isDebugEnabled() then
        Core.ui.zones.OnOpenPanel(getPlayer());
    end
end

local ISDebugMenu_setupButtons = ISDebugMenu.setupButtons;
function ISDebugMenu:setupButtons()
    self:addButtonInfo("PhunZones", showPhunZonesConfigs, "MAIN");
    ISDebugMenu_setupButtons(self);
end

local ISAdminPanelUI_create = ISAdminPanelUI.create;
function ISAdminPanelUI:create()
    ISAdminPanelUI_create(self);
    local fontHeight = getTextManager():getFontHeight(UIFont.Small);
    local btnWid = 150;
    local btnHgt = math.max(25, fontHeight + 3 * 2);
    local btnGapY = 5;

    local lastButton = self.children[self.IDMax - 1];
    lastButton = lastButton.internal == "CANCEL" and self.children[self.IDMax - 2] or lastButton;

    self.showPhunZonesConfigs = ISButton:new(lastButton.x, lastButton.y + 5 + lastButton.height,
        self.sandboxOptionsBtn.width, self.sandboxOptionsBtn.height, "PhunZones", self, showPhunZonesConfigs);
    self.showPhunZonesConfigs.internal = "";
    self.showPhunZonesConfigs:initialise();
    self.showPhunZonesConfigs:instantiate();
    self.showPhunZonesConfigs.borderColor = self.buttonBorderColor;
    self:addChild(self.showPhunZonesConfigs);
end
