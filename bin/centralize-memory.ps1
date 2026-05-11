#!/usr/bin/env pwsh
# Centralize Memory, Learning, and Case Documentation
#
# Usage: .\centralize-memory.ps1 -RepoPath "C:\repos" -CentralPath "C:\rdwr-intelij\.copilot-shared"
#
# This script:
# 1. Creates the central folder structure
# 2. Copies all repo-specific memory/learning/cases to central location
# 3. Creates symlinks in individual repos pointing to central location
# 4. Cleans up local copies (optional)

param(
    [string]$RepoPath = "C:\repos",
    [string]$CentralPath = "C:\rdwr-intelij\.copilot-shared",
    [string[]]$Repos = @("common_policy_editor"),
    [object]$CreateSymlinks = $true,
    [object]$DeleteLocal = $false,
    [object]$Verify = $true
)

# Helper function to convert various boolean-like values to proper boolean
function ConvertToBool {
    param([object]$Value)
    
    if ($Value -is [bool]) { return $Value }
    if ($Value -is [int]) { return $Value -ne 0 }
    if ($Value -is [string]) {
        if ($Value -eq "1" -or $Value -ieq "true" -or $Value -ieq "yes") { return $true }
        if ($Value -eq "0" -or $Value -ieq "false" -or $Value -ieq "no") { return $false }
    }
    return [bool]::Parse($Value.ToString())
}

# Convert parameters to proper boolean values
$CreateSymlinks = ConvertToBool $CreateSymlinks
$DeleteLocal = ConvertToBool $DeleteLocal
$Verify = ConvertToBool $Verify

$ErrorActionPreference = "Stop"

# Normalize Repos parameter - handle comma-separated strings
if ($Repos.Count -eq 1 -and $Repos[0] -is [string] -and $Repos[0].Contains(',')) {
    $Repos = @($Repos[0] -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}

# Colors for output
function Write-Success { param([string]$Msg) Write-Host $Msg -ForegroundColor Green }
function Write-Warn { param([string]$Msg) Write-Host $Msg -ForegroundColor Yellow }
function Write-Err { param([string]$Msg) Write-Host $Msg -ForegroundColor Red }
function Write-Info { param([string]$Msg) Write-Host $Msg -ForegroundColor Cyan }

# Ensure central path exists before creating log file
if (-not (Test-Path $CentralPath)) {
    New-Item -ItemType Directory -Path $CentralPath -Force | Out-Null
}

# Initialize logging — logs go to shared/memory/logs/ (not repo root)
$LogDir = Join-Path $CentralPath "shared/memory/logs"
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }
$LogFile = Join-Path $LogDir "centralize-memory-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

function Log {
    param([string]$Message)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$ts - $Message" | Tee-Object -FilePath $LogFile -Append
}

Write-Info "=== Central Memory Consolidation ==="
Write-Info "RepoPath: $RepoPath"
Write-Info "CentralPath: $CentralPath"
Write-Info "Repositories: $($Repos -join ', ')"
Write-Info "CreateSymlinks: $CreateSymlinks"
Write-Info "DeleteLocal: $DeleteLocal"
Write-Info ""

Log "Starting centralization..."

# Step 1: Create central directory structure
Write-Info "[1/5] Creating central directory structure..."
$dirs = @(
    "shared/memory/cross-repo",
    "shared/learning/best-practices",
    "shared/learning/troubleshooting",
    "shared/learning/design-patterns",
    "shared/cases/customer-cases",
    "shared/cases/root-cause-analysis"
)

for ($i = 0; $i -lt $Repos.Count; $i++) {
    $dirs += "shared/memory/$($Repos[$i])"
}

foreach ($dir in $dirs) {
    $fullPath = Join-Path $CentralPath $dir
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Log "Created: $fullPath"
    }
}
Write-Success "[OK] Directory structure created"

