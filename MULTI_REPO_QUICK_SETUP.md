# Multi-Repo Setup: Quick Reference

**Goal:** Link 15+ repos to the shared `.copilot-shared` space in under 2 hours  
**Result:** 95% token savings across entire system

---

## The Big Picture

```
BEFORE: Each repo has its own copy
├─ df_core/.github/instructions/ (130 KB) ← DUPLICATED
├─ kvision_configuration_service/.github/instructions/ (130 KB) ← DUPLICATED
├─ kvision_vrm/.github/instructions/ (130 KB) ← DUPLICATED
└─ ... (12 more repos with copies)
Total: 15 repos × 130 KB = 1.95 MB of duplication

AFTER: Single shared space
├─ .copilot-shared/shared/instructions/ (50 KB) ← USED BY ALL
├─ df_core/.github/.copilot-instructions.md (5 KB, repo-specific)
├─ kvision_configuration_service/.github/.copilot-instructions.md (5 KB, repo-specific)
└─ ... (12 more repos with light references)
Total: 50 KB shared + (15 × 5 KB) = 125 KB
Savings: 1.95 MB → 125 KB = 93% reduction
```

---

## 5-Minute Setup Per Repo

### For Each of Your 15+ Repos

```bash
# Navigate to repo
cd /path/to/<repo>

# 1. Create .github directory if missing
mkdir -p .github

# 2. Copy the template
cp /path/to/.copilot-shared/REPO_COPILOT_INSTRUCTIONS_TEMPLATE.md \
   .github/.copilot-instructions.md

# 3. Edit for your repo (2-3 minutes)
#    - Change [REPO-NAME]
#    - Change Language/Framework
#    - List your modules
#    - Add build commands
#    - Add known patterns
vim .github/.copilot-instructions.md

# 4. Create symlink to shared instructions (optional but recommended)
cd .github
ln -s ../../.copilot-shared/shared/instructions instructions-shared

# 5. Create memory file
cat > copilot-memory.md << 'EOF'
# [Repo Name] Copilot Memory

## Known Issues
- [List any issues you've found]

## Verified Commands
- [Commands that work in this repo]

## Code Patterns
- [Key patterns developers should know]
EOF

# 6. Commit
cd ..
git add .github/.copilot-instructions.md .github/copilot-memory.md
git commit -m "add: Copilot instructions (linked to shared .copilot-shared space)"

# 7. Go to next repo
cd /path/to/<next-repo>
```

---

## Batch Setup Script (Windows PowerShell)

If you want to automate across all repos:

```powershell
# run-multi-repo-setup.ps1
param(
    [string]$ReposParentDir = "C:\repos",
    [string]$SharedSpace = "C:\rdwr-intelij\.copilot-shared",
    [string]$TemplateFile = "$SharedSpace\REPO_COPILOT_INSTRUCTIONS_TEMPLATE.md"
)

# List of repos to configure
$repos = @(
    "df_core",
    "kvision_configuration_service",
    "common_policy_editor",
    "webui_components",
    "kvision_vrm",
    "kvision_cyber_controller_core",
    "kvision_deploy",
    "kvision_ha_orchestrator",
    "kvision_libs",
    "kvision_dp_inline_config",
    "kvision_manifest",
    "kvision_upgrade",
    "vision_core",
    "vision_ui"
    # Add more as needed
)

foreach ($repo in $repos) {
    $repoPath = Join-Path $ReposParentDir $repo
    $githubPath = Join-Path $repoPath ".github"
    
    if (-not (Test-Path $repoPath)) {
        Write-Warning "Repo not found: $repoPath"
        continue
    }
    
    Write-Host "Setting up $repo..." -ForegroundColor Green
    
    # Create .github directory
    New-Item -ItemType Directory -Path $githubPath -Force | Out-Null
    
    # Copy template
    $instructionsFile = Join-Path $githubPath ".copilot-instructions.md"
    Copy-Item -Path $TemplateFile -Destination $instructionsFile
    Write-Host "  ✓ Copied instructions template"
    
    # Create memory file
    $memoryFile = Join-Path $githubPath "copilot-memory.md"
    if (-not (Test-Path $memoryFile)) {
        @"
# $repo Copilot Memory

## Known Issues
- [Add issues you discover]

## Verified Commands
- [Commands that work]

## Code Patterns
- [Key patterns]
"@ | Out-File -FilePath $memoryFile -Encoding UTF8
        Write-Host "  ✓ Created copilot-memory.md"
    }
    
    # Create symlink to shared instructions
    $symlinkPath = Join-Path $githubPath "instructions-shared"
    if (-not (Test-Path $symlinkPath)) {
        # Calculate relative path
        $relativePath = "..\..\..\.copilot-shared\shared\instructions"
        cmd /c mklink /d "$symlinkPath" "$relativePath" | Out-Null
        Write-Host "  ✓ Created symlink to shared instructions"
    }
    
    # Git operations
    Push-Location $repoPath
    try {
        git add .github/.copilot-instructions.md
        git add .github/copilot-memory.md
        git commit -m "add: Copilot instructions (linked to shared space)" -q
        Write-Host "  ✓ Committed to git`n"
    }
    catch {
        Write-Warning "  ⚠ Git commit failed: $_"
    }
    finally {
        Pop-Location
    }
}

