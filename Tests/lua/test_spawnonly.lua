-- Spawn-only zed rules: "removespawn" and "movespawn".
--
-- The ask: a zone where zeds don't spawn but can still wander in. A zed spawn
-- can't be refused, so these act on a zed when it is created in the zone and
-- never afterwards. That means they must not switch on the per-update
-- eviction (which would catch the wanderers), must switch on the creation
-- check, and must reach bandits as a refused spawn, since those can be.
--
-- Run: ..\PhunTestKit\run.cmd . spawnonly

local kit = require "phuntestkit"
local harness, check = kit.harness, kit.check

kit.installGlobals()

ModData.add = function(name, data)
    harness.modData[name] = data
end
ModData.transmit = function()
end

harness.activeMods = {
    Bandits2 = true
}
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

_G.ArrayList = {
    new = function()
        return {
            size = function()
                return 0
            end
        }
    end
}

_G.Events = setmetatable({}, {
    __index = function(t, name)
        local e = {
            Add = function()
            end,
            Remove = function()
            end
        }
        rawset(t, name, e)
        return e
    end
})

kit.addMod("PhunZones2")

require "PhunZones/core"
require "PhunZones/process"
local Core = PhunZones

local spawned = {}
_G.BanditCompatibility = {
    AddZombiesInOutfit = function(x, y, z)
        table.insert(spawned, {x = x, y = y, z = z})
        return ArrayList.new()
    end
}

require "PhunZones/features/bandits"

kit.strip()

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

local function trySpawn(x, y)
    spawned = {}
    BanditCompatibility.AddZombiesInOutfit(x, y, 0, "Naked1", 0)
    return spawned[1]
end

local function body(modData, variables)
    return {
        getModData = function()
            return modData or {}
        end,
        GetVariable = function(_, name)
            return (variables or {})[name]
        end
    }
end
local zed = body()
local bandit = body({
    brain = {}
})
local npc = body({
    ProjectALifeOwned = true
})

local BASE_ORDER = 100000
local CAMP = {600, 600, 699, 699}
local FARM = {800, 800, 899, 899}

-- ---------------------------------------------------------------------------
check.section("the values read")

harness.reset()
writeConfig({
    Camp = {
        title = "Camp",
        zeds = "removespawn",
        order = BASE_ORDER,
        points = {CAMP}
    },
    Farm = {
        title = "Farm",
        zeds = "movespawn",
        order = BASE_ORDER + 1,
        points = {FARM}
    }
})
reload()

local camp, farm, open = Core.getLocation(650, 650), Core.getLocation(850, 850), Core.getLocation(500, 500)
check.same("removespawn reads as itself", Core.zedAction(camp, "zeds"), "removespawn")
check.same("movespawn reads as itself", Core.zedAction(farm, "zeds"), "movespawn")
check.same("a zed spawning in the camp is removed", Core.onCreateAction(Core.zombieAction(camp, zed)), "remove")
check.same("a zed spawning on the farm is moved", Core.onCreateAction(Core.zombieAction(farm, zed)), "move")
check.same("nothing happens to one spawning outside", Core.onCreateAction(Core.zombieAction(open, zed)), nil)

-- ---------------------------------------------------------------------------
check.section("wanderers are left alone")
-- Not evicting is what lets a zed that walked in stay: the per-update check,
-- and the sweep on a player's arrival, only act on evicting zones.

check.same("removespawn does not evict", Core.evicts(Core.zombieAction(camp, zed)), false)
check.same("nor does movespawn", Core.evicts(Core.zombieAction(farm, zed)), false)
check.same("per-update enforcement stays off", Core.data.hasZedAction, false)
check.same("creation enforcement is on", Core.data.hasCreateAction, true)

-- ---------------------------------------------------------------------------
check.section("bandits following the zed rule are refused at the spawn")

check.same("a bandit in the camp reads as nospawn", Core.zombieAction(camp, bandit), "nospawn")
check.same("and on the farm", Core.zombieAction(farm, bandit), "nospawn")
check.same("which is not acted on at creation", Core.onCreateAction(Core.zombieAction(camp, bandit)), nil)
check.ok("no bandit spawns in the camp", trySpawn(650, 650) == nil)
check.ok("nor on the farm, not even relocated", trySpawn(850, 850) == nil)
check.ok("outside is untouched", trySpawn(500, 500) ~= nil)
check.same("an A-Life NPC is never touched", Core.zombieAction(camp, npc), "none")

-- ---------------------------------------------------------------------------
check.section("the values belong to the zed field only")

harness.reset()
writeConfig({
    Camp = {
        title = "Camp",
        zeds = "remove",
        bandits = "removespawn",
        alife = "removespawn",
        order = BASE_ORDER,
        points = {CAMP}
    }
})
reload()

camp = Core.getLocation(650, 650)
check.same("bandits=removespawn reads as none", Core.banditAction(camp), "none")
check.same("alife=removespawn reads as none", Core.alifeAction(camp), "none")
check.same("an explicit bandit rule still wins over the zed one", Core.zombieAction(camp, bandit), "none")

-- ---------------------------------------------------------------------------
check.section("evicting rules also act at creation")
-- So a zed is dealt with when it loads rather than on its first update.

harness.reset()
writeConfig({
    _default = {
        zeds = "move"
    },
    Camp = {
        title = "Camp",
        zeds = "remove",
        order = BASE_ORDER,
        points = {CAMP}
    }
})
reload()

check.same("remove acts at creation", Core.onCreateAction(Core.zombieAction(Core.getLocation(650, 650), zed)), "remove")
check.same("move acts at creation", Core.onCreateAction(Core.zombieAction(Core.getLocation(500, 500), zed)), "move")
check.same("both switch per-update enforcement on", Core.data.hasZedAction, true)
check.same("and creation enforcement", Core.data.hasCreateAction, true)

-- ---------------------------------------------------------------------------
check.section("saying nothing switches nothing on")

harness.reset()
writeConfig({})
reload()
check.same("no per-update enforcement", Core.data.hasZedAction, false)
check.same("no creation enforcement", Core.data.hasCreateAction, false)

check.finish()
