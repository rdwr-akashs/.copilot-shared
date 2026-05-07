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
    [array]$Repos = @("common_policy_editor"),
    [switch]$CreateSymlinks = $true,
    [switch]$DeleteLocal = $false,
    [switch]$Verify = $true
)

$ErrorActionPreference = "Stop"

# Colors for output
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }
function Write-Error { Write-Host $args -ForegroundColor Red }
function Write-Info { Write-Host $args -ForegroundColor Cyan }

# Initialize logging
$LogFile = Join-Path $CentralPath "centralize-memory-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

function Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Tee-Object -FilePath $LogFile -Append
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

foreach ($repo in $Repos) {
    $dirs += "shared/memory/$repo"
}

foreach ($dir in $dirs) {
    $fullPath = Join-Path $CentralPath $dir
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Log "Created: $fullPath"
    }
}
Write-Success "✓ Directory structure created"

# Step 2: Copy repo-specific memory from individual repos
Write-Info "[2/5] Consolidating repo-specific memory..."
foreach ($repo in $Repos) {
    $repoPath = Join-Path $RepoPath $repo
    $centralMemory = Join-Path $CentralPath "shared/memory/$repo"
    
    if (-not (Test-Path $repoPath)) {
        Write-Warning "⚠ Repository not found: $repoPath"
        Log "WARN: Repository not found: $repoPath"
        continue
    }
    
    Write-Info "  Processing: $repo"
    
    # Copy from .github/memory if exists
    $githubMemory = Join-Path $repoPath ".github/memory"
    if (Test-Path $githubMemory) {
        Copy-Item "$githubMemory/*" $centralMemory -Force -Recurse -ErrorAction SilentlyContinue
        Log "  ✓ Copied .github/memory to $centralMemory"
    }
    
    # Copy from docs/memory if exists
    $docsMemory = Join-Path $repoPath "docs/memory"
    if (Test-Path $docsMemory) {
        Copy-Item "$docsMemory/*" $centralMemory -Force -Recurse -ErrorAction SilentlyContinue
        Log "  ✓ Copied docs/memory to $centralMemory"
    }
    
    # Copy from docs/learning if exists
    $docsLearning = Join-Path $repoPath "docs/learning"
    if (Test-Path $docsLearning) {
        $centralLearning = Join-Path $CentralPath "shared/learning"
        Copy-Item "$docsLearning/*" $centralLearning -Force -Recurse -ErrorAction SilentlyContinue
        Log "  ✓ Copied docs/learning to $centralLearning"
    }
}
Write-Success "✓ Repository memory consolidated"

# Step 3: Copy case documentation
Write-Info "[3/5] Consolidating case documentation..."
foreach ($repo in $Repos) {
    $repoPath = Join-Path $RepoPath $repo
    $casePath = Join-Path $repoPath ".agent_work"
    $centralCases = Join-Path $CentralPath "shared/cases/customer-cases"
    
    if (Test-Path $casePath) {
        # Copy all case files (RSEG-*, SC-*, INC-*)
        Get-ChildItem $casePath -Directory | Where-Object { $_.Name -match '^(RSEG|SC|INC)' } | ForEach-Object {
            Copy-Item $_.FullName "$centralCases/" -Force -Recurse -ErrorAction SilentlyContinue
            Log "  ✓ Copied case: $($_.Name)"
        }
    }
}
Write-Success "✓ Case documentation consolidated"

