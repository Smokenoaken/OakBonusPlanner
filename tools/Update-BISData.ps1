param(
    [string] $PatchLabel = "12.1",
    [string] $SeasonLabel = "Midnight Season 2",
    [string] $OutputPath = ""
)

$ErrorActionPreference = "Stop"

$root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$output = Join-Path $root "Data\BIS.lua"
if ($OutputPath) {
    $output = [System.IO.Path]::GetFullPath($OutputPath)
}
$baseIcy = "https://www.icy-veins.com/wow"
$baseWowhead = "https://www.wowhead.com/guide/classes"
$raidSourceNames = @(
    "Nek'zali the Soulcoiler", "Entombed Sentinels", "The Lost Explorers",
    "Vashnik the Malignant", "Sszorak", "The Twin Fangs", "The Coiled Altar", "Ula'tek",
    "Nek'zali", "Lost Explorers", "Vashnik", "Twin Fangs", "Coiled Altar"
)

$specs = @(
    @{ id = 71; classSlug = "warrior"; className = "Warrior"; specSlug = "arms"; specName = "Arms"; role = "dps" },
    @{ id = 72; classSlug = "warrior"; className = "Warrior"; specSlug = "fury"; specName = "Fury"; role = "dps" },
    @{ id = 73; classSlug = "warrior"; className = "Warrior"; specSlug = "protection"; specName = "Protection"; role = "tank" },
    @{ id = 65; classSlug = "paladin"; className = "Paladin"; specSlug = "holy"; specName = "Holy"; role = "healing" },
    @{ id = 66; classSlug = "paladin"; className = "Paladin"; specSlug = "protection"; specName = "Protection"; role = "tank" },
    @{ id = 70; classSlug = "paladin"; className = "Paladin"; specSlug = "retribution"; specName = "Retribution"; role = "dps" },
    @{ id = 253; classSlug = "hunter"; className = "Hunter"; specSlug = "beast-mastery"; specName = "Beast Mastery"; role = "dps" },
    @{ id = 254; classSlug = "hunter"; className = "Hunter"; specSlug = "marksmanship"; specName = "Marksmanship"; role = "dps" },
    @{ id = 255; classSlug = "hunter"; className = "Hunter"; specSlug = "survival"; specName = "Survival"; role = "dps" },
    @{ id = 250; classSlug = "death-knight"; className = "Death Knight"; specSlug = "blood"; specName = "Blood"; role = "tank" },
    @{ id = 251; classSlug = "death-knight"; className = "Death Knight"; specSlug = "frost"; specName = "Frost"; role = "dps" },
    @{ id = 252; classSlug = "death-knight"; className = "Death Knight"; specSlug = "unholy"; specName = "Unholy"; role = "dps" },
    @{ id = 577; classSlug = "demon-hunter"; className = "Demon Hunter"; specSlug = "havoc"; specName = "Havoc"; role = "dps" },
    @{ id = 581; classSlug = "demon-hunter"; className = "Demon Hunter"; specSlug = "vengeance"; specName = "Vengeance"; role = "tank" },
    @{ id = 1480; classSlug = "demon-hunter"; className = "Demon Hunter"; specSlug = "devourer"; specName = "Devourer"; role = "dps" },
    @{ id = 102; classSlug = "druid"; className = "Druid"; specSlug = "balance"; specName = "Balance"; role = "dps" },
    @{ id = 103; classSlug = "druid"; className = "Druid"; specSlug = "feral"; specName = "Feral"; role = "dps" },
    @{ id = 104; classSlug = "druid"; className = "Druid"; specSlug = "guardian"; specName = "Guardian"; role = "tank" },
    @{ id = 105; classSlug = "druid"; className = "Druid"; specSlug = "restoration"; specName = "Restoration"; role = "healing" },
    @{ id = 1467; classSlug = "evoker"; className = "Evoker"; specSlug = "devastation"; specName = "Devastation"; role = "dps" },
    @{ id = 1468; classSlug = "evoker"; className = "Evoker"; specSlug = "preservation"; specName = "Preservation"; role = "healing" },
    @{ id = 1473; classSlug = "evoker"; className = "Evoker"; specSlug = "augmentation"; specName = "Augmentation"; role = "dps" },
    @{ id = 62; classSlug = "mage"; className = "Mage"; specSlug = "arcane"; specName = "Arcane"; role = "dps" },
    @{ id = 63; classSlug = "mage"; className = "Mage"; specSlug = "fire"; specName = "Fire"; role = "dps" },
    @{ id = 64; classSlug = "mage"; className = "Mage"; specSlug = "frost"; specName = "Frost"; role = "dps" },
    @{ id = 268; classSlug = "monk"; className = "Monk"; specSlug = "brewmaster"; specName = "Brewmaster"; role = "tank" },
    @{ id = 270; classSlug = "monk"; className = "Monk"; specSlug = "mistweaver"; specName = "Mistweaver"; role = "healing" },
    @{ id = 269; classSlug = "monk"; className = "Monk"; specSlug = "windwalker"; specName = "Windwalker"; role = "dps" },
    @{ id = 256; classSlug = "priest"; className = "Priest"; specSlug = "discipline"; specName = "Discipline"; role = "healing" },
    @{ id = 257; classSlug = "priest"; className = "Priest"; specSlug = "holy"; specName = "Holy"; role = "healing" },
    @{ id = 258; classSlug = "priest"; className = "Priest"; specSlug = "shadow"; specName = "Shadow"; role = "dps" },
    @{ id = 259; classSlug = "rogue"; className = "Rogue"; specSlug = "assassination"; specName = "Assassination"; role = "dps" },
    @{ id = 260; classSlug = "rogue"; className = "Rogue"; specSlug = "outlaw"; specName = "Outlaw"; role = "dps" },
    @{ id = 261; classSlug = "rogue"; className = "Rogue"; specSlug = "subtlety"; specName = "Subtlety"; role = "dps" },
    @{ id = 262; classSlug = "shaman"; className = "Shaman"; specSlug = "elemental"; specName = "Elemental"; role = "dps" },
    @{ id = 263; classSlug = "shaman"; className = "Shaman"; specSlug = "enhancement"; specName = "Enhancement"; role = "dps" },
    @{ id = 264; classSlug = "shaman"; className = "Shaman"; specSlug = "restoration"; specName = "Restoration"; role = "healing" },
    @{ id = 265; classSlug = "warlock"; className = "Warlock"; specSlug = "affliction"; specName = "Affliction"; role = "dps" },
    @{ id = 266; classSlug = "warlock"; className = "Warlock"; specSlug = "demonology"; specName = "Demonology"; role = "dps" },
    @{ id = 267; classSlug = "warlock"; className = "Warlock"; specSlug = "destruction"; specName = "Destruction"; role = "dps" }
)

