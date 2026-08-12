local addonName, addonTable = ...

addonTable.Data = {
    seasonID = "midnight-season-2",
    seasonLabel = "Midnight Season 2",
    dataVersion = "2026-08-12.12.1-s2-keystoneloot-db",
    sourceLabel = "Icy Veins + Wowhead Season 2 data",
    sourceURL = "https://www.icy-veins.com/wow/beast-mastery-hunter-pve-dps-gear-best-in-slot",
    wowheadURL = "https://www.wowhead.com/guide/classes/hunter/beast-mastery/bis-gear",
    itemLevels = {
        myth = 344,
        crafted = 340,
        voidforged = 353,
    },
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

-- Season 2 defaults from the bundled crafted-gear guidance. Generated BIS
-- data may provide a more specific value on a spec or individual item later.
addonTable.Data.CraftedEmbellishments = {
    [71] = "Darkmoon Sigil: Hunt + Arcanoweave Lining",
    [72] = "Darkmoon Sigil: Hunt + Arcanoweave Lining",
    [73] = "Darkmoon Sigil: Hunt + Arcanoweave Lining",
    [65] = "Darkmoon Sigil: Hunt + Arcanoweave Lining",
    [66] = "Darkmoon Sigil: Hunt + Arcanoweave Lining",
    [70] = "Darkmoon Sigil: Hunt + Arcanoweave Lining",
    [253] = "Root Warden's Regalia + Arcanoweave Lining",
    [254] = "Root Warden's Regalia + Arcanoweave Lining",
    [255] = "Darkmoon Sigil: Hunt + Arcanoweave Lining",
    [259] = "Darkmoon Sigil: Hunt + Arcanoweave Lining",
    [260] = "Darkmoon Sigil: Void + Arcanoweave Lining + Prismatic Focusing Iris",
    [261] = "Darkmoon Sigil: Hunt + Arcanoweave Lining",
    [256] = "Darkmoon Sigil: Hunt + Arcanoweave Cord + Arcanoweave Lining",
    [257] = "Darkmoon Sigil: Hunt + Arcanoweave Cord + Arcanoweave Lining",
    [258] = "Darkmoon Sigil: Hunt + Arcanoweave Cord + Arcanoweave Lining",
    [250] = "Darkmoon Sigil: Hunt + Arcanoweave Lining",
    [251] = "Darkmoon Sigil: Hunt + Arcanoweave Lining",
    [252] = "Darkmoon Sigil: Hunt + Arcanoweave Lining",
    [262] = "Darkmoon Sigil: Hunt + Root Warden's Regalia",
    [263] = "Darkmoon Sigil: Hunt + Arcanoweave Lining",
    [264] = "Darkmoon Sigil: Hunt + Arcanoweave Lining",
    [62] = "Darkmoon Sigil: Blood",
    [63] = "Darkmoon Sigil: Hunt + Arcanoweave Lining",
    [64] = "Darkmoon Sigil: Hunt + Arcanoweave Lining",
    [265] = "Darkmoon Sigil: Hunt + Arcanoweave Lining",
    [266] = "Darkmoon Sigil: Hunt + Arcanoweave Lining",
    [267] = "Darkmoon Sigil: Hunt + Arcanoweave Lining",
    [268] = "Darkmoon Sigil: Void + Loa Worshiper's Band",
    [269] = "Darkmoon Sigil: Hunt + Loa Worshiper's Band",
    [270] = "Darkmoon Sigil: Void + Arcanoweave Lining",
    [102] = "Darkmoon Sigil: Hunt + Arcanoweave Lining",
    [103] = "Darkmoon Sigil: Hunt + Arcanoweave Lining",
    [104] = "Darkmoon Sigil: Hunt + Arcanoweave Lining",
    [105] = "Darkmoon Sigil: Hunt + Arcanoweave Lining",
    [577] = "Darkmoon Sigil: Hunt + Arcanoweave Lining",
    [581] = "Darkmoon Sigil: Hunt + Loa Worshiper's Band",
    [1480] = "Darkmoon Sigil: Hunt + Arcanoweave Lining",
    [1467] = "Darkmoon Sigil: Hunt + Arcanoweave Lining",
    [1468] = "Darkmoon Sigil: Hunt + Root Warden's Regalia + Arcanoweave Lining",
    [1473] = "Darkmoon Sigil: Hunt + Arcanoweave Lining",
}

-- Max-rank crafted links need the crafted-quality/stat/embellishment bonuses;
-- the recipe item IDs themselves intentionally resolve to a low base level.
-- These are the recommended Demonology Warlock bracer/cloak bonuses for S2.
addonTable.Data.CraftedBonusIDs = {
    [266] = { 12214, 12497, 12066, 8960, 12384, 8793, 13622, 13667, 12667 },
}

-- Season 2 raid token drops. The class group determines which shared-armor
-- token is eligible for the selected loot spec. Tier curios are not Voidcore
-- bonus-roll rewards and are deliberately omitted.
addonTable.Data.RaidTierTokens = {
    [2874] = { -- Entombed Sentinels
        { itemID = 270910, slotID = 7, slotLabel = "Hands token", classIDs = { 5, 8, 9 } },
        { itemID = 270911, slotID = 7, slotLabel = "Hands token", classIDs = { 4, 10, 11, 12 } },
        { itemID = 270912, slotID = 7, slotLabel = "Hands token", classIDs = { 3, 7, 13 } },
        { itemID = 270913, slotID = 7, slotLabel = "Hands token", classIDs = { 1, 2, 6 } },
    },
    [2894] = { -- The Lost Explorers
        { itemID = 270922, slotID = 2, slotLabel = "Shoulder token", classIDs = { 5, 8, 9 } },
        { itemID = 270923, slotID = 2, slotLabel = "Shoulder token", classIDs = { 4, 10, 11, 12 } },
        { itemID = 270924, slotID = 2, slotLabel = "Shoulder token", classIDs = { 3, 7, 13 } },
        { itemID = 270925, slotID = 2, slotLabel = "Shoulder token", classIDs = { 1, 2, 6 } },
    },
    [2882] = { -- Vashnik the Malignant
        { itemID = 270926, slotID = 4, slotLabel = "Chest token", classIDs = { 5, 8, 9 } },
        { itemID = 270927, slotID = 4, slotLabel = "Chest token", classIDs = { 4, 10, 11, 12 } },
        { itemID = 270928, slotID = 4, slotLabel = "Chest token", classIDs = { 3, 7, 13 } },
        { itemID = 270929, slotID = 4, slotLabel = "Chest token", classIDs = { 1, 2, 6 } },
    },
    [2871] = { -- Sszorak
        { itemID = 270918, slotID = 8, slotLabel = "Legs token", classIDs = { 5, 8, 9 } },
        { itemID = 270919, slotID = 8, slotLabel = "Legs token", classIDs = { 4, 10, 11, 12 } },
        { itemID = 270920, slotID = 8, slotLabel = "Legs token", classIDs = { 3, 7, 13 } },
        { itemID = 270921, slotID = 8, slotLabel = "Legs token", classIDs = { 1, 2, 6 } },
    },
    [2887] = { -- The Twin Fangs
        { itemID = 270914, slotID = 0, slotLabel = "Helm token", classIDs = { 5, 8, 9 } },
        { itemID = 270915, slotID = 0, slotLabel = "Helm token", classIDs = { 4, 10, 11, 12 } },
        { itemID = 270916, slotID = 0, slotLabel = "Helm token", classIDs = { 3, 7, 13 } },
        { itemID = 270917, slotID = 0, slotLabel = "Helm token", classIDs = { 1, 2, 6 } },
    },
}

-- These may appear in Encounter Journal boss loot, but Voidcores cannot award
-- them. Keep this explicit so they never enter a finite bonus-roll pool.
addonTable.Data.BonusRollExcludedItems = {
    [270909] = true, -- Slumbering Coil Curio (Ula'tek)
}

-- Current Season 2 Nebulous Voidcore currency. The planner reads it only
-- while refreshing its visible UI; it does not poll bags or the currency tab.
addonTable.Data.BonusRollCurrencyID = 3513

-- Blizzard's source-specific Voidcache tooltips retain the list of items that
-- can still be won. On first open, OBP compares that list with this bundled
-- class/spec database to recover rolls made before the addon was installed.
addonTable.Data.BonusRollChests = {
    { itemID = 279618, challengeModeID = 588 }, -- Altar of Fangs
    { itemID = 279623, challengeModeID = 587 }, -- Murder Row
    { itemID = 279620, challengeModeID = 586 }, -- Den of Nalorakk
    { itemID = 279619, challengeModeID = 584 }, -- The Blinding Vale
    { itemID = 279625, challengeModeID = 585 }, -- Voidscar Arena
    { itemID = 279621, challengeModeID = 249 }, -- King's Rest
    { itemID = 279624, challengeModeID = 250 }, -- Temple of Sethraliss
    { itemID = 279622, challengeModeID = 399 }, -- Ruby Life Pools
    { itemID = 274708, bossID = 2849 }, -- Nymrissa Tidecaller
    { itemID = 278285, bossID = 2888 }, -- Nek'zali the Soulcoiler
    { itemID = 278283, bossID = 2874 }, -- Entombed Sentinels
    { itemID = 278286, bossID = 2894 }, -- The Lost Explorers
    { itemID = 278287, bossID = 2882 }, -- Vashnik the Malignant
    { itemID = 278288, bossID = 2871 }, -- Sszorak
    { itemID = 278289, bossID = 2887 }, -- The Twin Fangs
    { itemID = 278290, bossID = 2883 }, -- The Coiled Altar
    { itemID = 278284, bossID = 2895 }, -- Ula'tek
}

addonTable.Data.Sources = {
    { id = "altar", name = "Altar of Fangs", kind = "Dungeon", challengeModeID = 588, weight = 3.0 },
    { id = "murder", name = "Murder Row", kind = "Dungeon", challengeModeID = 587, weight = 3.0 },
    { id = "den", name = "Den of Nalorakk", kind = "Dungeon", challengeModeID = 586, weight = 3.0 },
    { id = "blinding", name = "The Blinding Vale", kind = "Dungeon", challengeModeID = 584, weight = 3.0, aliases = { "The Blinding Vale", "Blinding Vale" } },
    { id = "voidscar", name = "Voidscar Arena", kind = "Dungeon", challengeModeID = 585, weight = 3.0 },
    { id = "kingsrest", name = "King's Rest", kind = "Dungeon", challengeModeID = 249, weight = 3.0, aliases = { "King's Rest", "Kings' Rest" } },
    { id = "temple", name = "Temple of Sethraliss", kind = "Dungeon", challengeModeID = 250, weight = 3.0 },
    { id = "ruby", name = "Ruby Life Pools", kind = "Dungeon", challengeModeID = 399, weight = 3.0 },
    { id = "nymrissa", name = "Nymrissa Tidecaller", kind = "Raid boss", bossID = 2849, weight = 2.0, aliases = { "Nymrissa Tidecaller", "Nymrissa" }, raidJournalInstanceID = 1317 },
    { id = "nekzali", name = "Nek'zali the Soulcoiler", kind = "Raid boss", bossID = 2888, weight = 2.0, aliases = { "Nek'zali the Soulcoiler", "Nek'zali" } },
    { id = "sentinels", name = "Entombed Sentinels", kind = "Raid boss", bossID = 2874, weight = 2.0 },
    { id = "explorers", name = "The Lost Explorers", kind = "Raid boss", bossID = 2894, weight = 2.0, aliases = { "The Lost Explorers", "Lost Explorers" } },
    { id = "vashnik", name = "Vashnik the Malignant", kind = "Raid boss", bossID = 2882, weight = 2.0, aliases = { "Vashnik the Malignant", "Vashnik" } },
    { id = "sszorak", name = "Sszorak", kind = "Raid boss", bossID = 2871, weight = 2.0 },
    { id = "twinfangs", name = "The Twin Fangs", kind = "Raid boss", bossID = 2887, weight = 2.0, aliases = { "The Twin Fangs", "Twin Fangs" } },
    { id = "coiledaltar", name = "The Coiled Altar", kind = "Raid boss", bossID = 2883, weight = 2.0, aliases = { "The Coiled Altar", "Coiled Altar" } },
    { id = "ulatek", name = "Ula'tek", kind = "Raid boss", bossID = 2895, weight = 4.0 },
}

addonTable.Data.Plans = {
    [253] = {
        label = "Beast Mastery Hunter",
        notes = "Season 2 seed. Score is finite-pool BIS coverage, not a live drop-rate estimate.",
        sources = {},
    },
}
