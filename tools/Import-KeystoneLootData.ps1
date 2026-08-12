param(
    [string] $KeystoneLootRoot = "C:\Blizzard Games\World of Warcraft\_retail_\Interface\AddOns\KeystoneLoot",
    [string] $AddonRoot = (Join-Path $PSScriptRoot "..")
)

$ErrorActionPreference = "Stop"
$utf8 = New-Object System.Text.UTF8Encoding($false)
$dataRoot = Join-Path $AddonRoot "Data"
New-Item -ItemType Directory -Force -Path $dataRoot | Out-Null

$imports = @(
    @{ Source = "data/items.lua"; Destination = "LootItems.lua"; Symbol = "ItemDatabase" },
    @{ Source = "data/dungeons.lua"; Destination = "LootDungeons.lua"; Symbol = "DungeonDatabase" },
    @{ Source = "data/raids.lua"; Destination = "LootRaids.lua"; Symbol = "RaidDatabase" }
)

foreach ($import in $imports) {
    $sourcePath = Join-Path $KeystoneLootRoot $import.Source
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "KeystoneLoot generated data was not found: $sourcePath"
    }

    $content = [System.IO.File]::ReadAllText($sourcePath)
    $content = $content.Replace("local AddonName, KeystoneLoot = ...;", "")
    $content = $content.Replace("KeystoneLoot.$($import.Symbol)", "OakBonusPlannerLoot.$($import.Symbol)")
    $content = "-- Imported from KeystoneLoot's generated Season 2 database.`r`n" +
        "-- Regenerate with tools/Import-KeystoneLootData.ps1 when KeystoneLoot updates.`r`n" +
        "OakBonusPlannerLoot = OakBonusPlannerLoot or {}`r`n" + $content.TrimStart()

    $destinationPath = Join-Path $dataRoot $import.Destination
    [System.IO.File]::WriteAllText($destinationPath, $content, $utf8)
    Write-Host "Imported $($import.Source) -> $destinationPath"
}
