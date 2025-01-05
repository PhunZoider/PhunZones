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

    local lookup = {}
    -- set chunks
    local cells = {}

    -- coordinates where zeds aren't allows
    self.zedless = {}

    for regionKey, regionData in pairs(results or {}) do

        for zoneKey, zoneData in pairs(regionData.zones or {}) do
            for _, v in ipairs(zoneData.zones) do
                local xIterations = math.ceil((v[3] - v[1]) / 300)
                local yIterations = math.ceil((v[4] - v[2]) / 300)
                for x = 0, xIterations do
                    for y = 0, yIterations do
                        local cx = math.ceil(v[1] / 300) + x
                        local cy = math.ceil(v[2] / 300) + y
                        local ckey = cx .. "_" .. cy
                        if not cells[ckey] then
                            cells[ckey] = {}
                        end
                        table.insert(cells[ckey], {regionKey, zoneKey, v[1], v[2], v[3], v[4]})
                    end
                end
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

