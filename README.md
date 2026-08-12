# Oak Bonus Planner

Oak Bonus Planner is a small, data-driven World of Warcraft addon for deciding where to spend bonus rolls based on the remaining Best in Slot targets for the selected class/spec.

## Season 2 quick test

The bundled Midnight Season 2 data covers all 40 retail specializations. It includes Icy Veins Overall/Raid/Mythic+ lists, Wowhead Overall lists where available, the Season 2 eight-dungeon rotation, Venomous Abyss loot and tier tokens, crafted recommendations, and stat priorities. Oak Bonus Planner is fully standalone and has no KeystoneLoot dependency.

Open the window with /obp, /oakbonus, or /bonusplanner. The class and spec buttons cycle through Blizzard's class/spec IDs. The planner recommends the loot spec with the highest remaining BIS coverage, then calculates each source as remaining wanted BIS items divided by remaining bonus-roll-eligible loot-pool items. On Season 2 day one, every character starts with an empty local roll ledger so the full loot plan is visible before the first bonus roll. Each future BONUS_ROLL_RESULT item is recorded only in Oak's own per-character SavedVariables and removed from that character's relevant finite pool. Season history is isolated, so a new season never inherits prior-season roll results.

Oak ships a generated Season 2 eligibility database based on the same per-item class/spec mapping used by KeystoneLoot. It is used immediately on first launch; users do not need KeystoneLoot installed and do not need to open the Adventure Guide or run a scan command. The bundled database is replaced with the next addon data release when Blizzard changes the season or patch.

When the planner is opened for the first time on a character, it makes a one-time, throttled comparison of Blizzard's 17 current Season 2 Voidcache tooltips against the bundled loot database. This recovers rolls made before OBP was installed for the character's current loot specialization. New rewards are tracked directly from `BONUS_ROLL_RESULT`. The scan cancels when the planner closes; use `/obp rescan` only when you want to repeat the recovery check.

This is a finite without-replacement pool percentage, not a live boss drop rate. It estimates the chance that the next bonus roll is a wanted remaining BIS item versus an unwanted remaining item in the selected loot spec's eligible pool.

The Oak Plan minimap button opens the planner with a left click and its options panel with a right click. The button can also be hidden from the in-addon Options panel or with `/obp options`. The compact planner uses a classic class/spec cascade, Dungeons, Raids, and Overall tabs, and sort controls for highest BIS chance, dungeon name, or total drops. Each source displays its eligible loot table with a gold star for BIS targets, a gold main-tank shield for Season 2 catalyst/tier targets, a red cross for unwanted loot, and desaturated icons for items already won. The footer shows the current character's available Nebulous Voidcores. Raid and Overall views include class-eligible Venomous Abyss tier tokens as actual pool items: Entombed Sentinels hands, Lost Explorers shoulders, Vashnik chest, Sszorak legs, and Twin Fangs helm. Curios are shown in the bundled data but excluded from the bonus-roll pool because Voidcores cannot award them. Crafted BIS slots and recommended stat priorities appear beside the tabs. Item tooltips resolve to max-track links: Mythic max for drops and catalyst/tier gear, and max crafted rank for crafted recommendations. The window can be resized from its lower-right corner and the item grid reflows with the available width. Right-click any item to set or remove it as a personal BIS override; the percentage and recommended loot spec update immediately.

## Weekly data releases

WoW addons cannot make arbitrary HTTPS requests to Wowhead or Icy Veins in-game. Weekly addon releases are therefore the right update boundary. From the repository root, run `powershell -ExecutionPolicy Bypass -File tools/Update-BISLists.ps1` to refresh `Data/BIS.lua`, the Season 2 BIS tables, review the data, bump the addon version, and ship the new addon package. For loot eligibility, `tools/Update-S2LootData.ps1` now imports KeystoneLoot's generated `data/items.lua`, `data/dungeons.lua`, and `data/raids.lua` when that addon is installed, preserving its per-spec eligibility database in Oak's own namespace. Run `tools/Import-KeystoneLootData.ps1` directly when only the local KeystoneLoot database needs refreshing. The Wowhead parser remains only as a fallback when the KeystoneLoot generated files are unavailable.

The initial references were:

- https://www.icy-veins.com/wow/beast-mastery-hunter-pve-dps-gear-best-in-slot
- https://www.wowhead.com/guide/classes/hunter/beast-mastery/bis-gear
- https://docs.google.com/spreadsheets/d/1PCG3WD8jc8OOfW2HUEBG2dbd_kVSuslcES-OuThyCMU/edit
