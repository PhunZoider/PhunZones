if isClient() then
    return
end
local Commands = require "PhunZones/server_commands"
local Core = PhunZones
local getTimestamp = getTimestamp

Events.OnClientCommand.Add(function(module, command, playerObj, arguments)
    if module == Core.name and Commands[command] then
        Commands[command](playerObj, arguments)
    end
end)

Events.OnServerStarted.Add(function()
    Core:ini()
end)

-- The engine keeps its own non-pvp zone list, and the server is the authority
-- on what belongs in it. A rebuild can add or drop zones, retitle them, or swap
-- a whole profile in, so the list is reconciled every time the data changes.
--
-- NonPvpZone.syncNonPvpZone only sends from a client, so a server-side add or
-- remove updates the server list and tells nobody. Clients that are already
-- connected therefore have to be pushed the new set by hand. A client joining
-- after this needs nothing: the engine ships the whole list in MetaDataPacket
-- as part of the connection handshake.
Events[Core.events.OnDataBuilt].Add(function()
    local rects = Core.refreshNoPvpZones()
    if isServer() then
        sendServerCommand(Core.name, Core.commands.syncNoPvp, {
            rects = rects
        })
    end
end)

