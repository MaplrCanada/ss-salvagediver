Config = {}

-- General settings
Config.Debug = false -- Enable/disable debug prints
Config.UseTarget = true -- Use qb-target instead of proximity prompts

-- Job settings
Config.JobName = "salvage"
Config.RequiredItems = {
    tank = "diving_gear", -- Diving equipment item name
    basic_tools = "basic_salvage_tools" -- Basic tools item name
}

-- Locations
Config.JobCenter = {
    coords = vector4(-1612.89, -1027.46, 13.15, 231.5), -- Santa Monica Pier area
    blip = {
        sprite = 356, -- Diving blip
        color = 3,
        scale = 0.7,
        label = "Salvage Diving Operations"
    },
    ped = {
        model = "a_m_y_beach_01", -- Beach themed ped
        scenario = "WORLD_HUMAN_CLIPBOARD"
    }
}

-- Salvage Areas (Legal Contracts)
Config.SalvageAreas = {
    {
        name = "Shipwreck Cove",
        coords = vector3(-2838.5, -376.19, -40.29),
        radius = 30.0,
        rewards = {
            {item = "old_boot", label = "Old Boot", chance = 70, payment = 10},
            {item = "rusty_anchor", label = "Rusty Anchor", chance = 50, payment = 50},
            {item = "ship_part", label = "Ship Part", chance = 40, payment = 75},
            {item = "antique_compass", label = "Antique Compass", chance = 20, payment = 150},
        },
        blip = {
            sprite = 597,
            color = 47,
            scale = 0.7,
            label = "Salvage Area: Shipwreck Cove"
        }
    },
    {
        name = "Cargo Wreck",
        coords = vector3(-3158.67, 3654.88, -37.21),
        radius = 40.0,
        rewards = {
            {item = "metal_scrap", label = "Metal Scrap", chance = 80, payment = 25},
            {item = "cargo_container", label = "Cargo Container", chance = 60, payment = 65},
            {item = "electronic_parts", label = "Electronic Parts", chance = 30, payment = 120},
            {item = "rare_cargo", label = "Rare Cargo", chance = 15, payment = 200},
        },
        blip = {
            sprite = 597,
            color = 47,
            scale = 0.7,
            label = "Salvage Area: Cargo Wreck"
        }
    }
}

-- Hidden Treasures (Illegal/valuable items)
Config.HiddenAreas = {
    {
        name = "Smuggler's Cache",
        coords = vector3(-3024.37, 1603.85, -39.75),
        radius = 15.0,
        rewards = {
            {item = "gold_coin", label = "Gold Coin", chance = 40, payment = 250},
            {item = "jewelry", label = "Jewelry", chance = 30, payment = 350},
            {item = "art_piece", label = "Art Piece", chance = 20, payment = 500},
            {item = "briefcase", label = "Mysterious Briefcase", chance = 10, payment = 1000},
        }
    },
    {
        name = "Sunken Yacht",
        coords = vector3(-2100.21, -1001.42, -45.89),
        radius = 25.0,
        rewards = {
            {item = "luxury_watch", label = "Luxury Watch", chance = 35, payment = 400},
            {item = "gold_bar", label = "Gold Bar", chance = 25, payment = 600},
            {item = "crypto_ledger", label = "Crypto Ledger", chance = 15, payment = 800},
            {item = "rare_gem", label = "Rare Gem", chance = 5, payment = 1500},
        }
    }
}

-- Reward system
Config.RewardSystem = {
    base_xp = 10, -- Base XP earned per salvage
    bonus_xp_multiplier = 1.5, -- Multiplier for finding rare items
    skill_levels = {
        [1] = {required_xp = 0, label = "Novice Diver"},
        [2] = {required_xp = 1000, label = "Amateur Salvager"},
        [3] = {required_xp = 3000, label = "Professional Diver"},
        [4] = {required_xp = 7000, label = "Expert Salvager"},
        [5] = {required_xp = 15000, label = "Master Treasure Hunter"}
    },
    -- Bonuses based on skill level (multipliers)
    skill_bonuses = {
        [1] = 1.0, -- Base rate
        [2] = 1.1, -- 10% bonus
        [3] = 1.25, -- 25% bonus
        [4] = 1.4, -- 40% bonus
        [5] = 1.6 -- 60% bonus
    }
}

-- UI Configuration
Config.UI = {
    show_oxygen = true,
    show_depth = true,
    show_compass = true,
    oxygen_warning_level = 25, -- Percentage when oxygen warning appears
    max_salvage_depth = 50 -- Maximum depth for salvaging (meters)
}

-- Salvage minigame settings
Config.Minigame = {
    difficulty = {
        [1] = {time = 15, grid_size = 5}, -- Novice
        [2] = {time = 12, grid_size = 5}, -- Amateur
        [3] = {time = 10, grid_size = 6}, -- Professional
        [4] = {time = 8, grid_size = 6}, -- Expert
        [5] = {time = 7, grid_size = 7} -- Master
    }
}

-- Item definitions (for reference, actual items should be in QBCore shared items)
Config.Items = {
    diving_gear = {
        name = "diving_gear",
        label = "Diving Gear",
        weight = 15000,
        type = "item",
        image = "diving_gear.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
        description = "Equipment for underwater diving"
    },
    basic_salvage_tools = {
        name = "basic_salvage_tools",
        label = "Basic Salvage Tools",
        weight = 7500,
        type = "item",
        image = "salvage_tools.png",
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
        description = "Basic tools for underwater salvage operations"
    }
}

-- Salvage durations
Config.SalvageDuration = {
    min = 5, -- Minimum time in seconds
    max = 15 -- Maximum time in seconds
}

-- Notification text
Config.Text = {
    job_start = "You've started working as a salvage diver. Head to a salvage area to begin.",
    job_end = "You've clocked out from salvage diving.",
    no_equipment = "You need proper diving gear to work as a salvage diver!",
    contract_accepted = "Salvage contract accepted. Navigate to the marked area on your GPS.",
    contract_completed = "Contract completed! Return to base for your payment.",
    item_found = "You found: %s",
    too_deep = "WARNING: You're approaching dangerous depths!",
    oxygen_low = "WARNING: Oxygen levels critically low!"
}