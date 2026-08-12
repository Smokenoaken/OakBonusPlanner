param(
    [string]$Version
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$addonRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$addonName = Split-Path -Leaf $addonRoot
$tocPath = Join-Path $addonRoot "$addonName.toc"

if (-not $Version) {
    $versionLine = Select-String -Path $tocPath -Pattern '^## Version:\s*(.+)$' | Select-Object -First 1
    if (-not $versionLine) { throw "Could not determine the addon's TOC version." }
    $Version = $versionLine.Matches[0].Groups[1].Value.Trim()
}

$distPath = Join-Path $addonRoot "dist"
New-Item -ItemType Directory -Force -Path $distPath | Out-Null
$zipPath = Join-Path $distPath "$addonName-v$Version.zip"
if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }

$excludedRootNames = @(".git", "dist", "tools")
$excludedFiles = @(".gitignore", "CHANGELOG.md", "README.md", "package-release.ps1")
$zip = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)

try {
    Get-ChildItem -LiteralPath $addonRoot -Recurse -File | Where-Object {
        $relative = $_.FullName.Substring($addonRoot.Length).TrimStart('\')
        $parts = $relative -split '[\\/]'
        -not ($excludedRootNames -contains $parts[0]) -and -not ($excludedFiles -contains $relative)
    } | ForEach-Object {
        $relative = $_.FullName.Substring($addonRoot.Length).TrimStart('\')
        $entryName = ($addonName + "\\" + $relative).Replace("\\", "/")
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $zip, $_.FullName, $entryName, [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
    }
}
finally {
    $zip.Dispose()
}

Write-Host $zipPath
