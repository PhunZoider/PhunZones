require "PhunZones/core"
local PZ = PhunZones

function PZ:processDataSet(data, doAll)
    local regions = {}
    local chunks = {}
    local mods = getActivatedMods()
    local warnings = {}

    local changes = ModData.getOrCreate(PZ.name .. "_Changes") or {}

    for k, v in pairs(changes) do

        if not regions[k] then
            regions[k] = v
        else

            for prop, propVal in pairs(v) do
                if prop ~= "areas" then
                    regions[k][prop] = propVal
                end
            end

            for ak, av in pairs(v.areas or {}) do
                if not regions[k].areas then
                    regions[k].areas = {}
                end
                if not regions[k].areas[ak] then
                    regions[k].areas[ak] = av
                else
                    for k, v in pairs(av) do
                        regions[k].areas[ak][k] = v
                    end
                end

            end
        end
    end

    for regionKey, regionValue in pairs(data or {}) do

        local skipRegion = false
        local changeRegion = changes[regionKey] or {}

        if doAll ~= true then
            local mod = changeRegion.mod or regionValue.mod
            if changeRegion.disabled == true or regionValue.disabled == true then
                skipRegion = true
            elseif (mod and not mods:contains(mod)) then
                skipRegion = true
            end
        end

        if not skipRegion then

            regions[regionKey] = {
                areas = {}
            }
            for k, v in pairs(regionValue or {}) do
                if k ~= "areas" then
                    regions[regionKey][k] = v
                end
            end

            for areaKey, areaValue in pairs(regionValue.areas or {}) do

                local skipArea = false

                if doAll ~= true then
                    if areaValue.disabled == true then
                        skipArea = true
                    elseif areaValue.mod and not mods:contains(areaValue.mod) then
                        skipArea = true
                    end
                end

                if not skipArea then
                    regions[regionKey].areas[areaKey] = {}
                    -- copy params from parent region
                    for k, v in pairs(regions[regionKey]) do
                        if k ~= "areas" then
                            regions[regionKey].areas[areaKey][k] = v
                        end
                    end

                    for k, v in pairs(areaValue or {}) do
                        if k ~= "points" then
                            regions[regionKey].areas[areaKey][k] = v
                        end
                    end

                    regions[regionKey].areas[areaKey].zone = regionKey
                    regions[regionKey].areas[areaKey].area = areaKey

                    for _, v in ipairs(areaValue.points or {}) do
                        local xIterations = math.floor((v[3] - v[1]) / 300)
                        local yIterations = math.floor((v[4] - v[2]) / 300)

                        for x = 0, xIterations do
                            for y = 0, yIterations do
                                local cx = math.floor(v[1] / 300) + x
                                local cy = math.floor(v[2] / 300) + y
                                local ckey = cx .. "_" .. cy
                                if not chunks[ckey] then
                                    chunks[ckey] = {}
                                end
                                table.insert(chunks[ckey], {
                                    zone = regionKey,
                                    area = areaKey,
                                    x = v[1],
                                    y = v[2],
                                    x2 = v[3],
                                    y2 = v[4]

                                })
                            end
                        end
                    end
                end
            end
        end
    end

    return {
        zones = regions,
        chunks = chunks
    }

end
