param(
    [string] $PatchLabel = "12.1",
    [string] $SeasonLabel = "Midnight Season 2",
    [string] $AddonRoot = (Join-Path $PSScriptRoot ".."),
    [string] $KeystoneLootRoot = "C:\Blizzard Games\World of Warcraft\_retail_\Interface\AddOns\KeystoneLoot"
)

$ErrorActionPreference = "Stop"

# KeystoneLoot's generated database is the authoritative prebuilt source for
# class/spec loot eligibility. Prefer it when available so a normal data
# refresh cannot regress to broad armor/stat heuristics. The Wowhead parser
# below remains a fallback for machines that do not have KeystoneLoot's files.
$keystoneData = @(
    (Join-Path $KeystoneLootRoot "data\items.lua"),
    (Join-Path $KeystoneLootRoot "data\dungeons.lua"),
    (Join-Path $KeystoneLootRoot "data\raids.lua")
)
if (($keystoneData | Where-Object { -not (Test-Path -LiteralPath $_) }).Count -eq 0) {
    & (Join-Path $PSScriptRoot "Import-KeystoneLootData.ps1") -KeystoneLootRoot $KeystoneLootRoot -AddonRoot $AddonRoot
    Write-Host "Used KeystoneLoot's generated Season database for loot eligibility."
    return
}

$headers = @{ "User-Agent" = "OakBonusPlanner/0.4 SeasonDataUpdater (contact: addon-maintainer)" }
$stamp = Get-Date -Format "yyyy-MM-dd"

$dungeons = @(
    @{ name = "Altar of Fangs"; challengeModeId = 588; instanceId = 2993; teleportSpellId = 1286812; url = "https://www.wowhead.com/guide/midnight/altar-of-fangs-dungeon-overview-location-rewards" },
    @{ name = "Murder Row"; challengeModeId = 587; instanceId = 2813; teleportSpellId = 1286809; url = "https://www.wowhead.com/guide/midnight/murder-row-dungeon-overview-location-rewards" },
    @{ name = "Den of Nalorakk"; challengeModeId = 586; instanceId = 2825; teleportSpellId = 1286807; url = "https://www.wowhead.com/guide/midnight/den-of-nalorakk-dungeon-overview-location-rewards" },
    @{ name = "The Blinding Vale"; challengeModeId = 584; instanceId = 2859; teleportSpellId = 1286801; url = "https://www.wowhead.com/guide/midnight/the-blinding-vale-dungeon-overview-location-rewards" },
    @{ name = "Voidscar Arena"; challengeModeId = 585; instanceId = 2923; teleportSpellId = 1286804; url = "https://www.wowhead.com/ptr/guide/midnight/voidscar-arena-dungeon-overview-location-rewards" },
    @{ name = "King's Rest"; challengeModeId = 249; instanceId = 1763; teleportSpellId = 131204; url = "https://www.wowhead.com/guide/kings-rest-dungeon-strategy-guide" },
    @{ name = "Temple of Sethraliss"; challengeModeId = 250; instanceId = 1877; teleportSpellId = 410078; url = "https://www.wowhead.com/guide/temple-of-sethraliss-dungeon-strategy-guide" },
    @{ name = "Ruby Life Pools"; challengeModeId = 399; instanceId = 2521; teleportSpellId = 393256; url = "https://www.wowhead.com/guide/dungeons/ruby-life-pools-strategy" }
)

$raidBosses = @(
    @{ name = "Nek'zali the Soulcoiler"; bossId = 2888; url = "https://www.wowhead.com/ptr/guide/midnight/raids/venomous-abyss-nekzali-the-soulcoiler-boss-strategy-abilities" },
    @{ name = "Entombed Sentinels"; bossId = 2874; url = "https://www.wowhead.com/ptr/guide/midnight/raids/venomous-abyss-entombed-sentinels-boss-strategy-abilities" },
    @{ name = "The Lost Explorers"; bossId = 2894; url = "https://www.wowhead.com/ptr/guide/midnight/raids/venomous-abyss-lost-explorers-boss-strategy-abilities" },
    @{ name = "Vashnik the Malignant"; bossId = 2882; url = "https://www.wowhead.com/ptr/guide/midnight/raids/venomous-abyss-vashnik-the-malignant-boss-strategy-abilities" },
    @{ name = "Sszorak"; bossId = 2871; url = "https://www.wowhead.com/ptr/guide/midnight/raids/venomous-abyss-sszorak-boss-strategy-abilities" },
    @{ name = "The Twin Fangs"; bossId = 2887; url = "https://www.wowhead.com/ptr/guide/midnight/raids/venomous-abyss-twin-fangs-boss-strategy-abilities" },
    @{ name = "The Coiled Altar"; bossId = 2883; url = "https://www.wowhead.com/ptr/guide/midnight/raids/venomous-abyss-coiled-altar-boss-strategy-abilities" },
    @{ name = "Ula'tek"; bossId = 2895; url = "https://www.wowhead.com/ptr/guide/midnight/raids/venomous-abyss-ulatek-boss-strategy-abilities" }
)

