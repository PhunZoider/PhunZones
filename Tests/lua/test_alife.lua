-- Project A-Life NPC zone control, and how a zone's rules pick between a zed,
-- a bandit and an A-Life NPC.
--
-- A-Life NPCs are zombie bodies, so before this they were caught by the zed
-- rule: a zone removing zeds deleted them, and A-Life's watchdog put them
-- straight back. The only thing a zone may now do to them is refuse the spawn,
-- through A-Life's own SpawnPolicy.excludedRegionAt.
--
-- Run: ..\PhunTestKit\run.cmd . alife

local kit = require "phuntestkit"
local harness, check = kit.harness, kit.check

kit.installGlobals()

ModData.add = function(name, data)
    harness.modData[name] = data
end
ModData.transmit = function()
end

harness.activeMods = {
    ProjectALifeNPCs = true,
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

local registered = {}
_G.Events = setmetatable({}, {
    __index = function(t, name)
        local e = {
            Add = function(fn)
                registered[name] = registered[name] or {}
                table.insert(registered[name], fn)
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

-- A-Life's own exclusion list, as shipped: the RV interior region it adds
-- itself stands in for "a region that is not ours".
local RV = {
    id = "rv_interior",
    x1 = 22500,
    y1 = 12000,
    x2 = 22599,
    y2 = 12099
}
_G.ProjectALife = {
    SpawnPolicy = {
        excludedRegions = {RV},
        excludedRegionAt = function(position)
            local x, y = tonumber(position and position.x), tonumber(position and position.y)
            if x == nil or y == nil then
                return nil
            end
            if x >= RV.x1 and x < RV.x2 + 1 and y >= RV.y1 and y < RV.y2 + 1 then
                return RV.id
            end
            return nil
        end
    }
}

require "PhunZones/features/alife"

kit.strip()

local hooked = ProjectALife.SpawnPolicy.excludedRegionAt

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

--- True when A-Life would be allowed to put a body at (x, y).
local function canSpawn(x, y)
    return ProjectALife.SpawnPolicy.excludedRegionAt({
        x = x + 0.5,
        y = y + 0.5,
        z = 0
    }) == nil
end

-- Stand-in zombie bodies. modData is all the rules look at, plus the
-- animation variable an MP client can see before A-Life's flags arrive.
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
local npcOnClient = body({}, {
    ALifeActor = "true"
})

local BASE_ORDER = 100000
local BASE = {600, 600, 699, 699}

-- ---------------------------------------------------------------------------
check.section("the hook binds")

check.ok("excludedRegionAt was wrapped", hooked ~= nil)
check.ok("install is retried on OnGameBoot", registered.OnGameBoot ~= nil and #registered.OnGameBoot == 1)
check.ok("install is retried on OnServerStarted",
    registered.OnServerStarted ~= nil and #registered.OnServerStarted == 1)
check.ok("install is retried on OnGameStart", registered.OnGameStart ~= nil and #registered.OnGameStart == 1)

Core.installALifeHooks()
Core.installALifeHooks()
check.ok("install is idempotent", ProjectALife.SpawnPolicy.excludedRegionAt == hooked)

-- ---------------------------------------------------------------------------
check.section("saying nothing changes nothing")

harness.reset()
writeConfig({})
reload()

check.ok("an unconfigured world still spawns", canSpawn(500, 500))
check.ok("A-Life's own regions still apply", not canSpawn(22550, 12050))
check.same("and keep their own id", hooked({
    x = 22550,
    y = 12050
}), "rv_interior")
check.same("a position without coordinates is not ours to judge", hooked({}), nil)

-- ---------------------------------------------------------------------------
check.section("Block Spawns")

harness.reset()
writeConfig({
    Base = {
        title = "Base",
        alife = "nospawn",
        order = BASE_ORDER,
        points = {BASE}
    }
})
reload()

check.same("reads as nospawn", Core.alifeAction(Core.getLocation(650, 650)), "nospawn")
check.ok("no NPC spawns in the zone", not canSpawn(650, 650))
check.ok("one tile inside the border is refused", not canSpawn(BASE[1], BASE[2]))
check.ok("one tile outside the border is allowed", canSpawn(BASE[1] - 1, BASE[2] - 1))
check.ok("a spawn outside the zone is left alone", canSpawn(500, 500))
check.same("the refusal names the zone", hooked({
    x = 650.5,
    y = 650.5
}), "PhunZones:Base")
check.same("nothing is flagged for eviction", Core.data.hasZedAction, false)
check.same("an NPC that walks in is left alone", Core.zombieAction(Core.getLocation(650, 650), npc), "nospawn")
check.same("which does not evict", Core.evicts(Core.zombieAction(Core.getLocation(650, 650), npc)), false)

-- A-Life only offers the two values; anything else must not quietly act.
harness.reset()
writeConfig({
    _default = {
        alife = "remove"
    },
    Base = {
        title = "Base",
        alife = "move",
        order = BASE_ORDER,
        points = {BASE}
    }
})
reload()
check.same("alife=remove reads as none", Core.alifeAction(Core.getLocation(500, 500)), "none")
check.same("alife=move reads as none", Core.alifeAction(Core.getLocation(650, 650)), "none")
check.ok("and neither blocks a spawn", canSpawn(500, 500) and canSpawn(650, 650))

-- ---------------------------------------------------------------------------
check.section("zed rules do not reach A-Life NPCs")
-- The reason this exists: removing an A-Life body makes its watchdog respawn
-- it, and a zone removing zeds would then remove it again, forever.

harness.reset()
writeConfig({
    _default = {
        zeds = "remove"
    },
    Arena = {
        title = "Arena",
        zeds = "move",
        bandits = "none",
        order = BASE_ORDER,
        points = {BASE}
    }
})
reload()

local open, arena = Core.getLocation(500, 500), Core.getLocation(650, 650)
check.same("a zed is removed", Core.zombieAction(open, zed), "remove")
check.same("a bandit follows the zed rule when it has none", Core.zombieAction(open, bandit), "remove")
check.same("an A-Life NPC is not removed", Core.zombieAction(open, npc), "none")
check.same("nor one only the client's animation variable marks", Core.zombieAction(open, npcOnClient), "none")
check.same("a zed is moved", Core.zombieAction(arena, zed), "move")
check.same("an exempted bandit is not", Core.zombieAction(arena, bandit), "none")
check.same("nor is an A-Life NPC", Core.zombieAction(arena, npc), "none")
check.ok("the zed rule does not block A-Life spawns", canSpawn(500, 500))

-- ---------------------------------------------------------------------------
check.section("without the mod nothing is hooked")

harness.activeMods.ProjectALifeNPCs = false
local untouched = function()
end
ProjectALife.SpawnPolicy.excludedRegionAt = untouched
package.loaded["PhunZones/features/alife"] = nil
require "PhunZones/features/alife"
check.ok("excludedRegionAt is left as it was", ProjectALife.SpawnPolicy.excludedRegionAt == untouched)
harness.activeMods.ProjectALifeNPCs = true

check.finish()
