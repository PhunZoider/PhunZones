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

{% raw %}

```lua
    WestPoint = { -- unique key for region
        difficulty = 2, -- some property
        title = "West Point",
        points = {{11100, 6580, 13199, 7499}}
    },
```

{% endraw %}

The next example demonstrates inheritence.

{% raw %}

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

{% endraw %}

The above configuration will mean that MarchRidge_Checkpoint get all the properties it doesn't specify from MarchRidge who get all their properties they don't specify from medium which get all their properties they don't specify from \_default. Change mediums minSprinterRisk at runtime and that cascades through MarchRidge to Checkpoint

## Built in Fields

| Property      | Type               | default | Description                                                                                                                                                                                      | Example                          |
| ------------- | ------------------ | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------- |
| title         | string             | nil     | Display name of current zone                                                                                                                                                                     | `title="Lousiville"`             |
| subtitle      | string             | nil     | optional sub text of zone                                                                                                                                                                        | `subtitle="The Mall"`            |
| order         | number             | nil     | optional precedence number. The higher the number, the higher the precedence this zone will have. If left nil, the precedence will be in order of process (later entries overwrite earlier ones) | `order=4`                        |
| enabled       | bool               | true    | set to false to disable loading of this zone                                                                                                                                                     | `enabled=false`                  |
| difficulty    | number             | nil     | An optional number to signify difficulty level to the user                                                                                                                                       | `difficulty=4`                   |
| zeds          | `Move` \| `Remove` | none    | `Move` teleport zeds away while `Remove` despawns them. The latter is more performant but can remove player corpses                                                                              | `zeds=move`                      |
| bandits       | `Move` \| `Remove` | none    | Same as zeds option but for bandits created via the Bandits2 mod                                                                                                                                 | `bandits=remove`                 |
| noannounce    | bool               | false   | Do not show the title of this location to the player when they first enter                                                                                                                       | `noannounce=true`                |
| nosafehouse   | bool               | false   | prevent safehouses from being created in this zone                                                                                                                                               | `nosafehouse=true`               |
| nobuilding    | bool               | false   | prevent construction here                                                                                                                                                                        | `nobuilding=true`                |
| noplacing     | bool               | false   | Prevent placing objects (eg a stove) here                                                                                                                                                        | `noplacing=true`                 |
| nopickup      | bool               | false   | Prevent picking moveables up (eg a stove)                                                                                                                                                        | `nopickup=true`                  |
| noscrap       | bool               | false   | Prevent items from being dissasembled here                                                                                                                                                       | `noscrap=true`                   |
| nodestruction | bool               | false   | Prevents the sledgehammer from being used here                                                                                                                                                   | `nodestruction=true`             |
| nofire        | bool               | false   | Prevents fire spread in this zone                                                                                                                                                                | `nofire=true`                    |
| noplayers     | bool               | false   | Prevents players from entering this zone                                                                                                                                                         | `noplayers=true`                 |
| modsRequired  | string             | nil     | semi-colon separated string of one or more modids that need to be active in order to load this zone. Note that B42 requires the \ prefix                                                         | `modsRequired="\phunsprinters2"` |

{% raw %}
| points | array | none | Array of points. Each point is in the format of `{x, y, x2, y2}` | `points={{100, 100, 200, 200}, {300, 200, 350, 250}}` |
{% endraw %}
| inherits | string | \_default | the key of the zone to inherit all unspecified properties | `inherits="_default"` |

Note that the \_default zone is the built in, root that all zones ultimately inherit from

## Staff exemptions

Two sandbox options let staff work inside their own restricted zones instead of
being blocked by them:

| Option                         | Default | Effect                                                                                                                   |
| ------------------------------ | ------- | ------------------------------------------------------------------------------------------------------------------------ |
| Staff ignore zone restrictions | off     | Staff are not blocked by `nobuilding`, `noplacing`, `nopickup`, `noscrap`, `nodestruction`, `nosafehouse` or `noplayers` |
| Include Moderator and GM       | off     | Widens the above from Admin only to also cover the Moderator, GM and Overseer roles                                      |

The second option does nothing on its own — the first has to be on as well.

Matching is on the role's name, case-insensitively, the same way the Editor Role
option works, so a server using custom roles can line one up by naming it after
one of these. Everyone else, including Observer, is unaffected.

`nofire` is deliberately **not** exempted. Every other restriction blocks an
action a specific player is taking, so there is somebody to check against.
Fire is environmental: the engine hands the mod a new fire and nothing else, so
there is no way to tell who started it. Exempting on "an exempt player is
standing there" would suppress fire inconsistently tile by tile as it spread,
and exempting the whole zone whenever staff are inside it would give any player
who followed them in a free burn. A `nofire` zone applies to everyone.

## Processing

The order of processing is as follows:

- Load all data points shipped with mod, omitting any which have modsRequired that are not loaded
- Load any of the customisations users have made from the JSON file located in `<zomboid directory>/lua/PhunZones.json`

