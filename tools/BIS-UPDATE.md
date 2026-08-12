# Oak Bonus Planner BIS update contract

When the request is “update the BIS lists,” run:

    pwsh -File .\tools\Update-BISLists.ps1

The helper refreshes all 40 supported specs from current Icy Veins gear and
stat pages plus Wowhead overall BIS, then writes `Data/BIS.lua` and the
matching Season 2 dungeon, raid, token, and item-pool files. It records the
patch, season, source URLs, and update date in the generated files.

The loot updater is also available by itself:

    pwsh -File .\tools\Update-S2LootData.ps1

It fetches the eight Season 2 Mythic+ dungeons and the Venomous Abyss boss
tables from Wowhead. Catalyst behavior is Season 2-specific in the calculation
engine: only the specific recommended catalyzed items are tracked, and a won
piece does not consume every item in that armor slot. Manual BIS overrides and
bonus-roll history remain saved-player data and are not overwritten.