# Step 2: Copy repo-specific memory from individual repos
Write-Info "[2/5] Consolidating repo-specific memory..."
for ($i = 0; $i -lt $Repos.Count; $i++) {
    $currentRepo = $Repos[$i]
    $currentRepoPath = Join-Path $RepoPath $currentRepo
    $currentCentralMemory = Join-Path $CentralPath "shared/memory/$currentRepo"

    if (-not (Test-Path $currentRepoPath)) {
        Write-Warn "[WARN] Repository not found: $currentRepoPath"
        Log "WARN: Repository not found: $currentRepoPath"
        continue
    }

    Write-Info "  Processing: $currentRepo"

    # Copy from memory-bank if exists AND is a real directory (not already a junction)
    $memoryBank = Join-Path $currentRepoPath "memory-bank"
    if (Test-Path $memoryBank) {
        $mbItem = Get-Item $memoryBank -Force -ErrorAction SilentlyContinue
        if ($mbItem -and -not $mbItem.LinkType) {
            Copy-Item "$memoryBank\*" $currentCentralMemory -Force -Recurse -ErrorAction SilentlyContinue
            Log "  Copied memory-bank to $currentCentralMemory"
        } else {
            Log "  Skipped memory-bank (already a junction to central)"
        }
    }

    # Copy from .github/memory if exists
    $githubMemory = Join-Path $currentRepoPath ".github/memory"
    if (Test-Path $githubMemory) {
        Copy-Item "$githubMemory\*" $currentCentralMemory -Force -Recurse -ErrorAction SilentlyContinue
        Log "  Copied .github/memory to $currentCentralMemory"
    }

    # Copy from docs/memory if exists
    $docsMemory = Join-Path $currentRepoPath "docs/memory"
    if (Test-Path $docsMemory) {
        Copy-Item "$docsMemory\*" $currentCentralMemory -Force -Recurse -ErrorAction SilentlyContinue
        Log "  Copied docs/memory to $currentCentralMemory"
    }

    # Copy from docs/learning if exists
    $docsLearning = Join-Path $currentRepoPath "docs/learning"
    if (Test-Path $docsLearning) {
        $centralLearning = Join-Path $CentralPath "shared/learning"
        Copy-Item "$docsLearning/*" $centralLearning -Force -Recurse -ErrorAction SilentlyContinue
        Log "  Copied docs/learning to $centralLearning"
    }
}
Write-Success "[OK] Repository memory consolidated"

# Step 3: Copy case documentation
Write-Info "[3/5] Consolidating case documentation..."
for ($i = 0; $i -lt $Repos.Count; $i++) {
    $currentRepo = $Repos[$i]
    $currentRepoPath = Join-Path $RepoPath $currentRepo
    $casePath = Join-Path $currentRepoPath ".agent_work"
    $centralCases = Join-Path $CentralPath "shared/cases/customer-cases"

    if (Test-Path $casePath) {
        Get-ChildItem $casePath -Directory | Where-Object { $_.Name -match '^(RSEG|SC|INC)' } | ForEach-Object {
            Copy-Item $_.FullName "$centralCases/" -Force -Recurse -ErrorAction SilentlyContinue
            Log "  Copied case: $($_.Name)"
        }
    }
}
Write-Success "[OK] Case documentation consolidated"

# Step 4: Create symlinks in individual repos
if ($CreateSymlinks) {
    Write-Info "[4/5] Creating symlinks in individual repos..."

    for ($i = 0; $i -lt $Repos.Count; $i++) {
        $currentRepo = $Repos[$i]
        $currentRepoPath = Join-Path $RepoPath $currentRepo
        $githubDir = Join-Path $currentRepoPath ".github"

        if (-not (Test-Path $githubDir)) {
            Write-Warn "[WARN] .github directory not found: $githubDir"
            continue
        }

        Write-Info "  ${currentRepo}: Creating junctions..."

        # Create learning symlink
        $learningLink = Join-Path $githubDir "learning"
        $learningTarget = Join-Path $CentralPath "shared/learning"

        if (Test-Path $learningLink) {
            cmd /c rmdir "$learningLink" 2>&1 | Out-Null
            if (Test-Path $learningLink) { Remove-Item $learningLink -Force -Recurse -ErrorAction SilentlyContinue }
        }

        cmd /c mklink /j "$learningLink" "$learningTarget" 2>&1 | Out-Null
        if ($?) {
            Log "  Junction created: .github/learning -> central learning"
        }

        # Create cases symlink
        $casesLink = Join-Path $githubDir "cases"
        $casesTarget = Join-Path $CentralPath "shared/cases"

        if (Test-Path $casesLink) {
            cmd /c rmdir "$casesLink" 2>&1 | Out-Null
            if (Test-Path $casesLink) { Remove-Item $casesLink -Force -Recurse -ErrorAction SilentlyContinue }
        }

        cmd /c mklink /j "$casesLink" "$casesTarget" 2>&1 | Out-Null
        if ($?) {
            Log "  Junction created: .github/cases -> central cases"
        }

        # Junction memory-bank at repo root -> central memory (so agent writes go to central)
        $memBankLink = Join-Path $currentRepoPath "memory-bank"
        $memBankTarget = Join-Path $CentralPath "shared/memory/$currentRepo"

        if (Test-Path $memBankLink) {
            $item = Get-Item $memBankLink -Force -ErrorAction SilentlyContinue
            if ($item -and $item.LinkType) {
                # Already a junction - remove just the junction point (not the target contents)
                cmd /c rmdir "$memBankLink" 2>&1 | Out-Null
            } else {
                # Real directory - content was already copied to central in Step 2, delete it
                cmd /c rmdir /s /q "$memBankLink" 2>&1 | Out-Null
            }
        }

        cmd /c mklink /j "$memBankLink" "$memBankTarget" 2>&1 | Out-Null
        if ($?) {
            Log "  Junction created: memory-bank -> central memory/$currentRepo"
        } else {
            Log "  WARN: Failed to create memory-bank junction for $currentRepo"
        }
    }

    Write-Success "[OK] Symlinks created"
} else {
    Write-Info "[4/5] Skipping symlink creation (-CreateSymlinks not set)"
}