# Step 4: Create symlinks in individual repos
if ($CreateSymlinks) {
    Write-Info "[4/5] Creating symlinks in individual repos..."
    
    foreach ($repo in $Repos) {
        $repoPath = Join-Path $RepoPath $repo
        $githubDir = Join-Path $repoPath ".github"
        
        if (-not (Test-Path $githubDir)) {
            Write-Warning "⚠ .github directory not found: $githubDir"
            continue
        }
        
        Write-Info "  ${repo}: Creating symlinks..."
        
        # Create memory symlink
        $symlink = Join-Path $githubDir "copilot-memory"
        $target = "$(Join-Path $CentralPath "shared/memory/$repo")"
        
        if (Test-Path $symlink) {
            Remove-Item $symlink -Force -ErrorAction SilentlyContinue
        }
        
        cmd /c mklink /d "$symlink" "$target" 2>&1 | Out-Null
        if ($?) {
            Log "  ✓ Symlink created: .github/copilot-memory → central memory"
        } else {
            Log "  ✗ Failed to create symlink (may require admin)"
        }
        
        # Create learning symlink
        $learningLink = Join-Path $githubDir "learning"
        $learningTarget = "$(Join-Path $CentralPath "shared/learning")"
        
        if (Test-Path $learningLink) {
            Remove-Item $learningLink -Force -ErrorAction SilentlyContinue
        }
        
        cmd /c mklink /d "$learningLink" "$learningTarget" 2>&1 | Out-Null
        if ($?) {
            Log "  ✓ Symlink created: .github/learning → central learning"
        }
        
        # Create cases symlink
        $casesLink = Join-Path $githubDir "cases"
        $casesTarget = "$(Join-Path $CentralPath "shared/cases")"
        
        if (Test-Path $casesLink) {
            Remove-Item $casesLink -Force -ErrorAction SilentlyContinue
        }
        
        cmd /c mklink /d "$casesLink" "$casesTarget" 2>&1 | Out-Null
        if ($?) {
            Log "  ✓ Symlink created: .github/cases → central cases"
        }
    }
    
    Write-Success "✓ Symlinks created"
} else {
    Write-Info "[4/5] Skipping symlink creation (-CreateSymlinks not set)"
}

# Step 5: Optional cleanup of local copies
if ($DeleteLocal) {
    Write-Info "[5/5] Cleaning up local copies..."
    
    foreach ($repo in $Repos) {
        $repoPath = Join-Path $RepoPath $repo
        
        # Remove local memory (if not a symlink)
        $memory = Join-Path $repoPath ".github/memory"
        if ((Test-Path $memory) -and -not (Get-Item $memory -ErrorAction SilentlyContinue).LinkType) {
            Remove-Item $memory -Force -Recurse
            Log "  ✓ Deleted local copy: .github/memory"
        }
        
        # Remove docs/memory and docs/learning if they exist
        $docsMemory = Join-Path $repoPath "docs/memory"
        $docsLearning = Join-Path $repoPath "docs/learning"
        
        if (Test-Path $docsMemory) {
            Remove-Item $docsMemory -Force -Recurse
            Log "  ✓ Deleted local copy: docs/memory"
        }
        if (Test-Path $docsLearning) {
            Remove-Item $docsLearning -Force -Recurse
            Log "  ✓ Deleted local copy: docs/learning"
        }
    }
    
    Write-Success "✓ Local copies cleaned up"
} else {
    Write-Info "[5/5] Skipping cleanup (-DeleteLocal not set)"
    Write-Warning "⚠ Consider deleting local copies manually after verifying centralization"
}

# Verification
if ($Verify) {
    Write-Info ""
    Write-Info "=== Verification ==="
    Write-Info "Checking central structure..."
    
    $errors = 0
    
    # Check central directories exist
    foreach ($dir in $dirs) {
        $fullPath = Join-Path $CentralPath $dir
        if (Test-Path $fullPath) {
            Write-Success "✓ $dir"
        } else {
            Write-Warning "✗ $dir (missing)"
            $errors++
        }
    }
    
    # Check symlinks in repos
    Write-Info "Checking symlinks in repositories..."
    foreach ($repo in $Repos) {
        $repoPath = Join-Path $RepoPath $repo
        
        $memoryLink = Join-Path $repoPath ".github/copilot-memory"
        if (Test-Path $memoryLink) {
            Write-Success "✓ ${repo}: .github/copilot-memory"
        } else {
            Write-Warning "✗ ${repo}: .github/copilot-memory (missing)"
            $errors++
        }
    }
    
    Write-Info ""
    if ($errors -eq 0) {
        Write-Success "✓ All verifications passed!"
    } else {
        Write-Warning "⚠ $errors verification(s) failed. Check log: $LogFile"
    }
}

Write-Info ""
Write-Success "=== Centralization Complete ==="
Write-Info "Log saved to: $LogFile"
Write-Info ""
Write-Info "Next steps:"
Write-Info "1. Update .copilot-instructions.md in each repo to reference central memory"
Write-Info "2. Test symlinks: cd <repo>/.github && ls -la copilot-memory"
Write-Info "3. Review CENTRALIZED_MEMORY_SETUP.md for documentation"
Write-Info "4. Commit changes and push (git add symlink references)"
Log "Centralization completed successfully"
