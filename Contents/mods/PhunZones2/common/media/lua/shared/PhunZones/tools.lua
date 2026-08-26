local json = require("PhunZones/json")
local tools = {}

tools.isLocal = not isClient() and not isServer() and not isCoopHost()

function tools.debug(...)

    local args = {...}
    for i, v in ipairs(args) do
        if type(v) == "table" then
            tools.printTable(v)
        else
            print(tostring(v))
        end
    end

end

function tools.printTable(t, indent)
    indent = indent or ""
    for key, value in pairs(t or {}) do
        if type(value) == "table" then
            print(indent .. key .. ":")
            tools.printTable(value, indent .. "  ")
        elseif type(value) ~= "function" then
            print(indent .. key .. ": " .. tostring(value))
        end
    end
end

function tools.getPlayerByUsername(name, caseSensitive)
    local online = tools.onlinePlayers()
    local text = caseSensitive and name or name:lower()
    for i = 0, online:size() - 1 do
        local player = online:get(i);
        if (caseSensitive and player:getUsername() == name) or
            (not caseSensitive and player:getUsername():lower() == text) then
            return player
        end
    end
    return nil
end

function tools.onlinePlayers(all)

    local onlinePlayers;

    if tools.isLocal then
        onlinePlayers = ArrayList.new();
        local p = getPlayer()
        onlinePlayers:add(p);
    elseif all ~= false and isClient() then
        onlinePlayers = ArrayList.new();
        for i = 0, getOnlinePlayers():size() - 1 do
            local player = getOnlinePlayers():get(i);
            if player:isLocalPlayer() then
                onlinePlayers:add(player);
            end
        end
    else
        onlinePlayers = getOnlinePlayers();
    end

    return onlinePlayers;
end

function tools.isAdmin()

    return (getAccessLevel and (getAccessLevel() == "moderator" or getAccessLevel() == "admin")) or false

end

-- ---------------------------------------------------------------------------
-- SHALLOW COPY
-- Returns a shallow copy of a table, optionally excluding specified keys.
-- Nested tables are not copied — they remain as shared references.
--
-- @param original    table
-- @param excludeKeys table|nil  array of keys to omit  e.g. {"points", "inherits"}
-- @return            table
-- ---------------------------------------------------------------------------
function tools.shallowCopy(original, excludeKeys)
    local exclude = {}
    for _, k in ipairs(excludeKeys or {}) do
        exclude[k] = true
    end
    local copy = {}
    for key, value in pairs(original or {}) do
        if not exclude[key] then
            copy[key] = value
        end
    end
    return copy
end

-- ---------------------------------------------------------------------------
-- DEEP COPY
-- Returns a fully independent deep copy of a table, optionally excluding
-- specified keys. Metatables are copied as-is (shallow reference).
-- Safe for nested zone property tables.
--
-- @param original    table
-- @param excludeKeys table|nil  array of keys to omit
-- @return            table
-- ---------------------------------------------------------------------------
function tools.deepCopy(original, excludeKeys)
    local exclude = {}
    for _, k in ipairs(excludeKeys or {}) do
        exclude[k] = true
    end

    local function _copy(obj)
        if type(obj) ~= "table" then
            return obj
        end
        local result = {}
        for k, v in pairs(obj) do
            if not exclude[k] then
                result[_copy(k)] = _copy(v)
            end
        end
        setmetatable(result, getmetatable(obj))
        return result
    end

    return _copy(original)
end

-- ---------------------------------------------------------------------------
-- TABLE SERIALISATION
-- Converts a Lua table to JSON for safe storage and import/export.
-- ---------------------------------------------------------------------------
function tools.tableToString(tbl)
    local result, err = json.encode(tbl)
    if not result then
        error(err)
    end
    return result
end

function tools.jsonToTable(src)
    return json.decode(src)
end

-- ---------------------------------------------------------------------------
-- SAVE TABLE
-- Serialises a table as JSON and writes it to the server Lua folder.
--
-- @param filename  string  path relative to the server Lua folder
-- @param data      table   the table to serialise and save
-- ---------------------------------------------------------------------------
function tools.saveTable(filename, data)
    if not data then
        return
    end
    local fileWriterObj = getFileWriter(filename, true, false)
    local result, err = json.encode(data)
    if not result then
        fileWriterObj:close()
        error(err)
    end
    fileWriterObj:write(result)
    fileWriterObj:close()
end

-- ---------------------------------------------------------------------------
-- LOAD TABLE
-- Reads and decodes a JSON file from the server Lua folder.
-- Returns nil if the file does not exist or cannot be parsed.
--
-- @param filename          string   path relative to the server Lua folder
-- @param createIfNotExists boolean  if true, creates the file if missing
-- @return                  table|nil
-- ---------------------------------------------------------------------------
function tools.loadTable(filename, createIfNotExists)
    local fileReaderObj = getFileReader(filename, createIfNotExists == true)
    if not fileReaderObj then
        return nil
    end

    local lines = {}
    local line = fileReaderObj:readLine()
    while line do
        lines[#lines + 1] = line
        line = fileReaderObj:readLine()
    end
    fileReaderObj:close()

    -- Guard against empty files
    if #lines == 0 then
        return nil
    end

    local result, err = json.decode(table.concat(lines, "\n"))
    if err then
        print("PhunZones file_utils: error loading '" .. filename .. "': " .. err)
        return nil
    end

    return result
end

return tools
