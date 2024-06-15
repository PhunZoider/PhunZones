if not isServer() then
    return
end
local PhunZones = PhunZones
local modList

-- Adds an entry to the bounds table
function PhunZones:add(data)

    local key = data.key

    if not modList then
        modList = getActivatedMods()
    end

    local title = data.title or data.name
    local subtitle = data.subtitle or nil
    local isVanilla = data.isVanilla == true or nil
    local mod = data.mod or nil
    local pvp = data.pvp == true
    if mod and data.isVanilla == true then
        mod = data.mod
    end

    if not self.zones[key] then
        self.zones[key] = {
            key = key,
            difficulty = data.difficulty or 1,
            isVanilla = isVanilla,
            noAnnounce = data.noAnnounce == true or nil,
            title = title,
            mod = mod,
            subtitle = subtitle,
            isVoid = data.isVoid == true or nil,
            pvp = pvp
        }
    end

    local z = self.zones[key]

    for _, v in ipairs(data.bounds or {}) do
        table.insert(self.bounds, {
            x = v.x,
            y = v.y,
            x2 = v.x2,
            y2 = v.y2,
            key = key,
            title = v.title or z.title,
            mod = v.mod or z.mod,
            subtitle = v.subtitle or z.subtitle,
            difficulty = v.difficulty or z.difficulty or 1,
            pvp = v.pvp or z.pvp,
            _key = v.x .. "_" .. v.y .. "_" .. v.x2 .. "_" .. v.y2
        })
    end

end

-- Reloads bounds from PhunZones.lua
function PhunZones:reload()
    local data = PhunTools:loadTable("PhunZones.lua")
    if data then
        self.zones = {}
        self.bounds = {}
        for k, v in pairs(data) do
            self:add(v)
        end
        local bounds = self.bounds
        ModData.add(self.name, {
            bounds = bounds
        })
        ModData.transmit(self.name)
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

Commands[PhunZones.commands.requestData] = function(playerObj)
    sendServerCommand(playerObj, PhunZones.name, PhunZones.commands.requestData, PhunZones.bounds)
end

Events.OnClientCommand.Add(function(module, command, playerObj, arguments)
    if module == PhunZones.name and Commands[command] then
        Commands[command](playerObj, arguments)
    end
end)

