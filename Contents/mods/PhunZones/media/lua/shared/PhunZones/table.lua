local tools = {}

--- returns a shallow copy of a table
--- @param original table
--- @return table
function tools:shallowCopyTable(original, excludeKeys)
    excludeKeys = excludeKeys or ArrayList.new();
    local copy = {}
    for key, value in pairs(original or {}) do
        if not excludeKeys:contains(key) then
            copy[key] = value
        end
    end
    return copy
end

--- returns a deep copy of a table
--- @param original table
--- @return table
function tools:deepCopyTable(original, excludeKeys)
    excludeKeys = excludeKeys or ArrayList.new();
    local orig_type = type(original)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(original) do
            if not excludeKeys:contains(orig_key) then
                copy[self:deepCopyTable(orig_key)] = self:deepCopyTable(orig_value, excludeKeys)
            end
        end
        setmetatable(copy, self:deepCopyTable(getmetatable(original)))
    else -- number, string, boolean, etc
        copy = original
    end
    return copy
end

-- Function to merge two tables without mutating the originals
function tools:mergeTables(tableA, tableB, excludeKeys)
    local mergedTable = {}
    excludeKeys = excludeKeys or ArrayList.new();
    -- Copy entries from tableA to mergedTable
    for k, v in pairs(tableA or {}) do
        if not excludeKeys:contains(k) then
            if type(v) == "table" then
                mergedTable[k] = self:mergeTables(v, {}) -- Ensure nested tables are copied as well
            else
                mergedTable[k] = v
            end
        end
    end

    -- Copy entries from tableB to mergedTable, overwriting duplicates from tableA
    for k, v in pairs(tableB or {}) do
        if not excludeKeys:contains(k) then
            if type(v) == "table" then
                mergedTable[k] = self:mergeTables(v, mergedTable[k] or {}) -- Ensure nested tables are copied as well
            else
                mergedTable[k] = v
            end
        end
    end

    return mergedTable
end

return tools
