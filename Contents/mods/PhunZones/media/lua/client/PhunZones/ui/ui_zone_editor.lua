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
PZ.ui.editor = ISCollapsableWindowJoypad:derive(profileName);
PZ.ui.editor.instances = {}
local UI = PZ.ui.editor

function UI.OnOpenPanel(playerObj, data, cb)

    local playerIndex = playerObj:getPlayerNum()

    local core = getCore()
    local width = 300 * FONT_SCALE
    local height = 350 * FONT_SCALE

    local x = (core:getScreenWidth() - width) / 2
    local y = (core:getScreenHeight() - height) / 2

    -- UI.instances[playerIndex] = UI:new(x, y, width, height, playerObj, playerIndex);
    -- UI.instances[playerIndex]:initialise();
    local instance = UI:new(x, y, width, height, playerObj, playerIndex);
    instance:initialise();
    ISLayoutManager.RegisterWindow(profileName, UI, instance)

    if not data then
        data = {}
    end

    instance:addToUIManager();
    instance:setVisible(true);

    instance.data = {}
    for k, v in pairs(PZ.fields) do
        if v.type == "string" or v.type == "int" then
            instance.data[k] = data[k] or ""
            instance.controls[k]:setText(tostring(instance.data[k]))

            if v.disableOnEdit then
                instance.controls["_" .. k]:setName(tostring(instance.data[k]))
                if (k == "zone" and instance.data[k] == "main") or (k ~= "zone" and tostring(instance.data[k]) ~= "") then
                    instance.controls[k]:setVisible(false)
                    instance.controls["_" .. k]:setVisible(true)
                else
                    instance.controls[k]:setVisible(true)
                    instance.controls["_" .. k]:setVisible(false)
                end
            end
        elseif v.type == "combo" then
            instance.data[k] = data[k] or ""
            if instance.data[k] ~= "" then
                for i = 1, #instance.controls[k].options do
                    if instance.controls[k].options[i] == instance.data[k] then
                        instance.controls[k].selected = i
                        break
                    end
                end
            else
                -- instance.controls[k]:setSelected(-1)
            end
        elseif v.type == "boolean" then
            instance.data[k] = v.trueIsNil and data[k] == nil or data[k] == true
            instance.controls[k]:setSelected(1, instance.data[k] == true)
        elseif v.type == "button" then
            instance.data[k] = data[k] or ""
            instance.controls[k].tooltip = getTextOrNull(v.tooltip) or v.tooltip or ""
            if not instance.data.region or instance.data.region == "" then
                instance.controls[k]:setEnable(false)
                if v.disabledOnNewToolTip then
                    instance.controls[k].tooltip = getTextOrNull(v.disabledOnNewToolTip)
                end
            else
                instance.controls[k]:setEnable(true)
            end
        end
    end

    if data.isDefault then
        instance.data.isDefault = true
        instance.title = "Global Defaults"
        instance.controls.region:setVisible(false)
        instance.controls._region:setName("Global Defaults")
        instance.controls._region:setVisible(true)
        instance.controls.zone:setVisible(false)
        instance.controls._zone:setName("    -    ")
    else
        instance.title = (instance.data.region or "New Zone") .. " - " .. (instance.data.zone or "")
        -- self.controls.region:setVisible(true)
        -- self.controls.zone:setVisible(true)
    end
    instance.cb = cb

    return instance;

end

function UI:new(x, y, width, height, player, playerIndex)
    local o = {};
    o = ISCollapsableWindowJoypad:new(x, y, width, height, player);
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

function UI:close()
    ISCollapsableWindowJoypad.close(self);
    self:setVisible(false);
    self:removeFromUIManager();
    self.instances[self.playerIndex] = nil
end

