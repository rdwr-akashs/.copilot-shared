<#
.SYNOPSIS
    Full refresh of all centralized context in .copilot-shared.
    Runs workspace-scan + repo-mix-all in one command.

.DESCRIPTION
    Master command that rebuilds the entire central knowledge store:
      1. workspace-scan.ps1  → shared/memory/architecture-map.md
      2. repo-mix-all.ps1    → shared/memory/repo-contexts/<repo>.md

    Run this periodically (weekly) or when onboarding a new team member.

.PARAMETER Root
    Workspace root. Defaults to parent of .copilot-shared.

.PARAMETER MaxFiles
    Max files per repo in repo-mix (default 300).

.PARAMETER MaxFileSizeKB
    Max file size per file (default 192).

.PARAMETER SkipRepoMix
    Skip repo-mix-all (just run workspace-scan).

.PARAMETER SkipArchitectureScan
    Skip workspace-scan (just run repo-mix-all).

.EXAMPLE
    powershell -File bin\full-context-refresh.ps1
    powershell -File bin\full-context-refresh.ps1 -MaxFiles 500
    powershell -File bin\full-context-refresh.ps1 -SkipRepoMix
#>
param(
    [string]$Root,
    [int]$MaxFiles = 300,
    [int]$MaxFileSizeKB = 192,
    [switch]$SkipRepoMix,
    [switch]$SkipArchitectureScan,
    # By default repo-context packs are lightweight summaries (1-2KB each).
    # Pass -FullDumps to also generate full content packs into repo-contexts/full/
    [switch]$FullDumps
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$BinDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SharedRoot = Split-Path -Parent $BinDir

if (-not $Root) {
    $Root = Split-Path -Parent $SharedRoot
}

$startTime = Get-Date

Write-Host ""
Write-Host "=========================================" -ForegroundColor White
Write-Host "  FULL CONTEXT REFRESH" -ForegroundColor White
Write-Host "=========================================" -ForegroundColor White
Write-Host "  workspace: $Root"
Write-Host "  store:     $(Join-Path $SharedRoot 'shared\memory')"
Write-Host ""

# --- Step 1: Architecture Map ---
if (-not $SkipArchitectureScan) {
    Write-Host "--- Step 1/2: Architecture Scan ---" -ForegroundColor Cyan
    $scanScript = Join-Path $BinDir 'workspace-scan.ps1'
    if (Test-Path $scanScript) {
        & $scanScript -Root $Root
    } else {
        Write-Host "  [warn] workspace-scan.ps1 not found" -ForegroundColor Yellow
    }
    Write-Host ""
} else {
    Write-Host "--- Step 1/2: Architecture Scan [SKIPPED] ---" -ForegroundColor DarkGray
}

# --- Step 2: Repo Context Packs ---
if (-not $SkipRepoMix) {
    $modeLabel = if ($FullDumps) { 'full dumps -> repo-contexts/full/' } else { 'summaries (default)' }
    Write-Host "--- Step 2/2: Repo Context Packs [$modeLabel] ---" -ForegroundColor Cyan
    $mixAllScript = Join-Path $BinDir 'repo-mix-all.ps1'
    if (Test-Path $mixAllScript) {
        $summaryOnly = -not $FullDumps
        & $mixAllScript -Root $Root -MaxFiles $MaxFiles -MaxFileSizeKB $MaxFileSizeKB -SummaryOnly $summaryOnly
    } else {
        Write-Host "  [warn] repo-mix-all.ps1 not found" -ForegroundColor Yellow
    }
    Write-Host ""
} else {
    Write-Host "--- Step 2/2: Repo Context Packs [SKIPPED] ---" -ForegroundColor DarkGray
}

# --- Summary ---
$elapsed = (Get-Date) - $startTime
$memDir = Join-Path $SharedRoot 'shared\memory'
$totalFiles = @(Get-ChildItem -Path $memDir -Recurse -File).Count
$totalSizeMB = [math]::Round(
    (Get-ChildItem -Path $memDir -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1MB, 1
)

Write-Host "=========================================" -ForegroundColor White
Write-Host "  REFRESH COMPLETE" -ForegroundColor White
Write-Host "=========================================" -ForegroundColor White
Write-Host "  Duration: $([math]::Round($elapsed.TotalSeconds, 1))s"
Write-Host "  Memory store: $totalFiles files, ${totalSizeMB}MB total"
Write-Host ""
Write-Host "  Central store contents:" -ForegroundColor Green
Write-Host "    shared/memory/architecture-map.md     (service topology)"
Write-Host "    shared/memory/repo-contexts/_index.md (repo context index)"
Write-Host "    shared/memory/cross-repo-learnings.md (cross-repo patterns)"
Write-Host "    shared/memory/active-context.md       (current focus)"
Write-Host "    shared/memory/customer-cases.md       (case patterns)"
Write-Host "    shared/memory/known-bugs.md           (bug reference)"
Write-Host "    shared/memory/tech-discoveries.md     (tech stack registry)"
Write-Host ""
Write-Host "  Access from any repo:" -ForegroundColor Green
Write-Host "    `$env:COPILOT_WORKSPACE_ROOT\.copilot-shared\shared\memory\" -ForegroundColor Cyan
