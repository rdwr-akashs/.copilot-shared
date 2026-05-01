<#
.SYNOPSIS
    Extracts RCA-critical files from a DefenseFlow / Vision support bundle.
    Default mode reads the zip index and decompresses only the files that matter
    for RCA — pulling ~10-50 MB from a 4-5 GB bundle in seconds.

.DESCRIPTION
    Two modes:
      Smart (default) — reads the zip central directory without decompressing,
        matches paths against the RCA-critical pattern list, extracts only matches.
        Handles nested zips up to 3 levels deep.
      Full (-Full)    — recursive full extraction of everything. Use when smart
        mode misses something or the bundle has an unusual layout.

.PARAMETER Bundle
    Path to the top-level support bundle directory, .zip, .tar.gz, or .tgz.

.PARAMETER OutDir
    Destination directory. Defaults to <bundle-name>_extracted next to the bundle.

.PARAMETER Full
    Switch. Extract all files instead of just RCA-critical ones.

.PARAMETER MaxDepth
    How many levels of nested zips to recurse into. Default: 3.

.EXAMPLE
    .\extract-support-bundle.ps1 -Bundle C:\cases\SC-12345\bundle.zip
    .\extract-support-bundle.ps1 -Bundle C:\cases\SC-12345\bundle.zip -Full
    .\extract-support-bundle.ps1 -Bundle C:\cases\SC-12345\ -OutDir C:\cases\SC-12345\extracted
#>

param(
    [Parameter(Mandatory)][string]$Bundle,
    [string]$OutDir,
    [switch]$Full,
    [int]$MaxDepth = 3
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# RCA-critical path patterns (regex, matched against zip entry full path).
# Covers: version, HA, BGP, PostgreSQL replication, logs, containers, time.
# Add patterns here when new RCA evidence sources are discovered.
# ---------------------------------------------------------------------------
$RCA_PATTERNS = @(
    # System identity & version
    'cli[/\\]system_info\.txt',
    'vision_version\.txt',
    # HA and failover
    'cli[/\\]ha_list\.txt',
    'logs[/\\]ha\.log',
    # BGP
    'cli[/\\]bgp_peers\.txt',
    'bgp[/\\]etc[/\\]exabgp\.conf',
    # PostgreSQL replication
    'postgresql[/\\]config[/\\]pg_hba\.conf',
    'postgresql[/\\]config[/\\]recovery\.conf',
    'postgresql[/\\]config[/\\]recovery\.conf\.orig',
    # Core logs
    'logs[/\\]one\.line\.problems\.log',
    'logs[/\\]rest\.short\.log',
    'logs[/\\]df\.log',
    'logs[/\\]war-room\.log',
    # Container health
    'containers_list\.txt',
    # NTP / clock skew
    'time\.txt',
    # Network
    'cli[/\\]network\.txt',
    'cli[/\\]interfaces\.txt',
    # Vision connectivity
    'vision[/\\]',
    # Standby subtree (same patterns inside standby_support/)
    'standby_support[/\\]'
)

# Compile to a single alternation regex for fast matching
$patternRegex = '(?i)(' + ($RCA_PATTERNS -join '|') + ')'

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Resolve-Bundle {
    param([string]$path)
    if (-not (Test-Path $path)) { throw "Bundle not found: $path" }
    return (Resolve-Path $path).Path
}

function Get-DefaultOutDir {
    param([string]$bundlePath)
    $parent = Split-Path $bundlePath -Parent
    $name   = [System.IO.Path]::GetFileNameWithoutExtension($bundlePath)
    # Strip extra extensions (.tar.gz -> strip .gz then .tar)
    $name   = [System.IO.Path]::GetFileNameWithoutExtension($name)
    return Join-Path $parent ($name + '_extracted')
}

function Expand-SmartZip {
    param(
        [string]$zipPath,
        [string]$destRoot,
        [int]$depth
    )
    if ($depth -le 0) {
        Write-Host "  [skip] max depth reached: $zipPath" -ForegroundColor DarkGray
        return
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    try {
        $matched = 0
        $nested  = @()

        foreach ($entry in $archive.Entries) {
            if ($entry.FullName.EndsWith('/')) { continue }  # directory entry

            $isRca    = $entry.FullName -match $patternRegex
            $isZip    = $entry.FullName -match '\.(zip|tar\.gz|tgz)$'
            $isNestedZip = $isZip -and ($depth -gt 1)

            if (-not $isRca -and -not $isNestedZip) { continue }

            $destFile = Join-Path $destRoot $entry.FullName.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
            $destDir  = Split-Path $destFile -Parent
            if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }

            if (-not (Test-Path $destFile)) {
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destFile)
                if ($isRca) {
                    $matched++
                    Write-Host "  [smart] $($entry.FullName)" -ForegroundColor DarkGreen
                }
            }

            if ($isNestedZip) {
                $nested += $destFile
            }
        }

        Write-Host "  -> $matched RCA files extracted from $(Split-Path $zipPath -Leaf)" -ForegroundColor Cyan

        # Recurse into nested zips
        foreach ($nestedZip in $nested) {
            $nestedDest = $nestedZip -replace '\.(zip|tar\.gz|tgz)$', '_extracted'
            New-Item -ItemType Directory -Path $nestedDest -Force | Out-Null
            Write-Host "`n  [nested] $(Split-Path $nestedZip -Leaf)" -ForegroundColor Yellow
            Expand-SmartZip -zipPath $nestedZip -destRoot $nestedDest -depth ($depth - 1)
        }
    }
    finally {
        $archive.Dispose()
    }
}

