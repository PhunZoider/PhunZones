local PZ = PhunZones

function PZ:refreshChanges()
    local data = PhunTools:loadTable("PhunZone_Changes.lua")
    if data then
        ModData.add(PZ.name .. "_Changes", data)
        self:processDataSet()
    end
end
