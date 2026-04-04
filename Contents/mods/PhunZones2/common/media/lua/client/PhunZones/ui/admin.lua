if isServer() then
    return
end

require "DebugUIs/DebugMenu/ISDebugMenu"
local Core = PhunZones

local function playerHasEditorAccess(player)
    -- Always allow in singleplayer
    if Core.isLocal then
        return true
    end
    local required = Core.getOption("EditorRole", "")
    if not required or required == "" then
        return true
    end
    local role = player and player.getRole and player:getRole()
    local roleName = role and role.getName and role:getName()
    if not roleName or roleName == "" then
        return false
    end
    return roleName:lower() == required:lower()
end

local function showPhunZonesConfigs()
    local player = getPlayer()
    if not playerHasEditorAccess(player) then
        local modal = ISModalDialog:new(0, 0, 300, 150, "Insufficient privileges to open the zone editor.", false, nil,
            nil, nil, nil, nil)
        modal:initialise()
        modal:addToUIManager()
        modal:setX((getCore():getScreenWidth() - modal:getWidth()) / 2)
        modal:setY((getCore():getScreenHeight() - modal:getHeight()) / 2)
        return
    end
    Core.ui.zones.OnOpenPanel(player)
end

local ISDebugMenu_setupButtons = ISDebugMenu.setupButtons;
function ISDebugMenu:setupButtons()
    self:addButtonInfo("PhunZones", showPhunZonesConfigs, "MAIN");
    ISDebugMenu_setupButtons(self);
end

local ISAdminPanelUI_create = ISAdminPanelUI.create;

-- b42
function ISAdminPanelUI:create()

    local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
    local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
    local UI_BORDER_SPACING = 10
    local BUTTON_HGT = FONT_HGT_SMALL + 6

    local btnWid = 200;
    local x = UI_BORDER_SPACING + 1;
    local y = FONT_HGT_MEDIUM + UI_BORDER_SPACING * 2 + 1;

    self.showPhunZonesConfigs = ISButton:new(x, y, btnWid, BUTTON_HGT, "** PhunZones **", self, showPhunZonesConfigs);
    self.showPhunZonesConfigs.internal = "";
    self.showPhunZonesConfigs:initialise();
    self.showPhunZonesConfigs:instantiate();
    self.showPhunZonesConfigs.borderColor = self.buttonBorderColor;
    self:addChild(self.showPhunZonesConfigs);

    ISAdminPanelUI_create(self);

end
