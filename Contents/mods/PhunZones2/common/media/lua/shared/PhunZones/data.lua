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
    WestPoint = {
        inherits = "Medium",
        title = "West Point",
        points = {{10903, 6580, 12282, 7205}}
    },
    EchoPark = {
        inherits = "Medium",
        title = "Echo Creek",
        points = {{3340, 10818, 3921, 11410}}
    },
    Ekron = {
        inherits = "Medium",
        title = "Ekron",
        points = {{10, 9299, 1101, 9974}}
    },
    ErikasFurnitureStore = {
        inherits = "Hard",
        title = "Erikas",
        modsRequired = "Erikas_Furniture_Store",
        points = {{11490, 8235, 11578, 8323}}
    },
    Grapeseed = {
        inherits = "Medium",
        title = "Grapeseed",
        modsRequired = "42Grapeseed",
        points = {{6280, 10800, 7488, 11693}}
    },
    Irvington = {
        inherits = "Medium",
        title = "Irvington",
        points = {{2155, 13785, 3013, 14246}, {1691, 14246, 3149, 14980}, {3660, 14610, 3860, 14780}}
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
    Muldraugh = {
        inherits = "Easy",
        title = "Muldraugh",
        points = {{10496, 9176, 11023, 10692}}
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
    DixieTrailerPark = {
        inherits = "Easy",
        title = "Dixie Trailer Park",
        points = {{11430, 8760, 11890, 8980}}
    },
    Rosewood = {
        inherits = "Very_Easy",
        title = "Rosewood",
        points = {{7800, 11096, 8200, 11424}, {7800, 11424, 8549, 11902}, {7900, 11902, 8520, 12360}}
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
    Riverside = {
        inherits = "Medium",
        title = "Riverside",
        points = {{5400, 5181, 6899, 5699}}
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
    Louisville = {
        inherits = "Hard",
        title = "Louisville",
        points = {{12400, 3904, 12545, 4483}, {11700, 950, 15954, 4215}}
    },
    Louisville_Downtown = {
        inherits = "Louisville",
        subtitle = "Downtown",
        difficulty = 4,
        points = {{11980, 1040, 13150, 2110}}
    },
    Louisville_GrandOhioMall = {
        inherits = "Louisville",
        subtitle = "Grand Ohio Mall",
        difficulty = 4,
        points = {{13455, 1250, 13690, 1430}}
    },
    Louisville_IroquoisPark = {
        inherits = "Louisville",
        subtitle = "Iroquois Park",
        difficulty = 2,
        points = {{13000, 2250, 13420, 2860}}
    },
    Louisville_ChapelmountDowns = {
        inherits = "Louisville",
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
    -- Key kept so existing configs still apply. This is Crossroads Mall, which
    -- is in Valley Station rather than Louisville.
    Louisville_Mall = {
        points = {{13519, 5724, 14088, 5975}},
        inherits = "ValleyStation",
        subtitle = "Crossroads Mall",
        difficulty = 4
    },
    -- The burnt-out quarantine town is on the vanilla map, no mod needed.
    Louisville_Quarantine_Zone = {
        points = {{13414, 3957, 13978, 4193}},
        subtitle = "Quarantine Zone",
        inherits = "Louisville",
        difficulty = 4
    },
    Louisville_Riverboat = {
        points = {{13084, 1165, 13146, 1199}},
        inherits = "Louisville_Downtown",
        subtitle = "Riverboat",
        modsRequired = "Louisville_Riverboat"
    },
    Taylorsville = {
        inherits = "Medium",
        title = "Taylorsville",
        modsRequired = "Taylorsville",
        points = {{9302, 6603, 10194, 7130}}
    },
    tikitown = {
        inherits = "Medium",
        title = "Tikitown",
        modsRequired = "tikitown",
        points = {{6889, 7188, 7386, 7741}, {7199, 6900, 7796, 7799}}
    },
    ValleyStation = {
        inherits = "Hard",
        title = "Valley Station",
        points = {{12397, 4556, 14737, 6477}}
    },
    CampFitzgerald = {
        inherits = "Medium",
        title = "Camp Fitzgerald",
        points = {{13740, 6590, 13930, 6800}}
    },
    Brandenburg = {
        inherits = "Hard",
        title = "Brandenburg",
        points = {{1280, 5670, 2517, 6701}}
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
    FallasLake = {
        inherits = "Medium",
        title = "Fallas Lake",
        points = {{7000, 8070, 7520, 8640}}
    },
    SunderlandHills = {
        inherits = "Hard",
        title = "Sunderland Hills Sanatorium",
        points = {{3800, 6090, 4300, 6560}}
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
    Frogtown = {
        inherits = "Medium",
        title = "Frogtown",
        modsRequired = "Frogtown",
        points = {{3300, 7500, 3800, 7800}}
    },
    -- to check
    DawnTown = { --
        inherits = "Medium",
        title = "Dawn Town",
        modsRequired = "dawn_town",
        points = {{2989, 8096, 3242, 8401}}
    },
    -- Coalfield is on the vanilla map; the key is kept so existing configs
    -- still apply.
    CoalField = {
        title = "Coalfield",
        inherits = "Medium",
        points = {{3353, 8115, 3600, 8380}}
    },
    ShamrockFarm = { --
        inherits = "Medium",
        title = "Shamrock Farm",
        modsRequired = "ShamrockFarm",
        points = {{2392, 7194, 2717, 7518}}
    },
    YanghuTown = { --
        inherits = "Medium",
        title = "Yanghu Town",
        modsRequired = "Yanghu Town",
        points = {{8698, 8982, 9598, 9609}}
    },
    LabRoad = { --
        inherits = "Hard",
        title = "Lab Road",
        modsRequired = "LAB Road",
        points = {{5774, 12298, 6315, 12603}}
    },
    SafeWayHamlet = { --
        inherits = "Medium",
        title = "SafeWay Hamlet",
        modsRequired = "SafeWayHamlet",
        points = {{12578, 10801, 12905, 11372}}
    },
    beek_muldraugh_firedept = {
        inherits = "Muldraugh",
        subtitle = "Fire Department",
        difficulty = 2,
        modsRequired = "beek_muldraugh_firedept",
        points = {{10500, 9177, 10585, 9234}}
    },
    VanilinhaCityB42 = {
        inherits = "Medium",
        title = "Vanilinha City",
        modsRequired = "VanilinhaCityB42",
        points = {{12001, 9609, 13558, 11063}}
    },
    Estate39 = {
        title = "Estate 39",
        inherits = "Medium",
        points = {{8396, 10069, 8510, 10180}},
        modsRequired = "Estate 39"
    },
    Meiyas = {
        title = "Meiyas",
        inherits = "Easy",
        points = {{8089, 10793, 8419, 11095}},
        noannounce = false,
        modsRequired = "Meiya'sTown"
    },
    QuellasCastle = {
        title = "Quella's Castle",
        inherits = "Riverside",
        difficulty = 3,
        points = {{5443, 5159, 5633, 5310}},
        modsRequired = "Quella's Castle"
    },
    Maplewood = {
        title = "Maplewood",
        inherits = "Medium",
        points = {{8116, 8394, 8608, 8687}},
        modsRequired = "Maplewood"
    },
    CathayaValley = {
        title = "Cathaya Valley",
        inherits = "Hard",
        points = {{7206, 12601, 7509, 13192}},
        modsRequired = "Cathaya Valley 2.0 B42 version"
    },
    Safeharbor = {
        title = "Safeharbor",
        inherits = "Hard",
        modsRequired = "modid",
        points = {{11658, 10470, 12611, 11028}}
    },
    MelsBunker = {
        title = "Mels Bunker",
        inherits = "Hard",
        modsRequired = "MelBunker",
        points = {{597, 8401, 733, 8543}}
    },
    Hunters = {
        title = "Hunters",
        inherits = "Hard",
        points = {{6065, 5732, 6088, 5784}},
        nobuilding = false,
        modsRequired = "Hunter'sBaseB42"
    },
    Anruisi = {
        title = "Anruisi",
        inherits = "_default",
        points = {{11996, 11397, 12600, 12000}},
        modsRequired = "AnruisiTown"
    },
    Blackstone = {
        title = "Blackstone",
        inherits = "Hard",
        points = {{14946, 6483, 16960, 8505}},
        modsRequired = "BlackstoneMapMod"
    },
    Mockingbird = {
        title = "Mockingbird",
        inherits = "_default",
        points = {{10173, 12876, 10506, 13225}},
        modsRequired = "Mockingbird"
    },
    DeltaCreek = {
        title = "Delta Creek",
        inherits = "Very_Hard",
        points = {{6190, 8225, 6502, 8638}},
        modsRequired = "Delta-Creek-Munitions"
    },
    SerenityCove = {
        title = "Serenity Cove",
        inherits = "Medium",
        points = {{6667, 12111, 6860, 12305}},
        modsRequired = "serenitycove"
    },
    YoungerCreek = {
        title = "Younger Creek",
        inherits = "Easy",
        points = {{12602, 11122, 12904, 11364}},
        modsRequired = "YoungerCreekKY"
    },
    KiiriEstate = {
        title = "Kiiri Estate",
        inherits = "Medium",
        points = {{11103, 8134, 11279, 8310}},
        modsRequired = "kiiriestate",
        order = 25
    },
    TravelierMotel = {
        title = "Travelier Motel",
        inherits = "Medium",
        points = {{3708, 7990, 3766, 8049}},
        modsRequired = "Motel"
    },
    ForgottenFarm = {
        title = "Forgotten Farm",
        inherits = "Easy",
        points = {{8290, 9036, 8365, 9100}},
        modsRequired = "ForgottenFarmBunker"
    },
    WestpointFireandMall = {
        subtitle = "Fire Station & Mall",
        inherits = "WestPoint",
        points = {{10998, 6904, 11267, 7200}},
        modsRequired = "Westpoint-Fire"
    },
    SerenityBunker = {
        title = "Serenity Bunker",
        inherits = "Very_Hard",
        points = {{4630, 9319, 4740, 9413}},
        modsRequired = "serenitybunker"
    },
    WestPointMilitaryBoat = {
        subtitle = "Military Boat",
        inherits = "WestPoint",
        points = {{11786, 6545, 12006, 6595}},
        modsRequired = "WMTBoat"
    },
    Greenleaf = {
        title = "Greenleaf",
        inherits = "Medium",
        points = {{6297, 10194, 6805, 10826}, {6773, 10487, 6995, 10827}},
        modsRequired = "Greenleaf B42 version"
    },
    RavenCreek = {
        difficulty = 3,
        inherits = "Very_Hard",
        title = "Raven Creek",
        modsRequired = "RavenCreekB42",
        points = {{5109, 17271, 5692, 17731}, {4088, 12855, 4097, 12856}, {5706, 15568, 5916, 16148},
                  {4191, 15301, 5385., 15601}, {4191, 15598, 5708, 16217}, {4800, 16214, 5703, 16821}}
    },
    RavenCreekInfectionControl = {
        inherits = "RavenCreek",
        difficulty = 4,
        modsRequired = "RavenCreekB42",
        points = {{4935, 16910, 5330, 17162}}
    },
    RavenCreekExpressway = {
        inherits = "RavenCreek",
        difficulty = 4,
        modsRequired = "RavenCreekB42",
        points = {{5382, 15340, 6398, 15453}}
    },
    RavenCreekCityPort = {
        inherits = "RavenCreek",
        points = {{4314, 16378, 4767, 17003}},
        difficulty = 4,
        modsRequired = "RavenCreekB42",
        subtitle = "City Port"
    }
}
