return {
    void = {
        difficulty = 0,
        isVoid = true,
        zeds = false,
        bandits = false,
        rv = true,
        zones = {
            main = {
                zones = {{21000, 6000, 24899, 13499}}
            }
        }
    },
    WestPoint = {
        difficulty = 2,
        title = "West Point",
        zones = {
            main = {
                zones = {{11100, 6580, 13199, 7499}}
            }
        }
    },
    MarchRidge = {
        difficulty = 3,
        title = "March Ridge",
        zones = {
            main = {
                zones = {{9600, 12600, 10499, 13199}}
            },
            checkpoint = {
                zones = {{10300, 12300, 10400, 12420}},
                subtitle = "Checkpoint",
                mods = "Checkpoint_March_Ridge"
            }
        }
    },
    Muldraugh = {
        difficulty = 1,
        title = "Muldraugh",
        rads = 5,
        zones = {
            main = {
                zones = {{10490, 9160, 11000, 10700}}
            },
            ncheckpoint = {
                difficulty = 3,
                zones = {{10560, 9110, 10660, 9200}},
                subtitle = "Checkpoint",
                mods = "Checkpoint_North_Muldraugh"
            }
        }
    },
    Rosewood = {
        difficulty = 0,
        title = "Rosewood",
        zones = {
            main = {
                zones = {{7800, 10800, 8699, 12299}}
            },
            Cabins = {
                zones = {{7503, 11402, 7788, 11689}},
                difficulty = 2,
                subtitle = "Cabins",
                mods = "rosewoodcabins"
            },
            Prison = {
                zones = {{7500, 11725, 7786, 11983}},
                difficulty = 2,
                subtitle = "Kentucky State Prison",
                mods = "rosewood_prison"
            },
            Mall = {
                cells = {{25, 38}},
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
        zones = {
            main = {
                zones = {{5400, 5100, 6899, 5699}}
            },
            East = {
                zones = {{6900, 5100, 7199, 5699}},
                title = "East Side",
                mods = "catball_eastriverside"
            },
            checkpoint = {
                zones = {{6750, 5700, 6835, 5768}},
                difficulty = 3,
                subtitle = "Checkpoint",
                mods = "Checkpoint_South_Riverside"
            }
        }
    },
    Louisville = {
        difficulty = 3,
        rads = 60,
        title = "Louisville",
        zones = {
            main = {
                zones = {{12400, 3904, 12545, 4483}, {11700, 300, 14699, 3899}}
            },
            QZ = {
                zones = {{12400, 3904, 12600, 4351}, {13410, 3900, 14090, 4190}},
                subtitle = "Quarantine Zone",
                difficulty = 2,
                mods = "Louisville_Quarantine_Zone"
            },
            Train = {
                zones = {{12607, 4196, 12859, 4495}, {12548, 4355, 12859, 4495}},
                subtitle = "Trainyard"
            },
            Mall = {
                zones = {{13519, 5724, 14088, 5975}},
                difficulty = 4,
                subtitle = "Mall"
            },
            Airport = {
                zones = {{12865, 4200, 13447, 4796}},
                subtitle = "International Airport",
                mods = "SimonMDLVInternationalAirport"
            },
            Hospital = {
                zones = {{12865, 4200, 12502, 3754}},
                subtitle = "Hospital",
                mods = "Battlefield_Louisville_Hospital"
            },
            Stadium = {
                zones = {{12900, 1240, 13050, 1345}},
                subtitle = "Hospital",
                mods = "Battlefield_Louisville_Stadium"
            },
            Port = {
                zones = {{12289, 3502, 12600, 5000}},
                difficulty = 2,
                subtitle = "Shipping Port",
                mods = "SimonMDLVHarbor"
            },
            Boat = {
                zones = {{12900, 900, 12930, 930}},
                difficulty = 2,
                subtitle = "Riverboat",
                mods = "Louisville_Riverboat"
            },
            Tuners = {
                zones = {{12300, 2400, 12600, 2700}},
                subtitle = "Custom Import Tuners",
                mods = "WedTuners"
            },
            Pizza = {
                zones = {{12900, 3685, 12941, 3734}},
                difficulty = 2,
                subtitle = "Freddy's Fazbear Pizza",
                mods = "Frede2"
            }
        }
    },
    Crossroads = {
        difficulty = 3,
        title = "Crossroads",
        subtitle = "Checkpoint",
        zones = {
            main = {
                zones = {{10515, 11125, 10670, 11285}}
            }
        }
    },
    Brasil = {
        difficulty = 1,
        title = "Brasiliana",
        mods = "Brazil farm",
        zones = {
            main = { -- respawn checked - failed
                title = "Brasiliana",
                difficulty = 1,
                zones = {{7225, 10800, 7800, 10975}, {7500, 10800, 7800, 11700}, {7226, 10870, 7337, 10975},
                         {7800, 11100, 8100, 11400}},
                mods = "Brazil farm"
            },
            farm = { -- respawn checked - failed
                zones = {{7226, 10870, 7337, 10975}},
                subtitle = "Farm",
                mods = "Brazil farm"
            },
            nova = { -- respawn checked - failed
                zones = {{7500, 10800, 7800, 11100}},
                subtitle = "Nova",
                mods = "NovaRosewood"
            },
            recanto = { -- respawn checked - failed
                zones = {{7500, 11400, 7800, 11700}},
                subtitle = "Recanto",
                mods = "recanto"
            },
            salinas = { -- respawn checked - failed
                zones = {{7500, 11100, 7800, 11400}},
                difficulty = 2,
                subtitle = "Salinas",
                mods = "salinas"
            },
            entrada = { -- respawn checked - failed
                zones = {{7800, 11100, 8100, 11400}},
                subtitle = "Entrada",
                mods = "entrada"
            }
        }
    },
    Taylorsville = {
        rads = 10,
        difficulty = 2,
        title = "Bridge",
        mods = "Taylorsville_bridge_to_Dirkerdam",
        zones = {
            Bridge = {
                zones = {{9601, 5703, 9900, 6597}}
            },
            main = {
                zones = {{9302, 6603, 10194, 7130}},
                mods = "Taylorsville"
            }
        }
    },
    Romero = {
        rads = 20,
        difficulty = 4,
        title = "The Romero",
        mods = "TheRomero",
        zones = {
            main = {
                zones = {{11894, 1240, 11985, 1506}},
                subtitle = "Ship of the dead"
            }
        }
    },
    ElliotPond = {
        difficulty = 2,
        title = "Elliot Pond",
        mods = "Elliot Pond",
        zones = {
            main = {
                zones = {{3902, 13501, 7489, 15593}}
            }
        }
    },
    RallyMap = {
        difficulty = 2,
        title = "Rally",
        mods = "RallyMap",
        zones = {
            main = {
                zones = {{14999, 4199, 16195, 5095}}
            }
        }
    },
    LyzzExotics = {
        difficulty = 2,
        title = "Exotics Rest Area",
        mods = "LyzzExotics",
        zones = {
            main = {
                zones = {{6900, 11100, 7197, 11396}}
            }
        }
    },
    NorthKillian = {
        difficulty = 2,
        title = "Killian County",
        mods = "NorthKillian",
        zones = {
            main = {
                zones = {{7206, 8702, 8689, 9590}}
            },
            Sorian = {
                zones = {{7209, 9101, 7599, 9441}},
                difficulty = 3,
                subtitle = "Sorian City"
            },
            Alcatraz = {
                zones = {{7811, 8999, 7974, 9222}},
                difficulty = 4,
                subtitle = "Alcatraz"
            },
            Edey = {
                zones = {{8134, 8869, 8620, 9293}},
                difficulty = 3,
                subtitle = "EdeyVille"
            },
            Zuley = {
                zones = {{7256, 8706, 7498, 8871}},
                subtitle = "Zuley Town"
            }
        }
    },
    KillianCenter = {
        difficulty = 3,
        title = "Killian Country",
        mods = "KillianCountryCenter",
        zones = {
            main = {
                zones = {{7499, 9590, 8099, 10198}}
            }
        }
    },
    Coryerdon = {
        rads = 30,
        difficulty = 3,
        title = "Coryerdon",
        mods = "coryerdon",
        zones = {
            main = {
                zones = {{7794, 5719, 9883, 6220}, {7794, 6220, 9298, 6596}, {8356, 6596, 9010, 7191}}
            }
        }
    },
    Jasperville = {
        difficulty = 3,
        title = "Jasperville",
        mods = "Jasperville",
        zones = {
            main = {
                zones = {{4807, 1503, 6939, 3288}}
            }
        }
    },
    Leavenburg = {
        difficulty = 3,
        title = "Leavenburg",
        mods = "Leavenburg",
        zones = {
            main = {
                zones = {{5402, 3871, 6337, 4475}}
            }
        }
    },
    AmusementPark = { -- respawn checked
        difficulty = 3,
        title = "Amusement Park",
        mods = "SimonMDValuTechAmusementPark",
        zones = {
            main = {
                zones = {{13503, 4201, 13796, 4794}}
            }
        }
    },
    nuke17x36 = {
        difficulty = 3,
        title = "Trucker Stop",
        mods = "nuke17x36",
        zones = {
            main = {
                zones = {{5109, 10830, 5260, 11000}}
            }
        }
    },
    nuke37x22 = {
        difficulty = 3,
        title = "Railyard",
        mods = "nuke37x22",
        zones = {
            main = {
                zones = {{11100, 9600, 11400, 9900}}
            }
        }
    },
    nuke22x22 = {
        difficulty = 3,
        title = "Construction Site",
        mods = "nuke22x22",
        zones = {
            main = {
                zones = {{6600, 6600, 6890, 6890}}
            }
        }
    },
    VSTOWN = {
        rads = 10,
        difficulty = 3,
        title = "Valley Station Town",
        mods = "VSTOWN",
        zones = {
            main = {
                zones = {{13800, 4800, 14690, 5090}}
            }
        }
    },
    Dirkerdam = { -- respawn checked - failed
        difficulty = 2,
        rads = 10,
        title = "Dirkerdam",
        mods = "Dirkerdam",
        zones = {
            main = {
                zones = {{6271, 2068, 8770, 4504}, {8829, 5606, 9067, 5978}, {8782, 4517, 9579, 4915},
                         {1899, 2118, 2723, 2879}}
            },
            Shipyard = {
                rads = 30,
                zones = {{7707, 4527, 8262, 5086}},
                difficulty = 3,
                subtitle = "Shipyard"
            }
        }
    },
    TrimbleCounty = {
        difficulty = 2,
        title = "Trimble County Power Station",
        mods = "TrimbleCountyPowerStation",
        zones = {
            main = {
                zones = {{15000, 3000, 18899, 4199}}
            },
            Crestwood = {
                zones = {{15003, 3902, 15521, 4109}},
                subtitle = "Crestwood"
            },
            LaGrange = {
                zones = {{15631, 3190, 16207, 3417}},
                subtitle = "La Grange"
            },
            Sulpher = {
                zones = {{17126, 3100, 17361, 3208}},
                subtitle = "Sulpher"
            },
            Campbellsburg = {
                zones = {{18402, 3574, 18598, 3856}},
                subtitle = "Campbellsburg"
            },
            NewCastle = {
                zones = {{17983, 3921, 3921, 4116}},
                subtitle = "New Castle"
            },
            Smithfield = {
                zones = {{17272, 3909, 17490, 4071}},
                subtitle = "Smithfield"
            }
        }
    },
    hopewell = {
        difficulty = 2,
        title = "Hopewell",
        mods = "hopewell_eng_zombies",
        zones = {
            main = {
                zones = {{14700, 2700, 15599, 3599}}
            }
        }
    },
    Crowlake = { -- respawn checked
        difficulty = 2,
        title = "Crowlake",
        mods = "Crowlake",
        zones = {
            main = {
                zones = {{6300, 11100, 6600, 11700}}
            }
        }
    },
    Pineville = {
        difficulty = 2,
        title = "Pineville",
        mods = "pineville",
        zones = {
            main = {
                zones = {{3900, 9000, 4200, 9300}, {3900, 9300, 4500, 10200}}
            }
        }
    },
    Yakama = {
        difficulty = 3,
        title = "Yakama State Park",
        mods = "YakamaStatePark",
        zones = {
            main = {
                zones = {{8400, 10500, 8700, 11400}, {8700, 11100, 9000, 11400}, {9000, 10500, 9600, 11400}}
            }
        }
    },
    LCv2 = {
        rads = 20,
        difficulty = 2,
        title = "Lake Cumberland",
        mods = "LCv2",
        zones = {
            main = {
                zones = {{13200, 6300, 17999, 8099}}
            }
        }
    },
    PrepperReloaded = {
        difficulty = 2,
        title = "Last Minute Prepper",
        mods = "LastMinutePrepperReloaded",
        zones = {
            main = {
                zones = {{13200, 3600, 13499, 3899}}
            }
        }
    },
    RfMCtBF = {
        difficulty = 2,
        title = "Monmouth County to Bedford Falls",
        mods = "RfMCtBF_addon",
        zones = {
            main = {
                zones = {{12900, 8100, 13499, 8399}}
            }
        }
    },
    BedfordFalls = { -- respawn checked
        difficulty = 2,
        title = "Bedford Falls",
        mods = "BedfordFalls",
        zones = {
            main = {
                zones = {{12600, 10800, 12900, 11400}, {12900, 9900, 13500, 11400}, {13500, 7500, 14400, 13200}}
            }
        }
    },
    Breakpoint = {
        difficulty = 2,
        title = "Breakpoint",
        mods = "Breakpoint",
        zones = {
            main = {
                zones = {{12600, 4800, 12899, 5099}}
            }
        }
    },
    FortKnoxLinked = {
        difficulty = 2,
        title = "Fort Knox",
        mods = "FortKnoxLinked",
        zones = {
            main = {
                zones = {{12300, 13200, 15899, 17999}}
            }
        }
    },
    Seaside = {
        difficulty = 2,
        title = "Seaside",
        mods = "Seaside",
        zones = {
            main = {
                zones = {{12300, 900, 12599, 1199}}
            }
        }
    },
    RedRacer = {
        difficulty = 2,
        title = "Redstone Raceway",
        mods = "RedRacer",
        zones = {
            main = {
                zones = {{12000, 10800, 12299, 11399}}
            }
        }
    },
    MonmouthCounty = {
        difficulty = 2,
        title = "Monmouth County",
        mods = "MonmouthCounty_new",
        zones = {
            main = {
                zones = {{11700, 7800, 12899, 8999}}
            }
        }
    },
    Ashenwood = { -- respawn checked
        difficulty = 2,
        title = "Ashenwood",
        mods = "Ashenwood",
        zones = {
            main = {
                zones = {{11400, 11100, 11699, 11699}}
            }
        }
    },
    Linden = {
        difficulty = 2,
        title = "Linden",
        mods = "Linden",
        zones = {
            main = {
                zones = {{11400, 8400, 11699, 8699}}
            }
        }
    },
    AddamsMansion = { -- respawn checked
        difficulty = 2,
        title = "Addams Mansion",
        mods = "AddamsMansion",
        zones = {
            main = {
                zones = {{11290, 9400, 11399, 9570}}
            }
        }
    },
    TeraMartEast = {
        rads = 10,
        difficulty = 2,
        title = "TeraMart East",
        mods = "TeraMart - East Side",
        zones = {
            main = {
                zones = {{10800, 11100, 11099, 11399}}
            }
        }
    },
    UncleReds = {
        rads = 40,
        difficulty = 2,
        title = "Uncle Red's Bunker",
        mods = "UncleRedsBunkerRedux",
        zones = {
            main = {
                zones = {{10800, 10800, 11099, 11099}}
            }
        }
    },
    Papaville = {
        difficulty = 2,
        title = "Papaville",
        mods = "Papaville",
        zones = {
            main = {
                zones = {{10800, 8100, 11099, 8399}}
            }
        }
    },
    Petroville = {
        difficulty = 2,
        title = "Petroville",
        mods = "Petroville",
        zones = {
            main = {
                zones = {{10500, 11700, 11399, 12599}}
            }
        }
    },
    TheMuseum = {
        difficulty = 2,
        title = "The Museum",
        mods = "TheMuseumID",
        zones = {
            main = {
                zones = {{10500, 8100, 10799, 8399}}
            }
        }
    },
    Elysium = {
        difficulty = 2,
        title = "Elysium Island",
        mods = "Elysium_Island",
        zones = {
            main = {
                zones = {{10500, 6300, 10799, 6899}}
            }
        }
    },
    CorOTRroad = { -- respawn checked
        difficulty = 2,
        title = "BFE",
        mods = "CorOTRroad",
        zones = {
            main = {
                zones = {{10500, 6000, 10799, 6300}, {10800, 6000, 11099, 6300}}
            }
        }
    },
    Otr = {
        difficulty = 2,
        title = "Over the River",
        mods = "Otr",
        zones = {
            main = {
                zones = {{11100, 5700, 6500, 6500}}
            },
            Ship = {
                zones = {{11100, 6300, 11400, 6500}},
                subtitle = "Ship"
            }
        }
    },
    militaryfueldepot = {
        rads = 70,
        difficulty = 2,
        title = "Military Fuel Depot",
        mods = "military fuel depot",
        zones = {
            main = {
                zones = {{10200, 12900, 10799, 13499}}
            }
        }
    },
    LandeDesolateCamping = {
        difficulty = 2,
        title = "Lande Desolate Camping",
        mods = "Lande Desolate Camping",
        zones = {
            main = {
                zones = {{10200, 10500, 10499, 10799}}
            }
        }
    },
    Springwood = {
        difficulty = 2,
        title = "Springwood",
        mods = "Springwood1",
        zones = {
            main = {
                zones = {{10200, 7800, 10499, 8399}}
            }
        }
    },
    Lalafell = {
        difficulty = 2,
        title = "Lalafell's Heart Lake Town",
        mods = "Lalafell's Heart Lake Town",
        zones = {
            main = {
                zones = {{9900, 10500, 10199, 10799}}
            }
        }
    },
    Chernaville = { -- respawn checked
        difficulty = 2,
        title = "Chernaville",
        mods = "Chernaville",
        zones = {
            main = {
                zones = {{9600, 10200, 9899, 10799}}
            }
        }
    },
    TWDprison = {
        difficulty = 2,
        title = "Prison",
        mods = "TWDprison",
        zones = {
            main = {
                zones = {{9600, 9300, 9899, 9599}}
            }
        }
    },
    Militaryairport = {
        rads = 60,
        difficulty = 2,
        title = "Military Airport",
        mods = "Militaryairport",
        zones = {
            main = {
                zones = {{9600, 7800, 10199, 8699}}
            }
        }
    },
    Hopefalls = {
        difficulty = 2,
        title = "Hopefalls",
        mods = "Hopefalls",
        zones = {
            main = {
                zones = {{9600, 6600, 9899, 6899}}
            }
        }
    },
    CONRTF = { -- respawn checked
        difficulty = 2,
        title = "C.O.N. Research & Testing Facility",
        mods = "CONRTF",
        zones = {
            main = {
                zones = {{9300, 12600, 9599, 12899}}
            }
        }
    },
    Speck = {
        difficulty = 2,
        title = "Speck",
        mods = "Speck_Map",
        zones = {
            main = {
                zones = {{9000, 12300, 9299, 12599}}
            }
        }
    },
    Pitstop = {
        difficulty = 2,
        title = "Pitstop",
        mods = "Pitstop",
        zones = {
            main = {
                zones = {{9000, 10500, 9300, 11700}, {9300, 11100, 10500, 11700}, {10500, 11400, 10800, 11700},
                         {13800, 1200, 14400, 1500}}
            }
        }
    },
    BetsysFarm = { -- respawn checked - failed
        difficulty = 2,
        title = "Betsy's Farm",
        mods = "DJBetsysFarm",
        zones = {
            main = {
                zones = {{9000, 9300, 9299, 9599}}
            }
        }
    },
    RabbitHash = {
        difficulty = 2,
        title = "Rabbit Hash",
        mods = "RabbitHashKY",
        zones = {
            main = {
                zones = {{9000, 7200, 9599, 7499}}
            }
        }
    },
    lakeivytownship = {
        difficulty = 2,
        title = "Lake Ivy",
        mods = "lakeivytownship",
        zones = {
            main = {
                zones = {{8700, 9600, 9599, 10499}}
            }
        }
    },
    ParkingLot = {
        difficulty = 2,
        title = "Parking Lot",
        mods = "ParkingLot",
        zones = {
            main = {
                zones = {{8700, 8700, 9299, 8999}}
            }
        }
    },
    EdsAuto = { -- respawn checked - failed
        difficulty = 2,
        title = "Ed's Auto Salvage",
        mods = "EdsAutoSalvage",
        zones = {
            main = {
                zones = {{8700, 8400, 8999, 8699}}
            }
        }
    },
    Homepie = {
        difficulty = 2,
        title = "Homepie",
        mods = "Myhometown",
        zones = {
            main = {
                zones = {{8700, 7800, 9299, 8399}}
            }
        }
    },
    firecamp = {
        difficulty = 2,
        title = "Firecamp",
        mods = "firecamp",
        zones = {
            main = {
                zones = {{8700, 7500, 8999, 7799}}
            }
        }
    },
    Orchidwood = {
        difficulty = 2,
        title = "Orchid",
        mods = "Orchidwood(official version)",
        zones = {
            main = {
                zones = {{8100, 9600, 8699, 10199}}
            }
        }
    },
    LittleTownship = {
        difficulty = 2,
        title = "Little Township",
        mods = "LittleTownship",
        zones = {
            main = {
                zones = {{8100, 8400, 8399, 8699}}
            }
        }
    },
    Greenport = {
        difficulty = 2,
        title = "Greenport",
        mods = "Greenport",
        zones = {
            main = {
                zones = {{8100, 7400, 8699, 7799}}
            }
        }
    },
    Blackwood = { -- respawn checked
        difficulty = 2,
        title = "Blackwood",
        mods = "Blackwood",
        zones = {
            main = {
                zones = {{7800, 10500, 8099, 10799}}
            }
        }
    },
    Eerie = {
        difficulty = 2,
        title = "Irvington",
        mods = "EerieCountry",
        zones = {
            main = {
                zones = {{11363, 17839, 11679, 18174}, {11998, 17136, 12245, 17390}, {11104, 15911, 11396, 16194},
                         {11442, 13807, 11930, 14335}, {11487, 14879, 11912, 15257}, {10266, 14733, 10590, 14972},
                         {7500, 13500, 12299, 18299}},
                difficulty = 3
            }
        }
    },
    HeavensHill = {
        difficulty = 2,
        title = "Heavens Hill",
        mods = "Heavens Hill",
        zones = {
            main = {
                zones = {{7500, 7800, 7799, 8099}}
            }
        }
    },
    Grapeseed = {
        difficulty = 2,
        title = "Grapeseed",
        mods = "Grapeseed",
        zones = {
            main = {
                zones = {{7200, 11100, 7499, 11399}}
            }
        }
    },
    Utopia = {
        difficulty = 2,
        title = "Utopia",
        mods = "Utopia",
        zones = {
            main = {
                zones = {{7200, 9600, 7499, 9899}}
            }
        }
    },
    NewEkron = {
        rads = 10,
        difficulty = 2,
        title = "New Ekron",
        mods = "NewEkron",
        zones = {
            main = {
                zones = {{6900, 8100, 7499, 8699}}
            }
        }
    },
    NettleTownship = {
        difficulty = 2,
        title = "Nettle Township",
        mods = "Nettle Township",
        zones = {
            main = {
                zones = {{6600, 9000, 7199, 9599}}
            }
        }
    },
    FortRockRidge = {
        difficulty = 2,
        title = "Fort Rock Ridge",
        mods = "Fort Rock Ridge",
        zones = {
            main = {
                zones = {{6600, 6000, 7199, 6599}}
            }
        }
    },
    Greenleaf = {
        difficulty = 2,
        title = "Greenleaf",
        mods = "Greenleaf",
        zones = {
            main = {
                zones = {{6300, 10200, 6899, 10799}}
            }
        }
    },
    SimonMDSpencerMansionLootable = {
        difficulty = 2,
        title = "Spencer Mansion",
        mods = "SimonMDSpencerMansionLootable",
        zones = {
            main = {
                zones = {{6300, 5700, 6599, 5999}}
            }
        }
    },
    ResearchBase2 = {
        difficulty = 2,
        title = "Research Base",
        mods = "rbr",
        zones = {
            main = {
                zones = {{5400, 12300, 5999, 12899}, {6000, 12300, 7499, 12599}},
                mods = "rbrA2"
            }
        }
    },
    ResearchBase = {
        difficulty = 2,
        title = "Research Base",
        mods = "rbrA",
        zones = {
            main = {
                zones = {{6300, 10200, 6899, 10799}}
            }
        }
    },
    FORTREDSTONE = {
        difficulty = 2,
        title = "Fort Redstone",
        mods = "FORTREDSTONE",
        zones = {
            main = {
                zones = {{5400, 11100, 5999, 12299}}
            }
        }
    },
    BearLake = { -- respawn checked
        rads = 10,
        difficulty = 2,
        title = "Big Bear Lake",
        mods = "BBL",
        zones = {
            main = {
                zones = {{4800, 6900, 6899, 8099}}
            }
        }
    },
    CedarHill = {
        difficulty = 2,
        title = "Cedar Hill",
        mods = "CedarHill",
        zones = {
            main = {
                zones = {{4800, 5700, 5099, 5999}}
            }
        }
    },
    Chinatown = { -- respawn checked
        rads = 10,
        difficulty = 2,
        title = "Chinatown",
        mods = "Chinatown",
        zones = {
            main = {
                zones = {{11100, 8700, 11399, 9299}}
            }
        }
    },
    wilboreky = {
        difficulty = 2,
        title = "Wilbore",
        mods = "wilboreky",
        zones = {
            main = {
                zones = {{4500, 9900, 5099, 10799}}
            }
        }
    },
    Chestown = { -- respawn checked
        difficulty = 2,
        title = "Chestown",
        mods = "Chestown",
        zones = {
            main = {
                zones = {{4500, 6600, 4799, 6899}}
            }
        }
    },
    OverlookHotel = {
        difficulty = 2,
        title = "The Overlook",
        mods = "OverlookHotel",
        zones = {
            main = {
                zones = {{4500, 6300, 4799, 6599}}
            }
        }
    },
    FinneganMentalAsylum = {
        difficulty = 4,
        title = "Finnegan Research Center",
        mods = "FinneganMentalAsylum",
        zones = {
            main = {
                zones = {{3902, 9578, 3987, 9678}, {3900, 9300, 4499, 9899}},
                difficulty = 2
            }
        }
    },
    SuperGigaMart = {
        difficulty = 2,
        title = "Super Giga Mart",
        mods = "SuperGigaMart",
        zones = {
            main = {
                zones = {{3600, 6300, 3899, 6599}}
            }
        }
    },
    RavenCreek = {
        rads = 30,
        difficulty = 3,
        title = "Raven Creek Village",
        mods = "RavenCreek",
        zones = {
            main = {
                zones = {{3909, 13036, 4492, 13496}, {3988, 13036, 4097, 12856}, {3046, 12157, 3544, 12809},
                         {4499, 11400, 4709, 11980}, {3000, 11100, 4194, 11400}, {3300, 11400, 4500, 12000},
                         {3587, 12000, 4339, 12590}}
            },
            InfectionControl = {
                zones = {{4193, 11100, 4400, 11220}},
                difficulty = 4,
                subtitle = "Infection Control"
            },
            Expressway = {
                zones = {{4400, 11100, 4714, 11220}},
                subtitle = "Expressway"
            },
            CityPort = {
                zones = {{3100, 12175, 3553, 12800}},
                difficulty = 4,
                subtitle = "City Port"
            }
        }
    },
    NWBlockade = {
        difficulty = 2,
        title = "Northwest Blockade",
        mods = "NWBlockade",
        zones = {
            main = {
                zones = {{3000, 6000, 3299, 6299}}
            }
        }
    },
    Hilltop = {
        difficulty = 2,
        title = "Hilltop",
        mods = "Hilltop",
        zones = {
            main = {
                zones = {{3000, 5700, 3299, 5999}}
            }
        }
    },
    Winchester = {
        difficulty = 2,
        title = "Winchester",
        mods = "Winchester",
        zones = {
            main = {
                zones = {{2100, 6600, 4199, 8699}}
            }
        }
    },
    tikitown = {
        difficulty = 2,
        title = "Tikitown",
        mod = "tikitown",
        zones = {
            main = {
                zones = {{6889, 7188, 7386, 7741}, {7199, 6900, 7796, 7469}}
            }
        }
    },
    CanvasbackStudios = { -- respawn checked
        difficulty = 2,
        title = "Canvasback Studios",
        mods = "Canvasback Studios",
        zones = {
            main = {
                zones = {{9910, 10200, 10170, 10440}}
            }
        }
    },
    Purgatory = {
        difficulty = 2,
        title = "Purgatory",
        mods = "PurgatoryCity",
        zones = {
            main = {
                zones = {{2700, 8700, 3900, 9300}}
            }
        }
    },
    NaturesVengeance = {
        difficulty = 2,
        title = "Nature's Vengeance",
        mods = "nv_township_v1",
        zones = {
            main = {
                zones = {{6300, 7800, 6600, 8100}}
            }
        }
    },
    Millstin = {
        difficulty = 2,
        title = "Millstin",
        mods = "millstinwithwestpoint",
        zones = {
            main = {
                zones = {{11100, 7200, 11700, 8100}}
            }
        }
    },
    Lighthousematrioshka = {
        difficulty = 2,
        title = "Lighthouse",
        mods = "Lighthousematrioshka",
        zones = {
            main = {
                zones = {{10800, 6300, 11100, 6600}}
            }
        }
    },
    savecity = {
        difficulty = 2,
        title = "SaveCity",
        mods = "savecity",
        zones = {
            main = {
                zones = {{11700, 7500, 12000, 7800}}
            }
        }
    },
    SimonMDRRRR = {
        difficulty = 2,
        title = "Rusty Rascals",
        mods = "SimonMDRRRR",
        zones = {
            main = {
                zones = {{14100, 3300, 14400, 3600}}
            }
        }
    },
    TWDterminus = {
        difficulty = 2,
        title = "Terminus",
        mods = "TWDterminus",
        zones = {
            main = {
                zones = {{11400, 10500, 11700, 11100}}
            }
        }
    },
    TheRuinsofBracklewhyte = {
        difficulty = 2,
        title = "Bracklewhyte",
        mods = "TheRuinsofBracklewhyte",
        zones = {
            main = {
                zones = {{5100, 9000, 5400, 9300}}
            }
        }
    },
    the_oasis = {
        difficulty = 2,
        title = "Oasis",
        mods = "the_oasis",
        zones = {
            main = {
                zones = {{4800, 9300, 5400, 9900}}
            }
        }
    },
    Valley_Station_44 = {
        difficulty = 2,
        title = "Valley Station",
        mods = "Valley_Station_44-19",
        zones = {
            main = {
                zones = {{13200, 5700, 13500, 6000}}
            }
        }
    },
    Trapalaketown = {
        difficulty = 2,
        title = "Trapalaketown",
        mods = "Trapalaketown",
        zones = {
            main = {
                zones = {{8400, 11700, 9000, 12000}}
            }
        }
    },
    TheYacht = {
        difficulty = 2,
        title = "The Yacht",
        mods = "The Yacht",
        zones = {
            main = {
                zones = {{3600, 5400, 3900, 5700}}
            }
        }
    },
    Wellsburg = {
        difficulty = 2,
        title = "Wellsburg Lake",
        mods = "Wellsburg",
        zones = {
            main = {
                zones = {{7500, 10200, 7800, 10500}}
            }
        }
    },
    WalterWhiteHouse = {
        difficulty = 2,
        title = "Walter White House",
        mods = "Walter White House",
        zones = {
            main = {
                zones = {{10800, 6900, 11100, 7200}}
            }
        }
    },
    WhiteForestCamp = {
        difficulty = 2,
        title = "White Forest Camp",
        mods = "White Forest Camp",
        zones = {
            main = {
                zones = {{10200, 8400, 10500, 8700}}
            }
        }
    },
    WeyhausenByCallnmx = {
        difficulty = 2,
        title = "Weyhausen",
        mods = "WeyhausenByCallnmx",
        zones = {
            main = {
                zones = {{5100, 9300, 5400, 9600}}
            }
        }
    },
    WesternScrapCarYard = {
        difficulty = 2,
        title = "Western Scrapyard",
        mods = "WesternScrapCarYard",
        zones = {
            main = {
                zones = {{8700, 9000, 9000, 9300}}
            }
        }
    },
    MilitaryCheckpointWestPointAbisi = {
        difficulty = 3,
        title = "Military Checkpoint",
        mods = "MilitaryCheckpointWestPointAbisi",
        zones = {
            main = {
                zones = {{11400, 7500, 11700, 7800}}
            }
        }
    },
    Ztardew = {
        difficulty = 2,
        title = "Ztardew Valley",
        mods = "Ztardew",
        zones = {
            main = {
                zones = {{12000, 9300, 12900, 1020}}
            }
        }
    },
    ZonaSegura0123 = {
        cells = {{39, 30}},
        difficulty = 2,
        title = "Zona Segura",
        mods = "ZonaSegura0123",
        zones = {
            main = {
                zones = {{11700, 9000, 12000, 9300}}
            }
        }
    },
    QuarryLake_Xavior = {
        difficulty = 2,
        title = "Quarry Lake",
        mods = "QuarryLake_Xavior",
        zones = {
            main = {
                zones = {{12000, 11400, 12600, 12000}}
            }
        }
    },
    EventureIsland = {
        difficulty = 2,
        title = "Eventure Island",
        mods = "EventureIsland",
        zones = {
            main = {
                zones = {{1445, 3884, 2638, 4992}}
            }
        }
    },
    NightFallky = {
        difficulty = 2,
        title = "NightFall",
        mods = "NightFallky",
        zones = {
            main = {
                zones = {{10200, 10200, 10500, 10500}}
            }
        }
    },
    SunsetLake = {
        difficulty = 2,
        title = "Sunset Lake",
        mods = "114519",
        zones = {
            main = {
                zones = {{6600, 11100, 7200, 12000}}
            }
        }
    },
    TravelierInn = {
        difficulty = 2,
        title = "Travelier Motor Inn",
        mods = "traveliermotorinnmotel",
        zones = {
            main = {
                zones = {{6115, 5794, 6194, 5846}}
            }
        }
    },
    NewAlbany = {
        difficulty = 2,
        title = "New Albany",
        mods = "NewAlbany",
        zones = {
            main = {
                zones = {{11700, 0, 15000, 900}}
            }
        }
    },
    ConstowmWithRCandFR = { -- respawn checked - failed
        difficulty = 3,
        title = "Constown",
        mods = "constownwithRCandFR",
        zones = {
            main = {
                zones = {{5100, 10800, 6300, 11400}}
            }
        }
    },
    NewEllroy = {
        cells = {{17, 33}, {17, 34}, {18, 33}, {18, 34}},
        difficulty = 3,
        title = "Ellroy",
        mods = "NewEllroy",
        zones = {
            main = {
                zones = {{5100, 9900, 5700, 10500}}
            }
        }
    },
    ErikasFurnitureStore = {
        cells = {{38, 27}},
        difficulty = 3,
        title = "Ellroy",
        mods = "Erikas_Furniture_Store",
        zones = {
            main = {
                zones = {{11486, 8229, 11584, 8322}}
            }
        }
    },
    BitterrootRanch = { -- respawn checked - failed
        cells = {{35, 24}, {35, 25}},
        difficulty = 3,
        title = "Bitterroot",
        mods = "Bitterroot Ranch",
        zones = {
            main = {
                zones = {{10607, 7555, 10768, 7637}}
            }
        }
    },
    NuclearReactor = {
        rads = 75,
        difficulty = 4,
        title = "Reactor",
        mods = "NUCExperimentalReactor;PhunRadNUC;",
        zones = {
            main = {
                rads = 25,
                zones = {{8390, 12273, 8472, 12750}}
            },
            approach = {
                rads = 50,
                zones = {{8400, 12300, 8772, 12650}}
            },
            grounds = {
                rads = 75,
                zones = {{8490, 12373, 8672, 12550}}
            },
            core = {
                rads = 100,
                zones = {{8537, 12421, 8617, 12475}}
            }
        }
    },
    DenseWoods = { -- respawn checked - failed
        difficulty = 3,
        title = "Woods",
        mods = "AbandonedSurvivorBase",
        zones = {
            main = {
                zones = {{14400, 5100, 14700, 5400}}
            }
        }
    },
    hospital = {
        difficulty = 0,
        zeds = false,
        bandits = false,
        title = "Unknown",
        mods = "respawn-hospital-rooms2",
        zones = {
            main = {
                zones = {{30000, 30000, 30300, 32300}}
            }
        }
    },
    shortrest = {
        difficulty = 2,
        title = "Shortrest",
        mods = "Shortrest_City",
        zones = {
            main = {
                zones = {{13200, 6600, 14700, 7500}}
            }
        }
    },
    jackson = {
        difficulty = 1,
        title = "Shortrest",
        mods = "jackson",
        zones = {
            main = {
                zones = {{10810, 10555, 11377, 10945}}
            }
        }
    }
}