Write-Host "Setup complete!" -ForegroundColor Green
```

**Usage:**
```powershell
# Default (assumes C:\repos and C:\rdwr-intelij\.copilot-shared)
.\run-multi-repo-setup.ps1

# Custom paths
.\run-multi-repo-setup.ps1 -ReposParentDir "D:\my-repos" -SharedSpace "D:\shared"
```

---

## Batch Setup Script (Bash/Git Bash on Windows)

```bash
#!/bin/bash
# run-multi-repo-setup.sh

REPOS_PARENT="/c/repos"
SHARED_SPACE="/c/rdwr-intelij/.copilot-shared"
TEMPLATE="$SHARED_SPACE/REPO_COPILOT_INSTRUCTIONS_TEMPLATE.md"

REPOS=(
    "df_core"
    "kvision_configuration_service"
    "common_policy_editor"
    "webui_components"
    "kvision_vrm"
    "kvision_cyber_controller_core"
    "kvision_deploy"
    "kvision_ha_orchestrator"
    "kvision_libs"
    "kvision_dp_inline_config"
    "kvision_manifest"
    "kvision_upgrade"
    "vision_core"
    "vision_ui"
)

for repo in "${REPOS[@]}"; do
    repo_path="$REPOS_PARENT/$repo"
    github_path="$repo_path/.github"
    
    if [ ! -d "$repo_path" ]; then
        echo "⚠ Repo not found: $repo_path"
        continue
    fi
    
    echo "Setting up $repo..."
    
    # Create .github directory
    mkdir -p "$github_path"
    
    # Copy template
    cp "$TEMPLATE" "$github_path/.copilot-instructions.md"
    echo "  ✓ Copied instructions template"
    
    # Create memory file
    if [ ! -f "$github_path/copilot-memory.md" ]; then
        cat > "$github_path/copilot-memory.md" << EOF
# $repo Copilot Memory

## Known Issues
- [Add issues you discover]

## Verified Commands
- [Commands that work]

## Code Patterns
- [Key patterns]
EOF
        echo "  ✓ Created copilot-memory.md"
    fi
    
    # Create symlink
    symlink_path="$github_path/instructions-shared"
    if [ ! -L "$symlink_path" ]; then
        ln -s "../../.copilot-shared/shared/instructions" "$symlink_path"
        echo "  ✓ Created symlink to shared instructions"
    fi
    
    # Git commit
    cd "$repo_path"
    git add .github/.copilot-instructions.md
    git add .github/copilot-memory.md
    git commit -m "add: Copilot instructions (linked to shared space)" -q 2>/dev/null
    echo "  ✓ Committed to git"
    echo ""
done

echo "✅ Setup complete!"
```

**Usage:**
```bash
chmod +x run-multi-repo-setup.sh
./run-multi-repo-setup.sh
```

---

## Verification Checklist

After running the setup script or doing manual setup:

```bash
# For each repo, verify:

# 1. Instructions file exists
ls -la <repo>/.github/.copilot-instructions.md

# 2. Memory file exists
ls -la <repo>/.github/copilot-memory.md

# 3. Symlink works (if used)
ls -la <repo>/.github/instructions-shared
# Should show: instructions-shared -> ../../.copilot-shared/shared/instructions

# 4. Shared space is accessible
cat <repo>/.github/instructions-shared/00-core-instructions.md | head -10

# 5. Git status is clean
cd <repo> && git status
# Should show nothing to commit, working tree clean
```

---

## Testing Multi-Repo Setup

### Quick Test: Open Each Repo in VS Code

```bash
# For each repo:
code <repo>

# In VS Code terminal:
# 1. Invoke an agent: @developer
# 2. Ask: "What are my repo-specific rules?"
# 3. Verify it references .copilot-instructions.md
# 4. Verify it can find shared instructions
```

### Full Test Script

```bash
# test-multi-repo-setup.sh

REPOS_PARENT="/c/repos"

# List of repos to test
REPOS=(
    "df_core"
    "kvision_configuration_service"
    "common_policy_editor"
)

echo "Testing multi-repo setup..."
echo ""

