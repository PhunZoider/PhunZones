local luautils = luautils
local loadstring = loadstring
local tools = {}

--- transforms and returns an array of strings into a table
--- @param tableOfStrings table<string>
--- @return table
function tools:tableOfStringsToTable(tableOfStrings)
    -- Error handling for invalid input
    if not tableOfStrings or type(tableOfStrings) ~= "table" or #tableOfStrings == 0 then
        return nil, " - Invalid input: file contents are not a valid table"
    end

    local concatenatedString
    local startsWithReturn = string.sub(tableOfStrings[1], 1, string.len("return")) == "return"
    if startsWithReturn then
        -- Input already includes "return", concatenate as is
        concatenatedString = table.concat(tableOfStrings, "\n")
    else
        -- Wrap the input in a "return" statement
        concatenatedString = "return {\n" .. table.concat(tableOfStrings, "\n") .. "\n}"
    end

    -- Safely execute the concatenated string
    local status, loadstringResult = pcall(loadstring, concatenatedString)
    if not status then
        return nil, " - Error in loadstring: " .. loadstringResult
    end

    local res
    status, res = pcall(loadstringResult)
    if not status then
        return nil, " - Error executing loadstring result: " .. res
    end

    return res, nil
end

function tools:tableOfStringsToTableold(tableOfStrings)
    -- Error handling for accessing the first element
    if not tableOfStrings or type(tableOfStrings) ~= "table" or #tableOfStrings == 0 then
        return nil, " - Invalid input: file contents are not a valid table"
    end

    local startsWithReturn = string.sub(tableOfStrings[1], 1, string.len("return")) == "return"
    local res = nil
    local status, loadstringResult

    if startsWithReturn == true then
        status, loadstringResult = pcall(loadstring, table.concat(tableOfStrings, "\n"))
    else
        status, loadstringResult = pcall(loadstring, "return {" .. table.concat(tableOfStrings, "\n") .. "}")
    end

    if not status then
        return nil, " - Error in loadstring: " .. loadstringResult
    end

    status, res = pcall(loadstringResult)
    if not status then
        return nil, " - Error executing loadstring result: " .. res
    end

    return res, nil
end

--- loads a table from a file
--- @param filename string path to the file contained in Lua folder of server
--- @return table
function tools:loadTable(filename, createIfNotExists)
    local res
    local data = {}
    local fileReaderObj = getFileReader(filename, createIfNotExists == true)
    if not fileReaderObj then
        return nil
    end
    local line = fileReaderObj:readLine()
    local startsWithReturn = nil
    while line do
        if startsWithReturn == nil then
            luautils.stringStarts = function(String, Start)
                return string.sub(String, 1, string.len(Start)) == Start;
            end
            startsWithReturn = luautils.stringStarts(line, "return")
        end
        data[#data + 1] = line
        line = fileReaderObj:readLine()
    end
    fileReaderObj:close()

    local result, err = self:tableOfStringsToTable(data)

    if err then
        print("Error loading file " .. filename .. ": " .. err)
    else
        return result
    end

end

--- saves a table to a file
--- @param fname string path to the file contained in Lua folder of server
--- @param data table
function tools:saveTable(fname, data)
    if not data then
        return
    end
    local fileWriterObj = getFileWriter(fname, true, false)
    local serialized = self:serializeTable(data, true)
    fileWriterObj:write("return " .. serialized .. "")
    fileWriterObj:close()
end

return tools