Existing `PhunZones.txt` files must be converted to `PhunZones.json` with the Phun configuration converter before updating. The converter is available at `https://phunzoider.github.io/PhunZones/converter/` and processes files locally in the browser. In single-player, the file is in `<zomboid directory>/lua/`; for multiplayer, use the server's `<zomboid directory>/Server/<server-name>/lua/` directory.

- Apply the active profile, if one is set (see below)
- Build inheritence chain
- Partition by chunk

## Profiles

A profile is a named, sparse overlay applied on top of the shipped data and your
customisations. It holds only the fields it changes, so zones added by a mod
update and edits you make in the zone editor both stay visible while a profile
is active.

Profiles are defined in a `profiles` block alongside `data` in
`PhunZones.json`. Existing files load unchanged; they simply have none defined.

```json
{
  "version": 3,
  "data": {},
  "profiles": {
    "night": {
      "Louisville": { "noplayers": true },
      "WestPoint": { "difficulty": 4 }
    }
  }
}
```

Any zone field can be overridden, and overrides inherit: closing `Louisville`
also closes `Louisville_Mall` and every other zone that inherits from it.

A profile can also turn a setting back **off**, for a zone that is closed by
default and opens for an event. Use `false`, not `null`:

```json
{
  "version": 3,
  "data": { "FallasLake": { "noplayers": true } },
  "profiles": { "open": { "FallasLake": { "noplayers": false } } }
}
```

`null` will not work and will not warn you. JSON null decodes to Lua nil, and a
nil-valued key is not in the table at all, so the overlay ends up saying nothing
about that field and the underlying value stands. `false` is a real value and
does override.

Only one profile is active at a time. Reverting is activating nothing — the
overlay is dropped and every value recomputes from the layers underneath, so no
previous value is ever stored and later edits are never clobbered.

### In the zone editor

The bottom bar of the zone editor carries the profile controls:

```
Editing: [ default ▾ ]  [Activate]  [New Profile]  [Del Profile]   Live: none
```

**Editing** is the layer your property edits are written to. `default` is the
base configuration — the `data` block, which is what the editor has always
edited. Pick a profile and the same property rows now write into that profile
instead.

**Live** is what players are actually experiencing right now. These are
deliberately separate: selecting a profile to edit does not activate it, so you
can build next weekend's event without anything changing under the players on
the server. **Activate** is what makes the selected layer live.

While you are editing a profile, the property rows are marked in three ways:

| Marker                     | Meaning                                                |
| -------------------------- | ------------------------------------------------------ |
| Orange bar, orange value   | This profile overrides the field                       |
| Grey-blue bar, plain value | Set by the base config or inherited from a parent zone |
| No bar, dimmed value       | Not set anywhere                                       |

Add Zone and Delete Zone are disabled while editing a profile. Both are
structural edits to the base configuration — a profile can only override fields
on zones that already exist — so rather than quietly writing them to the wrong
layer the editor turns them off.

Note that a profile cannot currently _remove_ an override once saved, only
change its value. Set the field back to whatever the base config uses, or edit
the `profiles` block in the JSON directly.

### From chat

Switch profiles in game with `/zoneprofile` (admin only):

```
/zoneprofile           show the active profile and what is defined
/zoneprofile night     activate "night"
/zoneprofile none      clear it
/zoneprofile default   also clears it
```

`none` and `default` both mean "no profile", and are not case sensitive. If you
have actually named a profile `default`, that profile wins and is still
activated normally.

The command does not need PhunServer2. It registers into PhunServer2's chat hook
when that mod is present so all its commands live in one place; otherwise
PhunZones installs its own. Without PhunServer2 the reply comes back as a halo
note and in the log rather than in the chat window.

The active profile is runtime state, not config: it is kept in ModData, so a
switch never rewrites your JSON file, and it survives a restart. If the active
profile is renamed or removed from the file, it is cleared on the next load
rather than left active while applying nothing.

### Scheduling profile changes

With [PhunServer2](https://github.com/PhunZoider/PhunServer) installed,
PhunZones registers a `zoneprofile` cron action, so profile swaps can run on the
real-world clock. In `PhunServer2Cron.json`:

```json
"closeLouisville": {
  "enabled": true, "action": "zoneprofile", "at": "22:00",
  "args": { "profile": "night" },
  "announcements": [ { "before": 600, "text": "Louisville closes in 10 minutes" } ]
},
"openLouisville": {
  "enabled": true, "action": "zoneprofile", "at": "06:00",
  "args": { "profile": "none" }
}
```

PhunServer2 is optional. Without it the action is simply not registered, and
profiles are switched by hand from `/zoneprofile` or from Lua via
`PhunZones.setActiveProfile(name)`.

Note that the two jobs are independent: if the server is down when the "open"
job was due, the profile stays active until something clears it. `/zoneprofile
none` is the escape hatch.

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
        type = "string", -- or int or bool or combo (requires a getOptions param that returns array of {lable="text", value = "value"}) or button (requires an onClick param)
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
