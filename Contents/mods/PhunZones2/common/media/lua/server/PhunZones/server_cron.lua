if isClient() then
    return
end

local Core = PhunZones

-- ---------------------------------------------------------------------------
-- Optional PhunServer2Cron integration.
--
-- PhunZones does not depend on PhunServer2. When it is absent this file
-- registers nothing and profiles are still driveable from /zoneprofile and from
-- Lua via Core.setActiveProfile.
--
-- Registration is deferred to OnServerStarted because load order between two
-- independent mods is not guaranteed. The cron runner resolves an action by
-- name at fire time, not at load time, so this is early enough for any job.
--
-- Example jobs in <Zomboid>/Lua/PhunServer2Cron.json:
--
--   "closeLouisville": {
--       "enabled": true, "action": "zoneprofile", "at": "22:00",
--       "args": { "profile": "night" },
--       "announcements": [ { "before": 600, "text": "Louisville closes in 10 minutes" } ]
--   },
--   "openLouisville": {
--       "enabled": true, "action": "zoneprofile", "at": "06:00",
--       "args": { "profile": "none" }
--   }
-- ---------------------------------------------------------------------------
Events.OnServerStarted.Add(function()
    if not PhunServer2 or type(PhunServer2.registerAction) ~= "function" then
        return
    end

    PhunServer2.registerAction("zoneprofile", {
        label = "IGUI_PhunZones_Action_ZoneProfile",
        fields = {
            profile = {
                type = "string",
                default = "",
                label = "IGUI_PhunZones_Field_Profile"
            }
        },
        handler = function(job, args)
            -- The cron runner only shallow-copies args, so this table is still
            -- the loaded job config one level down. Read from it, never mutate.
            local name = args and args.profile or ""
            local ok, err = Core.setActiveProfile(name)
            if not ok then
                print("PhunZones: job '" .. tostring(job and job.name) .. "' could not activate profile: " ..
                          tostring(err))
            end
        end
    })
end)
