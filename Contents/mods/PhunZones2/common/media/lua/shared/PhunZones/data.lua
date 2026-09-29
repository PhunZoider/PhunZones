-- Shipped default zones.
--
-- Vanilla rects are measured against the B42 map files (lotheader rooms,
-- TownZones, world map labels and street names). Mod rects are measured
-- against what each mod adds on top of vanilla, not its whole cell range,
-- since a mod that edits a cell ships every vanilla room in it too.
--
-- A zone only reliably beats the zones it inherits from. Where a mod zone
-- lands inside a vanilla district it inherits that district, and siblings are
-- kept from overlapping, otherwise which one shows depends on pairs() order.
return {
    ["_default"] = {
        title = "Kentucky",
        difficulty = 2
    },
    void = {
        difficulty = 0,
        title = "RV",
        isVoid = true,
        zeds = false,
        bandits = false,
        points = {{22500, 12000, 100000, 100000}},
        modsRequired = "PROJECTRVInterior42"
    },

    Very_Easy = {
        difficulty = 0
    },
    Easy = {
        difficulty = 1
    },
    Medium = {
        difficulty = 2
    },
    Hard = {
        difficulty = 3
    },
    Very_Hard = {
        difficulty = 4
    },

    -- -----------------------------------------------------------------------
    -- Louisville
    -- -----------------------------------------------------------------------
    Louisville = {
        inherits = "Hard",
        title = "Louisville",
        points = {{11940, 1040, 15954, 4215}, {12400, 3904, 12545, 4483}}
    },
    Louisville_Downtown = {
        inherits = "Louisville",
        subtitle = "Downtown",
        difficulty = 4,
        points = {{11980, 1040, 13150, 2110}}
    },
    Louisville_FossoilField = {
        inherits = "Louisville_Downtown",
        subtitle = "Fossoil Field",
        points = {{12940, 1505, 13095, 1650}}
    },
    Louisville_GeneralHospital = {
        inherits = "Louisville_Downtown",
        subtitle = "Louisville General Hospital",
        points = {{12915, 1990, 13000, 2100}}
    },
    -- East of downtown along the river: the Bruiser factory and Butcher St.
    Louisville_Butchertown = {
        inherits = "Louisville",
        subtitle = "Butchertown",
        points = {{13151, 1140, 13450, 1850}}
    },
    Louisville_BruiserFactory = {
        inherits = "Louisville_Butchertown",
        subtitle = "Louisville Bruiser Factory",
        points = {{13225, 1200, 13375, 1330}}
    },
    Louisville_GrandOhioMall = {
        inherits = "Louisville",
        subtitle = "Grand Ohio Mall",
        difficulty = 4,
        points = {{13455, 1250, 13690, 1430}}
    },
    -- Either side of Germantown Road.
    Louisville_Germantown = {
        inherits = "Louisville",
        subtitle = "Germantown",
        points = {{13451, 1440, 14340, 1850}, {13151, 1851, 14340, 2214}}
    },
    Louisville_EastEnd = {
        inherits = "Louisville",
        subtitle = "East End",
        points = {{13330, 2215, 14340, 3530}}
    },
    -- South of downtown: the university, the train station and the old
    -- neighbourhoods around them.
    Louisville_OldLouisville = {
        inherits = "Louisville",
        subtitle = "Old Louisville",
        points = {{12250, 2111, 12959, 2599}}
    },
    Louisville_University = {
        inherits = "Louisville_OldLouisville",
        subtitle = "Louisville State University",
        difficulty = 4,
        points = {{12250, 2150, 12655, 2445}}
    },
    Louisville_TrainStation = {
        inherits = "Louisville_OldLouisville",
        subtitle = "Train Station",
        points = {{12760, 2440, 12860, 2560}}
    },
    Louisville_WestEnd = {
        inherits = "Louisville",
        subtitle = "West End",
        points = {{11940, 2111, 12249, 2599}, {11940, 2600, 12099, 3530}}
    },
    Louisville_SouthEnd = {
        inherits = "Louisville",
        subtitle = "South End",
        points = {{12100, 2600, 13329, 3530}}
    },
    Louisville_IroquoisPark = {
        inherits = "Louisville_SouthEnd",
        subtitle = "Iroquois Park",
        difficulty = 2,
        points = {{12960, 2215, 13325, 2875}}
    },
    Louisville_ChapelmountDowns = {
        inherits = "Louisville_SouthEnd",
        subtitle = "Chapelmount Downs",
        points = {{12100, 2620, 12460, 2960}}
    },
    Louisville_StPeregrin = {
        inherits = "Louisville",
        subtitle = "St. Peregrin Hospital",
        difficulty = 4,
        points = {{12340, 3540, 12480, 3810}}
    },
    -- The farmland east of the city, out to the airport.
    Louisville_Outskirts = {
        inherits = "Louisville",
        subtitle = "Outskirts",
        difficulty = 2,
        points = {{14350, 950, 15954, 4215}}
    },
    Louisville_Airport = {
        points = {{15251, 2418, 15684, 3346}},
        subtitle = "Airport",
        inherits = "Louisville_Outskirts",
        difficulty = 4
    },
    Louisville_MilitaryCamp = {
        points = {{14990, 3550, 15700, 4000}},
        subtitle = "Military Camp",
        inherits = "Louisville_Outskirts",
        difficulty = 4
    },
    -- Key kept so existing configs still apply. This is the Knox Boundary Camp
    -- checkpoint on the Louisville wall; the trainyard is only part of it.
    Louisville_Trainyard = {
        points = {{12440, 3900, 12860, 4500}},
        subtitle = "Knox Boundary Camp",
        inherits = "Louisville",
        difficulty = 4
    },
    -- The burnt-out quarantine town is on the vanilla map, no mod needed. The
    -- Louisville Quarantine Zone mod builds it out a little further east.
    Louisville_Quarantine_Zone = {
        points = {{13414, 3957, 14010, 4193}},
        subtitle = "Quarantine Zone",
        inherits = "Louisville",
        difficulty = 4
    },
    Louisville_Riverboat = {
        points = {{13090, 1165, 13135, 1212}},
        inherits = "Louisville_Downtown",
        subtitle = "Riverboat",
        modsRequired = "Louisville_Riverboat"
    },
    Louisville_TowheadIsland = {
        inherits = "Louisville",
        subtitle = "Towhead Island FOB",
        difficulty = 4,
        points = {{13575, 980, 13880, 1248}},
        modsRequired = "Towhead-Island-FOB"
    },
    Louisville_MallBase = {
        inherits = "Louisville_Germantown",
        subtitle = "Mall Base",
        points = {{13595, 1500, 13845, 1590}, {13795, 1200, 13870, 1255}},
        modsRequired = "Louisville Mall Base (Build 42)"
    },
    Louisville_MilitaryComplex = {
        inherits = "Louisville_Outskirts",
        subtitle = "Military Complex",
        difficulty = 4,
        points = {{14350, 1800, 15250, 2935}},
        modsRequired = "Secretz42"
    },

    -- -----------------------------------------------------------------------
    -- Valley Station
    -- -----------------------------------------------------------------------
    ValleyStation = {
        inherits = "Hard",
        title = "Valley Station",
        points = {{12397, 4556, 14737, 6477}}
    },
    -- Key kept so existing configs still apply. This is Crossroads Mall, which
    -- is in Valley Station rather than Louisville.
    Louisville_Mall = {
        points = {{13519, 5724, 14088, 5975}},
        inherits = "ValleyStation",
        subtitle = "Crossroads Mall",
        difficulty = 4
    },
    CrossroadsMall_SecretZ = {
        inherits = "Louisville_Mall",
        points = {{13565, 5635, 14350, 5975}},
        modsRequired = "Secretz42"
    },
    Wildsteel = {
        inherits = "ValleyStation",
        title = "Wildsteel",
        points = {{14395, 5695, 14705, 6005}},
        modsRequired = "WILDSTEEL"
    },
    -- The Salt River bridge on the road out towards West Point.
    ValleyStation_BridgeCheckpoint = {
        inherits = "ValleyStation",
        subtitle = "Bridge Checkpoint",
        difficulty = 4,
        points = {{12650, 6405, 12810, 6535}},
        modsRequired = "Secretz42"
    },
    CampFitzgerald = {
        inherits = "Medium",
        title = "Camp Fitzgerald",
        points = {{13740, 6590, 13930, 6800}}
    },

    -- -----------------------------------------------------------------------
    -- West Point
    -- -----------------------------------------------------------------------
    WestPoint = {
        inherits = "Medium",
        title = "West Point",
        points = {{10870, 6580, 12330, 7280}}
    },
    -- The shops along Main St.
    WestPoint_Downtown = {
        inherits = "WestPoint",
        subtitle = "Downtown",
        difficulty = 3,
        points = {{11740, 6790, 12120, 7000}}
    },
    WestpointFireandMall = {
        subtitle = "Fire Station & Mall",
        inherits = "WestPoint",
        points = {{11030, 6915, 11240, 7135}},
        modsRequired = "Westpoint-Fire"
    },
    WestPointMilitaryBoat = {
        subtitle = "Military Boat",
        inherits = "WestPoint",
        points = {{11786, 6545, 12006, 6595}},
        modsRequired = "WMTBoat"
    },

    -- -----------------------------------------------------------------------
    -- Muldraugh and around
    -- -----------------------------------------------------------------------
    Muldraugh = {
        inherits = "Easy",
        title = "Muldraugh",
        points = {{10560, 9180, 10940, 10680}}
    },
    Muldraugh_North = {
        inherits = "Muldraugh",
        subtitle = "North",
        points = {{10560, 9180, 10940, 9860}}
    },
    Muldraugh_South = {
        inherits = "Muldraugh",
        subtitle = "South",
        points = {{10560, 10180, 10940, 10680}}
    },
    beek_muldraugh_firedept = {
        inherits = "Muldraugh_North",
        subtitle = "Fire Department",
        difficulty = 2,
        modsRequired = "beek_muldraugh_firedept",
        points = {{10520, 9185, 10635, 9240}}
    },
    Muldraugh_McCoys = {
        inherits = "Muldraugh",
        subtitle = "McCoy's Logging",
        points = {{10247, 9221, 10497, 9457}}
    },
    Muldraugh_Trainyard = {
        inherits = "Muldraugh",
        subtitle = "Trainyard",
        difficulty = 2,
        points = {{11500, 9620, 11920, 10220}}
    },
    Muldraugh_RefugeeCamp = {
        inherits = "Muldraugh_Trainyard",
        subtitle = "Train Depot Refugee Camp",
        difficulty = 4,
        points = {{11440, 9635, 11910, 10230}},
        modsRequired = "Secretz42"
    },
    Muldraugh_SouthernCheckpoint = {
        inherits = "Muldraugh",
        subtitle = "Southern Checkpoint",
        difficulty = 4,
        points = {{10505, 10815, 10730, 11100}},
        modsRequired = "Muldraugh-Checkpoint"
    },
    Muldraugh_CrossroadsCheckpoint = {
        inherits = "Muldraugh",
        subtitle = "Crossroads Checkpoint",
        difficulty = 4,
        points = {{10510, 11120, 10750, 11225}, {10895, 11130, 11010, 11270}},
        modsRequired = "Secretz42"
    },
    Bunker42 = {
        inherits = "Hard",
        title = "Bunker 42",
        points = {{11100, 9945, 11210, 10090}},
        modsRequired = "Bunker42"
    },
    DixieTrailerPark = {
        inherits = "Easy",
        title = "Dixie Trailer Park",
        points = {{11430, 8760, 11890, 8980}}
    },
    -- Nolan's Used Cars and the Spiffo's where the Dixie Highway meets the
    -- road west, north of the trailer park.
    Crossroads = {
        inherits = "Easy",
        title = "Crossroads",
        points = {{11560, 8220, 11710, 8400}}
    },
    CrossroadsCheckpoint = {
        inherits = "Crossroads",
        subtitle = "Military Checkpoint",
        difficulty = 4,
        points = {{11555, 7965, 11980, 8400}},
        modsRequired = "Crossroads-Checkpoint"
    },
    ErikasFurnitureStore = {
        inherits = "Crossroads",
        title = "Erika's Furniture",
        difficulty = 3,
        modsRequired = "Erikas_Furniture_Store",
        points = {{11495, 8238, 11615, 8340}}
    },
    KiiriEstate = {
        title = "Kiiri Estate",
        inherits = "Medium",
        points = {{11145, 8205, 11210, 8250}},
        modsRequired = "kiiriestate",
        order = 25
    },
    HopeCountryPrison = {
        title = "Hope Country Prison",
        inherits = "Very_Hard",
        points = {{11215, 8175, 11285, 8270}},
        modsRequired = "HCP"
    },

    -- -----------------------------------------------------------------------
    -- Riverside
    -- -----------------------------------------------------------------------
    Riverside = {
        inherits = "Medium",
        title = "Riverside",
        points = {{5420, 5130, 6910, 5610}}
    },
    -- The shops, restaurants and civic buildings around W Main St.
    Riverside_Downtown = {
        inherits = "Riverside",
        subtitle = "Downtown",
        difficulty = 3,
        points = {{6170, 5130, 6600, 5400}}
    },
    Riverside_ScenicGrove = {
        inherits = "Riverside",
        subtitle = "Scenic Grove Trailer Park",
        points = {{5270, 5850, 5450, 6130}}
    },
    Riverside_CountryClub = {
        inherits = "Riverside",
        subtitle = "West Maple Country Club",
        points = {{5500, 6300, 6310, 6760}}
    },
    Riverside_Checkpoint = {
        inherits = "Riverside",
        subtitle = "Military Checkpoint",
        difficulty = 4,
        points = {{5655, 5665, 5880, 5920}},
        modsRequired = "Secretz42;SZ_Checkpoint6"
    },
    Riverside_Mansion = {
        inherits = "Riverside",
        subtitle = "Mansion",
        points = {{7205, 5180, 7265, 5230}},
        modsRequired = "RiversideMansionMod42;RiversideMansionMod42Empty"
    },
    QuellasCastle = {
        title = "Quella's Castle",
        inherits = "Riverside",
        difficulty = 3,
        points = {{5443, 5159, 5633, 5310}},
        modsRequired = "Quella's Castle"
    },
    Floatopia = {
        title = "Floatopia",
        inherits = "Medium",
        points = {{4555, 5410, 4700, 5625}},
        modsRequired = "Floatopia"
    },
    Hunters = {
        title = "Hunters",
        inherits = "Hard",
        points = {{6065, 5732, 6088, 5784}},
        nobuilding = false,
        modsRequired = "Hunter'sBaseB42"
    },
    SunderlandHills = {
        inherits = "Hard",
        title = "Sunderland Hills Sanatorium",
        points = {{3800, 6090, 4300, 6560}}
    },

    -- -----------------------------------------------------------------------
    -- Rosewood
    -- -----------------------------------------------------------------------
    Rosewood = {
        inherits = "Very_Easy",
        title = "Rosewood",
        points = {{7800, 11096, 8340, 11424}, {7800, 11424, 8560, 11902}, {7900, 11902, 8520, 12360}}
    },
    -- Warehouses, the logging yard and the gas station north of town.
    Rosewood_Industrial = {
        inherits = "Rosewood",
        subtitle = "Industrial",
        points = {{7940, 11096, 8340, 11370}}
    },
    Rosewood_Downtown = {
        inherits = "Rosewood",
        subtitle = "Downtown",
        difficulty = 1,
        points = {{7990, 11390, 8200, 11760}}
    },
    Rosewood_Cabins = {
        points = {{7503, 11402, 7788, 11689}},
        inherits = "Rosewood",
        subtitle = "Cabins",
        modsRequired = "rosewoodcabins"
    },
    Rosewood_Prison = {
        points = {{7320, 11694, 7800, 11990}},
        inherits = "Rosewood",
        difficulty = 3,
        subtitle = "State Prison"
    },
    Rosewood_Prison2 = {
        points = {{7320, 11694, 7800, 11990}},
        inherits = "Rosewood",
        subtitle = "State Prison",
        difficulty = 3,
        modsRequired = "rosewood_prison"
    },
    Rosewood_Mall = {
        points = {{7560, 11420, 7777, 11637}},
        inherits = "Rosewood",
        subtitle = "Mall",
        modsRequired = "Rosewood Mall"
    },

    -- -----------------------------------------------------------------------
    -- Brandenburg
    -- -----------------------------------------------------------------------
    Brandenburg = {
        inherits = "Hard",
        title = "Brandenburg",
        points = {{1280, 5670, 2517, 6701}}
    },
    Brandenburg_Downtown = {
        inherits = "Brandenburg",
        subtitle = "Downtown",
        points = {{1600, 5760, 2100, 6110}}
    },
    Brandenburg_PSDelilah = {
        inherits = "Brandenburg",
        subtitle = "PS Delilah",
        points = {{2025, 5675, 2070, 5715}}
    },
    Brandenburg_Pondview = {
        inherits = "Brandenburg",
        subtitle = "Pondview Shopping Center",
        difficulty = 4,
        points = {{1845, 6320, 1970, 6420}}
    },
    Brandenburg_Checkpoint = {
        inherits = "Brandenburg",
        subtitle = "Military Checkpoint",
        difficulty = 4,
        points = {{1440, 5390, 1710, 5700}}
    },
    Brandenburg_DetentionCenter = {
        inherits = "Brandenburg",
        subtitle = "Detention Center",
        difficulty = 4,
        points = {{1340, 5815, 1470, 5925}}
    },
    Brandenburg_BrightValley = {
        inherits = "Brandenburg",
        subtitle = "Bright Valley Trailer Park",
        points = {{2513, 6178, 2894, 6482}}
    },

    -- -----------------------------------------------------------------------
    -- The rest of Knox
    -- -----------------------------------------------------------------------
    EchoPark = {
        inherits = "Medium",
        title = "Echo Creek",
        points = {{3340, 10818, 3921, 11410}}
    },
    Ekron = {
        inherits = "Medium",
        title = "Ekron",
        points = {{230, 9290, 1070, 9995}}
    },
    -- Derelict steel works south-east of Ekron. Unnamed on the map.
    SteelMill = {
        inherits = "Medium",
        title = "Abandoned Steel Mill",
        points = {{1690, 10630, 2060, 10975}}
    },
    FallasLake = {
        inherits = "Medium",
        title = "Fallas Lake",
        points = {{7000, 8070, 7520, 8640}}
    },
    Irvington = {
        inherits = "Medium",
        title = "Irvington",
        points = {{2155, 13785, 3013, 14246}, {1691, 14246, 3149, 14980}, {3660, 14610, 3860, 14780}}
    },
    -- Police, bank, fire station and clinic.
    Irvington_TownCenter = {
        inherits = "Irvington",
        subtitle = "Town Center",
        difficulty = 3,
        points = {{2360, 13920, 2540, 14080}}
    },
    IrvingtonSpeedway = {
        inherits = "Irvington",
        subtitle = "Speedway",
        points = {{870, 12770, 1234, 13424}}
    },
    MarchRidge = {
        inherits = "Medium",
        title = "March Ridge",
        points = {{9779, 12600, 10499, 12870}, {9780, 12854, 10074, 13163}}
    },
    MarchRidge_ResearchFacility = {
        inherits = "MarchRidge",
        subtitle = "Research Facility",
        difficulty = 4,
        points = {{10250, 12060, 10450, 12570}},
        modsRequired = "Secretz42"
    },
    PonyRoamO = {
        inherits = "Easy",
        title = "Pony Roam-O",
        points = {{8405, 8485, 8605, 8665}}
    },
    CampCamus = {
        inherits = "Easy",
        title = "Camp Camus",
        points = {{4630, 7800, 4800, 8050}}
    },
    MeadshireEstate = {
        inherits = "Medium",
        title = "Meadshire Estate",
        points = {{4040, 9340, 4330, 9650}}
    },
    -- Named for the forest it sits in, not for what is there.
    HogWallowForest = {
        inherits = "Very_Hard",
        title = "Hog Wallow Forest",
        points = {{5500, 12400, 5620, 12530}}
    },
    CampArthur = {
        inherits = "Easy",
        title = "Camp Arthur",
        points = {{8240, 14390, 8720, 14680}}
    },
    -- Coalfield is on the vanilla map; the key is kept so existing configs
    -- still apply.
    CoalField = {
        title = "Coalfield",
        inherits = "Medium",
        points = {{3353, 8115, 3600, 8380}}
    },

    -- -----------------------------------------------------------------------
    -- Map mods
    -- -----------------------------------------------------------------------
    Anruisi = {
        title = "Anruisi",
        inherits = "_default",
        points = {{11996, 11397, 12600, 12000}},
        modsRequired = "AnruisiTown"
    },
    -- A walled PvP arena just north of West Point. Its south wall runs into the
    -- West Point rect, so it inherits West Point to win that strip.
    BlackMaze = {
        title = "Black Maze",
        inherits = "WestPoint",
        difficulty = 4,
        points = {{10800, 6300, 11100, 6600}},
        modsRequired = "blackmaze_wp"
    },
    Blackstone = {
        title = "Blackstone",
        inherits = "Hard",
        points = {{15020, 6590, 16800, 8410}},
        modsRequired = "BlackstoneMapMod"
    },
    CathayaValley = {
        title = "Cathaya Valley",
        inherits = "Hard",
        points = {{7200, 12615, 7505, 13190}},
        modsRequired = "Cathaya Valley 2.0 B42 version"
    },
    DawnTown = {
        inherits = "Medium",
        title = "Dawn Town",
        modsRequired = "dawn_town",
        points = {{3000, 8105, 3215, 8385}}
    },
    DeerheadLakeBase = {
        title = "Deerhead Lake Base",
        inherits = "Very_Hard",
        points = {{4600, 8425, 4750, 8670}},
        modsRequired = "Secretz42"
    },
    DeltaCreek = {
        title = "Delta Creek",
        inherits = "Very_Hard",
        points = {{6235, 8220, 6480, 8620}},
        modsRequired = "Delta-Creek-Munitions"
    },
    -- Dirkerdam is its own world rather than an addition to Knox. It sits north
    -- of the Knox towns and doesn't overlap any of them.
    Dirkerdam = {
        title = "Dirkerdam",
        inherits = "Hard",
        points = {{7620, 2090, 8810, 5080}},
        modsRequired = "DirkerdamB42"
    },
    Dirkerdam_West = {
        inherits = "Dirkerdam",
        subtitle = "West",
        points = {{6270, 2090, 7619, 4580}},
        modsRequired = "DirkerdamB42"
    },
    Florius = {
        title = "Florius",
        inherits = "Medium",
        points = {{2080, 2290, 2800, 2880}},
        modsRequired = "DirkerdamB42"
    },
    Pertville = {
        title = "Pertville",
        inherits = "Medium",
        points = {{8860, 4560, 9560, 4800}},
        modsRequired = "DirkerdamB42"
    },
    Tashtego = {
        title = "Tashtego",
        inherits = "Easy",
        points = {{8780, 5610, 9060, 6090}},
        modsRequired = "DirkerdamB42"
    },
    Estate39 = {
        title = "Estate 39",
        inherits = "Medium",
        points = {{8420, 10070, 8470, 10115}},
        modsRequired = "Estate 39"
    },
    ForgottenFarm = {
        title = "Forgotten Farm",
        inherits = "Easy",
        points = {{8330, 9065, 8380, 9115}},
        modsRequired = "ForgottenFarmBunker"
    },
    FortIronCity = {
        title = "FortIron City",
        inherits = "Hard",
        points = {{3760, 7520, 4100, 7755}},
        modsRequired = "FortIronCity"
    },
    Frogtown = {
        inherits = "Medium",
        title = "Frogtown",
        modsRequired = "Frogtown",
        points = {{3085, 6910, 3740, 7440}, {3740, 7200, 3870, 7365}}
    },
    Grapeseed = {
        inherits = "Medium",
        title = "Grapeseed",
        modsRequired = "42Grapeseed",
        points = {{6280, 10800, 7488, 11693}}
    },
    Greenleaf = {
        title = "Greenleaf",
        inherits = "Medium",
        points = {{6295, 10195, 6890, 10790}},
        modsRequired = "Greenleaf B42 version"
    },
    LabRoad = {
        inherits = "Hard",
        title = "Lab Road",
        modsRequired = "LAB Road",
        points = {{5905, 12295, 6305, 12600}, {6110, 11790, 6155, 11835}}
    },
    Maplewood = {
        title = "Maplewood",
        inherits = "Medium",
        points = {{8120, 8400, 8400, 8685}},
        modsRequired = "Maplewood"
    },
    Meiyas = {
        title = "Meiyas",
        inherits = "Easy",
        points = {{8089, 10793, 8419, 11095}},
        noannounce = false,
        modsRequired = "Meiya'sTown"
    },
    MelsBunker = {
        title = "Mels Bunker",
        inherits = "Hard",
        modsRequired = "MelBunker",
        points = {{610, 8415, 865, 8640}}
    },
    MistyMountainHideaway = {
        title = "Misty Mountain Hideaway",
        inherits = "Easy",
        points = {{3410, 6710, 3470, 6765}},
        modsRequired = "MistyMountainHideaway"
    },
    Mockingbird = {
        title = "Mockingbird",
        inherits = "_default",
        points = {{10200, 12905, 10500, 13200}},
        modsRequired = "Mockingbird"
    },
    NorthCheckpoint = {
        title = "North Checkpoint",
        inherits = "Very_Hard",
        points = {{3665, 6975, 3855, 7130}, {4010, 7015, 4095, 7105}},
        modsRequired = "Secretz42"
    },
    RabbitHash = {
        title = "Rabbit Hash",
        inherits = "Easy",
        points = {{9045, 7240, 9575, 7490}},
        modsRequired = "RabbitHashKY"
    },
    -- Two releases: RavenCreekB42 and kardinal's B42 port, which reaches a
    -- little further north and adds a site to the south-east.
    RavenCreek = {
        difficulty = 3,
        inherits = "Very_Hard",
        title = "Raven Creek",
        modsRequired = "RavenCreekB42;kardinal_ravencreek_B42",
        points = {{5100, 17190, 5720, 17731}, {4088, 12855, 4097, 12856}, {5706, 15568, 5916, 16148},
                  {4191, 15185, 5385, 15601}, {4191, 15598, 5708, 16217}, {4800, 16214, 5703, 16821},
                  {5950, 17425, 6115, 17595}}
    },
    RavenCreekInfectionControl = {
        inherits = "RavenCreek",
        difficulty = 4,
        modsRequired = "RavenCreekB42;kardinal_ravencreek_B42",
        points = {{4935, 16910, 5330, 17162}}
    },
    RavenCreekExpressway = {
        inherits = "RavenCreek",
        difficulty = 4,
        modsRequired = "RavenCreekB42;kardinal_ravencreek_B42",
        points = {{5382, 15340, 6398, 15453}}
    },
    RavenCreekCityPort = {
        inherits = "RavenCreek",
        points = {{4314, 16378, 4767, 17003}},
        difficulty = 4,
        modsRequired = "RavenCreekB42;kardinal_ravencreek_B42",
        subtitle = "City Port"
    },
    -- Placeholder mod id: this never activates until the real one is known.
    Safeharbor = {
        title = "Safeharbor",
        inherits = "Hard",
        modsRequired = "modid",
        points = {{11658, 10470, 12611, 11028}}
    },
    SafeWayHamlet = {
        inherits = "Medium",
        title = "SafeWay Hamlet",
        modsRequired = "SafeWayHamlet",
        points = {{12578, 10801, 12905, 11372}}
    },
    Savannah = {
        title = "Savannah",
        inherits = "Medium",
        points = {{12940, 6895, 13205, 7205}},
        modsRequired = "TWD-SAVANNAH"
    },
    SecretBunker = {
        title = "Secret Bunker",
        inherits = "Very_Hard",
        points = {{6025, 11800, 6080, 11880}},
        modsRequired = "Secretz42"
    },
    SerenityBunker = {
        title = "Serenity Bunker",
        inherits = "Very_Hard",
        points = {{4645, 9295, 4745, 9410}},
        modsRequired = "serenitybunker"
    },
    SerenityCove = {
        title = "Serenity Cove",
        inherits = "Medium",
        points = {{6667, 12111, 6860, 12305}},
        modsRequired = "serenitycove"
    },
    ShamrockFarm = {
        inherits = "Medium",
        title = "Shamrock Farm",
        modsRequired = "ShamrockFarm",
        points = {{2480, 7200, 2685, 7305}}
    },
    SouthwestCheckpoint = {
        title = "Military Checkpoint",
        inherits = "Very_Hard",
        points = {{6670, 11175, 6805, 11340}},
        modsRequired = "Secretz42"
    },
    SunshineFarm = {
        title = "Sunshine Farm",
        inherits = "Easy",
        points = {{4360, 13900, 4575, 14010}},
        modsRequired = "Sunshine Farm"
    },
    Taylorsville = {
        inherits = "Medium",
        title = "Taylorsville",
        modsRequired = "Taylorsville",
        points = {{9335, 6600, 10205, 7110}, {10305, 6890, 10425, 6965}}
    },
    tikitown = {
        inherits = "Medium",
        title = "Tikitown",
        modsRequired = "tikitown",
        points = {{6735, 6905, 7805, 7795}, {6640, 7575, 6735, 7665}, {6665, 7135, 6735, 7180}}
    },
    TravelierMotel = {
        title = "Travelier Motel",
        inherits = "Medium",
        points = {{3715, 8000, 3750, 8050}},
        modsRequired = "Motel"
    },
    -- One mod, two settlements: the main town and a smaller one to the north.
    VanilinhaCityB42 = {
        inherits = "Medium",
        title = "Vanilinha City",
        modsRequired = "VanilinhaCityB42",
        points = {{12001, 9609, 13558, 11063}, {12900, 8720, 13420, 8980}}
    },
    YanghuTown = {
        inherits = "Medium",
        title = "Yanghu Town",
        modsRequired = "Yanghu Town",
        points = {{8700, 9000, 9520, 9575}}
    },
    YoungerCreek = {
        title = "Younger Creek",
        inherits = "Easy",
        points = {{12605, 11155, 12855, 11355}},
        modsRequired = "YoungerCreekKY"
    }
}
