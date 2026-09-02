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
- Block sledgehammer demolition
- Restrict PVP to chosen zones, or make chosen zones safe
- Block player and vehicle entry to specific zones
- Zone detection works inside [Project RV Interior](https://steamcommunity.com/sharedfiles/filedetails/?id=3543229299)
- Named zone profiles that swap a set of rules on demand, or on a schedule
- Optional staff exemptions, so admins can still work inside their own restricted zones
- Designed to be an extensive tool that can be used stand alone and/or by other mods
- Friendly widget that helps players identify what area they are in (eg Louisville - Mall)
- Comes pre-configured with a large selection of existng maps, along with tools to modify and/or create more
- Designed for max performance

[Steam Workshop Page](https://steamcommunity.com/sharedfiles/filedetails/?id=3676252660)

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

| Property      | Type               | default | Description                                                                                                                                                                                      | Example                          |
| ------------- | ------------------ | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------- |
| title         | string             | nil     | Display name of current zone                                                                                                                                                                     | `title="Lousiville"`             |
| subtitle      | string             | nil     | optional sub text of zone                                                                                                                                                                        | `subtitle="The Mall"`            |
| order         | number             | nil     | optional precedence number. The higher the number, the higher the precedence this zone will have. If left nil, the precedence will be in order of process (later entries overwrite earlier ones) | `order=4`                        |
| enabled       | bool               | true    | set to false to disable loading of this zone                                                                                                                                                     | `enabled=false`                  |
| difficulty    | number             | nil     | An optional number to signify difficulty level to the user                                                                                                                                       | `difficulty=4`                   |
| zeds          | `Move` \| `Remove` | none    | `Move` teleport zeds away while `Remove` despawns them. The latter is more performant but can remove player corpses                                                                              | `zeds=move`                      |
| bandits       | `None` \| `Move` \| `Remove` | zeds | Requires the Bandits2 mod. `Move` and `Remove` act as they do for zeds, and also stop bandits spawning in the zone at all. Left unset, a zone follows its own `zeds` setting; set `None` to let bandits in where zeds are moved or removed. Note this reads the inherited value, so a `bandits` set on an ancestor counts as set | `bandits=remove`                 |
| noannounce    | bool               | false   | Do not show the title of this location to the player when they first enter                                                                                                                       | `noannounce=true`                |
| nosafehouse   | bool               | false   | prevent safehouses from being created in this zone                                                                                                                                               | `nosafehouse=true`               |
| nobuilding    | bool               | false   | prevent construction here                                                                                                                                                                        | `nobuilding=true`                |
| noplacing     | bool               | false   | Prevent placing objects (eg a stove) here                                                                                                                                                        | `noplacing=true`                 |
| nopickup      | bool               | false   | Prevent picking moveables up (eg a stove)                                                                                                                                                        | `nopickup=true`                  |
| noscrap       | bool               | false   | Prevent items from being dissasembled here                                                                                                                                                       | `noscrap=true`                   |
| nodestruction | bool               | false   | Prevents the sledgehammer from being used here                                                                                                                                                   | `nodestruction=true`             |
| nofire        | bool               | false   | Prevents fire spread in this zone                                                                                                                                                                | `nofire=true`                    |
| noplayers     | bool               | false   | Prevents players from entering this zone. Vehicles are turned back too; one that cannot be relocated is braked in place instead                                                                    | `noplayers=true`                 |
| pvp           | bool               | unset   | Whether players can hurt each other here. `false` makes a safe zone. Setting `true` anywhere makes the rest of the map safe; see [PVP zones](#pvp-zones)                                                        | `pvp=true`                       |
| modsRequired  | string             | nil     | semi-colon separated string of one or more modids that need to be active in order to load this zone. Note that B42 requires the \ prefix                                                         | `modsRequired="\phunsprinters2"` |
| points | array | none | Array of points. Each point is in the format of `{x, y, x2, y2}` | `points={{100, 100, 200, 200}, {300, 200, 350, 250}}` |
| inherits | string | \_default | the key of the zone to inherit all unspecified properties | `inherits="_default"` |

Note that the \_default zone is the built in, root that all zones ultimately inherit from

## Staff exemptions

Two sandbox options let staff work inside their own restricted zones instead of
being blocked by them:

| Option                         | Default | Effect                                                                                                                   |
| ------------------------------ | ------- | ------------------------------------------------------------------------------------------------------------------------ |
| Staff ignore zone restrictions | off     | Staff are not blocked by `nobuilding`, `noplacing`, `nopickup`, `noscrap`, `nodestruction`, `nosafehouse` or `noplayers` |
| Include Moderator and GM       | off     | Widens the above from Admin only to also cover the Moderator, GM and Overseer roles                                      |

The second option does nothing on its own; the first has to be on as well.

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

Safe zones are not exempted either, for a different reason: the engine decides them
from the tile the hit came from and the tile it landed on, never from who
threw it. There is no player in that check to let through.

## PVP zones

`pvp` decides whether players can hurt each other in a zone. It has three
states, and the third one matters:

| Value | Meaning |
| ----- | --------- |
| unset | nobody has said. Inherits from the parent zone |
| `true` | pvp happens here |
| `false` | this is a safe zone |

PhunZones does not enforce any of this itself. The game has its own non-pvp
zone list, and a safe zone is registered there, which puts the restriction
somewhere Lua cannot reach:

- the attacker's client refuses the swing before it happens
- nobody can turn their safety off while stood inside one
- the server rejects player-hit-player and vehicle-hit-player packets

### Marking a pvp zone makes the rest of the map safe

Saying "pvp happens **here**" only means something if it does not happen
elsewhere, so as soon as any zone is set to `pvp=true`, the rest of the map is
asserted safe for you and that zone is cut out of it. One setting is enough:

```lua
    Arena = {
        title = "The Arena",
        pvp = true,
        points = {{640, 640, 659, 659}}
    },
```

That is the whole configuration for a safe server with one arena in it.

Set nothing at all and nothing happens: no rectangles are registered and your
server's own `PVP` option is left in charge, which is why installing the mod
changes nothing on its own.

`_default` overrides the assertion in either direction, for a server that wants
to be explicit:

| `_default.pvp` | Any zone `pvp=true`? | Whole map safe |
| -------------- | -------------------- | ---------------- |
| unset | no | no, your server config governs |
| unset | yes | yes, asserted for you |
| `false` | either | yes, you asked |
| `true` | either | no, you asked |

So `pvp=false` on a single zone, with no pvp zone anywhere, makes just that one
zone safe and leaves the rest of the map alone.

### Server settings

All of this **subtracts** pvp. It cannot add it, so:

| Setting           | Needs to be           | Why                                                                                                                                              |
| ----------------- | --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `PVP`             | `true`                | The game checks this before it looks at zones. With it off, pvp is off everywhere and none of this has anything to do                              |
| `AntiCheatSafety` | `3`, `2` or `1`       | Ban, Kick or Log. The shipped default of `4` disables it, which leaves nothing checking hits server-side if somebody is running a modified client |

There is no way to run `PVP=false` and open pvp up in one zone. Run `PVP=true`
and mark the arena instead.

If you are turning an existing PVE server into one with an arena, set the zone
up first and flip `PVP=true` last. The rectangles register happily while `PVP`
is still off (they are simply inert), so you can check them under Admin Panel
before anything changes for players.

### Multiplayer only

The game only consults these zones on a multiplayer client, so they do nothing
in singleplayer. PhunZones skips the whole thing there rather than pay for a
list it cannot use.

### Overlapping zones

Precedence works the way it does everywhere else, and nests as deep as you like:
a `pvp=false` vault inside a `pvp=true` arena is safe again, as long as it has
the higher precedence. The mod cuts those holes out of the rectangles it hands
the game, since the game itself has no notion of one zone overriding another.

Holes cost rectangles: one region can become up to four. The list is capped,
and a warning naming the areas left unprotected is printed to the server log if
a layout needs more than the cap. If you hit it, the fix is fewer zones
overlapping your safe zones.

Rectangles covered entirely by a wider one are dropped rather than registered,
so a map-wide safe area does not also register every zone sitting inside it.

### When the rectangles are built

Only on the server, and only when the zone data is rebuilt: at server start, and
whenever something triggers a rebuild: saving in the zone editor, activating or
editing a profile, or a scheduled profile swap. There is no per-tick work.

Rebuilds are reconciled rather than reapplied. Each rectangle is named after its
zone and its bounds, so a rebuild that did not move a safe zone produces the
same names, the comparison comes out empty, and nothing is added, removed or
sent to clients.

The rectangles themselves are saved in the world (`map_meta.bin`), the same as
any non-pvp zone made through the admin panel, so they survive a restart on
their own. The reconcile at server start compares against what the save
contained, which is how a zone deleted while the server was down gets cleaned
up.

### Removing the mod

Because the rectangles live in the world save, **uninstalling PhunZones leaves
them behind**. Nothing runs to clean them up, and the areas stay non-pvp with
no visible cause.

To clear them, either turn off the **Manage no-pvp zones** sandbox option before
uninstalling (PhunZones withdraws its own zones when it stops managing them),
or delete them afterwards under **Admin Panel → Non PVP Zone**, where they are
the entries titled `PhunZones_...`.

### Zones made by hand

PhunZones only touches zones it created, which are the ones titled
`PhunZones_...` in the admin panel. Anything an admin adds through
**Admin Panel → Non PVP Zone** is left alone.

Turning off the **Manage no-pvp zones** sandbox option hands the list back
entirely: PhunZones removes its own zones and stops managing them, leaving the
admin panel as the only thing writing to it.

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

Only one profile is active at a time. Reverting is activating nothing: the
overlay is dropped and every value recomputes from the layers underneath, so no
previous value is ever stored and later edits are never clobbered.

### In the zone editor

The bottom bar of the zone editor carries the profile controls:

```
Editing: [ default ▾ ]  [Activate]  [New Profile]  [Del Profile]   Live: none
```

**Editing** is the layer your property edits are written to. `default` is the
base configuration, the `data` block, which is what the editor has always
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
structural edits to the base configuration (a profile can only override fields
on zones that already exist), so rather than quietly writing them to the wrong
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
