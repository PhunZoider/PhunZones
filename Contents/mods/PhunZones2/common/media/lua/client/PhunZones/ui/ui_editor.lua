-- ui_editor.lua
-- Standalone data editor window for PhunZones export / import.
-- Provides a multiline text editor for the custom ModData layer,
-- allowing copy/paste sharing and direct Lua editing.
if isServer() then
    return
end

local Core = PhunZones

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local BUTTON_HGT = FONT_HGT_SMALL + 6

local profileName = "PhunZonesConfigEditor"
Core.ui.configEditor = ISCollapsableWindowJoypad:derive(profileName)
Core.ui.configEditor.instances = {}
local UI = Core.ui.configEditor

-- ===========================================================================
-- SERIALISATION / VALIDATION
-- ===========================================================================

function UI:buildExportString()
    local md = ModData.getOrCreate(Core.const.modifiedModData)
    return "return " .. Core.tools.tableToString(md) .. "\n"
end

function UI:parseImportString(src)
    local stripped = src:match("^%s*(.-)%s*$")
    if not stripped:match("^return%s") then
        return nil, "Import must start with 'return { ... }'"
    end

    local fn, err = loadstring(src)
    if not fn then
        return nil, "Lua syntax error:\n" .. tostring(err)
    end
    setfenv(fn, {})
    local ok, result = pcall(fn)
    if not ok then
        return nil, "Runtime error:\n" .. tostring(result)
    end
    if type(result) ~= "table" then
        return nil, "Expected a table, got " .. type(result)
    end

    for k, v in pairs(result) do
        if type(k) ~= "string" then
            return nil, "Zone keys must be strings, got " .. type(k)
        end
        if type(v) ~= "table" then
            return nil, "Zone '" .. tostring(k) .. "' must be a table"
        end
        if v.points ~= nil then
            if type(v.points) ~= "table" then
                return nil, "Zone '" .. k .. "'.points must be a table"
            end
            for i, p in ipairs(v.points) do
                if type(p) ~= "table" or #p ~= 4 then
                    return nil, "Zone '" .. k .. "'.points[" .. i .. "] must be {x1,y1,x2,y2}"
                end
                for j = 1, 4 do
                    if type(p[j]) ~= "number" then
                        return nil, "Zone '" .. k .. "'.points[" .. i .. "][" .. j .. "] must be a number"
                    end
                end
            end
        end
    end

    return result, nil
end

-- ===========================================================================
-- CONSTRUCTOR
-- ===========================================================================

function UI:new(x, y, w, h, text, readOnly, onImport)
    local o = ISCollapsableWindowJoypad:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.initialText = text or ""
    o.readOnly = readOnly
    o.onImport = onImport
    o.backgroundColor = {
        r = 0,
        g = 0,
        b = 0,
        a = 0.8
    }
    o.borderColor = {
        r = 0.4,
        g = 0.4,
        b = 0.4,
        a = 1
    }
    o.width = w
    o.height = h
    o.anchorLeft = true
    o.anchorRight = true
    o.anchorTop = true
    o.anchorBottom = true
    o.fontHgt = getTextManager():getFontFromEnum(UIFont.Small):getLineHeight()
    o.lineNumber = 30
    return o
end

-- ===========================================================================
-- INITIALISE  (builds all children — journal pattern)
-- ===========================================================================

