# PhunZones

A Project Zomboid mod for changing game behaviours depending on where the player is

## Features

- B41 and B42 compatable
- Create and manage zones with special properties
  - Title which can be displayed to players when entering
  - Toggle PvP
  - Toggle zed spawning
  - Toggle bandit spawning (for Bandits mod)
  - Toggle Radiation levels (for PhunRad mod)
  - Set difficulty (for PhunRunners, PhunRewards and other Phun mods)
  - Soon: reduce loot levels or prevent items from spawning
  - Soon: prevent building
  - Soon: prevent destruction
- Designed to be an extensive tool that can be used stand alone and/or by other mods
- Friendly widget that helps players identify what area they are in (eg Louisville - Mall)
- Comes pre-configured with loads of existng maps, along with tools to modify and/or create more
- Designed for max performance

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

The next example employs a subzone. A subzone inherits its properties from the parents region. The checkpoint subzone also uses the mod property so it will only appear if the mod "Checkpoint_March_Ridge" is active

```lua
    MarchRidge = { -- a unique key identifying region
        difficulty = 3,
        title = "March Ridge",
        points = {{9600, 12600, 10499, 13199}}
        subzones = {
            checkpoint = { -- unique key identifying subzone
                points = {{10300, 12300, 10400, 12420}},
                subtitle = "Checkpoint",
                mods = "Checkpoint_March_Ridge"
            }
        }
    },

```
Subzones supercede the parent zone, inheriting its properties while overwriting the ones they include. In the above example, entering the checkpoints zone will welcome the player with "March Ridgee - Checkpoint" and its difficulty would be 3

Notes:
- the subzone requires a unique key which can be any valid lua table key apart from `main` as it is reserved
- subzones do not have subzones!

## Fields

| Property     | Type | default | Description                                                          | Example |
| ------- | ------- |  ------- | -------------------------------------------------------------------- | -------------|
| title    | string* | nil | Display name of current zone | `title="Lousiville"` |
| subtitle    | string* | nil | optional sub text of zone | `subtitle="The Mall"` |
| order    | number* | nil | optional precedence number. The higher the number, the higher the precedence this zone will have. If left nil, the precedence will be in order of process (later entries overwrite earlier ones) | `order=4` |
| pvp    | bool* | false |Explicitly set players pvp flag when entering zone | `pvp=true` |
| enabled    | bool* | true |set to false to disable loading of this zone | `enabled=false` |
| difficulty    | number* | nil |0 is none and 4 is maximum. For use in PhunRunners | `difficulty=4` |
| rads    | number* | nil | Used in PhunRad | `rads=4` |
| isVoid    | bool* | false | used to flag the area isnt a real location. Used for the insides of RV interiors or basement mods | `isVoid=false` |
| zeds   | bool* | true | allow zeds to spawn in zone | `zeds=true` |
| bandits   | bool* | true | allow bandits to spawn in zone (requires bandits mod) | `bandits=true` |
| rv | bool* | false | set to true if you want the player to inherit the zone values where their rv currently is. eg a player enters the interior of their RV in a radiated zone, they will continue to take radiation as long as the vehicle is still in affected area. Probably only used if isVoid=true | `rv=true` |
| mods    | string* | nil | semi-colon separated string of one or more modids that need to be active in order to load this zone | `mods="phunstats;phunrunners"` |
| points | array | none | Array of points. Each point is in the format of `{x, y, x2, y2}` | `points={{100, 100, 200, 200}, {300, 200, 350, 250}}` |
| subzones | table | none | a key value table of subzones | `subzones={ theMall={ subtitle="The Mall", points={{1,1, 2, 2}}} }` |


## Processing

The order of processing is as follows:
- Load all internal included data points, omitting any which have mods not activated
- Load any of the zones from the filesystem located in `lua/PhunZone_Changes.lua`
- Load any data added by mods through extending the system outlined below

Notes:
- subzones inherit the parent zones properties
- A zone in PhunZone_Changes.lua with the key "MarchRidge" will overwrite the MarchRidge properties PhunZones ships with
- Overwriting happens sequentially, but if you want something for sure to be processed last (and thus prevented from being overwritten) then give it a high order property

## Shaping

Not everything is a rectangle! This is where the use of subzones + processing precedence comes in. Take for example the following zone
![Alt text](Docs/images/overlapping.png)

This is accomplished by either putting the subzones in order from grey to blue to red or by supplying the order field where red is the highest followed by blue

## Extending PhunZones

There are a couple ways to extend PhunZones. One way would be to add whatever additional properties you want when 

```lua
--media/lua/client/mymod.lua

Events[PhunZones.events.OnPhunZoneReady].Add(function()
    if PhunZones.data.zones.MarchRidge then
      PhunZones.data.zones.MarchRidget.isPhun=true
    end
end)
```

And listen out for when players location changes. Zone will contain all properties (including those that are inherited)
```lua
Events[PunZones.events.OnPhunZonesPlayerLocationChanged].Add(function(playerObj, zone, oldZone)
    if zone.isPhun then
      -- yay.
    end
end)
```

You can also obtain all the current zone properties via the PhunZones field of the players mod data eg `playerObj:getModData().PhunZones.title`

## Customising Zones in UI

- In admin and/or debug mode, right click anywhere and choose "PhunZones Admin"
- The drop down list will be populated with each of the currently loaded zones. Click the "Show All" checkbox to view all zones even if they were not loaded into current game (eg a required mod was not activated)
- 

## Customising Zones in file

