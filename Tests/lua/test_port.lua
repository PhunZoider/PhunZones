-- Moving a player out of a zone they are not allowed to be in.
--
-- The interesting part is not the move, it is everything around it: the
-- destination chunk is not loaded at the moment we ask, and the engine puts
-- back anyone standing on a square that does not exist. So the move has to be
-- held until it lands, nothing else may issue a second move while it is in
-- flight, and a move that will never land has to be given up on rather than
-- retried forever.
--
-- Run: ..\PhunTestKit\run.cmd . port

local kit = require "phuntestkit"
local harness, check = kit.harness, kit.check

kit.installGlobals()

-- Client side: this is where the enforcement tick and the hold loop live. Set
-- before the mod loads, because tools.isLocal is decided at load time.
_G.isClient = function()
    return true
end
_G.isServer = function()
    return false
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

-- The four-argument form, which is what a targeted server command takes.
harness.serverCommands = {}
_G.sendServerCommand = function(player, module, command, args)
    harness.serverCommands[#harness.serverCommands + 1] = {
        player = player,
        module = module,
        command = command,
        args = args
    }
end

_G.instanceof = function(obj, class)
    return type(obj) == "table" and obj.class == class
end

-- ---------------------------------------------------------------------------
-- The world.
--
-- isValidSquare is what a move is checked against before it is attempted; the
-- loaded square set is what the hold loop waits on. They are deliberately
-- separate: a coordinate can be part of the map and still not be in memory,
-- which is the whole situation being modelled here.
-- ---------------------------------------------------------------------------
local WORLD_MIN, WORLD_MAX = 0, 16799
local loaded = {}

local function squareKey(x, y, z)
    return math.floor(x) .. "," .. math.floor(y) .. "," .. math.floor(z or 0)
end

local function loadSquare(x, y, z)
    loaded[squareKey(x, y, z)] = true
end

_G.getWorld = function()
    return {
        getMetaGrid = function()
            return {
                isValidSquare = function(_, x, y)
                    return x >= WORLD_MIN and x <= WORLD_MAX and y >= WORLD_MIN and y <= WORLD_MAX
                end
            }
        end
    }
end

_G.getCell = function()
    return {
        getGridSquare = function(_, x, y, z)
            return loaded[squareKey(x, y, z)] and {} or nil
        end
    }
end

kit.addMod("PhunZones2")

require "PhunZones/core"
local Core = PhunZones

kit.strip()

-- ---------------------------------------------------------------------------
-- One closed zone, and open ground well away from it.
-- ---------------------------------------------------------------------------
local VAULT = {
    key = "Vault",
    noplayers = true
}
local OPEN = {
    key = "_default"
}

Core.inied = true
Core.data = {
    lookup = {
        Vault = VAULT,
        _default = OPEN
    },
    cells = {
        -- floor(1000/300) == 3 on both axes
        ["3_3"] = {{"Vault", 1000, 1000, 1100, 1100}}
    }
}
Core.settings = Core.settings or {}
Core.settings.StaffExempt = false

-- ---------------------------------------------------------------------------
-- Stand-ins.
-- ---------------------------------------------------------------------------

