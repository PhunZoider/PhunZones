-- Bandit zone control: which spawns a zone refuses, and how a bandit rule
-- relates to the zone's zed rule.
--
-- The bug this suite exists for: "Default: Remove, Louisville: None" left
-- bandits spawning everywhere. Two reasons. Bandits2 B42 spawns server-side
-- through BanditCompatibility.AddZombiesInOutfit and has no BanditScheduler at
-- all, so the hook that was supposed to stop it never bound to anything. And
-- waves are generated 60-75 tiles from a player, so the spawn point is
-- routinely in a different zone from the player who triggered it.
--
-- Run: ..\PhunTestKit\run.cmd . bandits

local kit = require "phuntestkit"
local harness, check = kit.harness, kit.check

kit.installGlobals()

harness.transmitted = {}
ModData.add = function(name, data)
    harness.modData[name] = data
end
ModData.transmit = function(name)
    harness.transmitted[#harness.transmitted + 1] = name
end

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

-- Bandits2 has to look loaded before features/bandits is required: the file
-- returns immediately when it is not, which is the behaviour a server without
-- the mod gets and is checked at the end of this suite.
harness.activeMods["Bandits2"] = true

-- The two engine pieces the hook touches. ArrayList stands in for the empty
-- java list a refused spawn hands back; Events only has to remember what was
-- registered, since the suite installs the hook itself.
_G.ArrayList = {
    new = function()
        local list = {}
        return {
            size = function()
                return #list
            end,
            get = function(_, i)
                return list[i + 1]
            end
        }
    end
}

local registered = {}
local function fakeEvent(name)
    return {
        Add = function(fn)
            registered[name] = registered[name] or {}
            table.insert(registered[name], fn)
        end,
        Remove = function()
        end
    }
end
_G.Events = setmetatable({}, {
    __index = function(t, name)
        local e = fakeEvent(name)
        rawset(t, name, e)
        return e
    end
})

kit.addMod("PhunZones2")

require "PhunZones/core"
require "PhunZones/process"
local Core = PhunZones

-- What the bandits mod actually calls. The stand-in records every spawn that
-- got through and where it landed, which is the whole observable behaviour.
local spawned = {}
_G.BanditCompatibility = {
    AddZombiesInOutfit = function(x, y, z, outfit, femaleChance)
        table.insert(spawned, {x = x, y = y, z = z})
        return ArrayList.new()
    end
}

local individualCalls, restoreCalls = 0, 0
_G.BanditServer = {
    Spawner = {
        Individual = function(player, args)
            individualCalls = individualCalls + 1
        end,
        Restore = function(player, args)
            restoreCalls = restoreCalls + 1
        end
    }
}

require "PhunZones/features/bandits"

kit.strip()

-- features/bandits calls install() at load, but BanditCompatibility was in
-- place first here, so the hook is already bound. On a real server load order
-- decides, which is why install() also runs from OnGameBoot/OnServerStarted/
-- OnGameStart. Those registrations are asserted below.
local hooked = BanditCompatibility.AddZombiesInOutfit

local function writeConfig(data)
    Core.tools.saveTable(Core.const.modifiedLuaFile, {
        version = 3,
        data = data or {}
    })
end

local function reload()
    Core.updateZoneData()
    Core.inied = true
end

--- Ask for a bandit at (x, y) and report where one actually appeared,
--- or nil if the spawn was refused.
local function trySpawn(x, y, z)
    spawned = {}
    local list = hooked(x, y, z or 0, "Naked1", 0)
    -- A refusal has to hand back something the mod can call :size() on, not
    -- nil: spawnGroup checks the size and would error on a bare nil. Asserted
    -- on every call rather than once, since the refusing path is the one that
    -- has to get this right.
    if not (list and list.size) then
        check.ok("spawn at " .. x .. "," .. y .. " returns a list", false)
    end
    return spawned[1]
end

local BASE_ORDER = 100000

-- Louisville stands in for "the one place bandits are allowed". Everything
-- outside it is unzoned world space, which resolves to _default.
local LVILLE = {12000, 5000, 12999, 5999}

local function inLville(x, y)
    return x >= LVILLE[1] and x <= LVILLE[3] and y >= LVILLE[2] and y <= LVILLE[4]
end

-- ---------------------------------------------------------------------------
check.section("the hook binds")

check.ok("AddZombiesInOutfit was wrapped", hooked ~= nil)
check.ok("install is retried on OnGameBoot", registered.OnGameBoot ~= nil and #registered.OnGameBoot == 1)
check.ok("install is retried on OnServerStarted",
    registered.OnServerStarted ~= nil and #registered.OnServerStarted == 1)
check.ok("install is retried on OnGameStart", registered.OnGameStart ~= nil and #registered.OnGameStart == 1)

-- Re-running install must not stack a second wrapper on top of the first,
-- because three events firing in a row on one machine is normal.
Core.installBanditHooks()
Core.installBanditHooks()
check.ok("install is idempotent", BanditCompatibility.AddZombiesInOutfit == hooked)

-- ---------------------------------------------------------------------------
check.section("saying nothing changes nothing")
-- A server that has not configured bandits must spawn exactly as before.

harness.reset()
writeConfig({})
reload()

check.same("no zone asks for enforcement", Core.data.hasZedAction, false)
local at = trySpawn(500, 500)
check.ok("an unconfigured world still spawns", at ~= nil)
check.same("at the coordinates asked for", at and at.x, 500)

-- ---------------------------------------------------------------------------
check.section("Default: Remove, Louisville: None")
-- The reported configuration, tested the way the user tested it.

harness.reset()
writeConfig({
    _default = {
        bandits = "remove"
    },
    Louisville = {
        title = "Louisville",
        bandits = "none",
        order = BASE_ORDER,
        points = {LVILLE}
    }
})
reload()

check.same("enforcement is flagged for the client", Core.data.hasZedAction, true)
check.same("Louisville inherits nothing over its own none", Core.data.lookup.Louisville.bandits, "none")
check.same("an unzoned tile resolves to remove", Core.banditAction(Core.getLocation(500, 500)), "remove")

check.ok("no bandit spawns in open country", trySpawn(500, 500) == nil)
check.ok("none spawns in Muldraugh either", trySpawn(10700, 9700) == nil)
check.ok("a bandit spawns in Louisville", trySpawn(12500, 5500) ~= nil)
check.ok("one tile inside the border still spawns", trySpawn(LVILLE[1], LVILLE[2]) ~= nil)
check.ok("one tile outside the border does not", trySpawn(LVILLE[1] - 1, LVILLE[2] - 1) == nil)

-- The case the old player-position check got wrong: the wave is triggered by a
-- player standing in Louisville, but the spawn point generated 60-75 tiles out
-- lands past the city limit. Testing the spawn point is what makes this fail.
check.ok("a wave from inside Louisville cannot land outside it",
    trySpawn(LVILLE[3] + 60, 5500) == nil)
check.ok("and the reverse: a wave from outside cannot land inside a blocked tile",
    trySpawn(LVILLE[1] - 60, 5500) == nil)

-- A sweep, because one bad rect edge is easy to miss with spot checks.
local misses = 0
for x = LVILLE[1] - 200, LVILLE[3] + 200, 37 do
    for y = LVILLE[2] - 200, LVILLE[4] + 200, 37 do
        local got = trySpawn(x, y) ~= nil
        if got ~= inLville(x, y) then
            misses = misses + 1
        end
    end
end
check.same("spawns land exactly where Louisville is", misses, 0)

-- ---------------------------------------------------------------------------
check.section("the unguarded spawner entry points")
-- spawnIndividual and spawnRestore take zombieList:get(0) without checking the
-- size, so a refusal has to happen above them rather than through an empty list.

individualCalls, restoreCalls = 0, 0
BanditServer.Spawner.Individual(nil, {x = 500, y = 500, z = 0, bid = 1})
check.same("Individual is refused in a blocked zone", individualCalls, 0)

BanditServer.Spawner.Individual(nil, {x = 12500, y = 5500, z = 0, bid = 1})
check.same("Individual goes through in Louisville", individualCalls, 1)

BanditServer.Spawner.Restore(nil, {bornCoords = {x = 500, y = 500, z = 0}})
check.same("Restore is refused in a blocked zone", restoreCalls, 0)

BanditServer.Spawner.Restore(nil, {bornCoords = {x = 12500, y = 5500, z = 0}})
check.same("Restore goes through in Louisville", restoreCalls, 1)

-- ---------------------------------------------------------------------------
check.section("Move relocates rather than refuses")

harness.reset()
writeConfig({
    _default = {
        bandits = "none"
    },
    Town = {
        title = "Town",
        bandits = "move",
        order = BASE_ORDER,
        points = {{600, 600, 699, 699}}
    }
})
reload()

local moved = trySpawn(650, 650)
check.ok("the spawn still happens", moved ~= nil)
check.ok("but not inside the zone", moved and not (moved.x >= 600 and moved.x <= 699 and
    moved.y >= 600 and moved.y <= 699))

local untouched = trySpawn(500, 500)
check.ok("a spawn outside the zone is left alone", untouched ~= nil)
check.same("exactly where it was asked for", untouched and untouched.x, 500)

-- ---------------------------------------------------------------------------
check.section("legacy index values still read")
-- Configs saved before the combo moved to string values store "1"/"2"/"3".

harness.reset()
writeConfig({
    _default = {
        bandits = "3"
    },
    Safe = {
        title = "Safe",
        bandits = "1",
        order = BASE_ORDER,
        points = {{600, 600, 699, 699}}
    }
})
reload()

check.same("3 reads as remove", Core.banditAction(Core.getLocation(500, 500)), "remove")
check.same("1 reads as none", Core.banditAction(Core.getLocation(650, 650)), "none")
check.ok("the old value still blocks", trySpawn(500, 500) == nil)
check.ok("and the old exemption still allows", trySpawn(650, 650) ~= nil)

-- ---------------------------------------------------------------------------
check.section("an unset bandit rule follows the zed rule")
-- A zone that says nothing about bandits has no bandit rule of its own, so a
-- bandit is treated as the zombie it is. An explicit none is a rule: it exempts
-- bandits from the zed setting, which is how you keep a zone zed-free but
-- populated.

harness.reset()
writeConfig({
    _default = {
        zeds = "remove"
    },
    Arena = {
        title = "Arena",
        zeds = "remove",
        bandits = "none",
        order = BASE_ORDER,
        points = {{600, 600, 699, 699}}
    }
})
reload()

check.same("unset bandits inherits the zeds rule", Core.banditAction(Core.getLocation(500, 500)), "remove")
check.same("explicit none overrides it", Core.banditAction(Core.getLocation(650, 650)), "none")
check.ok("no bandit where zeds are removed", trySpawn(500, 500) == nil)
check.ok("bandits allowed in the arena", trySpawn(650, 650) ~= nil)

-- ---------------------------------------------------------------------------
check.section("without Bandits2 nothing is flagged")
-- The bandit field can survive a server dropping the mod. It must then cost
-- nothing: no client-side per-zombie checking on its account.

harness.reset()
harness.activeMods["Bandits2"] = false
writeConfig({
    _default = {
        bandits = "remove"
    }
})
reload()
check.same("a bandit-only config does not switch enforcement on", Core.data.hasZedAction, false)

writeConfig({
    _default = {
        bandits = "remove",
        zeds = "remove"
    }
})
reload()
check.same("but a zed rule still does", Core.data.hasZedAction, true)

harness.activeMods["Bandits2"] = true

check.finish()