# Step 5: Optional cleanup of local copies
if ($DeleteLocal) {
    Write-Info "[5/5] Cleaning up local copies..."

    for ($i = 0; $i -lt $Repos.Count; $i++) {
        $currentRepo = $Repos[$i]
        $currentRepoPath = Join-Path $RepoPath $currentRepo

        # Remove local memory (if not a symlink)
        $memory = Join-Path $currentRepoPath ".github/memory"
        if ((Test-Path $memory) -and -not (Get-Item $memory -ErrorAction SilentlyContinue).LinkType) {
            Remove-Item $memory -Force -Recurse
            Log "  Deleted local copy: .github/memory"
        }

        # Remove docs/memory and docs/learning if they exist
        $docsMemory = Join-Path $currentRepoPath "docs/memory"
        $docsLearning = Join-Path $currentRepoPath "docs/learning"

        if (Test-Path $docsMemory) {
            Remove-Item $docsMemory -Force -Recurse
            Log "  Deleted local copy: docs/memory"
        }
        if (Test-Path $docsLearning) {
            Remove-Item $docsLearning -Force -Recurse
            Log "  Deleted local copy: docs/learning"
        }
    }

    Write-Success "[OK] Local copies cleaned up"
} else {
    Write-Info "[5/5] Skipping cleanup (-DeleteLocal not set)"
    Write-Warn "[NOTE] Consider deleting local copies manually after verifying centralization"
}

# Verification
if ($Verify) {
    Write-Info ""
    Write-Info "=== Verification ==="
    Write-Info "Checking central structure..."

    $errors = 0

    foreach ($dir in $dirs) {
        $fullPath = Join-Path $CentralPath $dir
        if (Test-Path $fullPath) {
            Write-Success "[OK] $dir"
        } else {
            Write-Warn "[FAIL] $dir (missing)"
            $errors++
        }
    }

    Write-Info "Checking junctions in repositories..."
    for ($i = 0; $i -lt $Repos.Count; $i++) {
        $currentRepo = $Repos[$i]
        $currentRepoPath = Join-Path $RepoPath $currentRepo
        $memBankCheck = Join-Path $currentRepoPath "memory-bank"

        if (Test-Path $memBankCheck) {
            $mbItem = Get-Item $memBankCheck -Force -ErrorAction SilentlyContinue
            if ($mbItem -and $mbItem.LinkType) {
                Write-Success "[OK] ${currentRepo}: memory-bank (junction)"
            } else {
                Write-Warn "[FAIL] ${currentRepo}: memory-bank exists but is NOT a junction"
                $errors++
            }
        } else {
            Write-Warn "[FAIL] ${currentRepo}: memory-bank (missing)"
            $errors++
        }
    }

    Write-Info ""
    if ($errors -eq 0) {
        Write-Success "[OK] All verifications passed!"
    } else {
        Write-Warn "[WARN] $errors verification(s) failed. Check log: $LogFile"
    }
}

Write-Info ""
Write-Success "=== Centralization Complete ==="
Write-Info "Log saved to: shared/memory/logs/$(Split-Path $LogFile -Leaf)"
Write-Info ""
Write-Info "Next steps:"
Write-Info "1. Verify: ls <repo>/memory-bank/ -- should show your memory files"
Write-Info "2. Verify: ls .copilot-shared/shared/memory/<repo>/ -- same files"
Write-Info "3. Run 'full-context-refresh.cmd' to rebuild architecture-map and repo-contexts"

Log 'Centralization completed successfully'
