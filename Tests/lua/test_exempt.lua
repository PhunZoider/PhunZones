-- Staff exemption from the "No ..." zone restrictions.
--
-- Run: ..\PhunTestKit\run.cmd . exempt

local kit = require "phuntestkit"
local harness, check = kit.harness, kit.check

kit.installGlobals()

_G.getCore = function()
    return {
        getGameVersion = function()
            return {
                getMajor = function()
                    return 42
                end,
                getMinor = function()
                    return 20
                end
            }
        end
    }
end

kit.addMod("PhunZones2")

require "PhunZones/core"
local Core = PhunZones

-- Everything past here runs without loadstring, load, loadfile or next.
kit.strip()

-- A player carrying a named role, the way B42 presents one.
local function playerWithRole(name)
    return {
        getRole = function()
            return {
                getName = function()
                    return name
                end
            }
        end,
        getUsername = function()
            return "player_" .. tostring(name)
        end
    }
end

-- A player with no role object at all, as in singleplayer.
local roleless = {
    getUsername = function()
        return "solo"
    end
}

local function setOptions(staffExempt, includeModGM)
    Core.settings.StaffExempt = staffExempt
    Core.settings.ExemptModGM = includeModGM
end

-- ---------------------------------------------------------------------------
check.section("off by default")

setOptions(nil, nil)
check.same("an admin is not exempt while the option is off", Core.isExempt(playerWithRole("Admin")), false)
check.same("nor is anyone else", Core.isExempt(playerWithRole("Moderator")), false)

-- ---------------------------------------------------------------------------
check.section("admin only")

setOptions(true, false)
check.same("Admin is exempt", Core.isExempt(playerWithRole("Admin")), true)
check.same("matching ignores case", Core.isExempt(playerWithRole("aDmIn")), true)
check.same("Moderator is not", Core.isExempt(playerWithRole("Moderator")), false)
check.same("GM is not", Core.isExempt(playerWithRole("GM")), false)
check.same("Overseer is not", Core.isExempt(playerWithRole("Overseer")), false)
check.same("Observer is never staff", Core.isExempt(playerWithRole("Observer")), false)
check.same("a plain player is not", Core.isExempt(playerWithRole("Player")), false)
check.same("an unknown custom role is not", Core.isExempt(playerWithRole("Builder")), false)

-- ---------------------------------------------------------------------------
check.section("including the lesser staff roles")

setOptions(true, true)
check.same("Admin still exempt", Core.isExempt(playerWithRole("Admin")), true)
check.same("Moderator now exempt", Core.isExempt(playerWithRole("Moderator")), true)
check.same("GM now exempt", Core.isExempt(playerWithRole("gm")), true)
check.same("Overseer now exempt", Core.isExempt(playerWithRole("Overseer")), true)
check.same("Observer still not", Core.isExempt(playerWithRole("Observer")), false)
check.same("a plain player still not", Core.isExempt(playerWithRole("Player")), false)

-- The second option is meaningless on its own: it must not grant anything
-- while the main switch is off.
setOptions(false, true)
check.same("Moderator is not exempt with the main option off",
    Core.isExempt(playerWithRole("Moderator")), false)
check.same("nor is Admin", Core.isExempt(playerWithRole("Admin")), false)

-- ---------------------------------------------------------------------------
check.section("bad input is not exempt")

setOptions(true, true)
check.same("nil player", Core.isExempt(nil), false)
check.same("a player with an empty role name", Core.isExempt(playerWithRole("")), false)

-- In multiplayer a roleless player must not fall back to the viewer's access
-- level, or every client would judge everyone by their own privileges.
_G.isClient = function()
    return true
end
_G.isCoopHost = function()
    return false
end
_G.getAccessLevel = function()
    return "admin"
end
check.same("a roleless player in MP does not inherit the viewer's level", Core.isExempt(roleless), false)

check.finish()
