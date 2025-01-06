local PZ = PhunZones
require "PhunZones/core"
local tableTools = require("PhunZones/table")
local fileTools = require("PhunZones/files")
local allLocations = require("PhunZones/data")

local excludedKeys = ArrayList:new();
local getActivatedMods = getActivatedMods
excludedKeys:add("children")
excludedKeys:add("zones")

local function getEntry(entry, omitMods)

    local row = nil

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
        row = tableTools:shallowCopyTable(entry, excludedKeys)
    else
        return nil
    end

    local mainzones = tableTools:shallowCopyTable(entry.zones)
    row.zones = {
        main = {
            zones = mainzones
        }
    }

    if entry.zones then
        for k, v in pairs(entry.zones) do
            local process = true
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
                row.zones[k] = tableTools:shallowCopyTable(v)
            end
        end
    end
    return row
end

function PZ:getCoreZones(omitMods)

    local results = {}
    local order = 0
    for key, entry in pairs(allLocations) do
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
    end
    return results
end

function PZ:getModifiedZones(omitMods)

    local data = fileTools:loadTable(self.const.modifiedLuaFile) or {}
    ModData.add(self.const.modifiedModData, data)
    local results = {}
    local order = 0
    for key, entry in pairs(data) do
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
    end
    return results
end

function PZ:getZones(omitMods, modifiedDataSet)

    local core = self:getCoreZones(omitMods)
    local modified = modifiedDataSet or self:getModifiedZones(omitMods)
    local results = tableTools:mergeTables(core or {}, modified or {})

    -- Flatten all entries down into a single array for sorting
    local flattened = {}
    local order = 0
    for k, v in pairs(results) do
        for k2, v2 in pairs(v.zones) do
            if v2.order then
                order = math.max(order, v2.order)
            end
            for k3, v3 in pairs(v2.zones) do
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

    for regionKey, regionData in pairs(results or {}) do

        for zoneKey, zoneData in pairs(regionData.zones or {}) do
            for _, v in ipairs(zoneData.zones) do
                -- local xIterations = (math.floor((v[3] - v[1]) / 300) + 1)
                -- local yIterations = (math.floor((v[4] - v[2]) / 300) + 1)
                -- for x = 0, xIterations do
                --     for y = 0, yIterations do
                --         local cx = math.floor(v[1] / 300) + x
                --         local cy = math.floor(v[2] / 300) + y
                --         local ckey = cx .. "_" .. cy
                --         if not cells[ckey] then
                --             cells[ckey] = {}
                --         end
                --         table.insert(cells[ckey], {regionKey, zoneKey, v[1], v[2], v[3], v[4]})
                --     end
                -- end
                if zoneData.zeds == false then
                    table.insert(self.zedless, v)
                end
            end
            local z = tableTools:shallowCopyTable(zoneData, excludedKeys) or {}

            z.region = regionKey
            z.zone = zoneKey
            local merged = tableTools:mergeTables(regionData, z, excludedKeys)
            if not lookup[regionKey] then
                lookup[regionKey] = {}
            end
            lookup[regionKey][zoneKey] = merged
        end
    end

    if omitMods then
        self.data = {
            cells = cells,
            zones = results,
            lookup = lookup
        }
    end

    -- print("ZONES: ")
    -- self:printTable(self.data.zones)
    -- print(" /ZONES ")

    -- print("LOOKUP: ")
    -- self:printTable(self.data.lookup)
    -- print(" /LOOKUP ")

    return {
        cells = cells,
        zones = results,
        lookup = lookup
    }
end

