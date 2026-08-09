# Oak Bonus Planner

Oak Bonus Planner is a small, data-driven World of Warcraft addon for deciding where to spend bonus rolls based on the remaining Best in Slot targets for the selected class/spec.

## Season 1 quick test

This first seed contains a curated Beast Mastery Hunter target map for Midnight Season 1. It can use a compatible Keystone Loot data table when one is exposed, but it does not require Keystone Loot to run. The fallback plan tracks the named targets directly.

Open the window with /obp, /oakbonus, or /bonusplanner. The class and spec buttons cycle through Blizzard's class/spec IDs. The planner sorts sources by remaining target coverage and shows the remaining target count. A BONUS_ROLL_RESULT event marks received items in the addon's saved variables. Season history is kept separately, so a Season 2 data update will not inherit Season 1 roll history.

This is a planning score, not a literal drop percentage. Exact odds depend on the eligible loot pool, difficulty, bonus-roll rules, and the character's current gear.

## Weekly data releases

WoW addons cannot make arbitrary HTTPS requests to Wowhead or Icy Veins in-game. Weekly addon releases are therefore the right update boundary: review the current source pages, update Data.lua, bump the addon version, and ship the new addon package. The UI and event tracking remain stable while Season 2 replaces the Season 1 data file.

The initial references were:

- https://www.icy-veins.com/wow/beast-mastery-hunter-pve-dps-gear-best-in-slot
- https://www.wowhead.com/guide/classes/hunter/beast-mastery/bis-gear
- https://docs.google.com/spreadsheets/d/1PCG3WD8jc8OOfW2HUEBG2dbd_kVSuslcES-OuThyCMU/edit
