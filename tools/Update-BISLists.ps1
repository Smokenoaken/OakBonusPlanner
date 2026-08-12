param(
    [string] $PatchLabel = "12.1",
    [string] $SeasonLabel = "Midnight Season 2",
    [string] $AddonRoot = (Join-Path $PSScriptRoot "..")
)

# User-facing BIS update command. "Update the BIS lists" means refreshing all
# supported specs from Icy Veins overall/raid/dungeon gear and stat pages plus
# Wowhead overall BIS, then writing Data\BIS.lua and the matching Season 2
# dungeon/raid/item loot tables. Keeping these updates together prevents a
# refreshed BIS list from pointing at a different season's denominator.
$script = Join-Path $PSScriptRoot "Update-BISData.ps1"
& $script -PatchLabel $PatchLabel -SeasonLabel $SeasonLabel
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$lootScript = Join-Path $PSScriptRoot "Update-S2LootData.ps1"
& $lootScript -PatchLabel $PatchLabel -SeasonLabel $SeasonLabel -AddonRoot $AddonRoot
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