function Get-Page([string] $url) {
    $lastError = $null
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 45 -Headers @{ "User-Agent" = "OakBonusPlanner-BIS-Updater/1.0" }
            return $response.Content
        } catch {
            $lastError = $_
            if ($attempt -lt 3) { Start-Sleep -Seconds (2 * $attempt) }
        }
    }
    throw $lastError
}

function Strip-Html([string] $value) {
    if (-not $value) { return "" }
    $value = [regex]::Replace($value, "<br\s*/?>", " ", "IgnoreCase")
    $value = [regex]::Replace($value, "<[^>]+>", " ")
    $value = [System.Net.WebUtility]::HtmlDecode($value)
    return [regex]::Replace($value, "\s+", " ").Trim()
}

function Escape-Lua([string] $value) {
    if ($null -eq $value) { return "" }
    return $value.Replace("\\", "\\\\").Replace('"', '\"').Replace("`r", " ").Replace("`n", " ")
}

function Get-Section([string] $html, [string[]] $headingIDs) {
    $start = $html.Length
    $headingID = ""
    foreach ($candidateID in $headingIDs) {
        $candidateStart = $html.IndexOf(('id="' + $candidateID + '"'))
        if ($candidateStart -ge 0 -and $candidateStart -lt $start) {
            $start = $candidateStart
            $headingID = $candidateID
        }
    }
    if ($headingID -eq "") { return "" }
    $end = $html.Length
    foreach ($otherID in @(
        "overall-best-in-slot", "best-overall-best-in-slot", "overall-bis-list",
        "best-raid-gear", "raid-gear-bis-list", "raid-gear-best-in-slot",
        "best-mythic-gear", "mythic-gear-bis-list", "mythic-gear-best-in-slot"
    )) {
        if ($otherID -eq $headingID) { continue }
        $candidate = $html.IndexOf(('id="' + $otherID + '"'), $start + 1)
        if ($candidate -ge 0 -and $candidate -lt $end) { $end = $candidate }
    }
    return $html.Substring($start, $end - $start)
}

function Get-IcyItems([string] $section) {
    $items = @()
    if (-not $section) { return $items }
    $chunks = [regex]::Split($section, '<div class="bis_item\b')
    foreach ($chunk in ($chunks | Select-Object -Skip 1)) {
        $idMatch = [regex]::Match($chunk, 'data-wowhead="item=(\d+)')
        if (-not $idMatch.Success) { continue }
        $slotMatch = [regex]::Match($chunk, '<span class="bis_item_slot">\s*([^<]+?)\s*</span>')
        $nameMatch = [regex]::Match($chunk, 'data-wowhead="item=' + $idMatch.Groups[1].Value + '[^"]*"[^>]*class="q\d+">\s*([^<]+?)\s*</span>')
        if (-not $nameMatch.Success) {
            $nameMatch = [regex]::Match($chunk, 'alt="([^"]+) Icon"')
        }
        $dropMatch = [regex]::Match($chunk, '<span class="bis_item_drop">(.*?)</span>', "Singleline")
        # The site renders blank inventory placeholders at the end of a grid.
        # Those have a slot label but no footer or item link; accepting them
        # lets text from the following FAQ leak into the next fake item.
        if (-not $dropMatch.Success) { continue }
        $originalMatch = [regex]::Match($chunk, 'original-item=(\d+)')
        $source = (Strip-Html $dropMatch.Groups[1].Value)
        $items += [pscustomobject]@{
            itemID = [int] $idMatch.Groups[1].Value
            slot = (Strip-Html $slotMatch.Groups[1].Value)
            name = (Strip-Html $nameMatch.Groups[1].Value)
            source = $source
            originalItemID = if ($originalMatch.Success) { [int] $originalMatch.Groups[1].Value } else { $null }
            isCatalyst = $source -match '(?i)catalyst'
        }
    }
    return $items
}

function Get-CardCatalystTargets([object[]] $items, [object] $catalog, [int] $specID) {
    $targets = @()
    foreach ($item in $items) {
        if (-not $item.isCatalyst) { continue }
        # The transformed tier card's footer can name another eligible
        # catalyst candidate. The only unambiguous identifier is
        # original-item: resolve that base item through the bundled Season 2
        # pool, then use the footer only if it is not present in the database.
        if ($item.originalItemID -and $catalog.byItemID.ContainsKey([int]$item.originalItemID)) {
            foreach ($source in @($catalog.byItemID[[int]$item.originalItemID])) {
                if ($catalog.itemSpecs[[int]$item.originalItemID] -contains $specID) {
                    $targets += [pscustomobject]@{
                        itemID = [int]$item.originalItemID
                        slot = $item.slot
                        name = $item.name
                        source = $source
                    }
                }
            }
            continue
        }

        # Never infer an item from a source and a stale imported slot label.
        # A guide card without its base original-item is informational only.
    }
    return @($targets | Sort-Object itemID, source -Unique)
}

function Get-IcyBisPanel([string] $html, [int] $index) {
    $match = [regex]::Match($html, '<div class="image_block_content"\s+id="bis_0_' + $index + '">(?<content>.*?)(?=<div class="image_block_content"|$)', 'Singleline')
    if ($match.Success) { return $match.Groups['content'].Value }
    return ""
}

function Get-IcyCatalystTargets([string] $html) {
    $targets = @()
    if (-not $html) { return $targets }
    foreach ($match in [regex]::Matches($html, '<li>\s*Catalyst\s+(?<slot>[^:]+):(?<body>.*?)</li>', "Singleline,IgnoreCase")) {
        $body = $match.Groups['body'].Value
        $idMatch = [regex]::Match($body, 'data-wowhead="item=(\d+)')
        if (-not $idMatch.Success) { continue }
        $nameMatch = [regex]::Match($body, 'class="q\d+">\s*([^<]+?)\s*</span>')
        if (-not $nameMatch.Success) {
            $nameMatch = [regex]::Match($body, 'alt="([^\"]+) Icon"')
        }
        $text = Strip-Html $body
        $sourceMatch = [regex]::Match($text, '\bfrom\s+(.+)$', "IgnoreCase")
        if (-not $sourceMatch.Success) { continue }
        $targets += [pscustomobject]@{
            itemID = [int] $idMatch.Groups[1].Value
            slot = (Strip-Html $match.Groups['slot'].Value)
            name = (Strip-Html $nameMatch.Groups[1].Value)
            source = (Strip-Html $sourceMatch.Groups[1].Value)
        }
    }
    return @($targets | Sort-Object itemID, source -Unique)
}

