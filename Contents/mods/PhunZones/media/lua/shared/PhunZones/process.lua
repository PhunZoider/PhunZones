local PZ = PhunZones
require "PhunZones/core"
require "PhunLib/core"
local PL = PhunLib
local fileTools = PL.file
local tableTools = PL.table
local allLocations = require("PhunZones/data")

local excludedKeys = ArrayList:new();
local getActivatedMods = getActivatedMods
excludedKeys:add("points")
excludedKeys:add("subzones")

local regionExludedKeys = ArrayList:new();
regionExludedKeys:add("points")
regionExludedKeys:add("subzones")
regionExludedKeys:add("zones")
regionExludedKeys:add("zone")
regionExludedKeys:add("isDefault")

local function getEntry(entry, omitMods)

    local row = nil
    local entries = 0
    local process = true
    if omitMods then
        if entry.mods then
            process = false
            local mods = luautils.split(entry.mods .. ";", ";")
            for _, m in ipairs(mods) do
                if m and getActivatedMods():contains(m) then
                    process = true
                    break
                end
            end
        end
    end
    if process == true then
        row = tableTools.shallowCopy(entry, excludedKeys)
    else
        return nil
    end

    row.zones = {
        main = {}
    }

    local mainzones = tableTools.shallowCopy(entry.points or {})
    if mainzones then
        entries = entries + 1
        row.zones.main.points = mainzones
    end

    if entry.subzones then
        for k, v in pairs(entry.subzones or {}) do

            local process = true -- v.points and #v.points > 0

            if omitMods then
                if v.mods then
                    local mods = luautils.split(v.mods .. ";", ";")
                    for _, m in ipairs(mods) do
                        if m and not getActivatedMods():contains(m) then
                            process = false
                        end
                    end
                end
            end
            if process then
                row.zones[k] = tableTools.shallowCopy(v)
                entries = entries + 1
            end
        end
    end
    if entries == 0 then
        -- no entries have any valid points so meh
        return nil
    end
    return row
end

function PZ:getCoreZones(omitMods)

    local results = {}
    local order = 0
    local coreData = self.settings.LoadDefaults and allLocations or {}
    local all = tableTools.merge(coreData, self.extended or {})
    for key, entry in pairs(all) do
        local status, err = pcall(function()
            local e = getEntry(entry, omitMods)
            local sortzones = {}
            if e then
                e.tmpKey = key
                table.insert(sortzones, e)
            end
            table.sort(sortzones, function(a, b)
                if a.order ~= b.order then
                    return (a.order or 0) < (b.order or 0)
                end
                return false
            end)
            for _, v in ipairs(sortzones) do
                order = order + 1
                v.order = v.order or order
                results[v.tmpKey] = v
                v.tmpKey = nil
            end
        end)
        if not status then
            print("Error caught in " .. key .. ": " .. tostring(err))
        end

    end
    return results, order
end

function PZ:getModifiedZones(omitMods, maxOrder)

    local data = {}
    if not isClient() then
        -- this is a server or local game
        -- load the modified data from ./lua/PhunZones.lua
        local d = fileTools.loadTable(self.const.modifiedLuaFile)
        if d == nil then
            print("PhunZones: missing ./lua/" .. self.const.modifiedLuaFile ..
                      ", this is normal if you haven't modified any zones")
        elseif d.data then
            ModData.add(self.const.modifiedModData, d.data or {})
            data = ModData.get(self.const.modifiedModData)
            print("PhunZones: loaded customisations from ./lua/" .. self.const.modifiedLuaFile)
        elseif d.data == nil then
            print("PhunZones: Unexpected format of ./lua/" .. self.const.modifiedLuaFile .. ", cannot load data")
        end
    end
    data = ModData.get(self.const.modifiedModData)
    if data == nil then
        data = {}
        ModData.add(self.const.modifiedModData, data)
    end

    local results = {}
    local order = (maxOrder or 0) + 1
    for key, entry in pairs(data) do
        local status, err = pcall(function()
            PL.debug("Processing modified zone: " .. key)
            local e = getEntry(entry, omitMods)
            local sortzones = {}
            if e then
                e.tmpKey = key
                table.insert(sortzones, e)
            end
            table.sort(sortzones, function(a, b)
                if a.order ~= b.order then
                    return (a.order or 0) < (b.order or 0)
                end
                return false
            end)
            for _, v in ipairs(sortzones) do
                order = order + 1
                v.order = v.order or order
                results[v.tmpKey] = v
                v.tmpKey = nil
            end
        end)
        if not status then
            print("Error caught in " .. key .. ": " .. tostring(err))
        end
    end
    return results
