-- PZTheMutants spawn rates per zone.
--
-- The Mutants mod decides what a zombie becomes on the server, a tick or so
-- after it is created. It takes the variant number (1-500) out of the zombie's
-- persistent outfit ID and looks it up in a table built once at startup from
-- the six *SpawnPercentage sandbox options. A variant that maps to a Mutant
-- type gets that Mutant's outfit, and from then on the zombie is that Mutant
-- for good. One that maps to nothing stays normal, and is asked again the
-- next time it is created (a chunk reload, say).
--
-- A zone can set its own percentage for each type. Empty means the sandbox
-- value, 0 means none of that type spawn here. The zone's percentages go
-- through the Mutants mod's own normalisation and are laid out over the
-- variants the same way its table is, so the same zombie always gets the same
-- answer in the same zone.
--
-- Mutants has no public hook for this, so two of its internals are wrapped.
-- Both are called once per classification, back to back:
--   ForeignOwnership.isClaimed(zombie, outfit) - gets the zombie, so the zone
--     it is standing in is noted here.
--   Classification.getTypeForVariant(variant) - answered from that zone's
--     table when it sets any rate of its own.
-- If either is missing (an update renamed them) nothing is wrapped and the
-- sandbox rates apply everywhere.
--
-- The rate that applies is the one where the zombie is classified, not where
-- it goes afterwards: a Mutant that walks into a zone set to 0 stays a Mutant.
local Core = PhunZones

if not getActivatedMods():contains("PZTheMutants") then
    return
end

-- In the order PZM_Classification fills its table. key is the entry in
-- PZTheMutants.MutantTypes, sandbox the option name under SandboxVars.PZTheMutants.
local TYPES = {{
    key = "PUKER",
    field = "mutantPuker",
    label = "IGUI_PhunZones_MutantPuker",
    sandbox = "PukerSpawnPercentage"
}, {
    key = "HUSK",
    field = "mutantHusk",
    label = "IGUI_PhunZones_MutantHusk",
    sandbox = "HuskSpawnPercentage"
}, {
    key = "SKITTER",
    field = "mutantSkitter",
    label = "IGUI_PhunZones_MutantSkitter",
    sandbox = "SkitterSpawnPercentage"
}, {
    key = "WRECKER",
    field = "mutantWrecker",
    label = "IGUI_PhunZones_MutantWrecker",
    sandbox = "WreckerSpawnPercentage"
}, {
    key = "LEAPER",
    field = "mutantLeaper",
    label = "IGUI_PhunZones_MutantLeaper",
    sandbox = "LeaperSpawnPercentage"
}, {
    key = "WEEPER",
    field = "mutantWeeper",
    label = "IGUI_PhunZones_MutantWeeper",
    sandbox = "WeeperSpawnPercentage"
}}

local function clampPercentage(v)
    if type(v) ~= "number" then
        return v
    end
    return math.max(0, math.min(100, v))
end

Core.groups.mutants = {
    label = "Mutants",
    order = 6
}

for i, t in ipairs(TYPES) do
    Core.fields[t.field] = {
        label = t.label,
        type = "double",
        tooltip = "IGUI_PhunZones_MutantSpawn_tooltip",
        group = "mutants",
        order = i,
        normalize = clampPercentage
    }
end

-- Classification only ever runs where the Mutants server code does: the
-- server, or single player.
if isClient() then
    return
end

local installed = false
local warned = false

-- zone key -> variant -> Mutant type, or false for a zone that sets no rate
-- of its own and so uses the Mutants mod's table.
local zoneTables = {}

-- The zone of the zombie being classified, from isClaimed to getTypeForVariant.
local pendingZone = nil

Events[Core.events.OnDataBuilt].Add(function()
    zoneTables = {}
end)

local function buildTable(zone)
    local mutants = PZTheMutants
    local sandbox = SandboxVars.PZTheMutants or {}
    local raw = {}
    local overridden = false

    for _, t in ipairs(TYPES) do
        local v = tonumber(zone[t.field])
        if v ~= nil then
            overridden = true
        else
            -- The Mutants mod's own fallback for a missing option is 0 too.
            v = tonumber(sandbox[t.sandbox]) or 0
        end
        raw[mutants.MutantTypes[t.key]] = v
    end

    if not overridden then
        return false
    end

    -- Same layout as Classification.rebuild: slot n is variant n + 1, and the
    -- last slot is variant 1, which is only reached when every slot is used.
    local slotCounts = mutants.Sandbox.normalizeSpawnPercentages(raw)
    local variantCount = mutants.PERSISTENT_OUTFIT_VARIANT_COUNT
    local variants = {}
    local assigned = 0

    for _, t in ipairs(TYPES) do
        local mutantType = mutants.MutantTypes[t.key]
        local count = math.min(slotCounts[mutantType] or 0, variantCount - assigned)
        for _ = 1, count do
            assigned = assigned + 1
            variants[assigned == variantCount and 1 or assigned + 1] = mutantType
        end
    end

    return variants
end

local function tableFor(zone)
    local key = zone.key or "_default"
    local variants = zoneTables[key]
    if variants == nil then
        variants = buildTable(zone)
        zoneTables[key] = variants
    end
    return variants
end

local function install()
    if installed then
        return
    end
    local mutants = PZTheMutants
    if not (mutants and mutants.ForeignOwnership and mutants.ForeignOwnership.isClaimed and mutants.Classification and
        mutants.Classification.getTypeForVariant and mutants.Sandbox and mutants.Sandbox.normalizeSpawnPercentages and
        mutants.MutantTypes and type(mutants.PERSISTENT_OUTFIT_VARIANT_COUNT) == "number") then
        return
    end
    installed = true

    local ownership = mutants.ForeignOwnership
    local classification = mutants.Classification
    local isClaimed = ownership.isClaimed
    local getTypeForVariant = classification.getTypeForVariant

    ownership.isClaimed = function(zombie, outfitName)
        local claimed, owner, reason = isClaimed(zombie, outfitName)
        pendingZone = nil
        if not claimed and zombie then
            pendingZone = Core.getLocation(zombie:getX(), zombie:getY())
        end
        return claimed, owner, reason
    end

    classification.getTypeForVariant = function(variant)
        local zone = pendingZone
        pendingZone = nil
        local variants = zone and tableFor(zone)
        if not variants then
            return getTypeForVariant(variant)
        end
        if type(variant) ~= "number" then
            return nil
        end
        return variants[variant]
    end

    Core.debugLn("PZTheMutants zone spawn rates installed")
end

-- Called from the events that fire once every mod's Lua is loaded. If the
-- Mutants internals still aren't there, say so once: zone rates are being
-- ignored and an admin setting them should know why.
local function installOrWarn()
    install()
    if not installed and not warned then
        warned = true
        Core.logLn("PZTheMutants is active but its classification could not be hooked; zone mutant rates are ignored")
    end
end

install()
Events.OnGameBoot.Add(install)
Events.OnServerStarted.Add(installOrWarn)
Events.OnGameStart.Add(installOrWarn)