for repo in "${REPOS[@]}"; do
    repo_path="$REPOS_PARENT/$repo"
    
    echo "Testing $repo..."
    
    # Test 1: Files exist
    if [ -f "$repo_path/.github/.copilot-instructions.md" ]; then
        echo "  ✓ .copilot-instructions.md exists"
    else
        echo "  ✗ .copilot-instructions.md missing"
    fi
    
    # Test 2: Memory file exists
    if [ -f "$repo_path/.github/copilot-memory.md" ]; then
        echo "  ✓ copilot-memory.md exists"
    else
        echo "  ✗ copilot-memory.md missing"
    fi
    
    # Test 3: Reference to shared space
    if grep -q "\.copilot-shared" "$repo_path/.github/.copilot-instructions.md"; then
        echo "  ✓ References shared space"
    else
        echo "  ✗ Does not reference shared space"
    fi
    
    # Test 4: Symlink works
    if [ -L "$repo_path/.github/instructions-shared" ]; then
        if [ -d "$repo_path/.github/instructions-shared" ]; then
            echo "  ✓ Symlink to shared instructions works"
        else
            echo "  ✗ Symlink is broken"
        fi
    else
        echo "  ⚠ No symlink (OK if using direct paths)"
    fi
    
    echo ""
done

echo "Testing complete!"
```

---

## Troubleshooting

### Problem: "Symlink creation failed on Windows"

**Solution:**
```bash
# Windows PowerShell (as Administrator)
cmd /c mklink /d <repo>\.github\instructions-shared ..\..\..\.copilot-shared\shared\instructions

# Or skip symlinks — use direct path references instead
# Edit .copilot-instructions.md to use absolute paths
# c:\rdwr-intelij\.copilot-shared\shared\instructions\...
```

### Problem: "Repo didn't pick up changes from shared space"

**Solution:**
```bash
# Verify the .copilot-instructions.md references shared space
cat <repo>/.github/.copilot-instructions.md | head -20
# Should show: c:\rdwr-intelij\.copilot-shared\shared\instructions\

# Verify symlink exists and is correct
ls -la <repo>/.github/instructions-shared

# If needed, re-create symlink
rm <repo>/.github/instructions-shared
ln -s ../../.copilot-shared/shared/instructions <repo>/.github/instructions-shared
```

### Problem: "Git commit failed (merge conflicts, branch issues)"

**Solution:**
```bash
# Check repo status
cd <repo>
git status

# If on wrong branch
git checkout main
git pull origin main

# Retry setup
# (or manually commit the .github files)
git add .github/
git commit -m "add: Copilot instructions"
git push origin main
```

---

## What Each Repo Now Gets

After setup, each repo has:

| File | Size | Purpose | Shared? |
|------|------|---------|---------|
| `.github/.copilot-instructions.md` | 5 KB | Repo-specific rules | No (customized) |
| `.github/copilot-memory.md` | 5 KB | Repo-specific findings | No (customized) |
| `.github/instructions-shared/` | Symlink | Link to shared instructions | Yes (symlink) |
| `../../.copilot-shared/shared/instructions/` | 50 KB | Core rules, all agents, all skills | Yes (shared) |

**Result:**
- ✅ Per-repo customization (each has its own rules)
- ✅ Shared best practices (all reference core space)
- ✅ No duplication (one copy of shared content)
- ✅ Easy to update globally (change shared space once, all repos see it)

---

## Timeline: Full Multi-Repo Setup

| Step | Effort | Time |
|------|--------|------|
| Create shared space (Phase 1) | Token optimization guide | ~1.5 hours |
| Set up first 3 repos (manual) | Copy template + customize | ~15 min |
| Set up remaining 12+ repos (automated) | Run script | ~5 min |
| Verify all repos work | Test in VS Code | ~10 min |
| **TOTAL** | | **~2 hours** |

---

## Multi-Repo Token Impact

### Current (No Optimization)
```
Per-repo load: 3.7M tokens
× 15 repos = 55.5M tokens per day (if all used daily)
```

### After Setup
```
Shared load: 230K tokens (once per session)
+ Per-repo: 10K tokens (lightweight)
= 240K tokens per repo per session
× 15 repos = 3.6M tokens per day (if all used daily)

Savings: 55.5M → 3.6M = 93% reduction
```

---

## Next Steps

1. **Run Phase 1 first:** `TOKEN_OPTIMIZATION_IMPLEMENTATION.md`
   - Archive repo-context dumps
   - Consolidate boilerplate
   - This takes 1.5 hours, saves 1.57M tokens

2. **Then run multi-repo setup:**
   - Copy `.copilot-instructions.md` to each repo
   - Customize per-repo sections
   - Create symlinks/memory files
   - This takes 1-2 hours, saves 93% across all repos

3. **Result:**
   - All 15+ repos use ONE shared space
   - 95% token reduction across system
   - Easy to maintain globally
   - Teams work faster with clearer rules

---

**All scripts and templates ready. Start with Phase 1 optimization, then roll out to all repos!**