end

function PZ:updateZoneData(omitMods, modifiedDataSet)

    local core, maxOrder = self:getCoreZones(omitMods)
    local modified = self:getModifiedZones(omitMods, maxOrder) or {}
    -- PhunLib:debug("======== modified zones =========", tostring(omitMods), modifiedDataSet, "====")
    local results = tableTools.merge(modified or {}, core or {})
    -- Flatten all entries down into a single array for sorting
    local flattened = {}
    local order = 0
    for k, v in pairs(results) do
        for k2, v2 in pairs(v.zones or {}) do
            if v2.order then
                order = math.max(order, v2.order)
            end
            for k3, v3 in pairs(v2.points or {}) do
                table.insert(flattened, {k, k2, v2.order, v3[1], v3[2], v3[3], v3[4]})
            end
        end
    end
    -- iterate through all to set the order.
    -- if order is set, add the total entries to the specified order
    -- to ensure it comes AFTER the entries that have none specificed
    for i, v in ipairs(flattened) do
        if not v[3] then
            v[3] = i
        else
            v[3] = i + order + v[3]
        end
    end

    -- Sort by the order descending.
    -- this ensures we honour the specified order
    -- as well as the "last one overwrites" rule
    table.sort(flattened, function(a, b)
        if a[3] ~= b[3] then
            return a[3] > b[3]
        end
        return false
    end)

    local lookup = {}
    -- set chunks
    local cells = {}

    -- Group by chunks for faster lookup
    for _, v in ipairs(flattened) do
        -- 1 = region key
        -- 2 = zone key
        -- 3 = order
        -- 4 = x1
        -- 5 = y1
        -- 6 = x2
        -- 7 = y2
        local xIterations = (math.floor((v[6] - v[4]) / 300) + 1)
        local yIterations = (math.floor((v[7] - v[5]) / 300) + 1)
        for x = 0, xIterations do
            for y = 0, yIterations do
                local cx = math.floor(v[4] / 300) + x
                local cy = math.floor(v[5] / 300) + y
                local ckey = cx .. "_" .. cy
                if not cells[ckey] then
                    cells[ckey] = {}
                end
                table.insert(cells[ckey], {v[1], v[2], v[4], v[5], v[6], v[7]})
            end
        end
    end

    -- coordinates where zeds aren't allows
    self.zedless = {}

    local _default = {}
    for regionKey, regionData in pairs(results or {}) do
        if regionKey == "_default" then
            regionData.isDefault = true
            regionData.zones = nil
            lookup._default = regionData
            _default = regionData
        end
    end

    for regionKey, regionData in pairs(results or {}) do
        if regionKey ~= "_default" then

            local inherited = tableTools.merge(_default, regionData, regionExludedKeys) or {}
            inherited.region = regionKey

            for zoneKey, zoneData in pairs(regionData.zones or {}) do

                inherited.zone = zoneKey
                local merged = tableTools.merge(inherited, zoneData, excludedKeys)
                if not lookup[regionKey] then
                    lookup[regionKey] = {}
                end
                lookup[regionKey][zoneKey] = merged
            end
        end

    end

    if omitMods then
        -- print("Storing zones globally")
        self.data = {
            cells = cells,
            zones = results,
            lookup = lookup
        }
    end

    return {
        cells = cells,
        zones = results,
        lookup = lookup
    }
end