function UI:createChildren()
    ISCollapsableWindowJoypad.createChildren(self);

    local offset = 10
    local x = offset
    local y = HEADER_HGT
    local h = FONT_HGT_MEDIUM

    self.controls = {}
    self.controls._panel = ISPanel:new(x, y, self.width - self.scrollwidth - offset * 2,
        self.height - y - 10 - BUTTON_HGT - offset);
    self.controls._panel:initialise();
    self.controls._panel:instantiate();
    self.controls._panel:setAnchorRight(true)
    self.controls._panel:setAnchorLeft(true)
    self.controls._panel:setAnchorTop(true)
    self.controls._panel:setAnchorBottom(true)
    self.controls._panel:addScrollBars()
    self.controls._panel.vscroll:setVisible(true)
    self.controls._panel.prerender = function(s)
        s:setStencilRect(0, 0, s.width, s.height);
        ISPanel.prerender(s)
    end
    self.controls._panel.render = function(s)
        ISPanel.render(s)
        s:clearStencilRect()
    end
    self.controls._panel.onMouseWheel = function(s, del)
        if s:getScrollHeight() > 0 then
            s:setYScroll(s:getYScroll() - (del * 40))
            return true
        end
        return false
    end

    self:addChild(self.controls._panel);

    for k, v in pairs(PZ.fields) do

        if v.initialize then
            v.initialize(self, self.data, self.player)
        end

        if v.type == "string" or v.type == "int" then
            local label = ISLabel:new(x, y, h, getTextOrNull(v.label) or v.label or k, 1, 1, 1, 1, UIFont.Small, true);
            label:initialise();
            label:instantiate();
            self.controls["label_" .. k] = label
            self.controls._panel:addChild(label);

            self.controls[k] = ISTextEntryBox:new("", x + 150, y, 125, h);
            self.controls[k]:initialise();
            self.controls[k].tooltip = getTextOrNull(v.tooltip) or v.tooltip or ""
            self.controls._panel:addChild(self.controls[k]);

            if v.disableOnEdit then
                local label = ISLabel:new(x + 150, y, h, getTextOrNull(v.label) or v.label or k, 1, 1, 1, 1,
                    UIFont.Small, true);
                label:initialise();
                label:instantiate();
                self.controls["_" .. k] = label
                self.controls._panel:addChild(label);
            end
        elseif v.type == "combo" then
            local label = ISLabel:new(x, y, h, getTextOrNull(v.label) or v.label or k, 1, 1, 1, 1, UIFont.Small, true);
            label:initialise();
            label:instantiate();
            self.controls["label_" .. k] = label
            self.controls._panel:addChild(label);
            self.controls[k] = ISComboBox:new(x + 150, y, 125, h, self, nil);
            self.controls[k]:initialise();
            if v.getOptions then
                local options = v.getOptions()
                for _, opt in ipairs(options or {}) do
                    self.controls[k]:addOption(opt)
                end
            end
            self.controls[k].tooltip = getTextOrNull(v.tooltip) or v.tooltip or ""
            self.controls._panel:addChild(self.controls[k]);
        elseif v.type == "boolean" then
            self.controls[k] = ISTickBox:new(x, y, BUTTON_HGT, BUTTON_HGT, getTextOrNull(v.label) or v.label or k, self)
            self.controls[k]:addOption(getTextOrNull(v.label) or v.label or k, nil)
            self.controls[k]:setSelected(1, true)
            self.controls[k]:setWidthToFit()
            self.controls[k]:setY(y)
            self.controls[k].tooltip = getTextOrNull(v.tooltip) or v.tooltip or ""
            self.controls._panel:addChild(self.controls[k])
        elseif v.type == "button" then
            local label = ISLabel:new(x, y, h, getTextOrNull(v.label) or v.label or k, 1, 1, 1, 1, UIFont.Small, true);
            label:initialise();
            label:instantiate();
            self.controls["label_" .. k] = label
            self.controls._panel:addChild(label);
            self.controls[k] = ISButton:new(x + 150, y, 125, BUTTON_HGT, "...", self, function()
                if v.onClick then
                    v.onClick(self, self.data, self.player)
                end
            end);
            self.controls[k].internal = k;
            self.controls[k]:initialise();
            self.controls[k].tooltip = getTextOrNull(v.tooltip) or v.tooltip or ""
            self.controls._panel:addChild(self.controls[k]);

        end

        y = y + h + 10

    end
    self.controls._panel:setScrollHeight(y + h + 10);
    self.controls._panel:setScrollChildren(true)

    self.controls._save = ISButton:new(x, self.height - BUTTON_HGT - offset, self.width - offset * 2, BUTTON_HGT,
        getText("UI_btn_save"), self, function(target)

            local data = {}

            for k, v in pairs(PZ.fields) do
                if v.type == "string" then
                    local text = self.controls[k]:getText()
                    if text ~= "" then
                        data[k] = text
                    else
                        data[k] = nil
                    end
                elseif v.type == "int" then
                    local text = self.controls[k]:getText():gsub("%D", "")
                    if text ~= "" then
                        data[k] = tonumber(text)
                    else
                        data[k] = nil
                    end
                elseif v.type == "combo" then
                    data[k] = self.controls[k].selected > 0 and self.controls[k].options[self.controls[k].selected] or
                                  nil
                elseif v.type == "boolean" then
                    data[k] = self.controls[k]:isSelected(1)
                    -- if self.controls[k]:isSelected(1) then
                    --     if v.trueIsNil then
                    --         data[k] = nil
                    --     else
                    --         data[k] = true
                    --     end
                    -- else
                    --     if v.trueIsNil then
                    --         data[k] = false
                    --     else
                    --         data[k] = nil
                    --     end
                    -- end
                end
            end

            if self.cb then
                local originalData = target.data
                -- if originalData.region then
                --     data.region = self.data.region
                -- end
                -- if self.data.zone then
                --     data.zone = self.data.zone
                -- end
                if originalData.isDefault then
                    data.isDefault = true
                    data.region = "_default"
                    data.zone = "main"
                end
                self.cb(data)
            end
            self:close()
        end);
    self.controls._save.internal = "SAVE";
    self.controls._save:initialise();
    self:addChild(self.controls._save);

end

function UI:setData(data)

end

function UI:prerender()
    ISCollapsableWindowJoypad.prerender(self)
    local offset = 10
    self.controls._panel:setWidth(self.width - self.scrollwidth - offset * 2)
    self.controls._panel:setHeight(self.controls._save.y - self:titleBarHeight() - offset * 2)
    self.controls._panel:updateScrollbars();
    -- self.controls._save:setX(self.width - self.scrollwidth - 80 - offset)
    self.controls._save:setX(offset)
    self.controls._save:setY(self.height - BUTTON_HGT - offset)
    self.controls._save:setWidth(self.width - offset * 2)
end

function UI:render()
    ISCollapsableWindowJoypad.render(self)
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
