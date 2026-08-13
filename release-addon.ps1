param(
    [Parameter(Mandatory = $true)]
    [string]$Version,

    [Parameter(Mandatory = $true)]
    [string[]]$Notes,

    [string]$CommitMessage,
    [switch]$SkipZip
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-Git {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)

    & git @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Git command failed: git $($Arguments -join ' ')"
    }
}

function Write-Utf8NoBom {
    param([Parameter(Mandatory = $true)][string]$Path, [Parameter(Mandatory = $true)][string]$Content)

    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Update-FirstMatch {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string]$Replacement
    )

    $content = [System.IO.File]::ReadAllText($Path, [System.Text.UTF8Encoding]::new($false, $true))
    $updated = [regex]::Replace($content, $Pattern, $Replacement, 1)
    if ($updated -eq $content) {
        throw "Expected version declaration was not found in '$Path'."
    }
    Write-Utf8NoBom -Path $Path -Content $updated
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -LiteralPath $scriptDir

$normalizedVersion = $Version.Trim().TrimStart([char[]]@('v', 'V'))
if ([string]::IsNullOrWhiteSpace($normalizedVersion)) {
    throw "Version cannot be empty."
}
$tagName = "v$normalizedVersion"
if (-not $CommitMessage) {
    $CommitMessage = "Release $tagName"
}

$status = @(git status --porcelain)
if ($LASTEXITCODE -ne 0) {
    throw "Could not read git status."
}
if ($status.Count -gt 0) {
    throw "Git working tree is not clean. Commit or stash changes before running release-addon.ps1."
}
if ((git tag --list $tagName)) {
    throw "Tag '$tagName' already exists."
}

& (Join-Path $scriptDir "sync-patreon-supporters.ps1")
if ($LASTEXITCODE -ne 0) {
    throw "sync-patreon-supporters.ps1 failed."
}

$notes = @($Notes | ForEach-Object { $_.Trim().TrimStart('-', '*', ' ') } | Where-Object { $_ })
if ($notes.Count -eq 0) {
    throw "Provide at least one release note."
}

$changelogPath = Join-Path $scriptDir "CHANGELOG.md"
$existing = [System.IO.File]::ReadAllText($changelogPath, [System.Text.UTF8Encoding]::new($false, $true)).Trim()
if ($existing -match "(?m)^## v$([regex]::Escape($normalizedVersion))$") {
    throw "CHANGELOG.md already has an entry for '$tagName'."
}
$entry = "## $tagName`r`n`r`n" + (($notes | ForEach-Object { "- $_" }) -join "`r`n")
Write-Utf8NoBom -Path $changelogPath -Content ($existing.Insert(0, "$entry`r`n`r`n") + "`r`n")
Update-FirstMatch -Path (Join-Path $scriptDir "OakBonusPlanner.toc") -Pattern '(?m)^## Version:\s*.+$' -Replacement "## Version: $normalizedVersion"

Invoke-Git -Arguments @("add", "CHANGELOG.md", "OakBonusPlanner.toc", "Supporters.lua", "sync-patreon-supporters.ps1", "release-addon.ps1", ".pkgmeta", "package-release.ps1", ".github/workflows/publish-release.yml")
Invoke-Git -Arguments @("commit", "-m", $CommitMessage)
Invoke-Git -Arguments @("tag", "-a", $tagName, "-m", $tagName)
Invoke-Git -Arguments @("push", "origin", "main")
Invoke-Git -Arguments @("push", "origin", $tagName)

if (-not $SkipZip) {
    & (Join-Path $scriptDir "package-release.ps1") -Version $normalizedVersion
    if ($LASTEXITCODE -ne 0) {
        throw "package-release.ps1 failed."
    }
}

Write-Host "Release complete: $tagName"
Write-Host "The tag triggers GitHub, CurseForge, and Wago publication when CF_API_TOKEN and WAGO_API_TOKEN are configured as repository secrets."
