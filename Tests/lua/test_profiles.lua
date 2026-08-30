-- Zone profiles: the sparse overlay, activation, and config round-tripping.
--
-- Run: ..\PhunTestKit\run.cmd . profiles

local kit = require "phuntestkit"
local harness, check = kit.harness, kit.check

kit.installGlobals()

-- The kit's ModData stand-in covers get/getOrCreate; PhunZones also uses add
-- and transmit. transmit only needs to be observable, not to do anything.
harness.transmitted = {}
ModData.add = function(name, data)
    harness.modData[name] = data
end
ModData.transmit = function(name)
    harness.transmitted[#harness.transmitted + 1] = name
end

-- The kit stands in for sendServerCommand but not its client counterpart.
-- PhunZones calls the 4-argument form: (player, module, command, args).
harness.clientCommands = {}
_G.sendClientCommand = function(player, module, command, args)
    harness.clientCommands[#harness.clientCommands + 1] = {
        module = module,
        command = command,
        args = args
    }
end
_G.getPlayer = function()
    return {
        getUsername = function()
            return "tester"
        end
    }
end

-- Two engine globals PhunZones touches that the kit does not stand in for.
-- getCore is read at load time by core.lua, so both go in before addMod.
harness.activeMods = {}
_G.getActivatedMods = function()
    return {
        contains = function(_, name)
            return harness.activeMods[name] == true
        end
    }
end
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
require "PhunZones/process"
local Core = PhunZones

-- Everything past here runs without loadstring, load, loadfile or next.
kit.strip()

local function writeConfig(data, profiles)
    local out = {
        version = 3,
        data = data or {}
    }
    if profiles then
        out.profiles = profiles
    end
    Core.tools.saveTable(Core.const.modifiedLuaFile, out)
end

local function reload()
    harness.transmitted = {}
    Core.updateZoneData()
end

-- ---------------------------------------------------------------------------
check.section("the overlay applies and lifts")

harness.reset()
writeConfig({}, {
    night = {
        MarchRidge = {
            noplayers = true
        }
    }
})
reload()

check.same("nothing active on a fresh load", Core.getActiveProfile(), nil)
check.same("zone is open with no profile", Core.data.lookup.MarchRidge.noplayers, nil)

local ok, err = Core.setActiveProfile("night")
check.ok("night activates", ok, tostring(err))
check.same("active profile is reported", Core.getActiveProfile(), "night")
check.same("zone is closed under night", Core.data.lookup.MarchRidge.noplayers, true)
check.ok("clients were told", #harness.transmitted > 0, "no ModData.transmit")

check.ok("none clears it", Core.setActiveProfile("none"))
check.same("zone is open again", Core.data.lookup.MarchRidge.noplayers, nil)
check.same("empty string also clears", Core.getActiveProfile(), nil)

-- ---------------------------------------------------------------------------
check.section("overlay respects inheritance")

harness.reset()
writeConfig({}, {
    lockdown = {
        Louisville = {
            noplayers = true
        }
    }
})
reload()
Core.setActiveProfile("lockdown")

check.same("parent is closed", Core.data.lookup.Louisville.noplayers, true)
check.same("child inherits the override", Core.data.lookup.Louisville_Mall.noplayers, true)
check.same("an unrelated zone is untouched", Core.data.lookup.MarchRidge.noplayers, nil)

-- ---------------------------------------------------------------------------
check.section("no value is ever captured")
-- The reason a profile is an overlay rather than a snapshot: an admin edit made
-- while a profile is live must survive the profile being lifted.

harness.reset()
writeConfig({}, {
    night = {
        MarchRidge = {
            noplayers = true
        }
    }
})
reload()
Core.setActiveProfile("night")

Core.saveChanges({
    MarchRidge = {
        difficulty = 4
    }
})

check.same("the edit applies under the profile", Core.data.lookup.MarchRidge.difficulty, 4)
check.same("the profile still closes the zone", Core.data.lookup.MarchRidge.noplayers, true)

Core.setActiveProfile("none")
check.same("the edit survives deactivation", Core.data.lookup.MarchRidge.difficulty, 4)
check.same("the zone reopens", Core.data.lookup.MarchRidge.noplayers, nil)

-- ---------------------------------------------------------------------------
check.section("writers preserve the profiles block")
-- saveChanges rewrites the whole config file. Emitting a bare { version, data }
-- would delete every profile the admin has defined.

local raw = Core.tools.loadTable(Core.const.modifiedLuaFile)
check.same("written as v3", raw.version, 3)
check.ok("profiles survived saveChanges", raw.profiles ~= nil and raw.profiles.night ~= nil,
    "profiles block was dropped by the rewrite")
check.same("profile contents are intact", raw.profiles.night.MarchRidge.noplayers, true)

Core.addDeletion("EchoPark")
raw = Core.tools.loadTable(Core.const.modifiedLuaFile)
check.ok("profiles survived addDeletion", raw.profiles ~= nil and raw.profiles.night ~= nil,
    "profiles block was dropped by addDeletion")

-- ---------------------------------------------------------------------------
check.section("bad input is refused, not applied")

harness.reset()
writeConfig({}, {
    night = {
        MarchRidge = {
            noplayers = true
        }
    }
})
reload()

local ok2, err2 = Core.setActiveProfile("nope")
check.same("an undefined profile is refused", ok2, false)
check.ok("the reason names it", tostring(err2):find("nope", 1, true) ~= nil, tostring(err2))
check.same("nothing was activated", Core.getActiveProfile(), nil)

check.same("a non-string is refused", (Core.setActiveProfile(42)), false)

-- ---------------------------------------------------------------------------
check.section("clearing aliases")

harness.reset()
writeConfig({}, {
    night = {
        MarchRidge = {
            noplayers = true
        }
    }
})
reload()

Core.setActiveProfile("night")
check.same("default clears", (Core.setActiveProfile("default")), true)
check.same("nothing is active after default", Core.getActiveProfile(), nil)

Core.setActiveProfile("night")
check.same("DEFAULT is case-insensitive", (Core.setActiveProfile("DEFAULT")), true)
check.same("nothing is active after DEFAULT", Core.getActiveProfile(), nil)

Core.setActiveProfile("night")
check.same("whitespace is trimmed", (Core.setActiveProfile("  none  ")), true)
check.same("nothing is active after padded none", Core.getActiveProfile(), nil)

-- A profile actually named "default" must still be reachable, or the alias
-- would make it permanently unusable.
harness.reset()
writeConfig({}, {
    default = {
        MarchRidge = {
            noplayers = true
        }
    }
})
reload()

check.ok("a profile named default activates", Core.setActiveProfile("default"))
check.same("it wins over the alias", Core.getActiveProfile(), "default")
check.same("and it actually applies", Core.data.lookup.MarchRidge.noplayers, true)
check.ok("none still clears it", Core.setActiveProfile("none"))
check.same("cleared", Core.getActiveProfile(), nil)

-- ---------------------------------------------------------------------------
check.section("a vanished profile is cleared on reload")
-- Renaming or deleting the live profile in the config would otherwise leave it
-- active while applying nothing, which is indistinguishable from a broken merge.

harness.reset()
writeConfig({}, {
    night = {
        MarchRidge = {
            noplayers = true
        }
    }
})
reload()

Core.setActiveProfile("night")
check.same("night is live", Core.getActiveProfile(), "night")

writeConfig({}, {
    day = {
        MarchRidge = {
            difficulty = 1
        }
    }
})
reload()

check.same("the stale active profile was cleared", Core.getActiveProfile(), nil)
check.equal("the new profile is the only one defined", Core.getProfileNames(), {"day"})
check.same("the old overlay is gone", Core.data.lookup.MarchRidge.noplayers, nil)

-- ---------------------------------------------------------------------------
check.section("a profile can turn a base setting back off")
-- Going the other way: the zone is closed in `data` and a profile reopens it.
-- JSON null is not the way to do that. The decoder turns null into Lua nil, and
-- a nil-valued key is simply not in the table, so the overlay says nothing about
-- the field and the base value stands. false is an actual value and does apply.

harness.reset()
local encoded = [[{
  "version": 3,
  "data": { "FallasLake": { "noplayers": true } },
  "profiles": {
    "nulled": { "FallasLake": { "noplayers": null } },
    "opened": { "FallasLake": { "noplayers": false } }
  }
}]]
local decoded = Core.tools.jsonToTable(encoded)
Core.tools.saveTable(Core.const.modifiedLuaFile, decoded)
reload()

check.same("closed by the custom layer", Core.data.lookup.FallasLake.noplayers, true)

Core.setActiveProfile("nulled")
check.same("a null override is dropped by the decoder", decoded.profiles.nulled.FallasLake.noplayers, nil)
check.same("so the zone stays closed", Core.data.lookup.FallasLake.noplayers, true)

Core.setActiveProfile("opened")
check.same("false does override it", Core.data.lookup.FallasLake.noplayers, false)

Core.setActiveProfile("none")
check.same("and lifting the profile closes it again", Core.data.lookup.FallasLake.noplayers, true)

-- ---------------------------------------------------------------------------
check.section("editing a profile that is not live")
-- What the editor relies on: it can build and mark up any profile without
-- disturbing players, and saving into an inactive profile changes nothing live.

harness.reset()
writeConfig({}, {
    night = {
        MarchRidge = {
            noplayers = true
        }
    }
})
reload()

local preview = Core.buildZoneData(true, "night")
check.same("an explicit profile builds without being active", preview.lookup.MarchRidge.noplayers, true)
check.same("it reports which profile shaped it", preview.profile, "night")
check.same("and exposes its sparse layer for override marking",
    preview.profileLayer.MarchRidge.noplayers, true)
check.same("nothing was activated by building it", Core.getActiveProfile(), nil)
check.same("live data is untouched", Core.data.lookup.MarchRidge.noplayers, nil)

check.same("false means no profile at all", Core.buildZoneData(true, false).profile, nil)

check.ok("saving into an inactive profile", Core.saveProfileChanges("night", {
    Rosewood = {
        nofire = true
    }
}))
check.same("live data still untouched", Core.data.lookup.Rosewood.nofire, nil)
check.same("but the profile now carries it",
    Core.buildZoneData(true, "night").lookup.Rosewood.nofire, true)

Core.setActiveProfile("night")
check.same("and it applies once activated", Core.data.lookup.Rosewood.nofire, true)

-- ---------------------------------------------------------------------------
check.section("creating and deleting profiles")

harness.reset()
writeConfig({}, nil)
reload()

check.equal("no profiles to start", Core.getProfileNames(), {})
check.ok("create", Core.createProfile("event"))
check.equal("it is listed", Core.getProfileNames(), {"event"})

check.same("creating it twice is refused", (Core.createProfile("event")), false)
check.same("a name with spaces is refused", (Core.createProfile("my event")), false)
check.same("a name with punctuation is refused", (Core.createProfile("night!")), false)
check.ok("underscores and hyphens are fine", Core.createProfile("night-time_2"))

-- A new profile must reach the file, or it is gone on restart.
local saved = Core.tools.loadTable(Core.const.modifiedLuaFile)
check.ok("new profiles are persisted", saved.profiles and saved.profiles.event ~= nil,
    "profile missing from the written config")

Core.saveProfileChanges("event", {
    MarchRidge = {
        noplayers = true
    }
})
Core.setActiveProfile("event")
check.same("event is live", Core.getActiveProfile(), "event")
check.same("and applies", Core.data.lookup.MarchRidge.noplayers, true)

check.ok("deleting the live profile", Core.deleteProfile("event"))
check.same("clears it", Core.getActiveProfile(), nil)
check.same("and reverts the zone", Core.data.lookup.MarchRidge.noplayers, nil)
check.same("deleting an unknown profile is refused", (Core.deleteProfile("event")), false)

-- ---------------------------------------------------------------------------
check.section("client requests apply optimistically")
-- The editor creates a profile and immediately switches to editing it. On a
-- client that races the server, so the request path updates the local copy
-- first; otherwise buildZoneData finds no such profile and the editor snaps
-- back to the base layer.

harness.reset()
writeConfig({}, nil)
reload()

local wasClient = isClient
_G.isClient = function()
    return true
end
_G.isCoopHost = function()
    return false
end
harness.clientCommands = {}

check.ok("create is accepted", Core.requestCreateProfile("event"))
check.equal("and is visible locally straight away", Core.getProfileNames(), {"event"})
check.same("while still asking the server", #harness.clientCommands, 1)
check.same("via the create command", harness.clientCommands[1].command, Core.commands.createProfile)

Core.requestProfileChanges("event", {
    MarchRidge = {
        noplayers = true
    }
})
local built = Core.buildZoneData(true, "event")
check.same("edits show without waiting for the reply", built.lookup.MarchRidge.noplayers, true)
check.same("and are marked as the profile's own", built.profileLayer.MarchRidge.noplayers, true)

-- The authoritative mutators refuse to run on a client at all: the guard comes
-- before any payload handling, so a client cannot write state the server has
-- not agreed to. Editors go through the request functions above instead.
check.same("saveProfileChanges is refused on a client",
    (Core.saveProfileChanges("event", {})), false)
check.same("createProfile is refused on a client", (Core.createProfile("other")), false)
check.same("deleteProfile is refused on a client", (Core.deleteProfile("event")), false)
check.same("setActiveProfile is refused on a client", (Core.setActiveProfile("event")), false)

Core.requestDeleteProfile("event")
check.equal("delete also applies locally", Core.getProfileNames(), {})

_G.isClient = wasClient
_G.isCoopHost = function()
    return false
end

-- ---------------------------------------------------------------------------
check.section("older configs still load")

harness.reset()
Core.tools.saveTable(Core.const.modifiedLuaFile, {
    version = 2,
    data = {
        MarchRidge = {
            difficulty = 1
        }
    }
})
reload()

check.equal("a v2 config defines no profiles", Core.getProfileNames(), {})
check.same("its custom layer still applies", Core.data.lookup.MarchRidge.difficulty, 1)
check.same("activating nothing is a no-op", Core.setActiveProfile(nil), true)

check.finish()