function Get-GuideCatalystSlotID([string] $slot) {
    switch -Regex ($slot) {
        '^(Helm|Head)$' { return 0 }
        '^Shoulders?$' { return 2 }
        '^Chest$' { return 4 }
        '^(Gloves|Hands)$' { return 7 }
        '^Legs$' { return 8 }
    }
    return $null
}

function Find-IcyItemIDByName([string] $html, [string] $name) {
    if (-not $html -or -not $name) { return $null }
    $escapedName = [regex]::Escape($name.Trim())
    $pattern = 'data-wowhead="item=(?<id>\d+)[^"]*"[^>]*class="q\d+">\s*' + $escapedName + '\s*</span>'
    $match = [regex]::Match($html, $pattern, 'IgnoreCase')
    if ($match.Success) { return [int]$match.Groups['id'].Value }
    return $null
}

function Get-CatalogSourceKey([string] $source) {
    $key = (($source -replace '(?i)^the\s+', '').Trim().ToLowerInvariant())
    $aliases = @{
        'nymrissa wavecaller' = 'nymrissa tidecaller'
        'nymrissa' = 'nymrissa tidecaller'
    }
    if ($aliases.ContainsKey($key)) { return $aliases[$key] }
    return $key
}

function SourceNamesMatch([string] $left, [string] $right) {
    $leftKey = Get-CatalogSourceKey $left
    $rightKey = Get-CatalogSourceKey $right
    if (-not $leftKey -or -not $rightKey) { return $false }
    return $leftKey -eq $rightKey -or $leftKey.Contains($rightKey) -or $rightKey.Contains($leftKey)
}

function ResolveCatalogSource([string] $sourceText, [object] $catalog) {
    $sourceText = ($sourceText -replace '\s*\.$', '').Trim()
    foreach ($candidate in @($catalog.sourceNames)) {
        if (SourceNamesMatch $sourceText $candidate) { return $candidate }
    }
    if ($sourceText -match '^(?<source>.+?)\s+in\s+(?:Venomous Abyss|Tidebound Grotto)\b') {
        $sourceText = $Matches['source'].Trim()
        foreach ($candidate in @($catalog.sourceNames)) {
            if (SourceNamesMatch $sourceText $candidate) { return $candidate }
        }
    }
    return $sourceText
}

function IsRaidCatalogSource([string] $source) {
    foreach ($raidSource in $raidSourceNames) {
        if (SourceNamesMatch $source $raidSource) { return $true }
    }
    return $false
}

function Get-SeasonLootCatalog {
    $itemFile = Join-Path $root "Data\LootItems.lua"
    $dungeonFile = Join-Path $root "Data\LootDungeons.lua"
    $raidFile = Join-Path $root "Data\LootRaids.lua"
    $itemNames = @{}
    $itemSlots = @{}
    $itemSpecs = @{}
    $sources = @{}

    foreach ($match in [regex]::Matches((Get-Content -LiteralPath $itemFile -Raw), '\[(\d+)\]\s*=\s*\{\s*name\s*=\s*"([^"]*)"')) {
        if ($match.Groups[2].Value) {
            $itemNames[[int] $match.Groups[1].Value] = $match.Groups[2].Value
        }
    }
    foreach ($match in [regex]::Matches((Get-Content -LiteralPath $itemFile -Raw), '\[(\d+)\]\s*=\s*\{.*?slotId\s*=\s*(\d+)', 'Singleline')) {
        $itemSlots[[int]$match.Groups[1].Value] = [int]$match.Groups[2].Value
    }
    foreach ($match in [regex]::Matches((Get-Content -LiteralPath $itemFile -Raw), '\[(\d+)\]\s*=\s*\{\s*classes\s*=\s*\{(?<classes>.*?)\},\s*(?:stats\s*=\s*\{[^}]*\},\s*)?slotId\s*=\s*\d+', 'Singleline')) {
        $specIDs = @()
        foreach ($classMatch in [regex]::Matches($match.Groups['classes'].Value, '\[\d+\]\s*=\s*\{([^}]*)\}')) {
            foreach ($specID in [regex]::Matches($classMatch.Groups[1].Value, '\d+')) {
                $specIDs += [int]$specID.Value
            }
        }
        $itemSpecs[[int]$match.Groups[1].Value] = @($specIDs | Sort-Object -Unique)
    }
    $sourceDefinitions = @{}
    $dataFile = Join-Path $root "Data.lua"
    $dataContent = Get-Content -LiteralPath $dataFile -Raw
    $excludedItemIDs = @{}
    $excludedBlock = [regex]::Match($dataContent, '(?is)BonusRollExcludedItems\s*=\s*\{(?<items>.*?)\}')
    foreach ($idMatch in [regex]::Matches($excludedBlock.Groups['items'].Value, '\[(\d+)\]\s*=\s*true')) {
        $excludedItemIDs[[int]$idMatch.Groups[1].Value] = $true
    }
    $tierTokenIDs = @{}
    $tierBlock = [regex]::Match($dataContent, '(?is)RaidTierTokens\s*=\s*\{(?<items>.*?)\n\}')
    foreach ($idMatch in [regex]::Matches($tierBlock.Groups['items'].Value, 'itemID\s*=\s*(\d+)')) {
        $tierTokenIDs[[int]$idMatch.Groups[1].Value] = $true
    }
    foreach ($match in [regex]::Matches($dataContent, '\{\s*id\s*=\s*"[^"]+",\s*name\s*=\s*"([^"]+)".*?(?:challengeModeID|bossID)\s*=\s*(\d+)', 'Singleline')) {
        $sourceDefinitions[[int]$match.Groups[2].Value] = $match.Groups[1].Value
    }

    $dungeonContent = Get-Content -LiteralPath $dungeonFile -Raw
    foreach ($match in [regex]::Matches($dungeonContent, 'challengeModeId\s*=\s*(\d+).*?lootTable\s*=\s*\{([^}]*)\}', 'Singleline')) {
        $source = $sourceDefinitions[[int]$match.Groups[1].Value]
        if (-not $source) { continue }
        foreach ($idMatch in [regex]::Matches($match.Groups[2].Value, '\d+')) {
            $itemID = [int]$idMatch.Value
            if ($excludedItemIDs.ContainsKey($itemID)) { continue }
            if (-not $sources.ContainsKey($itemID)) { $sources[$itemID] = @() }
            $sources[$itemID] += $source
        }
    }

    $raidContent = Get-Content -LiteralPath $raidFile -Raw
    foreach ($bossID in $sourceDefinitions.Keys) {
        $source = $sourceDefinitions[$bossID]
        $bossMatch = [regex]::Match($raidContent, "bossId\s*=\s*$bossID,\s*lootTable\s*=\s*\{(?<loot>.*?)\r?\n\s{16}\}\s*\r?\n\s{12}\}", 'Singleline')
        if (-not $bossMatch.Success) { continue }
        foreach ($idMatch in [regex]::Matches($bossMatch.Groups['loot'].Value, '\d+')) {
            $itemID = [int]$idMatch.Value
            if ($itemID -in @(14, 15, 16, 17)) { continue }
            if ($excludedItemIDs.ContainsKey($itemID)) { continue }
            if (-not $sources.ContainsKey($itemID)) { $sources[$itemID] = @() }
            $sources[$itemID] += $source
        }
    }

    $catalog = @{}
    $sourceSlotCatalog = @{}
    foreach ($itemID in $sources.Keys) {
        $itemName = $itemNames[$itemID]
        if (-not $itemName) { $itemName = "" }
        foreach ($source in @($sources[$itemID])) {
            if ($itemName) {
                $key = $itemName.ToLowerInvariant()
                if (-not $catalog.ContainsKey($key)) { $catalog[$key] = @() }
                $catalog[$key] += [pscustomobject]@{ itemID = $itemID; name = $itemName; source = $source }
            }
            if ($itemSlots.ContainsKey($itemID)) {
                $slotID = $itemSlots[$itemID]
                $sourceSlotKey = "$(Get-CatalogSourceKey $source)|$slotID"
                if (-not $sourceSlotCatalog.ContainsKey($sourceSlotKey)) { $sourceSlotCatalog[$sourceSlotKey] = @() }
                $sourceSlotCatalog[$sourceSlotKey] += [pscustomobject]@{ itemID = $itemID; name = $itemName; source = $source }
            }
        }
    }
    $sourceNames = @($sourceDefinitions.Values | Sort-Object -Unique)
    return [pscustomobject]@{
        byName = $catalog
        byItemID = $sources
        itemSlots = $itemSlots
        itemSpecs = $itemSpecs
        excludedItemIDs = $excludedItemIDs
        tierTokenIDs = $tierTokenIDs
        bySourceSlot = $sourceSlotCatalog
        sourceNames = $sourceNames
    }
}

