require "PhunZones/process"
local Core = PhunZones

function Core.normalizeZoneData(raw)
    local flat = {}
    for key, zone in pairs(raw) do
        if key ~= "_default" then
            local entry = {}
            -- copy all non-subzone fields
            for k, v in pairs(zone) do
                if k ~= "subzones" then
                    entry[k] = v
                end
            end
            flat[key] = entry
            -- promote subzones to top-level with inherits
            if zone.subzones then
                for subKey, sub in pairs(zone.subzones) do
                    local subEntry = {}
                    for k, v in pairs(sub) do
                        subEntry[k] = v
                    end
                    subEntry.inherits = key
                    flat[key .. "_" .. subKey] = subEntry
                end
            end
        else
            flat["_default"] = zone
        end
    end
    return flat
end
