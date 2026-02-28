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
        modsRequired = "\\PROJECTRVInterior42"
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
        title = "Echo Park",
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
        modsRequired = "\\Erikas_Furniture_Store",
        points = {{11490, 8235, 11578, 8323}}
    },
    Grapeseed = {
        inherits = "Medium",
        title = "Grapeseed",
        modsRequired = "\\42Grapeseed",
        points = {{6280, 10800, 7488, 11693}}
    },
    Irvington = {
        inherits = "Medium",
        title = "Irvington",
        points = {{2155, 13785, 3013, 14246}, {1691, 14246, 3149, 14980}}
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
        points = {{10496, 9176, 11023, 10692}, {10247, 9221, 10497, 9457}}
    },
    Rosewood = {
        inherits = "Very_Easy",
        title = "Rosewood",
        points = {{7800, 11424, 8549, 11902}, {8054, 11216, 8198, 11437}}
    },
    Rosewood_Cabins = {
        points = {{7503, 11402, 7788, 11689}},
        inherits = "Rosewood",
        subtitle = "Cabins",
        modsRequired = "\\rosewoodcabins"
    },
    Rosewood_Prison = {
        points = {{7559, 11741, 7786, 11983}},
        inherits = "Rosewood",
        difficulty = 3,
        subtitle = "State Prison"
    },
    Rosewood_Prison2 = {
        points = {{7559, 11741, 7786, 11983}},
        inherits = "Rosewood",
        subtitle = "State Prison",
        difficulty = 3,
        modsRequired = "\\rosewood_prison"
    },
    Rosewood_Mall = {
        points = {{7560, 11420, 7777, 11637}},
        inherits = "Rosewood",
        subtitle = "Mall",
        modsRequired = "\\Rosewood Mall"
    },
    Riverside = {
        inherits = "Medium",
        title = "Riverside",
        points = {{5400, 5181, 6899, 5699}}
    },
    Louisville = {
        inherits = "Hard",
        title = "Louisville",
        points = {{12400, 3904, 12545, 4483}, {11700, 950, 15954, 4215}}
    },
    Louisville_Airport = {
        points = {{15251, 2418, 15684, 3346}},
        subtitle = "Airport",
        inherits = "Louisville",
        difficulty = 4
    },
    Louisville_Trainyard = {
        points = {{12607, 4196, 12859, 4495}, {12548, 4355, 12859, 4495}},
        subtitle = "Trainyard",
        inherits = "Louisville"
    },
    Louisville_Mall = {
        points = {{13519, 5724, 14088, 5975}},
        inherits = "Louisville",
        subtitle = "Mall",
        difficulty = 4
    },
    Louisville_Quarantine_Zone = {
        points = {{13414, 3957, 13978, 4193}},
        subtitle = "Quarantine Zone",
        inherits = "Louisville",
        modsRequired = "\\Louisville_Quarantine_Zone",
        difficulty = 4
    },
    Louisville_Riverboat = {
        points = {{13084, 1165, 13146, 1199}},
        inherits = "Louisville",
        subtitle = "Riverboat",
        modsRequired = "\\Louisville_Riverboat"
    },
    Taylorsville = {
        inherits = "Medium",
        title = "Taylorsville",
        modsRequired = "\\Taylorsville",
        points = {{9302, 6603, 10194, 7130}}
    },
    tikitown = {
        inherits = "Medium",
        title = "Tikitown",
        modsRequired = "\\tikitown",
        points = {{6889, 7188, 7386, 7741}, {7199, 6900, 7796, 7799}}
    },
    ValleyStation = {
        inherits = "Hard",
        title = "Valley Station",
        points = {{12397, 4556, 14737, 6477}}
    },
    Brandenburg = {
        inherits = "Hard",
        title = "Brandenburg",
        points = {{1280, 5687, 2517, 6701}, {2513, 6178, 2894, 6482}, {1457, 5501, 1682, 5709}}
    },
    FallasLake = {
        inherits = "Medium",
        title = "Fallas Lake",
        points = {{7010, 8090, 7448, 8550}}
    },
    Frogtown = {
        inherits = "Medium",
        title = "Frogtown",
        modsRequired = "\\Frogtown",
        points = {{3300, 7800, 3800, 7500}}
    },
    -- to check
    DawnTown = { --
        inherits = "Medium",
        title = "Dawn Town",
        modsRequired = "\\dawn_town",
        points = {{2989, 8096, 3242, 8401}}
    },
    CoalField = {
        title = "Coal Field",
        inherits = "DawnTown",
        modsRequired = "\\dawn_town",
        points = {{3353, 8115, 3580, 8380}}
    },
    ShamrockFarm = { --
        inherits = "Medium",
        title = "Shamrock Farm",
        modsRequired = "\\ShamrockFarm",
        points = {{2392, 7194, 2717, 7518}}
    },
    YanghuTown = { --
        inherits = "Medium",
        title = "Yanghu Town",
        modsRequired = "\\Yanghu Town",
        points = {{8698, 8982, 9598, 9609}}
    },
    LabRoad = { --
        inherits = "Hard",
        title = "Lab Road",
        modsRequired = "\\LAB Road",
        points = {{5774, 12298, 6315, 12603}}
    },
    SafeWayHamlet = { --
        inherits = "Medium",
        title = "SafeWay Hamlet",
        modsRequired = "\\SafeWayHamlet",
        points = {{12578, 10801, 12905, 11372}}
    },
    beek_muldraugh_firedept = {
        inherits = "Medium",
        title = "Muldraugh",
        modsRequired = "\\beek_muldraugh_firedept",
        points = {{10500, 9177, 10585, 9234}}
    },
    VanilinhaCityB42 = {
        inherits = "Medium",
        title = "Vanilinha City",
        modsRequired = "\\VanilinhaCityB42",
        points = {{12001, 9609, 13558, 11063}}
    },
    Estate39 = {
        title = "Estate 39",
        inherits = "Medium",
        points = {{8396, 10069, 8510, 10180}},
        modsRequired = "\\Estate 39"
    },
    Meiyas = {
        title = "Meiyas",
        inherits = "Easy",
        points = {{8089, 10793, 8419, 11095}},
        noannounce = false,
        modsRequired = "\\Meiya'sTown"
    },
    QuellasCastle = {
        title = "Quella's Castle",
        inherits = "Hard",
        points = {{5443, 5159, 5633, 5310}},
        modsRequired = "\\Quella's Castle"
    },
    Maplewood = {
        title = "Maplewood",
        inherits = "Medium",
        points = {{8116, 8394, 8608, 8687}},
        modsRequired = "\\Maplewood"
    },
    CathayaValley = {
        title = "Cathaya Valley",
        inherits = "Hard",
        points = {{7206, 12601, 7509, 13192}},
        modsRequired = "\\Cathaya Valley 2.0 B42 version"
    },
    Safeharbor = {
        title = "Safeharbor",
        inherits = "Hard",
        modsRequired = "\\modid",
        points = {{11658, 10470, 12611, 11028}}
    },
    MelsBunker = {
        title = "Mels Bunker",
        inherits = "Hard",
        modsRequired = "\\MelBunker",
        points = {{597, 8401, 733, 8543}}
    },
    Hunters = {
        title = "Hunters",
        inherits = "Hard",
        points = {{6065, 5732, 6088, 5784}},
        nobuilding = false,
        modsRequired = "\\Hunter'sBaseB42"
    },
    Anruisi = {
        title = "Anruisi",
        inherits = "_default",
        points = {{11996, 11397, 12600, 12000}},
        modsRequired = "\\AnruisiTown"
    },
    Blackstone = {
        title = "Blackstone",
        inherits = "Hard",
        points = {{14946, 6483, 16960, 8505}},
        modsRequired = "\\BlackstoneMapMod"
    },
    Mockingbird = {
        title = "Mockingbird",
        inherits = "_default",
        points = {{10173, 12876, 10506, 13225}},
        modsRequired = "\\Mockingbird"
    },
    DeltaCreek = {
        title = "Delta Creek",
        inherits = "Very_Hard",
        points = {{6190, 8225, 6502, 8638}},
        modsRequired = "\\Delta-Creek-Munitions"
    },
    SerenityCove = {
        title = "Serenity Cove",
        inherits = "Medium",
        points = {{6667, 12111, 6860, 12305}},
        modsRequired = "\\serenitycove"
    },
    YoungerCreek = {
        title = "Younger Creek",
        inherits = "Easy",
        points = {{12602, 11122, 12904, 11364}},
        modsRequired = "\\YoungerCreekKY"
    },
    KiiriEstate = {
        title = "Kiiri Estate",
        inherits = "Medium",
        points = {{11103, 8134, 11279, 8310}},
        modsRequired = "\\kiiriestate",
        order = 25
    },
    TravelierMotel = {
        title = "Travelier Motel",
        inherits = "Medium",
        points = {{3708, 7990, 3766, 8049}},
        modsRequired = "\\Motel"
    },
    ForgottenFarm = {
        title = "Forgotten Farm",
        inherits = "Easy",
        points = {{8290, 9036, 8365, 9100}},
        modsRequired = "\\ForgottenFarmBunker"
    },
    WestpointFireandMall = {
        title = "",
        inherits = "WestPoint",
        points = {{10998, 6904, 11267, 7200}},
        modsRequired = "\\Westpoint-Fire"
    },
    SerenityBunker = {
        title = "Serenity Bunker",
        inherits = "Very_Hard",
        points = {{4630, 9319, 4740, 9413}},
        modsRequired = "\\serenitybunker"
    },
    WestPointMilitaryBoat = {
        title = "",
        inherits = "WestPoint",
        points = {{11786, 6545, 12006, 6595}},
        modsRequired = "\\WMTBoat"
    },
    Greenleaf = {
        title = "Greenleaf",
        inherits = "Medium",
        points = {{6297, 10194, 6805, 10826}, {6773, 10487, 6995, 10827}},
        modsRequired = "\\Greenleaf B42 version"
    },
    RavenCreek = {
        difficulty = 3,
        inherits = "Very_Hard",
        title = "Raven Creek",
        modsRequired = "\\RavenCreekB42",
        points = {{5109, 17271, 5692, 17731}, {4088, 12855, 4097, 12856}, {5706, 15568, 5916, 16148},
                  {4191, 15301, 5385., 15601}, {4191, 15598, 5708, 16217}, {4800, 16214, 5703, 16821}}
    },
    RavenCreekInfectionControl = {
        inherits = "RavenCreek",
        difficulty = 4,
        modsRequired = "\\RavenCreekB42",
        points = {{4935, 16910, 5330, 17162}}
    },
    RavenCreekExpressway = {
        inherits = "RavenCreek",
        difficulty = 4,
        modsRequired = "\\RavenCreekB42",
        points = {{5382, 15340, 6398, 15453}}
    },
    RavenCreekCityPort = {
        inherits = "RavenCreek",
        points = {{4314, 16378, 4767, 17003}},
        difficulty = 4,
        modsRequired = "\\RavenCreekB42",
        subtitle = "City Port"
    }
}
