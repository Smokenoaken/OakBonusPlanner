local addonName, addonTable = ...

addonTable.Data = {
    seasonID = "midnight-season-2",
    seasonLabel = "Midnight Season 2",
    dataVersion = "2026-08-15.12.1-s2-eligibility-fixes",
    sourceLabel = "Icy Veins + Wowhead Season 2 data",
    sourceURL = "https://www.icy-veins.com/wow/beast-mastery-hunter-pve-dps-gear-best-in-slot",
    wowheadURL = "https://www.wowhead.com/guide/classes/hunter/beast-mastery/bis-gear",
    itemLevels = {
        myth = 334,
        crafted = 331,
        voidforged = 353,
    },
    -- Midnight Season 2's rank-six Myth track and max-quality crafted
    -- modifiers. These are link modifiers, not display-only labels.
    itemLinkBonuses = {
        mythTrack = 12854,
        craftedQuality = 12497,
        craftedSeason = 13751,
        craftedMaximum = 13836,
        epic = 1674,
        ringNeck = 13534,
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

-- Profession recipe items intentionally resolve to a low base level. Crafted
-- links use Blizzard's current client item level with a 331 target instead of
-- stale static modifiers, which previously forced obsolete 285 tooltips.

-- The initial generator combined several independent guide parsers. These
-- are the reviewed Season 2 choices for the small set of duplicate tier-slot
-- candidates that combination produced. Keep one catalyst target per slot;
-- future generator runs preserve the first explicit guide target by default.
addonTable.Data.CatalystTargetPriority = {
    [71] = { overall = { [4] = 268222, [8] = 271878 } },
    [72] = { overall = { [4] = 268222, [8] = 271878 }, raids = { [0] = 268229 } },
    [65] = { dungeons = { [8] = 273776 } },
    [104] = { overall = { [0] = 271875 } },
    [257] = { dungeons = { [4] = 239032 } },
    [1468] = { dungeons = { [0] = 193765 } },
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
    [275937] = true, -- Hex Lord's Visage: cosmetic transmog appearance, not a Voidcore reward.
    [275938] = true, -- Alternate Hex Lord's Visage appearance, also cosmetic only.
    [281227] = true, -- Soulcoiler's Rush'kah: cosmetic appearance, not a Voidcore reward.
}

-- The upstream generated table is a useful season baseline, but Blizzard's
-- live Adventure Guide is authoritative for spec eligibility. Keep verified
-- additions here instead of editing generated data, so a future import cannot
-- silently discard a correction. Zul'jin's Guillotine Technique is listed for
-- Guardian in Blizzard's Coiled Altar loot list as well as Feral.
addonTable.Data.LootEligibilityAdditions = {
    [270173] = { [11] = { 104 } }, -- Zul'jin's Guillotine Technique: Guardian
}

-- Current Season 2 Nebulous Voidcore currency. The planner reads it only
-- while refreshing its visible UI; it does not poll bags or the currency tab.
-- 3513 is a different currency that can have a valid, unrelated quantity.
addonTable.Data.BonusRollCurrencyID = 3418

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