function UI:initialise()
    ISCollapsableWindowJoypad.initialise(self)

    -- KEY FIX: tell the engine NOT to route key events through Lua first.
    -- ISCollapsableWindowJoypad sets wantKeyEvents=true which intercepts
    -- printable characters before they reach the Java text component.
    self:setWantKeyEvents(false)

    local btnWid = 160
    local btnHgt = math.max(FONT_HGT_SMALL + 3 * 2, 25)
    local padBot = 10
    local inset = 2

    -- Multiline entry — height = inset + lines*fontHgt + inset (journal pattern)
    local entryH = inset + self.lineNumber * self.fontHgt + inset
    self.entry = ISTextEntryBox:new(self.initialText, 10, 20, self.width - 20, entryH)
    self.entry:initialise()
    self.entry:instantiate()
    self.entry:setMultipleLine(true)
    self.entry.javaObject:setMaxLines(self.lineNumber)
    self.entry.javaObject:setMaxTextLength(self.lineNumber * 200)
    self:addChild(self.entry)
    self.entry:focus()

    local bottom = self.entry:getBottom()

    -- Status label (import mode — shows validation errors)
    self.statusLbl = ISLabel:new(10, bottom + 6, FONT_HGT_SMALL + 2, "", 1, 0.4, 0.4, 1, UIFont.Small, true)
    self.statusLbl:initialise()
    self.statusLbl:instantiate()
    self:addChild(self.statusLbl)

    local btnY = bottom + 6

    -- Validate & Import button (import mode only)
    if not self.readOnly then
        self.importBtn = ISButton:new((self.width / 2) - btnWid - 5, btnY, btnWid, btnHgt, "Validate & Import", self,
            self.onImportClick)
        self.importBtn.internal = "IMPORT"
        self.importBtn:initialise()
        self.importBtn:instantiate()
        self.importBtn.borderColor = {
            r = 1,
            g = 1,
            b = 1,
            a = 0.1
        }
        self:addChild(self.importBtn)
    end

    -- Close / Cancel button
    local closeLabel = self.readOnly and "Close" or "Cancel"
    local closeX = self.readOnly and (self.width / 2) - (btnWid / 2) or (self.width / 2) + 5
    self.closeBtn = ISButton:new(closeX, btnY, btnWid, btnHgt, closeLabel, self, self.onClose)
    self.closeBtn.internal = "CLOSE"
    self.closeBtn:initialise()
    self.closeBtn:instantiate()
    self.closeBtn.borderColor = {
        r = 1,
        g = 1,
        b = 1,
        a = 0.1
    }
    self:addChild(self.closeBtn)

    -- Fit window height to content (journal pattern)
    self:setHeight(self.closeBtn:getBottom() + padBot)
end

-- ===========================================================================
-- CALLBACKS
-- ===========================================================================

function UI:onClose()
    self:setVisible(false)
    self:removeFromUIManager()
end

function UI:onImportClick()
    if not self.onImport then
        return
    end
    local ok, err = self.onImport(self.entry:getText())
    if ok then
        self:onClose()
    else
        self.statusLbl.name = "Error: " .. (err or "unknown"):gsub("\n", "  ")
        self.statusLbl.r, self.statusLbl.g, self.statusLbl.b = 1.0, 0.3, 0.3
    end
end

function UI:onKeyPressed(key)
    -- Only handle Escape — all other keys should flow to the Java text component.
    -- setWantKeyEvents(false) in initialise() is the primary fix; this is a fallback.
    if key == Keyboard.KEY_ESCAPE then
        self:onClose()
    end
end

-- ===========================================================================
-- RENDER
-- ===========================================================================

function UI:prerender()
    self.pinButton:setVisible(false)
    self.collapseButton:setVisible(false)
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g,
        self.backgroundColor.b)
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g,
        self.borderColor.b)
end

-- ===========================================================================
-- OPEN
-- ===========================================================================

function UI:open(readOnly)
    local sw = getCore():getScreenWidth()
    local sh = getCore():getScreenHeight()
    local w = math.min(860, sw - 40)
    local h = math.min(580, sh - 40)
    local mx = math.floor((sw - w) / 2)
    local my = math.floor((sh - h) / 2)

    local uiRef = self
    local text = self:buildExportString()

    local onImport = not readOnly and function(src)
        local data, err = uiRef:parseImportString(src)
        if err then
            return false, err
        end
        local md = ModData.getOrCreate(Core.const.modifiedModData)
        for k in pairs(md) do
            md[k] = nil
        end
        for k, v in pairs(data) do
            md[k] = v
        end
        ModData.transmit(Core.const.modifiedModData)
        return true, nil
    end or nil

    local win = UI:new(mx, my, w, h, text, readOnly, onImport)
    win:initialise()
    win:setTitle(readOnly and "Zone Data — Export" or "Zone Data — Edit / Import")
    win:addToUIManager()
    win:setVisible(true)
end