function Assert-CatalystTargets([object[]] $targets, [object] $catalog, [int] $specID, [string] $label) {
    foreach ($target in $targets) {
        if (-not $target.itemID -or -not $target.source) {
            throw "Invalid catalyst target in $label"
        }
        $expectedSlotID = Get-GuideCatalystSlotID $target.slot
        if ($null -eq $expectedSlotID) {
            throw "Unsupported catalyst slot '$($target.slot)' in $label for item $($target.itemID)"
        }
        if (-not $catalog.itemSlots.ContainsKey([int]$target.itemID)) {
            throw "Catalyst item $($target.itemID) is absent from the Season 2 item database in $label"
        }
        if ($target.tierToken) { continue }
        if ($catalog.itemSpecs[[int]$target.itemID] -notcontains $specID) {
            throw "Catalyst item $($target.itemID) is not eligible for spec $specID in $label"
        }
        $sourceMatch = $false
        foreach ($source in @($catalog.byItemID[[int]$target.itemID])) {
            if (SourceNamesMatch $target.source $source) {
                $sourceMatch = $true
                break
            }
        }
        if (-not $sourceMatch) {
            throw "Catalyst item $($target.itemID) is not in '$($target.source)' according to the Season 2 loot database in $label"
        }
    }
}

function Get-GuideFAQCatalystTargets([string] $html, [object] $catalog, [int] $specID) {
    # Some current Icy Veins guides present catalyst choices only in the
    # "Which Slots Do I Want Tier Set In?" FAQ.  The page gives an item name
    # and source rather than an item link, so resolve that pair against our
    # reviewed Season 2 loot catalog before writing it as a target.
    $faq = [regex]::Match($html, '"name":"Which Slots Do I Want Tier Set In\?".*?"text":"(?<answer>(?:\\.|[^"])*)"', 'Singleline')
    if (-not $faq.Success) {
        return [pscustomobject]@{ targets = @(); unresolved = @() }
    }

    $answer = $faq.Groups['answer'].Value
    $answer = $answer.Replace('\u2014', '—').Replace('\"', '"').Replace('\/', '/')
    $answer = Strip-Html $answer
    $targets = @()
    $unresolved = @()
    $slotPattern = '(?is)(?<slot>Helm|Head|Shoulders|Chest|Gloves|Hands|Legs)\s*(?:—|-)\s*(?<choices>.*?)(?=\s+(?:Helm|Head|Shoulders|Chest|Gloves|Hands|Legs)\s*(?:—|-)|$)'
    foreach ($slotMatch in [regex]::Matches($answer, $slotPattern)) {
        $slot = Strip-Html $slotMatch.Groups['slot'].Value
        $choices = $slotMatch.Groups['choices'].Value
        foreach ($choice in [regex]::Matches($choices, '(?is)(?<name>[^()]+?)\s+from\s+(?<source>[^()]+?)\s*\((?<note>[^)]*)\)')) {
            $name = (Strip-Html $choice.Groups['name'].Value) -replace '(?i)^or\s+', ''
            $sourceText = Strip-Html $choice.Groups['source'].Value
            $matched = $false
            foreach ($candidate in @($catalog.byName[$name.ToLowerInvariant()])) {
                if ($catalog.itemSpecs[[int]$candidate.itemID] -notcontains $specID) { continue }
                if ($sourceText.IndexOf($candidate.source, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) { continue }
                $targets += [pscustomobject]@{ itemID = $candidate.itemID; slot = $slot; name = $candidate.name; source = $candidate.source }
                $matched = $true
            }
            if (-not $matched) {
                $sourceKey = Get-CatalogSourceKey (($sourceText -replace '(?i)\s+if\b.*$', '').Trim())
                $namedCandidates = @(
                    $catalog.byName[$name.ToLowerInvariant()] |
                    Where-Object {
                        $_ -and $catalog.itemSpecs[[int]$_.itemID] -contains $specID -and
                        (SourceNamesMatch $_.source $sourceText)
                    } |
                    Sort-Object itemID -Unique
                )
                foreach ($candidate in $namedCandidates) {
                    $targets += [pscustomobject]@{ itemID = $candidate.itemID; slot = $slot; name = $candidate.name; source = $candidate.source }
                    $matched = $true
                }
                $linkedID = Find-IcyItemIDByName $html $name
                if (-not $matched -and $linkedID -and $catalog.itemSpecs[$linkedID] -contains $specID) {
                    foreach ($candidateSource in @($catalog.byItemID[$linkedID])) {
                        if (SourceNamesMatch $candidateSource $sourceText) {
                            $targets += [pscustomobject]@{ itemID = $linkedID; slot = $slot; name = $name; source = $candidateSource }
                            $matched = $true
                        }
                    }
                }
            }
            if (-not $matched) { $unresolved += "${slot}: $name ($sourceText)" }
        }
        foreach ($choice in [regex]::Matches($choices, '(?is)(?<name>[^()]+?)\s*\((?<source>[^)]+)\)')) {
            $name = (Strip-Html $choice.Groups['name'].Value) -replace '(?i)^or\s+', ''
            $sourceText = Strip-Html $choice.Groups['source'].Value
            if ($sourceText -match '(?i)^if\b') { continue }
            $matched = $false
            foreach ($candidate in @($catalog.byName[$name.ToLowerInvariant()])) {
                if ($catalog.itemSpecs[[int]$candidate.itemID] -notcontains $specID) { continue }
                if ($sourceText.IndexOf($candidate.source, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) { continue }
                $targets += [pscustomobject]@{ itemID = $candidate.itemID; slot = $slot; name = $candidate.name; source = $candidate.source }
                $matched = $true
            }
            if (-not $matched) {
                $sourceKey = Get-CatalogSourceKey (($sourceText -replace '(?i)\s+if\b.*$', '').Trim())
                $namedCandidates = @(
                    $catalog.byName[$name.ToLowerInvariant()] |
                    Where-Object {
                        $_ -and $catalog.itemSpecs[[int]$_.itemID] -contains $specID -and
                        (SourceNamesMatch $_.source $sourceText)
                    } |
                    Sort-Object itemID -Unique
                )
                foreach ($candidate in $namedCandidates) {
                    $targets += [pscustomobject]@{ itemID = $candidate.itemID; slot = $slot; name = $candidate.name; source = $candidate.source }
                    $matched = $true
                }
                $linkedID = Find-IcyItemIDByName $html $name
                if (-not $matched -and $linkedID -and $catalog.itemSpecs[$linkedID] -contains $specID) {
                    foreach ($candidateSource in @($catalog.byItemID[$linkedID])) {
                        if (SourceNamesMatch $candidateSource $sourceText) {
                            $targets += [pscustomobject]@{ itemID = $linkedID; slot = $slot; name = $name; source = $candidateSource }
                            $matched = $true
                        }
                    }
                }
            }
            if (-not $matched) { $unresolved += "${slot}: $name ($sourceText)" }
        }
    }
    return [pscustomobject]@{
        targets = @($targets | Sort-Object itemID, source -Unique)
        unresolved = @($unresolved | Sort-Object -Unique)
    }
}

function Get-PanelCatalystTargets([string] $panel, [object] $catalog, [int] $specID) {
    $targets = @()
    $unresolved = @()
    if (-not $panel) { return [pscustomobject]@{ targets = $targets; unresolved = $unresolved } }

    $answerPattern = '(?is)<details\b[^>]*>.*?<span class="faq-block__question">\s*Which\s+(?:Tier\s+Set\s+Pieces|Slots)\s+Do\s+I\s+Want(?:\s+Tier\s+Set\s+In|\s+(?:For|From)\s+[^?]+)?\?\s*</span>.*?<div class="faq-block__answer">(?<answer>.*?)</div>\s*</div>\s*</details>'
    foreach ($answerMatch in [regex]::Matches($panel, $answerPattern)) {
        $answer = $answerMatch.Groups['answer'].Value
        foreach ($lineMatch in [regex]::Matches($answerMatch.Groups['answer'].Value, '(?is)<li\b[^>]*>\s*<strong>\s*(?<slot>Helm|Head|Shoulders|Chest|Gloves|Hands|Legs)\s*</strong>\s*-\s*(?<body>.*?)</li>')) {
            $slot = Strip-Html $lineMatch.Groups['slot'].Value
            $body = $lineMatch.Groups['body'].Value
            $text = Strip-Html $body
            $sourceMatch = [regex]::Match($text, '\bfrom\s+(?<source>.+)$', 'IgnoreCase')
            if (-not $sourceMatch.Success) {
                $unresolved += "${slot}: $text"
                continue
            }
            $source = ResolveCatalogSource $sourceMatch.Groups['source'].Value $catalog
            $itemMatch = [regex]::Match($body, 'data-wowhead="item=(\d+)')
            if ($itemMatch.Success) {
                $nameMatch = [regex]::Match($body, 'class="q\d+">\s*([^<]+?)\s*</span>')
                if (-not $nameMatch.Success) { $nameMatch = [regex]::Match($body, 'alt="([^"]+) Icon"') }
                $targets += [pscustomobject]@{
                    itemID = [int]$itemMatch.Groups[1].Value
                    slot = $slot
                    name = Strip-Html $nameMatch.Groups[1].Value
                    source = $source
                }
                continue
            }
            if ($text -match '(?i)tier\s+token') {
                # Tier tokens are handled by the runtime's class-aware token
                # map. A representative token merely anchors the source here;
                # it must never be treated as a direct catalyst item.
                $tokenItemID = switch (Get-CatalogSourceKey $source) {
                    'entombed sentinels' { 270910 }
                    'lost explorers' { 270922 }
                    'vashnik the malignant' { 270926 }
                    'sszorak' { 270918 }
                    'twin fangs' { 270914 }
                }
                if ($tokenItemID) {
                    $targets += [pscustomobject]@{
                        itemID = $tokenItemID
                        slot = $slot
                        name = 'Tier token'
                        source = $source
                        tierToken = $true
                    }
                    continue
                }
            }
            $unresolved += "${slot}: $text"
        }

        # Some guides use <strong>Helm:</strong> item cards without repeating
        # the source. Their item IDs are sufficient only when the bundled
        # Season 2 catalog can supply a single eligible source for this spec.
        foreach ($cardMatch in [regex]::Matches($answer, '(?is)<li\b[^>]*>\s*<strong>\s*(?<slot>Helm|Head|Shoulders?|Chest|Gloves|Hands|Legs)\s*:\s*</strong>\s*(?<body>.*?)</li>')) {
            $slot = Strip-Html $cardMatch.Groups['slot'].Value
            $body = $cardMatch.Groups['body'].Value
            if ((Strip-Html $body) -match '(?i)no\s+good\s+choices|do\s+not\s+cataly[sz]e|offpiece') { continue }
            $itemMatch = [regex]::Match($body, 'data-wowhead="item=(\d+)')
            if (-not $itemMatch.Success) { continue }
            $itemID = [int]$itemMatch.Groups[1].Value
            if (-not ($catalog.itemSpecs[$itemID] -contains $specID)) { continue }
            $sources = @($catalog.byItemID[$itemID] | Sort-Object -Unique)
            if ($sources.Count -ne 1) { continue }
            $nameMatch = [regex]::Match($body, 'class="q\d+">\s*([^<]+?)\s*</span>')
            $targets += [pscustomobject]@{
                itemID = $itemID
                slot = $slot
                name = Strip-Html $nameMatch.Groups[1].Value
                source = $sources[0]
            }
        }

        # A number of healer and tank guides express the same recommendation
        # as a Slot / Item / Source table instead of a list.
        foreach ($rowMatch in [regex]::Matches($answer, '(?is)<tr\b[^>]*>\s*<td[^>]*>\s*(?<slot>Helm|Head|Shoulders?|Chest|Gloves|Hands|Legs)\s*</td>\s*<td[^>]*>(?<item>.*?)</td>\s*<td[^>]*>(?<source>.*?)</td>\s*</tr>')) {
            $slot = Strip-Html $rowMatch.Groups['slot'].Value
            $itemBody = $rowMatch.Groups['item'].Value
            if ((Strip-Html $itemBody) -match '(?i)tier\s+token|don''t\s+catalyst') { continue }
            $itemMatch = [regex]::Match($itemBody, 'data-wowhead="item=(\d+)')
            if (-not $itemMatch.Success) { continue }
            $itemID = [int]$itemMatch.Groups[1].Value
            if (-not ($catalog.itemSpecs[$itemID] -contains $specID)) { continue }
            $source = ResolveCatalogSource (Strip-Html $rowMatch.Groups['source'].Value) $catalog
            $nameMatch = [regex]::Match($itemBody, 'class="q\d+">\s*([^<]+?)\s*</span>')
            $targets += [pscustomobject]@{
                itemID = $itemID
                slot = $slot
                name = Strip-Html $nameMatch.Groups[1].Value
                source = $source
            }
        }

        # Other Icy Veins authors use prose rather than list markup, for
        # example "Helm: Gaze of the Coiled Watcher from Ula'tek". Resolve
        # those recommendations by source, tier slot, and current spec so the
        # generated record is still a real Voidcore-eligible item.
        $plainAnswer = Strip-Html $answer
        $prosePattern = '(?is)(?<slot>Helm|Head|Shoulders?|Chest|Gloves|Hands|Legs)\s*(?:—|-|:)\s*(?<body>.*?)(?=\s+(?:Helm|Head|Shoulders?|Chest|Gloves|Hands|Legs)\s*(?:—|-|:)|$)'
        foreach ($proseMatch in [regex]::Matches($plainAnswer, $prosePattern)) {
            $slot = $proseMatch.Groups['slot'].Value
            $body = $proseMatch.Groups['body'].Value
            $sourceMatch = [regex]::Match($body, '(?:\bfrom\s+|\()(?<source>[^.;()]+)\)?', 'IgnoreCase')
            if (-not $sourceMatch.Success) { continue }
            $source = ResolveCatalogSource $sourceMatch.Groups['source'].Value.Trim() $catalog
            $slotID = Get-GuideCatalystSlotID $slot
            foreach ($candidate in @(
                $catalog.bySourceSlot["$(Get-CatalogSourceKey $source)|$slotID"] |
                Where-Object { $_ -and $catalog.itemSpecs[[int]$_.itemID] -contains $specID } |
                Sort-Object itemID -Unique
            )) {
                if (-not $candidate) { continue }
                $targets += [pscustomobject]@{
                    itemID = [int]$candidate.itemID
                    slot = $slot
                    name = $candidate.name
                    source = $candidate.source
                }
            }
        }
    }
    return [pscustomobject]@{
        targets = @($targets | Sort-Object itemID, source -Unique)
        unresolved = @($unresolved | Sort-Object -Unique)
    }
}

function Get-StatPriority([string] $html) {
    $start = $html.IndexOf('class="stat-priority-widget"')
    if ($start -lt 0) {
        $heading = [regex]::Match($html, '<h2 id="[^"]*stat-priority[^"]*">.*?</h2>', "Singleline")
        if (-not $heading.Success) { return "" }
        $start = $heading.Index
        $window = $html.Substring($start, [Math]::Min(14000, $html.Length - $start))
        $ordered = [regex]::Match($window, '<ol>(.*?)</ol>', "Singleline")
        if ($ordered.Success) {
            $items = @()
            foreach ($item in [regex]::Matches($ordered.Groups[1].Value, '<li>\s*(.*?)\s*</li>', "Singleline")) {
                $value = Strip-Html $item.Groups[1].Value
                if ($value) { $items += $value }
            }
            if ($items.Count -gt 0) { return ($items -join " > ") }
        }
    } else {
        $window = $html.Substring($start, [Math]::Min(9000, $html.Length - $start))
    }
    $stats = @()
    foreach ($match in [regex]::Matches($window, '<div class="stat-name">\s*([^<]+?)\s*</div>')) {
        $name = (Strip-Html $match.Groups[1].Value)
        if ($name -and $stats -notcontains $name) { $stats += $name }
    }
    return ($stats -join " > ")
}

function Get-WowheadOverall([string] $html) {
    $start = $html.IndexOf('[tab name=\"Overall BiS\"')
    if ($start -lt 0) { $start = $html.IndexOf('[tab name="Overall BiS"') }
    if ($start -lt 0) { return @() }
    $end = $html.IndexOf('[/tab]', $start)
    if ($end -lt 0) { $end = $html.Length }
    $section = $html.Substring($start, $end - $start)
    $ids = @()
    foreach ($match in [regex]::Matches($section, '\[item=(\d+)')) {
        $id = [int] $match.Groups[1].Value
        if ($ids -notcontains $id) { $ids += $id }
    }
    return $ids
}

function Get-WowheadCatalystRequirements([string] $html, [object] $catalog) {
    $requirements = @()
    $unresolved = @()
    $heading = [regex]::Match($html, '(?is)<h3[^>]*>\s*Best\s+Gear\s+to\s+Catalyze\s+for\s+.*?</h3>')
    if (-not $heading.Success) {
        return [pscustomobject]@{ requirements = $requirements; unresolved = $unresolved }
    }
    $tail = $html.Substring($heading.Index + $heading.Length)
    $end = [regex]::Match($tail, '(?is)<h[23][^>]*>')
    $section = if ($end.Success) { $tail.Substring(0, $end.Index) } else { $tail }
    # Wowhead lists all five tier slots first, then gives an instruction for
    # each slot. Only entries explicitly beginning with "Catalyze" are
    # catalyst targets. The other instructions (for example "Use the natural
    # drop") identify tier tokens, not bonus-roll catalyst candidates.
    $plain = [System.Net.WebUtility]::HtmlDecode(($section -replace '<br\s*/?>', "`n" -replace '<[^>]+>', ' '))
    $lines = @($plain -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    $pairs = @()
    for ($index = 0; $index -lt ($lines.Count - 1); $index++) {
        if ($lines[$index] -notmatch '^(Head|Helm|Shoulder|Shoulders|Chest|Gloves|Hands|Legs)$') { continue }
        $pairs += [pscustomobject]@{
            slot = $lines[$index]
            source = ResolveCatalogSource $lines[$index + 1] $catalog
        }
        $index++
    }
    $instructions = @($lines | Where-Object { $_ -match '(?i)^Cataly[sz]e\b|^Use\s+(?:the\s+)?(?:natural|regular)' })
    for ($index = 0; $index -lt $pairs.Count; $index++) {
        if ($instructions[$index] -match '(?i)^Cataly[sz]e\b') {
            $requirements += $pairs[$index]
        }
    }
    return [pscustomobject]@{
        requirements = @($requirements | Sort-Object slot, source -Unique)
        unresolved = @($unresolved | Sort-Object -Unique)
    }
}

function Get-WowheadCatalystTargets([object[]] $requirements, [object] $catalog, [int] $specID) {
    $targets = @()
    $unresolved = @()
    foreach ($requirement in $requirements) {
        $sourceText = $requirement.source
        # Guides sometimes recommend an auction-house/raid-trash piece. It is
        # not a source-specific Voidcore reward and must not enter this pool.
        if ($sourceText -match '(?i)\b(?:boe|trash|world|craft)\b') { continue }
        $slotID = Get-GuideCatalystSlotID $requirement.slot
        $sourceKey = Get-CatalogSourceKey $sourceText
        $candidates = @(
            $catalog.bySourceSlot["$sourceKey|$slotID"] |
            Where-Object { $_ -and $catalog.itemSpecs[[int]$_.itemID] -contains $specID } |
            Sort-Object itemID -Unique
        )
        if ($candidates.Count -eq 1) {
            $candidate = $candidates[0]
            $targets += [pscustomobject]@{
                itemID = [int]$candidate.itemID
                slot = $requirement.slot
                name = $candidate.name
                source = $candidate.source
            }
        } elseif ($candidates.Count -eq 0) {
            $unresolved += "$($requirement.slot) from $sourceText"
        } else {
            $unresolved += "Ambiguous $($requirement.slot) from $sourceText"
        }
    }
    return [pscustomobject]@{
        targets = @($targets | Sort-Object itemID, source -Unique)
        unresolved = @($unresolved | Sort-Object -Unique)
    }
}

$records = @()
$failed = @()
$lootCatalog = Get-SeasonLootCatalog
foreach ($spec in $specs) {
    $gearSlug = "$($spec.specSlug)-$($spec.classSlug)-pve-$($spec.role)"
    $icyGearURL = "$baseIcy/$gearSlug-gear-best-in-slot"
    $icyStatURL = "$baseIcy/$gearSlug-stat-priority"
    $wowheadURL = "$baseWowhead/$($spec.classSlug)/$($spec.specSlug)/bis-gear"
    Write-Host "Scraping $($spec.specName) $($spec.className)..."
    try {
        $gear = Get-Page $icyGearURL
        $stat = Get-Page $icyStatURL
        $wowhead = Get-Page $wowheadURL
        $overallPanel = Get-IcyBisPanel $gear 0
        $dungeonsPanel = Get-IcyBisPanel $gear 1
        $raidsPanel = Get-IcyBisPanel $gear 2
        $overall = @(Get-IcyItems $(if ($overallPanel) { $overallPanel } else { Get-Section $gear @("overall-best-in-slot", "best-overall-best-in-slot", "overall-bis-list") }))
        $raids = @(Get-IcyItems $(if ($raidsPanel) { $raidsPanel } else { Get-Section $gear @("best-raid-gear", "raid-gear-bis-list", "raid-gear-best-in-slot") }))
        $dungeons = @(Get-IcyItems $(if ($dungeonsPanel) { $dungeonsPanel } else { Get-Section $gear @("best-mythic-gear", "mythic-gear-bis-list", "mythic-gear-best-in-slot") }))
        if ($overall.Count -eq 0) { throw "Icy Veins overall list was empty" }
        $crafted = @($overall | Where-Object { $_.source -match '(?i)crafted|blacksmithing|leatherworking|tailoring|engineering|jewelcrafting|inscription' } | Select-Object itemID, slot, name, source)
        $faqTargets = Get-GuideFAQCatalystTargets $gear $lootCatalog $spec.id
        $overallPanelTargets = Get-PanelCatalystTargets $overallPanel $lootCatalog $spec.id
        $raidPanelTargets = Get-PanelCatalystTargets $raidsPanel $lootCatalog $spec.id
        $dungeonPanelTargets = Get-PanelCatalystTargets $dungeonsPanel $lootCatalog $spec.id
        $wowheadCatalystRequirements = Get-WowheadCatalystRequirements $wowhead $lootCatalog
        $wowheadCatalystTargets = Get-WowheadCatalystTargets $wowheadCatalystRequirements.requirements $lootCatalog $spec.id
        $unresolved = @(
            $faqTargets.unresolved +
            $overallPanelTargets.unresolved +
            $raidPanelTargets.unresolved +
            $dungeonPanelTargets.unresolved +
            $wowheadCatalystRequirements.unresolved |
            Sort-Object -Unique
        )
        $unresolved += $wowheadCatalystTargets.unresolved
        if ($unresolved.Count -gt 0) {
            throw ("Unresolved catalyst target(s): " + ($unresolved -join "; "))
        }
        $faqCatalyst = @(
            (Get-IcyCatalystTargets $gear) +
            $faqTargets.targets +
            $overallPanelTargets.targets +
            $wowheadCatalystTargets.targets
            | Where-Object { $_.itemID -and $_.source }
            | Sort-Object itemID, source -Unique
        )
        $raidFaqCatalyst = @(
            $faqCatalyst + $raidPanelTargets.targets |
            Where-Object { IsRaidCatalogSource $_.source } |
            Sort-Object itemID, source -Unique
        )
        $dungeonFaqCatalyst = @(
            $faqCatalyst + $dungeonPanelTargets.targets |
            Where-Object { -not (IsRaidCatalogSource $_.source) } |
            Sort-Object itemID, source -Unique
        )
        $cardOverallCatalyst = @(Get-CardCatalystTargets $overall $lootCatalog $spec.id)
        $cardRaidCatalyst = @(Get-CardCatalystTargets $raids $lootCatalog $spec.id)
        $cardDungeonCatalyst = @(Get-CardCatalystTargets $dungeons $lootCatalog $spec.id)
        $catalyst = [pscustomobject]@{
            overall = @(
                $faqCatalyst + $cardOverallCatalyst
                | Sort-Object itemID, source -Unique
            )
            raids = @(
                $raidFaqCatalyst + $cardRaidCatalyst
                | Sort-Object itemID, source -Unique
            )
            dungeons = @(
                $dungeonFaqCatalyst + $cardDungeonCatalyst
                | Sort-Object itemID, source -Unique
            )
        }
        foreach ($mode in @("overall", "raids", "dungeons")) {
            $catalyst.$mode = @(
                $catalyst.$mode |
                Where-Object { -not $lootCatalog.excludedItemIDs.ContainsKey([int]$_.itemID) } |
                ForEach-Object {
                    [pscustomobject]@{
                        itemID = $_.itemID
                        slot = $_.slot
                        name = $_.name
                        source = $_.source
                        tierToken = $_.tierToken -or $lootCatalog.tierTokenIDs.ContainsKey([int]$_.itemID)
                    }
                } |
                Sort-Object itemID, source -Unique
            )
        }
        Assert-CatalystTargets $catalyst.overall $lootCatalog $spec.id "$($spec.specName) $($spec.className) overall"
        Assert-CatalystTargets $catalyst.raids $lootCatalog $spec.id "$($spec.specName) $($spec.className) raids"
        Assert-CatalystTargets $catalyst.dungeons $lootCatalog $spec.id "$($spec.specName) $($spec.className) dungeons"
        $records += [pscustomobject]@{
            id = $spec.id
            name = "$($spec.specName) $($spec.className)"
            statPriority = Get-StatPriority $stat
            statURL = $icyStatURL
            icyVeinsURL = $icyGearURL
            wowheadURL = $wowheadURL
            overall = $overall
            raids = $raids
            dungeons = $dungeons
            crafted = $crafted
            catalyst = $catalyst
            wowheadOverall = @(Get-WowheadOverall $wowhead)
        }
    } catch {
        $failed += "$($spec.id): $($_.Exception.Message)"
    }
}

if ($failed.Count -gt 0) {
    throw ("Scrape failed:`n" + ($failed -join "`n"))
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("-- Generated by tools/Update-BISData.ps1. Do not edit by hand.")
$lines.Add("-- Sources: Icy Veins and Wowhead, $SeasonLabel (Patch $PatchLabel).")
$lines.Add("OakBonusPlannerBIS = OakBonusPlannerBIS or {}")
$quote = [char]34
$lines.Add("OakBonusPlannerBIS.patch = $quote$(Escape-Lua $PatchLabel)$quote")
$lines.Add("OakBonusPlannerBIS.season = $quote$(Escape-Lua $SeasonLabel)$quote")
$lines.Add("OakBonusPlannerBIS.generatedAt = `"$(Get-Date -Format yyyy-MM-dd)`"")
$lines.Add("OakBonusPlannerBIS.Specs = {")
foreach ($record in ($records | Sort-Object id)) {
    $lines.Add("    [$($record.id)] = {")
    $lines.Add("        name = `"$(Escape-Lua $record.name)`",")
    $lines.Add("        statPriority = `"$(Escape-Lua $record.statPriority)`",")
    $lines.Add("        statURL = `"$(Escape-Lua $record.statURL)`",")
    $lines.Add("        icyVeinsURL = `"$(Escape-Lua $record.icyVeinsURL)`",")
    $lines.Add("        wowheadURL = `"$(Escape-Lua $record.wowheadURL)`",")
    foreach ($mode in @("overall", "raids", "dungeons")) {
        $lines.Add("        $mode = {")
        foreach ($item in ($record.$mode | Sort-Object itemID -Unique)) {
            $lines.Add("            { itemID = $($item.itemID), slot = `"$(Escape-Lua $item.slot)`", name = `"$(Escape-Lua $item.name)`", source = `"$(Escape-Lua $item.source)`" },")
        }
        $lines.Add("        },")
    }
    $lines.Add("        crafted = {")
    foreach ($item in ($record.crafted | Sort-Object itemID -Unique)) {
        $lines.Add("            { itemID = $($item.itemID), slot = `"$(Escape-Lua $item.slot)`", name = `"$(Escape-Lua $item.name)`", source = `"$(Escape-Lua $item.source)`" },")
    }
    $lines.Add("        },")
    $lines.Add("        catalyst = {")
    foreach ($mode in @("overall", "raids", "dungeons")) {
        $lines.Add("            $mode = {")
        foreach ($item in ($record.catalyst.$mode | Where-Object { $_.itemID -and $_.source } | Sort-Object itemID, source -Unique)) {
            $tierToken = if ($item.tierToken) { ", tierToken = true" } else { "" }
            $lines.Add("                { itemID = $($item.itemID), slot = `"$(Escape-Lua $item.slot)`", name = `"$(Escape-Lua $item.name)`", source = `"$(Escape-Lua $item.source)`"$tierToken },")
        }
        $lines.Add("            },")
    }
    $lines.Add("        },")
    $lines.Add("        wowheadOverall = {")
    foreach ($itemID in ($record.wowheadOverall | Sort-Object -Unique)) { $lines.Add("            $itemID,") }
    $lines.Add("        },")
    $lines.Add("    },")
}
$lines.Add("}")

$encoding = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($output, ($lines -join "`r`n") + "`r`n", $encoding)
Write-Host "Wrote $output ($($records.Count) specs)."
