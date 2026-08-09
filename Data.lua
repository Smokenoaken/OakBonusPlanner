local addonName, addonTable = ...

addonTable.Data = {
    seasonID = "midnight-season-1",
    seasonLabel = "Midnight Season 1",
    dataVersion = "2026-08-09.1",
    sourceLabel = "Icy Veins seed",
    sourceURL = "https://www.icy-veins.com/wow/beast-mastery-hunter-pve-dps-gear-best-in-slot",
    wowheadURL = "https://www.wowhead.com/guide/classes/hunter/beast-mastery/bis-gear",
}

-- The selector knows every retail class/spec. This first seed intentionally has
-- a curated BM Hunter plan; additional specs can be added without changing UI
-- or tracking code.
addonTable.Data.Specs = {
    [1] = { name = "Warrior", specs = { [71] = "Arms", [72] = "Fury", [73] = "Protection" } },
    [2] = { name = "Paladin", specs = { [65] = "Holy", [66] = "Protection", [70] = "Retribution" } },
    [3] = { name = "Hunter", specs = { [253] = "Beast Mastery", [254] = "Marksmanship", [255] = "Survival" } },
    [4] = { name = "Rogue", specs = { [259] = "Assassination", [260] = "Outlaw", [261] = "Subtlety" } },
    [5] = { name = "Priest", specs = { [256] = "Discipline", [257] = "Holy", [258] = "Shadow" } },
    [6] = { name = "Death Knight", specs = { [250] = "Blood", [251] = "Frost", [252] = "Unholy" } },
    [7] = { name = "Shaman", specs = { [262] = "Elemental", [263] = "Enhancement", [264] = "Restoration" } },
    [8] = { name = "Mage", specs = { [62] = "Arcane", [63] = "Fire", [64] = "Frost" } },
    [9] = { name = "Warlock", specs = { [265] = "Affliction", [266] = "Demonology", [267] = "Destruction" } },
    [10] = { name = "Monk", specs = { [268] = "Brewmaster", [269] = "Windwalker", [270] = "Mistweaver" } },
    [11] = { name = "Druid", specs = { [102] = "Balance", [103] = "Feral", [104] = "Guardian", [105] = "Restoration" } },
    [12] = { name = "Demon Hunter", specs = { [577] = "Havoc", [581] = "Vengeance", [1480] = "Devourer" } },
    [13] = { name = "Evoker", specs = { [1467] = "Devastation", [1468] = "Preservation", [1473] = "Augmentation" } },
}

addonTable.Data.Sources = {
    { id = "maisara", name = "Maisara Caverns", kind = "Dungeon", challengeModeID = 560, weight = 3.0 },
    { id = "seat", name = "Seat of the Triumvirate", kind = "Dungeon", challengeModeID = 239, weight = 3.0 },
    { id = "pit", name = "Pit of Saron", kind = "Dungeon", challengeModeID = 556, weight = 3.0 },
    { id = "nexus", name = "Nexus-Point Xenas", kind = "Dungeon", challengeModeID = 559, weight = 3.0 },
    { id = "algethar", name = "Algeth'ar Academy", kind = "Dungeon", challengeModeID = 402, weight = 4.0 },
    { id = "chimaerus", name = "Chimaerus", kind = "Raid boss", bossID = 2795, weight = 4.0 },
    { id = "vaelgor", name = "Vaelgor and Ezzorak", kind = "Raid boss", bossID = 2735, weight = 2.0 },
    { id = "midnightfalls", name = "L'ura, Midnight Falls", kind = "Raid boss", bossID = 2740, weight = 3.0 },
    { id = "rotmire", name = "Rotmire", kind = "World boss", bossID = 2711, weight = 2.0 },
}

addonTable.Data.Plans = {
    [253] = {
        label = "Beast Mastery Hunter",
        notes = "Season 1 seed. Score is target coverage, not a published drop percentage.",
        sources = {
            maisara = { targets = { { slot = "Weapon", slotIDs = { 13, 15, 16 }, label = "Best M+ weapon" } } },
            seat = { targets = { { slot = "Shoulder", slotIDs = { 3 }, itemName = "Pauldrons of the Void Hunter" } } },
            pit = { targets = { { slot = "Neck", slotIDs = { 2 }, itemName = "Barbed Ymirheim Choker" } } },
            nexus = { targets = {
                { slot = "Ring", slotIDs = { 11 }, itemName = "Occlusion of Void" },
                { slot = "Ring", slotIDs = { 11 }, itemName = "Omission of Light" },
            } },
            algethar = { targets = { { slot = "Trinket", slotIDs = { 12 }, itemName = "Algeth'ar Puzzle Box" } } },
            chimaerus = { targets = {
                { slot = "Chest", slotIDs = { 5 }, itemName = "Primal Sentry's Scaleplate" },
                { slot = "Trinket", slotIDs = { 12 }, label = "Best raid trinket" },
            } },
            vaelgor = { targets = { { slot = "Shoulder", slotIDs = { 3 }, itemName = "Nullwalker's Dread Epaulettes" } } },
            midnightfalls = { targets = { { slot = "Ring", slotIDs = { 11 }, itemName = "Eye of Midnight" } } },
            rotmire = { targets = {
                { slot = "Neck", slotIDs = { 2 }, itemName = "Rotmire's Sporeheart" },
                { slot = "Ring", slotIDs = { 11 }, itemName = "Sporecaller's Blooming Loop" },
            } },
        },
    },
}
