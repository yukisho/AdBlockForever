[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Destination = (Join-Path (Split-Path -Parent $PSScriptRoot) "AdBlockForever"),
    [switch]$Package,
    [switch]$ValidateOnly,
    [switch]$AllowDirtyDestination
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-FullPath {
    param([Parameter(Mandatory)][string]$Path)
    return [System.IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
}

function Get-ManifestEntries {
    param([Parameter(Mandatory)][string]$ManifestPath)

    $entries = [System.Collections.Generic.List[string]]::new()
    foreach ($line in Get-Content -LiteralPath $ManifestPath) {
        $entry = $line.Trim().Replace('\', '/')
        if ($entry.Length -eq 0 -or $entry.StartsWith('#')) {
            continue
        }
        if ([System.IO.Path]::IsPathRooted($entry) -or $entry -match '(^|/)\.\.(/|$)') {
            throw "Unsafe release-manifest entry: $entry"
        }
        if (-not $entries.Contains($entry)) {
            $entries.Add($entry)
        }
    }
    return $entries
}

function Assert-CleanGitWorktree {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath (Join-Path $Path '.git'))) {
        return
    }
    $status = & git -C $Path status --porcelain 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Could not inspect the destination Git worktree: $status"
    }
    if ($status) {
        throw "The public worktree has uncommitted changes. Commit or stash them, or rerun with -AllowDirtyDestination after reviewing the risk."
    }
}

function Assert-Toc {
    param(
        [Parameter(Mandatory)][string]$TocPath,
        [Parameter(Mandatory)][string]$SourceRoot
    )

    $tocName = Split-Path -Leaf $TocPath
    $toc = Get-Content -Raw -LiteralPath $TocPath
    foreach ($required in @('## Interface:', '## Title:', '## Version:', '## SavedVariables:')) {
        if ($toc -notmatch "(?m)^$([regex]::Escape($required))") {
            throw "$tocName is missing required metadata: $required"
        }
    }

    foreach ($line in Get-Content -LiteralPath $TocPath) {
        $reference = $line.Trim()
        if ($reference.Length -eq 0 -or $reference.StartsWith('#')) {
            continue
        }
        $referencedPath = Join-Path $SourceRoot $reference
        if (-not (Test-Path -LiteralPath $referencedPath -PathType Leaf)) {
            throw "TOC references a missing file: $reference"
        }
    }
}

function Test-LuaSyntax {
    param(
        [Parameter(Mandatory)][string[]]$Entries,
        [Parameter(Mandatory)][string]$SourceRoot
    )

    $luac = Get-Command luac -ErrorAction SilentlyContinue
    if (-not $luac) {
        Write-Host "Lua syntax: skipped (luac is not installed)." -ForegroundColor DarkYellow
        return
    }

    foreach ($entry in $Entries) {
        if ([System.IO.Path]::GetExtension($entry) -ne '.lua') {
            continue
        }
        & $luac.Source -p (Join-Path $SourceRoot $entry)
        if ($LASTEXITCODE -ne 0) {
            throw "Lua syntax validation failed: $entry"
        }
    }
    Write-Host "Lua syntax: passed." -ForegroundColor Green
}

function Test-RegressionSuite {
    param([Parameter(Mandatory)][string]$SourceRoot)

    $runtime = Get-Command lua -ErrorAction SilentlyContinue
    if (-not $runtime) {
        $runtime = Get-Command luajit -ErrorAction SilentlyContinue
    }
    if (-not $runtime) {
        Write-Host "Regression suite: skipped (lua/luajit is not installed)." -ForegroundColor DarkYellow
        return
    }

    Push-Location $SourceRoot
    try {
        & $runtime.Source (Join-Path $SourceRoot 'Tests\run.lua')
        if ($LASTEXITCODE -ne 0) {
            throw 'AdBlock Forever regression suite failed.'
        }
    }
    finally {
        Pop-Location
    }
    Write-Host "Regression suite: passed." -ForegroundColor Green
}

$sourceRoot = Get-FullPath $PSScriptRoot
$destinationRoot = Get-FullPath $Destination
$expectedDestination = Get-FullPath (Join-Path (Split-Path -Parent $sourceRoot) 'AdBlockForever')
$manifestPath = Join-Path $sourceRoot 'release-manifest.txt'
$tocPath = Join-Path $sourceRoot 'AdBlockForever.toc'
$developmentTocPath = Join-Path $sourceRoot 'AdBlockForeverDev.toc'
$obsoleteReleaseFiles = @('UI.lua', 'Advanced.lua', 'BlockedLog.lua')

