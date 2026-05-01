<#
.SYNOPSIS
    Exports the shared memory files to a timestamped archive.

.DESCRIPTION
    Copies shared/memory/*.md (excluding templates/) to a ZIP archive
    for backup or sharing with teammates.

.PARAMETER OutputDir
    Directory to write the archive to. Defaults to current directory.

.EXAMPLE
    powershell -File bin\export-memory.ps1
    powershell -File bin\export-memory.ps1 -OutputDir C:\backups
#>
param(
    [string]$OutputDir = '.'
)

$ErrorActionPreference = 'Stop'
$BinDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$SharedRoot = Split-Path -Parent $BinDir
$MemoryDir  = Join-Path $SharedRoot 'shared\memory'

if (-not (Test-Path $MemoryDir)) {
    Write-Host "No memory directory found at $MemoryDir" -ForegroundColor Red
    exit 1
}

$timestamp = Get-Date -Format 'yyyy-MM-dd_HHmm'
$archiveName = "copilot-memory-$timestamp.zip"
$archivePath = Join-Path (Resolve-Path $OutputDir) $archiveName

# Collect memory files (skip templates/)
$files = Get-ChildItem -Path $MemoryDir -Filter '*.md' -File
if ($files.Count -eq 0) {
    Write-Host "No memory files found to export." -ForegroundColor Yellow
    exit 0
}

# Create temp staging folder
$staging = Join-Path $env:TEMP "copilot-memory-export-$timestamp"
New-Item -ItemType Directory -Path $staging -Force | Out-Null

foreach ($f in $files) {
    Copy-Item $f.FullName $staging
}

Compress-Archive -Path "$staging\*" -DestinationPath $archivePath -Force
Remove-Item $staging -Recurse -Force

Write-Host "Exported $($files.Count) memory files to: $archivePath" -ForegroundColor Green
