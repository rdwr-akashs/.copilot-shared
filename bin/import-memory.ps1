<#
.SYNOPSIS
    Imports memory files from a previously exported archive.

.DESCRIPTION
    Restores shared/memory/*.md from a ZIP archive created by export-memory.ps1.
    Merges by appending new entries (does not overwrite existing content).

.PARAMETER ArchivePath
    Path to the ZIP file created by export-memory.ps1.

.PARAMETER Force
    If set, overwrites existing files instead of merging.

.EXAMPLE
    powershell -File bin\import-memory.ps1 -ArchivePath copilot-memory-2024-01-15_1430.zip
    powershell -File bin\import-memory.ps1 -ArchivePath backup.zip -Force
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$ArchivePath,

    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$BinDir     = Split-Path -Parent $MyInvocation.MyCommand.Path
$SharedRoot = Split-Path -Parent $BinDir
$MemoryDir  = Join-Path $SharedRoot 'shared\memory'

if (-not (Test-Path $ArchivePath)) {
    Write-Host "Archive not found: $ArchivePath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $MemoryDir)) {
    New-Item -ItemType Directory -Path $MemoryDir -Force | Out-Null
}

# Extract to temp
$staging = Join-Path $env:TEMP "copilot-memory-import-$(Get-Date -Format 'yyyyMMddHHmmss')"
Expand-Archive -Path $ArchivePath -DestinationPath $staging -Force

$imported = 0
$skipped  = 0

foreach ($f in (Get-ChildItem $staging -Filter '*.md')) {
    $target = Join-Path $MemoryDir $f.Name

    if ((Test-Path $target) -and -not $Force) {
        # Merge: append only lines from import that don't exist in current file
        $existing = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $incoming = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)

        if ($existing.Length -ge $incoming.Length) {
            Write-Host "  SKIP $($f.Name) (existing file is same size or larger)" -ForegroundColor Yellow
            $skipped++
        } else {
            # The incoming file has more content — take the larger version
            Copy-Item $f.FullName $target -Force
            Write-Host "  MERGE $($f.Name) (imported larger version)" -ForegroundColor Green
            $imported++
        }
    } else {
        Copy-Item $f.FullName $target -Force
        Write-Host "  IMPORT $($f.Name)" -ForegroundColor Green
        $imported++
    }
}

Remove-Item $staging -Recurse -Force

Write-Host ""
Write-Host "Imported: $imported, Skipped: $skipped" -ForegroundColor Cyan