function Expand-FullZip {
    param([string]$zipPath, [string]$destRoot, [int]$depth)
    if ($depth -le 0) { return }

    Write-Host "  [full] extracting $(Split-Path $zipPath -Leaf) ..." -ForegroundColor Yellow
    Expand-Archive -LiteralPath $zipPath -DestinationPath $destRoot -Force

    # Recurse into any nested zips found after extraction
    Get-ChildItem -Path $destRoot -Recurse -File -Include '*.zip' | ForEach-Object {
        $nestedDest = $_.FullName -replace '\.zip$', '_extracted'
        if (-not (Test-Path $nestedDest)) {
            New-Item -ItemType Directory -Path $nestedDest -Force | Out-Null
            Expand-FullZip -zipPath $_.FullName -destRoot $nestedDest -depth ($depth - 1)
        }
    }

    # Handle .tar.gz / .tgz
    Get-ChildItem -Path $destRoot -Recurse -File | Where-Object { $_.Name -match '\.tar\.gz$|\.tgz$' } | ForEach-Object {
        $nestedDest = $_.FullName -replace '\.(tar\.gz|tgz)$', '_extracted'
        if (-not (Test-Path $nestedDest)) {
            New-Item -ItemType Directory -Path $nestedDest -Force | Out-Null
            tar -xzf $_.FullName -C $nestedDest
        }
    }

    # Decompress single .gz files in place
    Get-ChildItem -Path $destRoot -Recurse -File -Filter '*.gz' |
        Where-Object { $_.Name -notmatch '\.tar\.gz$' } | ForEach-Object {
            $out = $_.FullName -replace '\.gz$', ''
            if (-not (Test-Path $out)) {
                $in  = [System.IO.File]::OpenRead($_.FullName)
                $gz  = New-Object System.IO.Compression.GzipStream($in, [System.IO.Compression.CompressionMode]::Decompress)
                $outStream = [System.IO.File]::Create($out)
                $gz.CopyTo($outStream)
                $outStream.Close(); $gz.Close(); $in.Close()
            }
        }
}