if ($destinationRoot -ne $expectedDestination) {
    throw "For safety, the destination must be the sibling AdBlockForever folder: $expectedDestination"
}
if ($destinationRoot -eq $sourceRoot) {
    throw 'The source and destination folders cannot be the same.'
}
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw 'release-manifest.txt was not found.'
}

$entries = @(Get-ManifestEntries -ManifestPath $manifestPath)
if ($entries.Count -eq 0) {
    throw 'release-manifest.txt contains no release files.'
}
foreach ($requiredEntry in @('AdBlockForever.toc', 'Core.lua', 'Core/Classifier.lua', 'UI/MainWindow.lua')) {
    if ($entries -notcontains $requiredEntry) {
        throw "The release manifest must include $requiredEntry."
    }
}
foreach ($entry in $entries) {
    if ($entry -match '^(DevTools|Tests|Releases)(/|$)' -or $entry -match '(^|/)Build-Release\.ps1$') {
        throw "Development-only path cannot be included in a release: $entry"
    }
    $sourcePath = Join-Path $sourceRoot $entry
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Release file does not exist: $entry"
    }
}

Assert-Toc -TocPath $tocPath -SourceRoot $sourceRoot
Assert-Toc -TocPath $developmentTocPath -SourceRoot $sourceRoot
Test-LuaSyntax -Entries $entries -SourceRoot $sourceRoot
Test-RegressionSuite -SourceRoot $sourceRoot

$versionLine = Select-String -LiteralPath $tocPath -Pattern '^## Version:\s*(.+?)\s*$' | Select-Object -First 1
$version = $versionLine.Matches[0].Groups[1].Value
Write-Host "Validated AdBlock Forever $version with $($entries.Count) release files." -ForegroundColor Green

if ($ValidateOnly) {
    return
}

if ((Test-Path -LiteralPath $destinationRoot) -and -not $AllowDirtyDestination) {
    Assert-CleanGitWorktree -Path $destinationRoot
}
if (-not (Test-Path -LiteralPath $destinationRoot)) {
    New-Item -ItemType Directory -Path $destinationRoot | Out-Null
}

$stageRoot = Join-Path $sourceRoot '.release-staging'
$stageAddon = Join-Path $stageRoot 'AdBlockForever'
if (Test-Path -LiteralPath $stageRoot) {
    Remove-Item -LiteralPath $stageRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $stageAddon -Force | Out-Null

try {
    foreach ($entry in $entries) {
        $sourcePath = Join-Path $sourceRoot $entry
        $stagedPath = Join-Path $stageAddon $entry
        $stagedParent = Split-Path -Parent $stagedPath
        if (-not (Test-Path -LiteralPath $stagedParent)) {
            New-Item -ItemType Directory -Path $stagedParent -Force | Out-Null
        }
        Copy-Item -LiteralPath $sourcePath -Destination $stagedPath -Force
    }

    if ($PSCmdlet.ShouldProcess($destinationRoot, "copy $($entries.Count) approved release files")) {
        foreach ($entry in $entries) {
            $stagedPath = Join-Path $stageAddon $entry
            $destinationPath = Join-Path $destinationRoot $entry
            $destinationParent = Split-Path -Parent $destinationPath
            if (-not (Test-Path -LiteralPath $destinationParent)) {
                New-Item -ItemType Directory -Path $destinationParent -Force | Out-Null
            }
            Copy-Item -LiteralPath $stagedPath -Destination $destinationPath -Force
        }
        foreach ($obsoleteEntry in $obsoleteReleaseFiles) {
            $obsoletePath = Join-Path $destinationRoot $obsoleteEntry
            if (Test-Path -LiteralPath $obsoletePath -PathType Leaf) {
                Remove-Item -LiteralPath $obsoletePath -Force
            }
        }
        Write-Host "Promoted approved files to $destinationRoot" -ForegroundColor Green
    }

    if ($Package) {
        $releaseDirectory = Join-Path $sourceRoot 'Releases'
        $archivePath = Join-Path $releaseDirectory "AdBlockForever-$version.zip"
        if (-not (Test-Path -LiteralPath $releaseDirectory)) {
            New-Item -ItemType Directory -Path $releaseDirectory -Force | Out-Null
        }
        if (Test-Path -LiteralPath $archivePath) {
            Remove-Item -LiteralPath $archivePath -Force
        }
        Compress-Archive -LiteralPath $stageAddon -DestinationPath $archivePath -CompressionLevel Optimal
        Write-Host "Created $archivePath" -ForegroundColor Green
    }
}
finally {
    if (Test-Path -LiteralPath $stageRoot) {
        Remove-Item -LiteralPath $stageRoot -Recurse -Force
    }
}
