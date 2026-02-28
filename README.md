# PhunZones

A Project Zomboid mod for changing game behaviours depending on where the player is

## Features

- B42+ compatible
- Single player or Multiplayer
- Create and manage zones with special properties
- Display custom location names when entering zones
- Create zombie-free areas
- Block Bandits (requires Bandits 2)
- Prevent safehouse creation
- Restrict picking up or placing objects
- Restrict dismantling and crafting
- Block construction
- Prevent fire spread
- Block player entry to specific zones
- Zone detection works inside [Project RV Interior](https://steamcommunity.com/sharedfiles/filedetails/?id=3543229299)
- Designed to be an extensive tool that can be used stand alone and/or by other mods
- Friendly widget that helps players identify what area they are in (eg Louisville - Mall)
- Comes pre-configured with a large selection of existng maps, along with tools to modify and/or create more
- Designed for max performance

[Steam Workshop Page](https://steamcommunity.com/sharedfiles/filedetails/?id=3674596146)

## Editing Zones

You can access the Zone Editor from the Admin or Debug menu.
![UI Editor](https://github.com/PhunZoider/PhunZones/blob/main/Docs/images/ui.png)

## Zone definition

The table for zone definitions are designed for maximum flexibility and ease. By way of illustration:

The following would make a zone for westpoint. When a player entered these coordinates, they would be shown a welcome for "West Point"

```lua
    WestPoint = { -- unique key for region
        difficulty = 2, -- some property
        title = "West Point",
        points = {{11100, 6580, 13199, 7499}}
    },
```

The next example demonstrates inheritence.

```lua
    medium = {
        difficulty = 3,
        minSprinterRisk = 10 -- A prop from PhunSprionters2
    },
    MarchRidge = { -- a unique key identifying region
        title = "March Ridge",
        inherits="medium",
        points = {{9600, 12600, 10499, 13199}}
    },
    MarchRidge_Checkpoint = {
        subtitle = "Checkpoint",
        modsRequired="\\Checkpoint_March_Ridge",
        inherits="MarchRidge"

    }


```

The above configuration will mean that MarchRidge_Checkpoint get all the properties it doesn't specify from MarchRidge who get all their properties they don't specify from medium which get all their properties they don't specify from \_default. Change mediums minSprinterRisk at runtime and that cascades through MarchRidge to Checkpoint

## Built in Fields

| Property      | Type               | default   | Description                                                                                                                                                                                      | Example                                               |
| ------------- | ------------------ | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------- |
| title         | string             | nil       | Display name of current zone                                                                                                                                                                     | `title="Lousiville"`                                  |
| subtitle      | string             | nil       | optional sub text of zone                                                                                                                                                                        | `subtitle="The Mall"`                                 |
| order         | number             | nil       | optional precedence number. The higher the number, the higher the precedence this zone will have. If left nil, the precedence will be in order of process (later entries overwrite earlier ones) | `order=4`                                             |
| enabled       | bool               | true      | set to false to disable loading of this zone                                                                                                                                                     | `enabled=false`                                       |
| difficulty    | number             | nil       | An optional number to signify difficulty level to the user                                                                                                                                       | `difficulty=4`                                        |
| zeds          | `Move` \| `Remove` | none      | `Move` teleport zeds away while `Remove` despawns them. The latter is more performant but can remove player corpses                                                                              | `zeds=move`                                           |
| bandits       | `Move` \| `Remove` | none      | Same as zeds option but for bandits created via the Bandits2 mod                                                                                                                                 | `bandits=remove`                                      |
| noannounce    | bool               | false     | Do not show the title of this location to the player when they first enter                                                                                                                       | `noannounce=true`                                     |
| nosafehouse   | bool               | false     | prevent safehouses from being created in this zone                                                                                                                                               | `nosafehouse=true`                                    |
| nobuilding    | bool               | false     | prevent construction here                                                                                                                                                                        | `nobuilding=true`                                     |
| noplacing     | bool               | false     | Prevent placing objects (eg a stove) here                                                                                                                                                        | `noplacing=true`                                      |
| nopickup      | bool               | false     | Prevent picking moveables up (eg a stove)                                                                                                                                                        | `nopickup=true`                                       |
| noscrap       | bool               | false     | Prevent items from being dissasembled here                                                                                                                                                       | `noscrap=true`                                        |
| nodestruction | bool               | false     | Prevents the sledgehammer from being used here                                                                                                                                                   | `nodestruction=true`                                  |
| nofire        | bool               | false     | Prevents fire spread in this zone                                                                                                                                                                | `nofire=true`                                         |
| noplayers     | bool               | false     | Prevents players from entering this zone                                                                                                                                                         | `noplayers=true`                                      |
| modsRequired  | string             | nil       | semi-colon separated string of one or more modids that need to be active in order to load this zone. Note that B42 requires the \ prefix                                                         | `modsRequired="\phunsprinters2"`                      |
| points        | array              | none      | Array of points. Each point is in the format of `{x, y, x2, y2}`                                                                                                                                 | `points={{100, 100, 200, 200}, {300, 200, 350, 250}}` |
| inherits      | string             | \_default | the key of the zone to inherit all unspecified properties                                                                                                                                        | `inherits="_default"`                                 |

Note that the \_default zone is the built in, root that all zones ultimately inherit from

## Processing

The order of processing is as follows:

- Load all data points shipped with mod, omitting any which have modsRequired that are not loaded
- Load any of the customisations users have made from the filesystem located in `<zomboid directory>/lua/PhunZones.lua`
- Build inheritence chain
- Partition by chunk

## Extending PhunZones

There are a couple ways to extend PhunZones. If you want to add custom properties that users can set values for, add the field to PhunZones and optionally add some default values to existing zones.

The following code adds 2 fields from PhunSprinters2 into PhunZones

```lua
require "PhunZones/core"
require "PhunSprinters/core"
local Core = PhunSprinters
local PZ = PhunZones

if getActivatedMods():contains("\\phunzones2") or getActivatedMods():contains("\\phunzones2test") then

    print("PhunZones2 detected, adding zone fields for PhunSprinters")

    PZ.fields.minSprinterRisk = {
        label = "IGUI_PhunSprinters_minRisk", -- can also be text
        type = "string", -- or int or bool or combo (requires a getOptions param) or button (requires an onClick param)
        tooltip = "IGUI_PhunSprinters_minRisk_Tooltip", -- could be text
        default = "", -- default value
        group = "mods", -- section of the editor to appear in
        order = 100
    }

    PZ.fields.maxSprinterRisk = {
        label = "IGUI_PhunSprinters_maxRisk",
        type = "string",
        tooltip = "IGUI_PhunSprinters_maxRisk_Tooltip",
        default = "",
        group = "mods",
        order = 101
    }

else
    Core.debugLn("PhunZones2 not detected, using default zone data for PhunSprinters")
end

```

Optionally listen out for when a players location changes. Zone will contain all properties (including those that are inherited)

```lua
if PhunZones then

    Events[PhunZones.events.OnPhysicalZoneChanged].Add(function(player, zone)
        local zoneInfo = PhunZones.getPhysicalZone(player)
    end)

end
```

or just check via x/y coordinates or via player/zed objects

```lua

    local zone = PhunZones.getLocation(100, 100)
    local playerZone = PhunZones.getLocation(getPlayer())
    local zedInfo = PhunZones.getLocation(zombieObj)

```

The above will give you a table of all resolved properties for the location/zone.
