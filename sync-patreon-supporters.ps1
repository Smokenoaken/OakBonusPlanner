$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Get-ConfiguredValue {
    param([Parameter(Mandatory = $true)][string]$Name)

    $value = [Environment]::GetEnvironmentVariable($Name, "Process")
    if ([string]::IsNullOrWhiteSpace($value)) {
        $value = [Environment]::GetEnvironmentVariable($Name, "User")
    }
    return $value
}

function Escape-LuaString {
    param([Parameter(Mandatory = $true)][string]$Value)

    if ($Value -match '[\x00-\x1F]') {
        throw "Patreon supporter name contains a control character: '$Value'."
    }
    return $Value.Replace('\', '\\').Replace('"', '\"')
}

function Update-LuaStringList {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string[]]$Names
    )

    $content = [System.IO.File]::ReadAllText($Path, [System.Text.UTF8Encoding]::new($false, $true))
    $declaration = "addonTable.Patreons = {"
    $start = $content.IndexOf($declaration, [System.StringComparison]::Ordinal)
    if ($start -lt 0) { throw "Could not find '$declaration' in '$Path'." }

    $bodyStart = $content.IndexOf("`n", $start) + 1
    $closingMatch = [regex]::Match($content.Substring($bodyStart), '(?m)^[ \t]*\}')
    if (-not $closingMatch.Success) { throw "Could not find the supporter-list closing brace in '$Path'." }

    $newline = if ($content.Contains("`r`n")) { "`r`n" } else { "`n" }
    $lines = foreach ($name in $Names) { '    "' + (Escape-LuaString -Value $name) + '",' }
    $replacement = $declaration + $newline + ($lines -join $newline) + $newline + '}'
    $updated = $content.Substring(0, $start) + $replacement + $content.Substring($bodyStart + $closingMatch.Index + $closingMatch.Length)
    if ($updated -ne $content) {
        [System.IO.File]::WriteAllText($Path, $updated, [System.Text.UTF8Encoding]::new($false))
        return $true
    }
    return $false
}

$accessToken = Get-ConfiguredValue -Name "OAKUI_PATREON_ACCESS_TOKEN"
$campaignId = Get-ConfiguredValue -Name "OAKUI_PATREON_CAMPAIGN_ID"
if ([string]::IsNullOrWhiteSpace($accessToken)) { throw "OAKUI_PATREON_ACCESS_TOKEN is not configured." }
if ([string]::IsNullOrWhiteSpace($campaignId)) { throw "OAKUI_PATREON_CAMPAIGN_ID is not configured." }

$baseUrl = "https://www.patreon.com/api/oauth2/v2/campaigns/$campaignId/members?page%5Bcount%5D=100&fields%5Bmember%5D=full_name,patron_status,currently_entitled_amount_cents,pledge_relationship_start"
$nextUrl = $baseUrl
$members = [System.Collections.Generic.List[object]]::new()
do {
    $page = Invoke-RestMethod -Uri $nextUrl -Headers @{ Authorization = "Bearer $accessToken" } -Method Get
    foreach ($member in @($page.data)) { [void]$members.Add($member) }

    $nextUrl = $null
    if ($page.PSObject.Properties.Name -contains "links" -and $page.links -and $page.links.PSObject.Properties.Name -contains "next" -and $page.links.next) {
        $nextUrl = [string]$page.links.next
    }
    if (-not $nextUrl -and $page.PSObject.Properties.Name -contains "meta" -and $page.meta -and $page.meta.PSObject.Properties.Name -contains "pagination" -and $page.meta.pagination -and $page.meta.pagination.PSObject.Properties.Name -contains "cursors" -and $page.meta.pagination.cursors -and $page.meta.pagination.cursors.PSObject.Properties.Name -contains "next" -and $page.meta.pagination.cursors.next) {
        $nextUrl = "$baseUrl&page%5Bcursor%5D=$([uri]::EscapeDataString([string]$page.meta.pagination.cursors.next))"
    }
} while ($nextUrl)

$names = @($members | Where-Object {
    $attributes = $_.attributes
    $attributes -and $attributes.patron_status -eq "active_patron" -and [int64]$attributes.currently_entitled_amount_cents -gt 0 -and -not [string]::IsNullOrWhiteSpace([string]$attributes.full_name) -and -not [string]::IsNullOrWhiteSpace([string]$attributes.pledge_relationship_start)
} | Sort-Object @{ Expression = { [datetime]$_.attributes.pledge_relationship_start } }, @{ Expression = { [string]$_.attributes.full_name } } | ForEach-Object { ([string]$_.attributes.full_name).Trim() })

if ($names.Count -eq 0) { throw "Patreon returned no eligible active paid members; refusing to erase the existing supporter list." }

$supportersPath = Join-Path $PSScriptRoot "Supporters.lua"
if (Update-LuaStringList -Path $supportersPath -Names $names) {
    Write-Host "Updated Supporters.lua with $($names.Count) active paid Patreon supporters."
} else {
    Write-Host "Supporters.lua already contains the current $($names.Count)-member Patreon list."
}
