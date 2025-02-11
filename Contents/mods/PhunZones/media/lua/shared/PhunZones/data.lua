return {
    void = {
        difficulty = 0,
        isVoid = true,
        zeds = false,
        bandits = false,
        rv = true,
        points = {{21000, 6000, 24899, 13499}}
    },
    WestPoint = {
        difficulty = 2,
        title = "West Point",
        points = {{11100, 6580, 13199, 7499}}
    },
    MarchRidge = {
        difficulty = 3,
        title = "March Ridge",
        points = {{9600, 12600, 10499, 13199}},
        subzones = {
            checkpoint = {
                points = {{10300, 12300, 10400, 12420}},
                subtitle = "Checkpoint",
                mods = "Checkpoint_March_Ridge"
            }
        }
    },
    Muldraugh = {
        difficulty = 1,
        title = "Muldraugh",
        points = {{10490, 9160, 11000, 10700}},
        subzones = {
            ncheckpoint = {
                difficulty = 3,
                points = {{10560, 9110, 10660, 9200}},
                subtitle = "Checkpoint",
                mods = "Checkpoint_North_Muldraugh"
            }
        }
    },
    Rosewood = {
        difficulty = 0,
        title = "Rosewood",
        points = {{7800, 10800, 8699, 12299}},
        subzones = {
            Cabins = {
                points = {{7503, 11402, 7788, 11689}},
                difficulty = 2,
                subtitle = "Cabins",
                mods = "rosewoodcabins"
            },
            Prison = {
                points = {{7500, 11725, 7786, 11983}},
                difficulty = 2,
                subtitle = "Kentucky State Prison",
                mods = "rosewood_prison"
            },
            Mall = {
                cells = {{25, 38}},
                points = {{7560, 11420, 7777, 11637}},
                difficulty = 2,
                subtitle = "Mall",
                mods = "Rosewood Mall"
            }
        }
    },
    Riverside = {
        difficulty = 2,
        title = "Riverside",
        points = {{5400, 5100, 6899, 5699}},
        subzones = {
            East = {
                points = {{6900, 5100, 7199, 5699}},
                title = "East Side",
                mods = "catball_eastriverside"
            },
            checkpoint = {
                points = {{6750, 5700, 6835, 5768}},
                difficulty = 3,
                subtitle = "Checkpoint",
                mods = "Checkpoint_South_Riverside"
            }
        }
    },
    Louisville = {
        difficulty = 3,
        title = "Louisville",
        points = {{12400, 3904, 12545, 4483}, {11700, 300, 14699, 3899}},
        subzones = {
            QZ = {
                points = {{12400, 3904, 12600, 4351}, {13410, 3900, 14090, 4190}},
                subtitle = "Quarantine Zone",
                difficulty = 2,
                mods = "Louisville_Quarantine_Zone"
            },
            Train = {
                points = {{12607, 4196, 12859, 4495}, {12548, 4355, 12859, 4495}},
                subtitle = "Trainyard"
            },
            Mall = {
                points = {{13519, 5724, 14088, 5975}},
                difficulty = 4,
                subtitle = "Mall"
            },
            Airport = {
                points = {{12865, 4200, 13447, 4796}},
                subtitle = "International Airport",
                mods = "SimonMDLVInternationalAirport"
            },
            Hospital = {
                points = {{12865, 4200, 12502, 3754}},
                subtitle = "Hospital",
                mods = "Battlefield_Louisville_Hospital"
            },
            Stadium = {
                points = {{12900, 1240, 13050, 1345}},
                subtitle = "Hospital",
                mods = "Battlefield_Louisville_Stadium"
            },
            Port = {
                points = {{12289, 3502, 12600, 5000}},
                difficulty = 2,
                subtitle = "Shipping Port",
                mods = "SimonMDLVHarbor"
            },
            Boat = {
                points = {{12900, 900, 12930, 930}},
                difficulty = 2,
                subtitle = "Riverboat",
                mods = "Louisville_Riverboat"
            },
            Tuners = {
                points = {{12300, 2400, 12600, 2700}},
                subtitle = "Custom Import Tuners",
                mods = "WedTuners"
            },
            Pizza = {
                points = {{12900, 3685, 12941, 3734}},
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
        points = {{10515, 11125, 10670, 11285}}
    },
    Brasil = {
        difficulty = 3,
        title = "Brasiliana",
        mods = "Brazil farm",
        points = {{7225, 10800, 7800, 10975}, {7500, 10800, 7800, 11700}},
        subzones = {
            farm = { -- respawn checked - failed
                points = {{7226, 10870, 7337, 10975}},
                subtitle = "Farm",
                mods = "Brazil farm"
            },
            nova = { -- respawn checked - failed
                points = {{7500, 10800, 7800, 11100}},
                subtitle = "Nova",
                mods = "NovaRosewood"
            },
            recanto = { -- respawn checked - failed
                points = {{7500, 11400, 7800, 11700}},
                subtitle = "Recanto",
                mods = "recanto"
            },
            salinas = { -- respawn checked - failed
                points = {{7500, 11100, 7800, 11400}},
                difficulty = 2,
                subtitle = "Salinas",
                mods = "salinas"
            },
            entrada = { -- respawn checked - failed
                points = {{7800, 11100, 8100, 11400}},
                subtitle = "Entrada",
                mods = "entrada"
            }
        }
    },
    Taylorsville = {
        difficulty = 2,
        title = "Bridge",
        mods = "Taylorsville",
        points = {{9302, 6603, 10194, 7130}},
        subzones = {
            Bridge = {
                points = {{9601, 5703, 9900, 6597}},
                mods = "Taylorsville_bridge_to_Dirkerdam"
            }
        }
    },
    Romero = {
        difficulty = 4,
        title = "The Romero",
        mods = "TheRomero",
        points = {{11894, 1240, 11985, 1506}},
        subtitle = "Ship of the dead"
    },
    ElliotPond = {
        difficulty = 2,
        title = "Elliot Pond",
        mods = "Elliot Pond",
        points = {{3902, 13501, 7489, 15593}}
    },
    RallyMap = {
        difficulty = 2,
        title = "Rally",
        mods = "RallyMap",
        points = {{14999, 4199, 16195, 5095}}
    },
    LyzzExotics = {
        difficulty = 2,
        title = "Exotics Rest Area",
        mods = "LyzzExotics",
        points = {{6900, 11100, 7197, 11396}}
    },
    NorthKillian = {
        difficulty = 2,
        title = "Killian County",
        mods = "NorthKillian",
        points = {{7206, 8702, 8689, 9590}},
        subzones = {
            Sorian = {
                points = {{7209, 9101, 7599, 9441}},
                difficulty = 3,
                subtitle = "Sorian City"
            },
            Alcatraz = {
                points = {{7811, 8999, 7974, 9222}},
                difficulty = 4,
                subtitle = "Alcatraz"
            },
            Edey = {
                points = {{8134, 8869, 8620, 9293}},
                difficulty = 3,
                subtitle = "EdeyVille"
            },
            Zuley = {
                points = {{7256, 8706, 7498, 8871}},
                subtitle = "Zuley Town"
            }
        }
    },
    KillianCenter = {
        difficulty = 3,
        title = "Killian Country",
        mods = "KillianCountryCenter",
        points = {{7499, 9590, 8099, 10198}}
    },
    Coryerdon = {
        difficulty = 3,
        title = "Coryerdon",
        mods = "coryerdon",
        points = {{7794, 5719, 9883, 6220}, {7794, 6220, 9298, 6596}, {8356, 6596, 9010, 7191}}
    },
    Jasperville = {
        difficulty = 3,
        title = "Jasperville",
        mods = "Jasperville",
        points = {{4807, 1503, 6939, 3288}}
    },
    Leavenburg = {
        difficulty = 3,
        title = "Leavenburg",
        mods = "Leavenburg",
        points = {{5402, 3871, 6337, 4475}}
    },
    AmusementPark = {
        difficulty = 3,
        title = "Amusement Park",
        mods = "SimonMDValuTechAmusementPark",
        points = {{13503, 4201, 13796, 4794}}
    },
    nuke17x36 = {
        difficulty = 3,
        title = "Trucker Stop",
        mods = "nuke17x36",
        points = {{5109, 10830, 5260, 11000}}
    },
    nuke37x22 = {
        difficulty = 3,
        title = "Railyard",
        mods = "nuke37x22",
        points = {{11100, 9600, 11400, 9900}}
    },
    nuke22x22 = {
        difficulty = 3,
        title = "Construction Site",
        mods = "nuke22x22",
        points = {{6600, 6600, 6890, 6890}}
    },
    VSTOWN = {
        difficulty = 3,
        title = "Valley Station Town",
        mods = "VSTOWN",
        points = {{13800, 4800, 14690, 5090}}
    },
    Dirkerdam = { -- respawn checked - failed
        difficulty = 2,
        title = "Dirkerdam",
        mods = "Dirkerdam",
        points = {{6271, 2068, 8770, 4504}, {8829, 5606, 9067, 5978}, {8782, 4517, 9579, 4915}, {1899, 2118, 2723, 2879}},
        subzones = {
            Shipyard = {
                points = {{7707, 4527, 8262, 5086}},
                difficulty = 3,
                subtitle = "Shipyard"
            }
        }
    },
    TrimbleCounty = {
        difficulty = 2,
        title = "Trimble County Power Station",
        mods = "TrimbleCountyPowerStation",
        points = {{15000, 3000, 18899, 4199}},
        subzones = {
            Crestwood = {
                points = {{15003, 3902, 15521, 4109}},
                subtitle = "Crestwood"
            },
            LaGrange = {
                points = {{15631, 3190, 16207, 3417}},
                subtitle = "La Grange"
            },
            Sulpher = {
                points = {{17126, 3100, 17361, 3208}},
                subtitle = "Sulpher"
            },
            Campbellsburg = {
                points = {{18402, 3574, 18598, 3856}},
                subtitle = "Campbellsburg"
            },
            NewCastle = {
                points = {{17983, 3921, 3921, 4116}},
                subtitle = "New Castle"
            },
            Smithfield = {
                points = {{17272, 3909, 17490, 4071}},
                subtitle = "Smithfield"
            }
        }
    },
    hopewell = {
        difficulty = 2,
        title = "Hopewell",
        mods = "hopewell_eng_zombies",
        points = {{14700, 2700, 15599, 3599}}
    },
    Crowlake = { -- respawn checked
        difficulty = 2,
        title = "Crowlake",
        mods = "Crowlake",
        points = {{6300, 11100, 6600, 11700}}
    },
    Pineville = {
        difficulty = 2,
        title = "Pineville",
        mods = "pineville",
        points = {{3900, 9000, 4200, 9300}, {3900, 9300, 4500, 10200}}
    },
    Yakama = {
        difficulty = 3,
        title = "Yakama State Park",
        mods = "YakamaStatePark",
        points = {{8400, 10500, 8700, 11400}, {8700, 11100, 9000, 11400}, {9000, 10500, 9600, 11400}}
    },
    LCv2 = {
        difficulty = 2,
        title = "Lake Cumberland",
        mods = "LCv2",
        points = {{13200, 6300, 17999, 8099}}
    },
    PrepperReloaded = {
        difficulty = 2,
        title = "Last Minute Prepper",
        mods = "LastMinutePrepperReloaded",
        points = {{13200, 3600, 13499, 3899}}
    },
    RfMCtBF = {
        difficulty = 2,
        title = "Monmouth County to Bedford Falls",
        mods = "RfMCtBF_addon",
        points = {{12900, 8100, 13499, 8399}}
    },
    BedfordFalls = { -- respawn checked
        difficulty = 2,
        title = "Bedford Falls",
        mods = "BedfordFalls",
        points = {{12600, 10800, 12900, 11400}, {12900, 9900, 13500, 11400}, {13500, 7500, 14400, 13200}}
    },
    Breakpoint = {
        difficulty = 2,
        title = "Breakpoint",
        mods = "Breakpoint",
        points = {{12600, 4800, 12899, 5099}}
    },
    FortKnoxLinked = {
        difficulty = 2,
        title = "Fort Knox",
        mods = "FortKnoxLinked",
        points = {{12300, 13200, 15899, 17999}}
    },
    Seaside = {
        difficulty = 2,
        title = "Seaside",
        mods = "Seaside",
        points = {{12300, 900, 12599, 1199}}
    },
    RedRacer = {
        difficulty = 2,
        title = "Redstone Raceway",
        mods = "RedRacer",
        points = {{12000, 10800, 12299, 11399}}
    },
    MonmouthCounty = {
        difficulty = 2,
        title = "Monmouth County",
        mods = "MonmouthCounty_new",
        points = {{11700, 7800, 12899, 8999}}
    },
    Ashenwood = { -- respawn checked
        difficulty = 2,
        title = "Ashenwood",
        mods = "Ashenwood",
        points = {{11400, 11100, 11699, 11699}}
    },
    Linden = {
        difficulty = 2,
        title = "Linden",
        mods = "Linden",
        points = {{11400, 8400, 11699, 8699}}
    },
    AddamsMansion = { -- respawn checked
        difficulty = 2,
        title = "Addams Mansion",
        mods = "AddamsMansion",
        points = {{11290, 9400, 11399, 9570}}
    },
    TeraMartEast = {
        difficulty = 2,
        title = "TeraMart East",
        mods = "TeraMart - East Side",
        points = {{10800, 11100, 11099, 11399}}
    },
    UncleReds = {
        difficulty = 2,
        title = "Uncle Red's Bunker",
        mods = "UncleRedsBunkerRedux",
        points = {{10800, 10800, 11099, 11099}}
    },
    Papaville = {
        difficulty = 2,
        title = "Papaville",
        mods = "Papaville",
        points = {{10800, 8100, 11099, 8399}}
    },
    Petroville = {
        difficulty = 2,
        title = "Petroville",
        mods = "Petroville",
        points = {{10500, 11700, 11399, 12599}}
    },
    TheMuseum = {
        difficulty = 2,
        title = "The Museum",
        mods = "TheMuseumID",
        points = {{10500, 8100, 10799, 8399}}
    },
    Elysium = {
        difficulty = 2,
        title = "Elysium Island",
        mods = "Elysium_Island",
        points = {{10500, 6300, 10799, 6899}}
    },
    CorOTRroad = { -- respawn checked
        difficulty = 2,
        title = "BFE",
        mods = "CorOTRroad",
        points = {{10500, 6000, 10799, 6300}, {10800, 6000, 11099, 6300}}
    },
    Otr = {
        difficulty = 2,
        title = "Over the River",
        mods = "Otr",
        points = {{11100, 5700, 6500, 6500}},
        subzones = {
            Ship = {
                points = {{11100, 6300, 11400, 6500}},
                subtitle = "Ship"
            }
        }
    },
    militaryfueldepot = {
        difficulty = 2,
        title = "Military Fuel Depot",
        mods = "military fuel depot",
        points = {{10200, 12900, 10799, 13499}}
    },
    LandeDesolateCamping = {
        difficulty = 2,
        title = "Lande Desolate Camping",
        mods = "Lande Desolate Camping",
        points = {{10200, 10500, 10499, 10799}}
    },
    Springwood = {
        difficulty = 2,
        title = "Springwood",
        mods = "Springwood1",
        points = {{10200, 7800, 10499, 8399}}
    },
    Lalafell = {
        difficulty = 2,
        title = "Lalafell's Heart Lake Town",
        mods = "Lalafell's Heart Lake Town",
        points = {{9900, 10500, 10199, 10799}}
    },
    Chernaville = { -- respawn checked
        difficulty = 2,
        title = "Chernaville",
        mods = "Chernaville",
        points = {{9600, 10200, 9899, 10799}}
    },
    TWDprison = {
        difficulty = 2,
        title = "Prison",
        mods = "TWDprison",
        points = {{9600, 9300, 9899, 9599}}
    },
    Militaryairport = {
        difficulty = 2,
        title = "Military Airport",
        mods = "Militaryairport",
        points = {{9600, 7800, 10199, 8699}}
    },
    Hopefalls = {
        difficulty = 2,
        title = "Hopefalls",
        mods = "Hopefalls",
        points = {{9600, 6600, 9899, 6899}}
    },
    CONRTF = { -- respawn checked
        difficulty = 2,
        title = "C.O.N. Research & Testing Facility",
        mods = "CONRTF",
        points = {{9300, 12600, 9599, 12899}}
    },
    Speck = {
        difficulty = 2,
        title = "Speck",
        mods = "Speck_Map",
        points = {{9000, 12300, 9299, 12599}}
    },
    Pitstop = {
        difficulty = 2,
        title = "Pitstop",
        mods = "Pitstop",
        points = {{9000, 10500, 9300, 11700}, {9300, 11100, 10500, 11700}, {10500, 11400, 10800, 11700},
                  {13800, 1200, 14400, 1500}}
    },
    BetsysFarm = { -- respawn checked - failed
        difficulty = 2,
        title = "Betsy's Farm",
        mods = "DJBetsysFarm",
        points = {{9000, 9300, 9299, 9599}}
    },
    RabbitHash = {
        difficulty = 2,
        title = "Rabbit Hash",
        mods = "RabbitHashKY",
        points = {{9000, 7200, 9599, 7499}}
    },
    lakeivytownship = {
        difficulty = 2,
        title = "Lake Ivy",
        mods = "lakeivytownship",
        points = {{8700, 9600, 9599, 10499}}
    },
    ParkingLot = {
        difficulty = 2,
        title = "Parking Lot",
        mods = "ParkingLot",
        points = {{8700, 8700, 9299, 8999}}
    },
    EdsAuto = { -- respawn checked - failed
        difficulty = 2,
        title = "Ed's Auto Salvage",
        mods = "EdsAutoSalvage",
        points = {{8700, 8400, 8999, 8699}}
    },
    Homepie = {
        difficulty = 2,
        title = "Homepie",
        mods = "Myhometown",
        points = {{8700, 7800, 9299, 8399}}
    },
    firecamp = {
        difficulty = 2,
        title = "Firecamp",
        mods = "firecamp",
        points = {{8700, 7500, 8999, 7799}}
    },
    Orchidwood = {
        difficulty = 2,
        title = "Orchid",
        mods = "Orchidwood(official version)",
        points = {{8100, 9600, 8699, 10199}}
    },
    LittleTownship = {
        difficulty = 2,
        title = "Little Township",
        mods = "LittleTownship",
        points = {{8100, 8400, 8399, 8699}}
    },
    Greenport = {
        difficulty = 2,
        title = "Greenport",
        mods = "Greenport",
        points = {{8100, 7400, 8699, 7799}}
    },
    Blackwood = { -- respawn checked
        difficulty = 2,
        title = "Blackwood",
        mods = "Blackwood",
        points = {{7800, 10500, 8099, 10799}}
    },
    Eerie = {
        title = "Irvington",
        mods = "EerieCountry",
        points = {{11363, 17839, 11679, 18174}, {11998, 17136, 12245, 17390}, {11104, 15911, 11396, 16194},
                  {11442, 13807, 11930, 14335}, {11487, 14879, 11912, 15257}, {10266, 14733, 10590, 14972},
                  {7500, 13500, 12299, 18299}},
        difficulty = 3
    },
    HeavensHill = {
        difficulty = 2,
        title = "Heavens Hill",
        mods = "Heavens Hill",
        points = {{7500, 7800, 7799, 8099}}
    },
    Grapeseed = {
        difficulty = 2,
        title = "Grapeseed",
        mods = "Grapeseed",
        points = {{7200, 11100, 7499, 11399}}
    },
    Utopia = {
        difficulty = 2,
        title = "Utopia",
        mods = "Utopia",
        points = {{7200, 9600, 7499, 9899}}
    },
    NewEkron = {
        difficulty = 2,
        title = "New Ekron",
        mods = "NewEkron",
        points = {{6900, 8100, 7499, 8699}}
    },
    NettleTownship = {
        difficulty = 2,
        title = "Nettle Township",
        mods = "Nettle Township",
        oints = {{6600, 9000, 7199, 9599}}
    },
    FortRockRidge = {
        difficulty = 2,
        title = "Fort Rock Ridge",
        mods = "Fort Rock Ridge",
        points = {{6600, 6000, 7199, 6599}}
    },
    Greenleaf = {
        difficulty = 2,
        title = "Greenleaf",
        mods = "Greenleaf",
        points = {{6300, 10200, 6899, 10799}}
    },
    SimonMDSpencerMansionLootable = {
        difficulty = 2,
        title = "Spencer Mansion",
        mods = "SimonMDSpencerMansionLootable",
        points = {{6300, 5700, 6599, 5999}}
    },
    ResearchBase2 = {
        difficulty = 2,
        title = "Research Base",
        mods = "rbr",
        points = {{5400, 12300, 5999, 12899}, {6000, 12300, 7499, 12599}}

    },
    ResearchBase = {
        difficulty = 2,
        title = "Research Base",
        mods = "rbrA",
        points = {{6300, 10200, 6899, 10799}}
    },
    FORTREDSTONE = {
        difficulty = 2,
        title = "Fort Redstone",
        mods = "FORTREDSTONE",
        points = {{5400, 11100, 5999, 12299}}
    },
    BearLake = { -- respawn checked
        difficulty = 2,
        title = "Big Bear Lake",
        mods = "BBL",
        points = {{4800, 6900, 6899, 8099}}
    },
    CedarHill = {
        difficulty = 2,
        title = "Cedar Hill",
        mods = "CedarHill",
        points = {{4800, 5700, 5099, 5999}}
    },
    Chinatown = { -- respawn checked
        difficulty = 2,
        title = "Chinatown",
        mods = "Chinatown",
        points = {{11100, 8700, 11399, 9299}}
    },
    wilboreky = {
        difficulty = 2,
        title = "Wilbore",
        mods = "wilboreky",
        points = {{4500, 9900, 5099, 10799}}
    },
    Chestown = { -- respawn checked
        difficulty = 2,
        title = "Chestown",
        mods = "Chestown",
        points = {{4500, 6600, 4799, 6899}}
    },
    OverlookHotel = {
        difficulty = 2,
        title = "The Overlook",
        mods = "OverlookHotel",
        points = {{4500, 6300, 4799, 6599}}
    },
    FinneganMentalAsylum = {
        difficulty = 4,
        title = "Finnegan Research Center",
        mods = "FinneganMentalAsylum",
        points = {{3902, 9578, 3987, 9678}, {3900, 9300, 4499, 9899}}
    },
    SuperGigaMart = {
        difficulty = 2,
        title = "Super Giga Mart",
        mods = "SuperGigaMart",
        points = {{3600, 6300, 3899, 6599}}
    },
    RavenCreek = {
        difficulty = 3,
        title = "Raven Creek Village",
        mods = "RavenCreek",
        points = {{3909, 13036, 4492, 13496}, {3988, 13036, 4097, 12856}, {3046, 12157, 3544, 12809},
                  {4499, 11400, 4709, 11980}, {3000, 11100, 4194, 11400}, {3300, 11400, 4500, 12000},
                  {3587, 12000, 4339, 12590}},
        subzones = {

            InfectionControl = {
                points = {{4193, 11100, 4400, 11220}},
                difficulty = 4,
                subtitle = "Infection Control"
            },
            Expressway = {
                points = {{4400, 11100, 4714, 11220}},
                subtitle = "Expressway"
            },
            CityPort = {
                points = {{3100, 12175, 3553, 12800}},
                difficulty = 4,
                subtitle = "City Port"
            }
        }
    },
    NWBlockade = {
        difficulty = 2,
        title = "Northwest Blockade",
        mods = "NWBlockade",
        points = {{3000, 6000, 3299, 6299}}
    },
    Hilltop = {
        difficulty = 2,
        title = "Hilltop",
        mods = "Hilltop",
        points = {{3000, 5700, 3299, 5999}}
    },
    Winchester = {
        difficulty = 2,
        title = "Winchester",
        mods = "Winchester",
        points = {{2100, 6600, 4199, 8699}}
    },
    tikitown = {
        difficulty = 2,
        title = "Tikitown",
        mod = "tikitown",
        points = {{6889, 7188, 7386, 7741}, {7199, 6900, 7796, 7469}}
    },
    CanvasbackStudios = { -- respawn checked
        difficulty = 2,
        title = "Canvasback Studios",
        mods = "Canvasback Studios",
        points = {{9910, 10200, 10170, 10440}}
    },
    Purgatory = {
        difficulty = 2,
        title = "Purgatory",
        mods = "PurgatoryCity",
        points = {{2700, 8700, 3900, 9300}}
    },
    NaturesVengeance = {
        difficulty = 2,
        title = "Nature's Vengeance",
        mods = "nv_township_v1",
        points = {{6300, 7800, 6600, 8100}}
    },
    Millstin = {
        difficulty = 2,
        title = "Millstin",
        mods = "millstinwithwestpoint",
        points = {{11100, 7200, 11700, 8100}}
    },
    Lighthousematrioshka = {
        difficulty = 2,
        title = "Lighthouse",
        mods = "Lighthousematrioshka",
        points = {{10800, 6300, 11100, 6600}}
    },
    savecity = {
        difficulty = 2,
        title = "SaveCity",
        mods = "savecity",
        points = {{11700, 7500, 12000, 7800}}
    },
    SimonMDRRRR = {
        difficulty = 2,
        title = "Rusty Rascals",
        mods = "SimonMDRRRR",
        points = {{14100, 3300, 14400, 3600}}
    },
    TWDterminus = {
        difficulty = 2,
        title = "Terminus",
        mods = "TWDterminus",
        points = {{11400, 10500, 11700, 11100}}
    },
    TheRuinsofBracklewhyte = {
        difficulty = 2,
        title = "Bracklewhyte",
        mods = "TheRuinsofBracklewhyte",
        points = {{5100, 9000, 5400, 9300}}
    },
    the_oasis = {
        difficulty = 2,
        title = "Oasis",
        mods = "the_oasis",
        points = {{4800, 9300, 5400, 9900}}
    },
    Valley_Station_44 = {
        difficulty = 2,
        title = "Valley Station",
        mods = "Valley_Station_44-19",
        points = {{13200, 5700, 13500, 6000}}
    },
    Trapalaketown = {
        difficulty = 2,
        title = "Trapalaketown",
        mods = "Trapalaketown",
        points = {{8400, 11700, 9000, 12000}}
    },
    TheYacht = {
        difficulty = 2,
        title = "The Yacht",
        mods = "The Yacht",
        points = {{3600, 5400, 3900, 5700}}
    },
    Wellsburg = {
        difficulty = 2,
        title = "Wellsburg Lake",
        mods = "Wellsburg",
        points = {{7500, 10200, 7800, 10500}}
    },
    WalterWhiteHouse = {
        difficulty = 2,
        title = "Walter White House",
        mods = "Walter White House",
        points = {{10800, 6900, 11100, 7200}}
    },
    WhiteForestCamp = {
        difficulty = 2,
        title = "White Forest Camp",
        mods = "White Forest Camp",
        points = {{10200, 8400, 10500, 8700}}
    },
    WeyhausenByCallnmx = {
        difficulty = 2,
        title = "Weyhausen",
        mods = "WeyhausenByCallnmx",
        points = {{5100, 9300, 5400, 9600}}
    },
    WesternScrapCarYard = {
        difficulty = 2,
        title = "Western Scrapyard",
        mods = "WesternScrapCarYard",
        points = {{8700, 9000, 9000, 9300}}
    },
    MilitaryCheckpointWestPointAbisi = {
        difficulty = 3,
        title = "Military Checkpoint",
        mods = "MilitaryCheckpointWestPointAbisi",
        points = {{11400, 7500, 11700, 7800}}
    },
    Ztardew = {
        difficulty = 2,
        title = "Ztardew Valley",
        mods = "Ztardew",
        points = {{12000, 9300, 12900, 1020}}
    },
    ZonaSegura0123 = {
        cells = {{39, 30}},
        difficulty = 2,
        title = "Zona Segura",
        mods = "ZonaSegura0123",
        points = {{11700, 9000, 12000, 9300}}
    },
    QuarryLake_Xavior = {
        difficulty = 2,
        title = "Quarry Lake",
        mods = "QuarryLake_Xavior",
        points = {{12000, 11400, 12600, 12000}}
    },
    EventureIsland = {
        difficulty = 2,
        title = "Eventure Island",
        mods = "EventureIsland",
        points = {{1445, 3884, 2638, 4992}}
    },
    NightFallky = {
        difficulty = 2,
        title = "NightFall",
        mods = "NightFallky",
        points = {{10200, 10200, 10500, 10500}}
    },
    SunsetLake = {
        difficulty = 2,
        title = "Sunset Lake",
        mods = "114519",
        points = {{6600, 11100, 7200, 12000}}
    },
    TravelierInn = {
        difficulty = 2,
        title = "Travelier Motor Inn",
        mods = "traveliermotorinnmotel",
        points = {{6115, 5794, 6194, 5846}}
    },
    NewAlbany = {
        difficulty = 2,
        title = "New Albany",
        mods = "NewAlbany",
        points = {{11700, 0, 15000, 900}}
    },
    ConstowmWithRCandFR = { -- respawn checked - failed
        difficulty = 3,
        title = "Constown",
        mods = "constownwithRCandFR",
        points = {{5100, 10800, 6300, 11400}}
    },
    NewEllroy = {
        difficulty = 3,
        title = "Ellroy",
        mods = "NewEllroy",
        points = {{5100, 9900, 5700, 10500}}
    },
    ErikasFurnitureStore = {
        cells = {{38, 27}},
        difficulty = 3,
        title = "Erikas",
        mods = "Erikas_Furniture_Store",
        points = {{11486, 8229, 11584, 8322}}
    },
    BitterrootRanch = { -- respawn checked - failed
        cells = {{35, 24}, {35, 25}},
        difficulty = 3,
        title = "Bitterroot",
        mods = "Bitterroot Ranch",
        points = {{10607, 7555, 10768, 7637}}
    },
    NuclearReactor = {
        difficulty = 4,
        title = "Reactor",
        mods = "NUCExperimentalReactor;PhunRadNUC;",
        points = {{8390, 12273, 8872, 12750}},
        subzones = {
            approach = {
                points = {{8400, 12300, 8772, 12650}}
            },
            grounds = {
                points = {{8490, 12373, 8672, 12550}}
            },
            core = {
                points = {{8537, 12421, 8617, 12475}}
            }
        }
    },
    DenseWoods = { -- respawn checked - failed
        difficulty = 3,
        title = "Woods",
        mods = "AbandonedSurvivorBase",
        points = {{14400, 5100, 14700, 5400}}
    },
    Hartburg = {
        difficulty = 3,
        title = "Hartburg",
        mods = "hartburg",
        points = {{6600, 11100, 6897, 11696}}
    },
    hospital = {
        difficulty = 0,
        zeds = false,
        bandits = false,
        title = "Unknown",
        mods = "respawn-hospital-rooms2",
        points = {{30000, 30000, 30300, 32300}}
    },
    shortrest = {
        difficulty = 2,
        title = "Shortrest",
        mods = "Shortrest_City",
        points = {{13200, 6600, 14700, 7500}}
    },
    jackson = {
        difficulty = 1,
        title = "Shortrest",
        mods = "jackson",
        points = {{10810, 10555, 11377, 10945}}
    }
}