function Expand-TarGz {
    param([string]$tarPath, [string]$destRoot)
    New-Item -ItemType Directory -Path $destRoot -Force | Out-Null
    & tar -xzf $tarPath -C $destRoot
    if ($LASTEXITCODE -ne 0) { throw "tar failed on: $tarPath" }
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

$bundlePath = Resolve-Bundle $Bundle

if (-not $OutDir) {
    $OutDir = Get-DefaultOutDir $bundlePath
}
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

$mode = if ($Full) { 'FULL' } else { 'SMART' }
Write-Host "`nextract-support-bundle  [$mode mode]" -ForegroundColor White
Write-Host "  bundle : $bundlePath"
Write-Host "  output : $OutDir"
Write-Host "  depth  : $MaxDepth"
Write-Host ""

# Case 1: input is a directory — find the top-level archive(s) inside it
if ((Get-Item $bundlePath).PSIsContainer) {
    $archives = Get-ChildItem -Path $bundlePath -File |
        Where-Object { $_.Name -match '\.(zip|tar\.gz|tgz)$' }

    if (-not $archives) {
        # Already extracted directory — treat as output root and scan for nested
        Write-Host "  [info] directory with no top-level archive — scanning for nested archives" -ForegroundColor Cyan
        if ($Full) {
            # Decompress any gz logs in place
            Get-ChildItem -Path $bundlePath -Recurse -File -Filter '*.gz' |
                Where-Object { $_.Name -notmatch '\.tar\.gz$' } | ForEach-Object {
                    $out = $_.FullName -replace '\.gz$', ''
                    if (-not (Test-Path $out)) {
                        $in  = [System.IO.File]::OpenRead($_.FullName)
                        $gz  = New-Object System.IO.Compression.GzipStream($in, [System.IO.Compression.CompressionMode]::Decompress)
                        $outStream = [System.IO.File]::Create($out)
                        $gz.CopyTo($outStream); $outStream.Close(); $gz.Close(); $in.Close()
                        Write-Host "  [gz] $($_.Name)" -ForegroundColor DarkGreen
                    }
                }
        }
    } else {
        foreach ($arc in $archives) {
            $arcDest = Join-Path $OutDir $arc.BaseName
            New-Item -ItemType Directory -Path $arcDest -Force | Out-Null
            if ($Full) {
                if ($arc.Name -match '\.(tar\.gz|tgz)$') {
                    Expand-TarGz -tarPath $arc.FullName -destRoot $arcDest
                } else {
                    Expand-FullZip -zipPath $arc.FullName -destRoot $arcDest -depth $MaxDepth
                }
            } else {
                if ($arc.Name -match '\.(tar\.gz|tgz)$') {
                    # No smart mode for tar.gz yet — always full (tar.gz is not randomly accessible)
                    Write-Host "  [info] tar.gz detected — smart mode not supported, extracting fully" -ForegroundColor Yellow
                    Expand-TarGz -tarPath $arc.FullName -destRoot $arcDest
                } else {
                    Expand-SmartZip -zipPath $arc.FullName -destRoot $arcDest -depth $MaxDepth
                }
            }
        }
    }

# Case 2: single .zip file
} elseif ($bundlePath -match '\.zip$') {
    if ($Full) {
        Expand-FullZip -zipPath $bundlePath -destRoot $OutDir -depth $MaxDepth
    } else {
        Expand-SmartZip -zipPath $bundlePath -destRoot $OutDir -depth $MaxDepth
    }

# Case 3: single .tar.gz / .tgz
} elseif ($bundlePath -match '\.(tar\.gz|tgz)$') {
    Write-Host "  [info] tar.gz detected — smart mode not supported for tar.gz, extracting fully" -ForegroundColor Yellow
    Expand-TarGz -tarPath $bundlePath -destRoot $OutDir
}

Write-Host "`n[done] output: $OutDir" -ForegroundColor Green

# Print a quick size summary
$extracted = Get-ChildItem -Path $OutDir -Recurse -File
$totalMB   = [math]::Round(($extracted | Measure-Object -Property Length -Sum).Sum / 1MB, 1)
Write-Host "  $($extracted.Count) files, ${totalMB} MB extracted" -ForegroundColor Cyan
Write-Host ""
Write-Host "Tip: pass -Full to extract everything (use when smart mode misses files)"
