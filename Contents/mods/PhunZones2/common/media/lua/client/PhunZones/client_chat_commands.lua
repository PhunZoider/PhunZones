if isServer() then
    return
end

local Core = PhunZones

-- ---------------------------------------------------------------------------
-- /zoneprofile [name|none|default]
--
-- Until the editor grows a profile selector this is the only way to see or
-- change the active profile in-game, and the escape hatch if a scheduled swap
-- leaves the wrong profile live (a "close" job that fired while its matching
-- "open" job was missed, say). Worth keeping even once the UI exists.
--
-- PhunServer2 owns a /command hook any of its modules can register into, and we
-- use it when it is there. When it is not, PhunZones installs its own wrapper:
-- without PhunServer2 there is no cron either, so this command is the only way
-- to use profiles at all and it cannot be allowed to disappear with the mod.
-- ---------------------------------------------------------------------------

local function describe()
    local names = Core.getProfileNames()
    if #names == 0 then
        return "PhunZones: no profiles defined in lua/PhunZones.json"
    end
    return "PhunZones: active = " .. (Core.getActiveProfile() or "none") .. " | defined: " ..
               table.concat(names, ", ")
end

local function isDefined(name)
    for _, n in ipairs(Core.getProfileNames()) do
        if n == name then
            return true
        end
    end
    return false
end

-- Returns true when handled silently, or a string to show the player.
local function handler(args)
    local name = args and args[1]

    if not name or name == "" then
        return describe()
    end

    -- The client already holds the profile list, so a typo is answered here
    -- rather than round-tripped to a server that would silently ignore it.
    -- A defined profile wins over the clearing aliases, matching setActiveProfile.
    if not isDefined(name) and not Core.isProfileClearAlias(name) then
        return "PhunZones: no such profile '" .. name .. "'. " .. describe()
    end

    local ok, err = Core.requestSetProfile(name)
    if not ok then
        return "PhunZones: " .. tostring(err)
    end
    return true
end

-- ---------------------------------------------------------------------------
-- Standalone fallback, used only when PhunServer2 is absent.
--
-- PhunServer2's FakeMessage duck-types a ChatMessage to inject a line into the
-- chat window. Reproducing that here would mean copying its coupling to the
-- chat renderer's internals for one command, so the fallback reports through
-- the halo note PhunZones already uses elsewhere, and puts the full text in the
-- log where a longer profile list stays readable.
-- ---------------------------------------------------------------------------
local function reply(text)
    print(text)
    local player = getPlayer()
    if player then
        player:setHaloNote(text, 255, 255, 255, 400)
    end
end

local function installOwnHook()
    local original = ISChat.onCommandEntered

    ISChat.onCommandEntered = function(self)
        local text = ISChat.instance.textEntry:getText() or ""
        local verb, rest = text:match("^/(%S+)%s*(.-)%s*$")

        if verb and verb:lower() == "zoneprofile" then
            ISChat.instance:logChatCommand(text)
            if not Core.tools.isAdmin() then
                reply("PhunZones: you do not have access to that command")
            else
                local result = handler({rest ~= "" and rest or nil})
                if type(result) == "string" then
                    reply(result)
                end
            end
            ISChat.instance.textEntry:setText("")
            return
        end

        original(self)
    end
end

Events.OnGameStart.Add(function()
    if PhunServer2 and type(PhunServer2.registerCommand) == "function" then
        PhunServer2.registerCommand("zoneprofile", {
            admin = true,
            handler = handler
        })
    else
        installOwnHook()
    end
end)
