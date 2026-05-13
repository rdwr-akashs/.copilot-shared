#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Verify that all repos have central memory properly configured.

.DESCRIPTION
    Checks every repo in the workspace for:
    1. Presence of .github/ directory
    2. Junctions pointing to central memory (copilot-memory, learning, cases)
    3. Junction pointing to shared memory-bank
    4. .gitignore entries for memory paths
    5. copilot-instructions.md exists
    6. Reports which repos need setup

.PARAMETER WorkspacePath
    Path to the workspace root. Defaults to parent of .copilot-shared.

.PARAMETER Repair
    Automatically fix issues (re-run setup for broken repos).

.EXAMPLE
    .\verify-central-memory.ps1
    .\verify-central-memory.ps1 -WorkspacePath "C:\rdwr-intelij" -Repair
#>
param(
    [string]$WorkspacePath = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent),
    [switch]$Repair = $false
)

$ErrorActionPreference = "Stop"

# Colors
function Write-Success { param([string]$Msg) Write-Host "  ✅ $Msg" -ForegroundColor Green }
function Write-Warn { param([string]$Msg) Write-Host "  ⚠️  $Msg" -ForegroundColor Yellow }
function Write-Err { param([string]$Msg) Write-Host "  ❌ $Msg" -ForegroundColor Red }
function Write-Info { param([string]$Msg) Write-Host "  ℹ️  $Msg" -ForegroundColor Cyan }
function Write-Header { param([string]$Msg) Write-Host "`n$Msg" -ForegroundColor Cyan -BackgroundColor Black }

Write-Header "=== Central Memory Verification ==="
Write-Info "Workspace: $WorkspacePath"
Write-Info ""

# Discover all repos (exclude .copilot-shared itself)
$repos = @()
Get-ChildItem -Path $WorkspacePath -Directory | ForEach-Object {
    if ($_.Name -ne ".copilot-shared" -and (Test-Path (Join-Path $_.FullName ".git"))) {
        $repos += $_.Name
    }
}

if ($repos.Count -eq 0) {
    Write-Err "No Git repos found in workspace"
    exit 1
}

Write-Info "Found $($repos.Count) repo(s): $($repos -join ', ')"
Write-Info ""

$summary = @{
    Total = $repos.Count
    FullyConfigured = 0
    PartiallyConfigured = 0
    Unconfigured = 0
    Issues = @()
}

# Check each repo
foreach ($repo in $repos | Sort-Object) {
    Write-Host "`n[Checking] $repo" -ForegroundColor Cyan
    
    $repoPath = Join-Path $WorkspacePath $repo
    $status = $null
    $issues = @()
    
    # 1. Check .github exists
    $githubPath = Join-Path $repoPath ".github"
    if (-not (Test-Path $githubPath)) {
        Write-Err ".github/ not found"
        $issues += "missing-.github"
        $status = "unconfigured"
    } else {
        Write-Success ".github/ exists"
    }
    
    # 2. Check junctions
    $junctions = @{
        "copilot-memory" = Join-Path $githubPath "copilot-memory"
        "learning" = Join-Path $githubPath "learning"
        "cases" = Join-Path $githubPath "cases"
        "memory-bank" = Join-Path $repoPath "memory-bank"
    }
    
    $junctionCount = 0
    foreach ($juncName in $junctions.Keys) {
        $juncPath = $junctions[$juncName]
        
        if (Test-Path $juncPath) {
            $item = Get-Item $juncPath
            if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                Write-Success "Junction: $juncName"
                $junctionCount++
            } else {
                Write-Warn "Path exists but is NOT a junction: $juncName"
                $issues += "not-junction-$juncName"
            }
        } else {
            Write-Warn "Junction missing: $juncName"
            $issues += "missing-junction-$juncName"
        }
    }
    
    # 3. Check .gitignore
    $gitignorePath = Join-Path $repoPath ".gitignore"
    if (Test-Path $gitignorePath) {
        $gitignore = Get-Content $gitignorePath -Raw
        $memoryEntries = @("memory-bank/", "copilot-memory/", "personal-instructions.md")
        $foundCount = 0
        
        foreach ($entry in $memoryEntries) {
            if ($gitignore -match [regex]::Escape($entry)) {
                $foundCount++
            }
        }
        
        if ($foundCount -eq 3) {
            Write-Success ".gitignore configured"
        } else {
            Write-Warn ".gitignore missing some entries ($foundCount/3)"
            $issues += "gitignore-incomplete"
        }
    } else {
        Write-Warn ".gitignore not found"
        $issues += "no-gitignore"
    }
    
    # 4. Check copilot-instructions.md
    $instructPath = Join-Path $githubPath "copilot-instructions.md"
    if (Test-Path $instructPath) {
        Write-Success "copilot-instructions.md exists"
    } else {
        Write-Warn "copilot-instructions.md missing"
        $issues += "missing-copilot-instructions"
    }
    
    # Determine overall status
    if ($issues.Count -eq 0) {
        $status = "fully-configured"
        $summary.FullyConfigured++
    } elseif ($junctionCount -ge 3) {
        $status = "partially-configured"
        $summary.PartiallyConfigured++
    } else {
        $status = "unconfigured"
        $summary.Unconfigured++
    }
    
    Write-Host "  Status: $status" -ForegroundColor $(
        if ($status -eq "fully-configured") { "Green" }
        elseif ($status -eq "partially-configured") { "Yellow" }
        else { "Red" }
    )
    
    if ($issues.Count -gt 0) {
        $summary.Issues += @{ Repo = $repo; Issues = $issues }
    }
}

# Summary report
Write-Header "=== Summary ==="
Write-Host "Total repos: $($summary.Total)"
Write-Success "Fully configured: $($summary.FullyConfigured)"
Write-Warn "Partially configured: $($summary.PartiallyConfigured)"
Write-Err "Unconfigured: $($summary.Unconfigured)"

if ($summary.Issues.Count -gt 0) {
    Write-Header "=== Issues Found ==="
    foreach ($item in $summary.Issues) {
        Write-Host "`n[$($item.Repo)]" -ForegroundColor Yellow
        foreach ($issue in $item.Issues) {
            Write-Host "  - $issue"
        }
    }
    
    if ($Repair) {
        Write-Header "=== Auto-Repair Mode ==="
        Write-Info "Attempting to repair unconfigured repos..."
        
        $centralPath = Join-Path $WorkspacePath ".copilot-shared"
        $setupScript = Join-Path $centralPath "bin\setup-repo.ps1"
        
        foreach ($item in $summary.Issues) {
            $repo = $item.Repo
            Write-Info "Setting up: $repo"
            
            $repoPath = Join-Path $WorkspacePath $repo
            & $setupScript $repoPath -Force
        }
        
        Write-Success "Repair complete. Run this script again to verify."
    } else {
        Write-Info "Run with -Repair flag to auto-fix: .\verify-central-memory.ps1 -Repair"
    }
}

Write-Header "=== Done ==="
if ($summary.Unconfigured -eq 0) {
    Write-Success "All repos properly configured!"
} else {
    Write-Err "$($summary.Unconfigured) repo(s) need setup"
}