--- A player who goes where they are put.
local function makePlayer(name, x, y, z)
    local p = {
        class = "IsoPlayer",
        x = x or 0,
        y = y or 0,
        z = z or 0,
        teleports = {},
        setters = {},
        halos = {}
    }
    function p:getUsername()
        return name
    end
    function p:getX()
        return self.x
    end
    function p:getY()
        return self.y
    end
    function p:getZ()
        return self.z
    end
    function p:getVehicle()
        return nil
    end
    function p:teleportTo(tx, ty, tz)
        self.teleports[#self.teleports + 1] = {
            x = tx,
            y = ty,
            z = tz
        }
        self.x, self.y, self.z = tx, ty, tz
    end
    function p:setHaloNote(text)
        self.halos[#self.halos + 1] = text
    end
    return p
end

--- A player the engine keeps putting back. Every move is recorded and none of
--- them takes, which is the shape of a destination that never loads.
local function makeStubbornPlayer(name, x, y, z)
    local p = makePlayer(name, x, y, z)
    function p:teleportTo(tx, ty, tz)
        self.teleports[#self.teleports + 1] = {
            x = tx,
            y = ty,
            z = tz
        }
    end
    return p
end

--- A build with no teleportTo, so the bare setters are all there is.
local function makeLegacyPlayer(name, x, y, z)
    local p = makePlayer(name, x, y, z)
    p.teleportTo = nil
    local function record(kind)
        return function(self, v)
            self.setters[#self.setters + 1] = {
                kind = kind,
                value = v
            }
        end
    end
    p.setX = function(self, v)
        record("x")(self, v)
        self.x = v
    end
    p.setY = function(self, v)
        record("y")(self, v)
        self.y = v
    end
    p.setZ = function(self, v)
        record("z")(self, v)
        self.z = v
    end
    p.setLx = record("lx")
    p.setLy = record("ly")
    p.setLz = record("lz")
    return p
end

--- Run the tick handlers n times. Copied first, because the hold loop takes
--- itself off the list the moment its last port lands.
local function tick(n)
    for _ = 1, (n or 1) do
        local handlers = {}
        for i, fn in ipairs(harness.eventHandlers.OnTick or {}) do
            handlers[i] = fn
        end
        for _, fn in ipairs(handlers) do
            fn()
        end
    end
end

local function setterFor(p, kind)
    for _, s in ipairs(p.setters) do
        if s.kind == kind then
            return s.value
        end
    end
    return nil
end

-- ---------------------------------------------------------------------------
check.section("a destination has to be part of this world")

local offmap = makePlayer("offmap", 1050, 1050)
check.same("a move off the map is refused", Core.portPlayer(offmap, -50, -50, 0), false)
check.same("and nobody is moved", #offmap.teleports, 0)
check.same("and nothing is left holding", Core.isPortPending(offmap), false)

check.same("a move onto the map is accepted", Core.portPlayer(offmap, 5000, 5000, 0), true)
loadSquare(5000, 5000, 0)
tick(1)

-- ---------------------------------------------------------------------------
check.section("the move is held until the chunk exists")

local held = makePlayer("held", 1050, 1050)
Core.portPlayer(held, 7000, 7000, 0)

check.same("the move is made immediately", #held.teleports, 1)
check.same("centred on the tile rather than its corner", held.teleports[1].x, 7000.5)
check.same("and it is still in flight", Core.isPortPending(held), true)

tick(3)
check.same("it is re-asserted every tick while the square is missing", #held.teleports, 4)
check.same("still in flight", Core.isPortPending(held), true)

loadSquare(7000, 7000, 0)
tick(1)
check.same("once the square is there the hold lets go", Core.isPortPending(held), false)
check.same("and stops re-asserting", #held.teleports, 4)

tick(5)
check.same("nothing more is issued afterwards", #held.teleports, 4)

-- ---------------------------------------------------------------------------
check.section("a move that will never land is given up on")

local lost = makeStubbornPlayer("lost", 1050, 1050)
Core.portPlayer(lost, 9000, 9000, 0)
check.same("in flight to start with", Core.isPortPending(lost), true)

tick(179)
check.same("still trying just short of the limit", Core.isPortPending(lost), true)

tick(1)
check.same("gives up at the limit", Core.isPortPending(lost), false)

local issued = #lost.teleports
tick(50)
check.same("and does not quietly keep going", #lost.teleports, issued)

-- ---------------------------------------------------------------------------
check.section("enforcement stands off while a move is in flight")

local flying = makePlayer("flying", 1050, 1050)
Core.portPlayer(flying, 8000, 8000, 0)
local before = #flying.teleports

check.same("the player is denied", Core.enforceZoneAccess(flying, VAULT, {
    zone = "_default",
    x = 5000,
    y = 5000,
    z = 0
}), false)
check.same("but no second move is stacked on the first", #flying.teleports, before)

loadSquare(8000, 8000, 0)
flying.x, flying.y = 8000.5, 8000.5
tick(1)
check.same("and once it lands the hold is released", Core.isPortPending(flying), false)

-- ---------------------------------------------------------------------------
check.section("an open zone lets everyone through")

local walker = makePlayer("walker", 5000, 5000)
check.same("nothing to enforce", Core.enforceZoneAccess(walker, OPEN, {
    zone = "_default",
    x = 4999,
    y = 5000,
    z = 0
}), true)
check.same("and nobody is moved", #walker.teleports, 0)

-- ---------------------------------------------------------------------------
check.section("enforcement never gives up")

-- Every move is recorded and none of them takes, so this player never leaves
-- the zone however many times they are bounced. A denial cannot tell that
-- apart from someone walking straight back in, so both keep being moved.
local stuck = makeStubbornPlayer("stuck", 1050, 1050)
local lastAt = {
    zone = "Vault",
    x = 1050,
    y = 1050,
    z = 0
}

local moves = {}
for _ = 1, 10 do
    local was = #stuck.teleports
    Core.enforceZoneAccess(stuck, VAULT, lastAt)
    moves[#moves + 1] = (#stuck.teleports > was)
    -- Let the hold give up, so the next attempt is not simply standing off.
    tick(180)
end

check.same("the first attempt moves them", moves[1], true)
check.same("so does the sixth", moves[6], true)
check.same("and the tenth", moves[10], true)
check.same("they are still denied", Core.enforceZoneAccess(stuck, VAULT, lastAt), false)
check.same("and still told why", #stuck.halos > 0, true)
tick(180)

-- ---------------------------------------------------------------------------
check.section("walked in: sent back the way they came, clear of the line")

-- lastAt is just outside the west edge (x 1000) and they are just inside.
local walkedIn = makePlayer("walkedIn", 1001, 1050)
Core.enforceZoneAccess(walkedIn, VAULT, {
    zone = "_default",
    x = 999,
    y = 1050,
    z = 0
})
check.same("pushed further west than where they were", walkedIn.teleports[1].x, 996.5)
check.same("along the same row", walkedIn.teleports[1].y, 1050.5)
loadSquare(996, 1050, 0)
tick(1)

-- ---------------------------------------------------------------------------
check.section("ported or logged in: nearest edge in a straight line")

-- 20 in from the north edge, 50+ from the others.
local dropped = makePlayer("dropped", 1050, 1020)
Core.enforceZoneAccess(dropped, VAULT, {
    zone = "Vault",
    x = 1050,
    y = 1020,
    z = 0
})
check.same("straight north", dropped.teleports[1].x, 1050.5)
check.same("past the edge by the pushback", dropped.teleports[1].y, 997.5)
loadSquare(1050, 997, 0)
tick(1)

-- A second Vault rect butting onto the north edge: the straight line has to
-- hop both, and east is now the shorter way out.
Core.data.cells["3_3"][2] = {"Vault", 1000, 900, 1100, 999}
local hopped = makePlayer("hopped", 1090, 1020)
Core.enforceZoneAccess(hopped, VAULT, {
    zone = "Vault",
    x = 1090,
    y = 1020,
    z = 0
})
check.same("east past both", hopped.teleports[1].x, 1103.5)
check.same("on the same row", hopped.teleports[1].y, 1020.5)
loadSquare(1103, 1020, 0)
tick(1)

-- One tile from the shared edge: north looks closest, but that only reaches
-- the second rect, and the real way out north is 102 tiles. West is 51.
check.same("north is measured across both rects", Core.findNearestSafePosition(1050, 1001, 0, "Vault"), 999)
Core.data.cells["3_3"][2] = nil

-- ---------------------------------------------------------------------------
check.section("builds without teleportTo still get the bookkeeping")

local legacy = makeLegacyPlayer("legacy", 1050, 1050)
Core.portPlayer(legacy, 4000, 4000, 0)

check.same("position is set", setterFor(legacy, "x"), 4000.5)
-- The one that actually mattered: left pointing at the old position, the
-- character interpolates towards the new one from wherever it used to be.
check.same("and so is the last position", setterFor(legacy, "lx"), 4000.5)
check.same("on both axes", setterFor(legacy, "ly"), 4000.5)
check.same("and the floor", setterFor(legacy, "lz"), 0)

loadSquare(4000, 4000, 0)
tick(1)

-- ---------------------------------------------------------------------------
check.section("a dedicated server hands the move to the owning client")

_G.isServer = function()
    return true
end
harness.serverCommands = {}

local remote = makePlayer("remote", 1050, 1050)
check.same("the move is accepted", Core.portPlayer(remote, 6000, 6000, 0), true)
check.same("nothing is moved from here", #remote.teleports, 0)
check.same("nor left holding here", Core.isPortPending(remote), false)
check.same("one command was sent", #harness.serverCommands, 1)

local sent = harness.serverCommands[1]
check.same("addressed to that player", sent.player, remote)
check.same("asking them to teleport", sent.command, Core.commands.playerTeleport)
check.same("naming them, since the client looks them up by name", sent.args.username, "remote")
check.same("to the right tile", sent.args.x, 6000)

_G.isServer = function()
    return false
end

check.finish()
