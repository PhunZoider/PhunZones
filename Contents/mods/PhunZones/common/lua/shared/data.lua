return {
    void = {
        difficulty = 0,
        title = "Void",
        isVoid = true,
        zones = {{21000, 6000, 24899, 13499}}
    },
    WestPoint = {
        difficulty = 2,
        rads = 20,
        title = "West Point",
        zones = {{11100, 6580, 13199, 7499}}
    },
    EchoPark = {
        difficulty = 2,
        title = "Echo Park",
        zones = {{3340, 10818, 3921, 11410}}
    },
    Ekron = {
        difficulty = 2,
        title = "Ekron",
        zones = {{10, 9226, 1101, 9974}}
    },
    Irvington = {
        difficulty = 2,
        title = "Irvington",
        zones = {{2155, 13785, 3013, 14245}, {1691, 14246, 3149, 14980}}
    },
    IrvingtonSpeedway = {
        difficulty = 2,
        title = "Irvington",
        subtitle = "Speedway",
        zones = {{870, 12770, 1234, 13424}}
    },
    MarchRidge = {
        difficulty = 2,
        rads = 35,
        title = "March Ridge",
        zones = {{9600, 12600, 10499, 13199}}
    },
    Muldraugh = {
        difficulty = 1,
        rads = 10,
        title = "Muldraugh",
        zones = {{10558, 9175, 11023, 10692}}
    },
    Rosewood = {
        difficulty = 0,
        title = "Rosewood",
        zones = {{7800, 10800, 8699, 12299}},
        children = {
            cabins = {
                zones = {{7503, 11402, 7788, 11689}},
                difficulty = 2,
                subtitle = "Cabins",
                mods = "rosewoodcabins"
            },
            prison = {
                zones = {{7559, 11741, 7786, 11983}},
                difficulty = 2,
                subtitle = "State Prison"
            },
            prison2 = {
                zones = {{7559, 11741, 7786, 11983}},
                difficulty = 2,
                subtitle = "State Prison",
                mods = "rosewood_prison"
            },
            mall = {
                zones = {{7560, 11420, 7777, 11637}},
                difficulty = 2,
                subtitle = "Mall",
                mods = "Rosewood Mall"
            }
        }
    },
    Riverside = {
        difficulty = 2,
        title = "Riverside",
        zones = {{5400, 5100, 6899, 5699}}
    },
    Louisville = {
        difficulty = 3,
        rads = 80,
        title = "Louisville",
        zones = {{12400, 3904, 12545, 4483}, {11700, 300, 14699, 3899}},
        children = {
            airport = {
                zones = {{15251, 2418, 15684, 3346}},
                subtitle = "Airport"
            },
            train = {
                zones = {{12607, 4196, 12859, 4495}, {12548, 4355, 12859, 4495}},
                subtitle = "Trainyard"
            },
            mall = {
                zones = {{13519, 5724, 14088, 5975}},
                difficulty = 4,
                subtitle = "Mall"
            }
        }
    },
    ValleyStation = {
        difficulty = 4,
        title = "Valley Station",
        zones = {{12472, 5099, 13209, 6477}}
    },
    Brandenburg = {
        difficulty = 4,
        title = "Brandenburg",
        zones = {{814, 5384, 3100, 7066}}
    }
}