function Get-Page([string] $url) {
    Write-Host "Fetching $url"
    return (Invoke-WebRequest -UseBasicParsing -Headers $headers -Uri $url -TimeoutSec 60).Content
}

function Convert-HtmlText([string] $value) {
    if (-not $value) { return "" }
    return ([System.Net.WebUtility]::HtmlDecode((($value -replace '<[^>]+>', " ") -replace '\s+', ' '))).Trim()
}

function Get-GathererItems([string] $html) {
    $items = @{}
    $header = [regex]::Match($html, 'WH\.Gatherer\.addData\(3,\s*\d+,\s*')
    $start = $header.Index
    if (-not $header.Success) { return $items }
    $start = $html.IndexOf('{', $start)
    $end = $html.IndexOf(');', $start)
    if ($start -lt 0 -or $end -lt 0) { return $items }
    try {
        $object = $html.Substring($start, $end - $start) | ConvertFrom-Json
        foreach ($property in $object.PSObject.Properties) { $items[[int]$property.Name] = $property.Value }
    } catch {
        Write-Warning "Could not parse Wowhead item metadata: $($_.Exception.Message)"
    }
    return $items
}

function Get-LootRows([string] $html) {
    $rows = @{}

    # Current Midnight guides render the loot table as HTML rows.
    $matches = [regex]::Matches($html, '<tr[^>]*>.*?<a href="/(?:ptr/)?item=(\d+)/[^\"]+">([^<]+)</a>.*?<td>([^<]+)</td>.*?</tr>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    foreach ($match in $matches) {
        $id = [int]$match.Groups[1].Value
        $rows[$id] = @{ name = (Convert-HtmlText $match.Groups[2].Value); type = (Convert-HtmlText $match.Groups[3].Value); stats = "" }
    }

    # Legacy dungeon pages and the Ruby guide retain Wowhead's source markup.
    $matches = [regex]::Matches($html, '\[tr\]\[td\](.*?)\[\/td\]\[td\]\[item=(\d+)[^\]]*\]\[\/td\]\[td\](.*?)\[\/td\]\[\/tr\]', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    foreach ($match in $matches) {
        $id = [int]$match.Groups[2].Value
        $rows[$id] = @{ name = ""; type = (Convert-HtmlText $match.Groups[1].Value); stats = (Convert-HtmlText $match.Groups[3].Value) }
    }

    # Some older guides use the same source markup without the table wrappers.
    # Limit this fallback to the dungeon loot section so mounts and guide links
    # do not become false loot-pool entries.
    $lootStart = $html.IndexOf('dungeon loot')
    if ($lootStart -ge 0) {
            $rows = @{}
            $lootEnd = $html.IndexOf('Mythic+ Loot', $lootStart)
            if ($lootEnd -lt 0) { $lootEnd = $html.Length }
            $segment = $html.Substring($lootStart, $lootEnd - $lootStart)
            foreach ($match in [regex]::Matches($segment, '\[item=(\d+)')) {
                $id = [int]$match.Groups[1].Value
                if (-not $rows.ContainsKey($id)) { $rows[$id] = @{ name = ""; type = ""; stats = "" } }
            }
    }

    return $rows
}

function Get-SlotId([string] $type, $metadata = $null) {
    $value = $type.ToLowerInvariant()
    if ($value -match 'helm|head') { return 0 }
    if ($value -match 'neck') { return 1 }
    if ($value -match 'shoulder') { return 2 }
    if ($value -match 'back|cloak') { return 3 }
    if ($value -match 'chest') { return 4 }
    if ($value -match 'waist|belt|girdle') { return 5 }
    if ($value -match 'wrist|bracer') { return 6 }
    if ($value -match 'hand|glove') { return 7 }
    if ($value -match 'leg') { return 8 }
    if ($value -match 'feet|boot') { return 9 }
    if ($value -match 'ring') { return 11 }
    if ($value -match 'trinket') { return 12 }
    if ($value -match 'off-hand|off hand|shield') { return 13 }
    if ($value -match 'weapon|one-hand|two-hand|1h|2h|dagger|mace|axe|sword|fist') { return 10 }
    $slotbak = $metadata.jsonequip.slotbak
    switch ([int]$slotbak) {
        1 { return 0 }; 3 { return 2 }; 5 { return 4 }; 6 { return 5 }
        7 { return 8 }; 8 { return 9 }; 9 { return 6 }; 10 { return 7 }
        11 { return 11 }; 12 { return 12 }; 13 { return 10 }; 16 { return 3 }
        17 { return 10 }; 21 { return 10 }; 22 { return 10 }; 23 { return 13 }
    }
    return 14
}

$specsByClass = @{
    1 = @(71,72,73); 2 = @(65,66,70); 3 = @(253,254,255); 4 = @(259,260,261)
    5 = @(256,257,258); 6 = @(250,251,252); 7 = @(262,263,264); 8 = @(62,63,64)
    9 = @(265,266,267); 10 = @(268,269,270); 11 = @(102,103,104,105)
    12 = @(577,581,1480); 13 = @(1467,1468,1473)
}
$cloth = @(5,8,9)
$leather = @(4,10,11,12)
$mail = @(3,7,13)
$plate = @(1,2,6)
$intSpecs = @(62,63,64,65,102,105,1467,1468,1473,256,257,258,262,264,265,266,267,268,270)
$agiSpecs = @(102,103,104,105,253,254,255,259,260,261,263,268,269,577,581,1480)
$strSpecs = @(65,66,70,71,72,73,250,251,252)
$bonusRollClassExclusions = @{}

function Get-ClassSpecs([hashtable] $row, $metadata, [int] $itemID) {
    $text = (([string]$row.type) + " " + [string]$row.stats + " " + [string]$metadata.icon).ToLowerInvariant()
    $selectedClasses = @()
    $selectedSpecs = @()
    if ($text -match 'cloth') { $selectedClasses = $cloth }
    elseif ($text -match 'leather') { $selectedClasses = $leather }
    elseif ($text -match 'mail') { $selectedClasses = $mail }
    elseif ($text -match 'plate') { $selectedClasses = $plate }
    else {
        $equip = $metadata.jsonequip
        $hasInt = $equip -and $equip.int
        $hasAgi = $equip -and $equip.agi
        $hasStr = $equip -and $equip.str
        if ($text -match 'int' -or $hasInt) { $selectedSpecs += $intSpecs }
        if ($text -match 'agi' -or $hasAgi) { $selectedSpecs += $agiSpecs }
        if ($text -match 'str' -or $hasStr) { $selectedSpecs += $strSpecs }
    }
    $result = @{}
    foreach ($classID in ($specsByClass.Keys | Sort-Object)) {
        if ($selectedClasses -contains [int]$classID) {
            $result[[int]$classID] = @($specsByClass[[int]$classID])
        } elseif ($selectedSpecs.Count -gt 0) {
            $matchingSpecs = @($specsByClass[[int]$classID] | Where-Object { $selectedSpecs -contains $_ })
            if ($matchingSpecs.Count -gt 0) { $result[[int]$classID] = $matchingSpecs }
        } elseif ($selectedClasses.Count -eq 0) {
            $result[[int]$classID] = @($specsByClass[[int]$classID])
        }
    }
    foreach ($excludedItemID in $bonusRollClassExclusions.Keys) {
        if ([int]$excludedItemID -eq $itemID -and $result.Count -gt 0) {
            foreach ($classID in $bonusRollClassExclusions[$excludedItemID]) {
                $result.Remove([int]$classID)
            }
        }
    }
    return $result
}

function Escape-Lua([string] $value) { return ($value -replace '\\', '\\\\' -replace '"', '\"') }
function Format-LuaArray([int[]] $values) { return ($values | Sort-Object -Unique | ForEach-Object { [string]$_ }) -join ', ' }
function Format-LuaClasses([hashtable] $classes) {
    return (($classes.Keys | Sort-Object | ForEach-Object { "[$_] = { " + (Format-LuaArray $classes[$_]) + " }" }) -join ', ')
}
function Test-BonusRollEligibleLoot($row) {
    # Loot-guide pages also list profession recipes. They cannot be won from a
    # bonus roll, so they must never enter the finite item pool.
    return -not ($row.name -match '^(Pattern|Design|Formula|Plans|Recipe|Schematic):')
}

$allItems = @{}
$dungeonRows = @{}
foreach ($dungeon in $dungeons) {
    $html = Get-Page $dungeon.url
    $meta = Get-GathererItems $html
    $rows = Get-LootRows $html
    $eligibleIDs = @($rows.Keys | Where-Object { Test-BonusRollEligibleLoot $rows[$_] })
    $dungeonRows[$dungeon.name] = @($eligibleIDs | Sort-Object)
    foreach ($id in $eligibleIDs) {
        if (-not $allItems.ContainsKey($id)) { $allItems[$id] = $rows[$id] }
        if ($rows[$id].name -and -not $allItems[$id].name) { $allItems[$id].name = $rows[$id].name }
        if ($rows[$id].type -and -not $allItems[$id].type) { $allItems[$id].type = $rows[$id].type }
        if ($rows[$id].stats -and -not $allItems[$id].stats) { $allItems[$id].stats = $rows[$id].stats }
        if (-not $allItems[$id].metadata -and $meta.ContainsKey($id)) { $allItems[$id].metadata = $meta[$id] }
    }
}

$raidRows = @{}
foreach ($boss in $raidBosses) {
    $html = Get-Page $boss.url
    $meta = Get-GathererItems $html
    $rows = Get-LootRows $html
    $eligibleIDs = @($rows.Keys | Where-Object { Test-BonusRollEligibleLoot $rows[$_] })
    $raidRows[$boss.name] = @($eligibleIDs | Sort-Object)
    foreach ($id in $eligibleIDs) {
        if (-not $allItems.ContainsKey($id)) { $allItems[$id] = $rows[$id] }
        if ($rows[$id].name -and -not $allItems[$id].name) { $allItems[$id].name = $rows[$id].name }
        if ($rows[$id].type -and -not $allItems[$id].type) { $allItems[$id].type = $rows[$id].type }
        if ($rows[$id].stats -and -not $allItems[$id].stats) { $allItems[$id].stats = $rows[$id].stats }
        if (-not $allItems[$id].metadata -and $meta.ContainsKey($id)) { $allItems[$id].metadata = $meta[$id] }
    }
}

$outData = Join-Path $AddonRoot 'Data'
New-Item -ItemType Directory -Force -Path $outData | Out-Null

$dungeonText = @(
    "-- Generated by tools/Update-S2LootData.ps1. Do not edit by hand.",
    "-- Sources: Wowhead Season 2 dungeon loot guides, refreshed $stamp.",
    "OakBonusPlannerLoot = OakBonusPlannerLoot or {}",
    "OakBonusPlannerLoot.DungeonDatabase = {"
)
foreach ($dungeon in $dungeons) {
    $ids = Format-LuaArray ([int[]]$dungeonRows[$dungeon.name])
    $dungeonText += "    { name = `"$(Escape-Lua $dungeon.name)`", challengeModeId = $($dungeon.challengeModeId), teleportSpellId = $($dungeon.teleportSpellId), instanceId = $($dungeon.instanceId), lootTable = { $ids } },"
}
$dungeonText += "};"
Set-Content -LiteralPath (Join-Path $outData 'LootDungeons.lua') -Value $dungeonText -Encoding utf8

$raidText = @(
    "-- Generated by tools/Update-S2LootData.ps1. Do not edit by hand.",
    "-- Sources: Wowhead Season 2 Venomous Abyss boss loot guides, refreshed $stamp.",
    "OakBonusPlannerLoot = OakBonusPlannerLoot or {}",
    "OakBonusPlannerLoot.RaidDatabase = {",
    "    { name = `"The Venomous Abyss`", journalInstanceId = 1320, instanceId = 3004, bossList = {"
)
foreach ($boss in $raidBosses) {
    $ids = Format-LuaArray ([int[]]$raidRows[$boss.name])
    $raidText += "        { name = `"$(Escape-Lua $boss.name)`", bossId = $($boss.bossId), lootTable = { [14] = { $ids }, [15] = { $ids }, [16] = { $ids }, [17] = { $ids } } },"
}
$raidText += "    } }"
$raidText += "};"
Set-Content -LiteralPath (Join-Path $outData 'LootRaids.lua') -Value $raidText -Encoding utf8

$itemText = @(
    "-- Generated by tools/Update-S2LootData.ps1. Do not edit by hand.",
    "-- Sources: Wowhead Season 2 loot tables, refreshed $stamp.",
    "OakBonusPlannerLoot = OakBonusPlannerLoot or {}",
    "OakBonusPlannerLoot.ItemDatabase = {"
)
foreach ($id in ($allItems.Keys | Sort-Object {[int]$_})) {
    $row = $allItems[$id]
    $metadata = $row.metadata
    $slot = Get-SlotId $row.type $row.metadata
    $classes = Get-ClassSpecs $row $metadata ([int]$id)
    $itemText += "    [$id] = { name = `"$(Escape-Lua $row.name)`", classes = { $(Format-LuaClasses $classes) }, slotId = $slot }, -- $(Escape-Lua $row.name)"
}
$itemText += "};"
Set-Content -LiteralPath (Join-Path $outData 'LootItems.lua') -Value $itemText -Encoding utf8

Write-Host "Wrote $($dungeons.Count) Season 2 dungeons, $($raidBosses.Count) raid bosses, and $($allItems.Count) unique items."
