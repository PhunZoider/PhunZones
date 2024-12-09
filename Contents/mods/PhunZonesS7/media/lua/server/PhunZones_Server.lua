if not isServer() then
    return
end
local PhunZones = PhunZones
local modList

-- Adds an entry to the bounds table
function PhunZones:add(data)

    for i = #data, 1, -1 do
        local v = data[i]
        local z = self.zones[v.key]
        -- force each entry to the beggining of the table
        -- so that subsequent entries "override" previous ones
        local entry = {
            x = v.x,
            y = v.y,
            x2 = v.x2,
            y2 = v.y2,
            key = z.key,
            title = v.title or z.title or "Unknown",
            mod = v.mod or z.mod,
            subtitle = v.subtitle or z.subtitle,
            difficulty = v.difficulty or z.difficulty or 1,
            pvp = v.pvp or z.pvp,
            _key = v.x .. "_" .. v.y .. "_" .. v.x2 .. "_" .. v.y2
        }
        -- PhunTools:printTable(entry)
        table.insert(self.bounds, entry)
    end

end

-- Reloads bounds from PhunZones.lua
function PhunZones:reload()
    local data = PhunTools:loadTable("PhunZones.lua")
    if data then

        self.zones = {}
        self.chunks = {}
        local bounds = {}

        if not modList then
            modList = getActivatedMods()
        end
        for _, v in ipairs(data or {}) do
            local title = v.title or data.name
            local subtitle = v.subtitle or nil
            local isVanilla = v.isVanilla == true or nil
            local mod = v.mod or nil
            local pvp = v.pvp == true
            if mod and v.isVanilla == true then
                mod = v.mod
            end
            local key = v.key
            local isVanilla = v.isVanilla == true or nil
            if isVanilla or mod == nil or modList:contains(mod) then
                if not self.zones[key] then
                    self.zones[key] = {
                        key = key,
                        difficulty = v.difficulty or 1,
                        isVanilla = isVanilla,
                        noAnnounce = v.noAnnounce == true or nil,
                        title = title,
                        mod = mod,
                        subtitle = subtitle,
                        isVoid = v.isVoid == true or nil,
                        pvp = pvp
                    }
                elseif v.title and not self.zones[key].title then
                    self.zones[key].title = title
                end
                if v.bounds then
                    for _, vv in ipairs(v.bounds) do
                        vv.key = key
                        vv.title = vv.title or title
                        vv.subtitle = vv.subtitle or subtitle
                        vv.noAnnounce = vv.noAnnounce or v.noAnnounce or nil
                        -- vv.difficulty = vv.difficulty or data.difficulty or 1
                        vv.isVoid = vv.isVoid or v.isVoid or nil
                        table.insert(bounds, vv)

                        -- how many x chunks are there?
                        local chunksx = math.ceil((vv.x2 - vv.x) / 300)
                        local chunksy = math.ceil((vv.y2 - vv.y) / 300)

                        for i = 0, chunksx do
                            for j = 0, chunksy do
                                local cx = math.floor(vv.x / 300)
                                local cy = math.floor(vv.y / 300)
                                local key = cx .. "_" .. cy
                                if not self.chunks[key] then
                                    self.chunks[key] = {}
                                end
                                table.insert(self.chunks[key], vv)
                            end
                        end
                    end
                end
            else
                print("Skipping " .. tostring(key) .. " because mod " .. tostring(mod) .. " is not active")

            end

        end

        self.bounds = {}
        self:add(bounds)

        -- print("CHUNKS")
        -- PhunTools:printTable(self.chunks)

        -- readd to moddata for persistence and easy client sync?
        ModData.add(self.name .. "_zones", self.zones)
        ModData.add(self.name .. "_bounds", self.bounds)
        -- ModData.add(self.name .. "_chunks", self.chunks)
    end
end

function PhunZones:getFormattedBounds()
    local bounds = self.bounds
    local zones = {}

    local result = {}
    for k, v in pairs(self.zones) do
        result[k] = v
        result[k].bounds = {}
    end
    for _, v in ipairs(self.bounds) do
        local z = result[v.key]
        local line = {}
        for k, vv in pairs(v) do
            if k ~= "key" then
                line[k] = vv
            end
        end
        if line.title ~= nil and line.title == z.title then
            line.title = nil
        end
        if line.subtitle ~= nil and line.subtitle == z.subtitle then
            line.subtitle = nil
        end
        if line.mod ~= nil and line.mod == z.mod then
            line.mod = nil
        end
        if line.difficulty ~= nil and line.difficulty == z.difficulty then
            line.difficulty = nil
        end
        if line.pvp ~= nil and line.pvp == z.pvp then
            line.pvp = nil
        end
        table.insert(z.bounds, line)
    end

    return result

end

function PhunZones:export()
    if PhunTools then
        local list = self:getFormattedBounds()
        PhunTools:saveTable("PhunZones.lua", list)
        return list.result
    end
end

local Commands = {}

Commands[PhunZones.commands.reload] = function()
    PhunZones:reload()
end

-- Commands[PhunZones.commands.requestData] = function(playerObj)
--     ModData.transmit(playerObj, PhunZones.name .. "_zones")
--     ModData.transmit(playerObj, PhunZones.name .. "_bounds")
-- end

Events.OnClientCommand.Add(function(module, command, playerObj, arguments)
    if module == PhunZones.name and Commands[command] then
        Commands[command](playerObj, arguments)
    end
end)

