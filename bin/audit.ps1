<#
.SYNOPSIS
    Batch health check — runs doctor.cmd on every repo under the workspace root.

.DESCRIPTION
    Scans sibling repos and runs the doctor checks (junctions, required files,
    freshness) producing a single summary table.

.PARAMETER Root
    Workspace root to scan. Defaults to parent of .copilot-shared.

.EXAMPLE
    powershell -File bin\audit.ps1
#>

param(
    [ArgumentCompleter({
        param($wordToComplete, $commandAst, $cursorPosition)
        try {
            $root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
            $dirs = @(Get-ChildItem -Path $root -Directory -ErrorAction SilentlyContinue | Where-Object { Test-Path (Join-Path $_.FullName '.git') } | Select-Object -ExpandProperty Name)
            $dirs | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "Workspace root")
            }
        } catch { }
    })]
    [string]$Root
)

$ErrorActionPreference = 'Continue'
$BinDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SharedRoot = Split-Path -Parent $BinDir

if (-not $Root) {
    $Root = Split-Path -Parent $SharedRoot
}

Write-Host ""
Write-Host "=== Copilot Shared — Workspace Audit ===" -ForegroundColor Cyan
Write-Host "Scanning: $Root"
Write-Host ""

$dirs = Get-ChildItem -Path $Root -Directory | Where-Object { $_.Name -ne '.copilot-shared' }

$results = @()

foreach ($dir in $dirs) {
    $gitDir   = Join-Path $dir.FullName '.git'
    if (-not (Test-Path $gitDir)) { continue }

    $name = $dir.Name

    # Check .github exists
    $ghDir = Join-Path $dir.FullName '.github'
    $hasGithub = Test-Path $ghDir

    # Check copilot-instructions.md
    $ciFile = Join-Path $dir.FullName '.github\copilot-instructions.md'
    $hasCopilot = Test-Path $ciFile

    # Check junctions
    $junctions = @('skills', 'instructions', 'prompts', 'plans')
    $junctionOk = 0
    foreach ($j in $junctions) {
        $jp = Join-Path $dir.FullName ".github\$j"
        if (Test-Path $jp) { $junctionOk++ }
    }

    # Check repo-cache freshness
    $rcFile = Join-Path $dir.FullName '.github\repo-cache.md'
    $rcAge = ''
    if (Test-Path $rcFile) {
        $days = ((Get-Date) - (Get-Item $rcFile).LastWriteTime).Days
        $rcAge = "${days}d"
    }

    # Check agents
    $agentCount = 0
    $agentDir = Join-Path $dir.FullName '.github\agents'
    if (Test-Path $agentDir) {
        $agentCount = @(Get-ChildItem -Path $agentDir -Filter '*.agent.md' -ErrorAction SilentlyContinue).Count
    }

    $status = if ($hasCopilot -and $junctionOk -eq 4) { 'OK' }
              elseif ($hasCopilot) { 'PARTIAL' }
              else { 'MISSING' }

    $results += [PSCustomObject]@{
        Status     = $status
        Repo       = $name
        Junctions  = "$junctionOk/4"
        Hooks      = if ($hasHooks) { 'yes' } else { 'no' }
        Agents     = $agentCount
        RepoCache  = $rcAge
    }
}

# Print summary table
Write-Host ("{0,-9} {1,-30} {2,-10} {3,-6} {4,-7} {5}" -f 'STATUS', 'REPO', 'JUNCTIONS', 'HOOKS', 'AGENTS', 'REPO-CACHE')
Write-Host ("{0,-9} {1,-30} {2,-10} {3,-6} {4,-7} {5}" -f '------', '----', '---------', '-----', '------', '----------')

foreach ($r in $results | Sort-Object Status, Repo) {
    $color = switch ($r.Status) { 'OK' { 'Green' }; 'PARTIAL' { 'Yellow' }; default { 'Red' } }
    Write-Host ("{0,-9} {1,-30} {2,-10} {3,-6} {4,-7} {5}" -f $r.Status, $r.Repo, $r.Junctions, $r.Hooks, $r.Agents, $r.RepoCache) -ForegroundColor $color
}

$okCount      = @($results | Where-Object Status -eq 'OK').Count
$partialCount = @($results | Where-Object Status -eq 'PARTIAL').Count
$missingCount = @($results | Where-Object Status -eq 'MISSING').Count

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  OK:       $okCount"
Write-Host "  Partial:  $partialCount"
Write-Host "  Missing:  $missingCount"
Write-Host "  Total:    $($results.Count) repos"
Write-Host "=====================================" -ForegroundColor Cyan
