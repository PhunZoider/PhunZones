-- Bandits2 spawn control.
--
-- Bandits2 spawns from the server (BanditServerSpawner), so on a dedicated
-- server nothing client-side can stop a bandit appearing -- by the time a
-- client sees one it already exists and can only be deleted after the fact.
--
-- Every live bandit the mod creates -- scheduled waves, wanderer groups,
-- restores, and mod/admin spawns -- funnels through a single global shared
-- function, BanditCompatibility.AddZombiesInOutfit, which takes the spawn
-- coordinates. Wrapping that lets a zone refuse a bandit before one exists.
--
-- The coordinates matter: waves are generated 60-75 tiles from a random
-- player, so the spawn point is regularly in a different zone from the player
-- who triggered it. Testing the spawn point rather than the player position is
-- the difference between "no bandits in this zone" and "no bandits while a
-- player happens to be standing here".
--
-- Two of the mod's callers take zombieList:get(0) without checking the size
-- first, so those two entry points are short-circuited above the funnel rather
-- than handed an empty list.
local Core = PhunZones

if not getActivatedMods():contains("Bandits2") then
    return
end

local installed = false

-- Where a bandit asked for at (x, y, z) should actually spawn.
-- Returns x, y, z to go ahead with, or nil when the spawn must not happen.
local function resolveSpawn(x, y, z)
    local zone = Core.getLocation(x, y)
    local action = Core.banditAction(zone)

    if action == "remove" then
        return nil
    end

    if action == "move" then
        -- Same treatment a bandit already inside the zone gets: pushed to the
        -- nearest tile outside it. If the zone has no reachable outside -- the
        -- default zone covers everything unzoned, so it never does -- refuse.
        local nx, ny, nz = Core.findNearestSafePosition(x, y, z, zone.key)
        if not nx then
            return nil
        end
        return nx, ny, nz
    end

    return x, y, z
end

local function install()
    if installed then
        return
    end
    if not BanditCompatibility or not BanditCompatibility.AddZombiesInOutfit then
        return
    end
    installed = true

    local addZombiesInOutfit = BanditCompatibility.AddZombiesInOutfit

    BanditCompatibility.AddZombiesInOutfit = function(x, y, z, ...)
        local sx, sy, sz = resolveSpawn(x, y, z)
        if not sx then
            -- The mod's own "no valid spawn point" path returns an empty list,
            -- so callers already cope with getting nothing back.
            return ArrayList.new()
        end
        return addZombiesInOutfit(sx, sy, sz, ...)
    end

    -- BanditServer only exists server-side; in single player and on a co-op
    -- host the spawner file is loaded too, but a dedicated client has neither.
    if BanditServer and BanditServer.Spawner then
        -- spawnIndividual and spawnRestore both call zombieList:get(0) without
        -- checking the size, which would throw on the empty list above. Both
        -- are reached only through these two globals, so refusing here keeps
        -- the block quiet instead of noisy.
        local individual = BanditServer.Spawner.Individual
        if individual then
            BanditServer.Spawner.Individual = function(player, args)
                local x = args.x or (player and player:getX())
                local y = args.y or (player and player:getY())
                local z = args.z or (player and player:getZ())
                if x and y and not resolveSpawn(x, y, z) then
                    return
                end
                return individual(player, args)
            end
        end

        local restore = BanditServer.Spawner.Restore
        if restore then
            BanditServer.Spawner.Restore = function(player, args)
                local born = args and args.bornCoords
                if born and born.x and not resolveSpawn(born.x, born.y, born.z) then
                    return
                end
                return restore(player, args)
            end
        end
    end
end

Core.installBanditHooks = install

-- Load order between two mods is not ours to decide, so the hook is installed
-- from events that all fire after every mod's Lua has been read, on whichever
-- of them this build sees first. install() is idempotent.
install()
Events.OnGameBoot.Add(install)
Events.OnServerStarted.Add(install)
Events.OnGameStart.Add(install)
