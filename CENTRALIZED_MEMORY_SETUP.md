# Centralized Memory, Learning & Case Documentation

**Purpose:** Consolidate all memory bank, learning docs, and case files from individual repos into the central `.copilot-shared` hub.

**Architecture:**
```
/.copilot-shared/
├─ shared/
│  ├─ memory/
│  │  ├─ cross-repo/           ← Shared learnings across all repos
│  │  ├─ df_core/              ← Repo-specific memory
│  │  ├─ kvision_*/            ← Repo-specific memory
│  │  ├─ webui_components/     ← Repo-specific memory
│  │  └─ README.md
│  ├─ learning/                ← Central learning docs
│  │  ├─ patterns/
│  │  ├─ best-practices/
│  │  └─ README.md
│  └─ cases/                   ← Case docs & RCA
│     ├─ customer-cases/
│     ├─ root-cause-analysis/
│     └─ README.md
```

**Individual repos link back:**
```
df_core/.github/
├─ .copilot-instructions.md (includes link to central memory)
└─ instructions → symlink to /.copilot-shared/shared/instructions

kvision_*/.github/
├─ .copilot-instructions.md (includes link to central memory)
└─ instructions → symlink to /.copilot-shared/shared/instructions
```

---

## Phase 1: Central Repository Structure

### Current State
✅ `shared/memory/` exists
✅ `cases/` exists

### Needed Additions

```
shared/memory/
├── cross-repo/                   [NEW]
│   ├── architecture-patterns.md
│   ├── deployment-learnings.md
│   └── incident-retrospectives.md
│
├── <repo-name>/                  [NEW - one per repo]
│   ├── memory.md
│   └── performance-notes.md
│
├── README.md                      [UPDATE]
└── repo-contexts/ (existing)

shared/learning/                  [NEW TOP-LEVEL]
├── best-practices/
│   ├── java-patterns.md
│   ├── react-patterns.md
│   └── devops-patterns.md
├── troubleshooting/
│   ├── common-errors.md
│   └── debug-strategies.md
└── README.md

shared/cases/                      [EXISTS - EXPAND]
├── customer-cases/               [NEW]
│   ├── RSEG-*/
│   ├── SC-*/
│   └── INC-*/
├── root-cause-analysis/          [NEW]
│   ├── RSEG-*.rca.md
│   └── known-issues.md
├── README.md                      [UPDATE]
└── _template/
```

---

## Phase 2: Migration From Individual Repos

### Step 1: Create Directory Structure

```bash
# In /.copilot-shared/shared/
mkdir -p memory/cross-repo
mkdir -p memory/df_core
mkdir -p memory/kvision_configuration_service
mkdir -p memory/kvision_incident_response
mkdir -p memory/webui_components
mkdir -p memory/vision_core

mkdir -p learning/best-practices
mkdir -p learning/troubleshooting
mkdir -p learning/design-patterns

mkdir -p cases/customer-cases
mkdir -p cases/root-cause-analysis
```

### Step 2: For Each Repo (df_core, kvision_*, webui_components, etc.)

**Location of per-repo docs to migrate:**

| Repo | Current Path | Migrate To |
|------|--------------|-----------|
| df_core | `.github/copilot-memory.md` OR `docs/memory/` | `/.copilot-shared/shared/memory/df_core/` |
| kvision_* | `.github/memory/` | `/.copilot-shared/shared/memory/kvision_*/` |
| webui_components | `.github/memory/` | `/.copilot-shared/shared/memory/webui_components/` |
| vision_core | `.github/memory/` | `/.copilot-shared/shared/memory/vision_core/` |
| All repos | `docs/cases/` or `.agent_work/` | `/.copilot-shared/shared/cases/` |

### Step 3: Consolidate Repo-Specific Memory

```bash
# Example for df_core
cd /c/repos/df_core
cp -r .github/copilot-memory.md ../../.copilot-shared/shared/memory/df_core/
cp -r docs/learning/* ../../.copilot-shared/shared/learning/

# Example for kvision services
cd /c/repos/kvision_configuration_service
cp -r .github/memory/* ../../.copilot-shared/shared/memory/kvision_configuration_service/
```

### Step 4: Consolidate Case Documentation

```bash
# Collect all case files
# Look for:
# - .agent_work/RSEG-*/
# - .agent_work/SC-*/
# - .agent_work/INC-*/
# - docs/cases/

cp -r .agent_work/RSEG-* ../../.copilot-shared/shared/cases/customer-cases/
cp -r docs/cases/* ../../.copilot-shared/shared/cases/
```

---

## Phase 3: Set Up Symlinks in Individual Repos

### Windows (PowerShell)

```powershell
# For each repo, run:
cd C:\repos\df_core\.github

# Link to central memory
cmd /c mklink /d copilot-memory ..\..\..\.copilot-shared\shared\memory\df_core
cmd /c mklink /d learning ..\..\..\.copilot-shared\shared\learning
cmd /c mklink /d cases ..\..\..\.copilot-shared\shared\cases
```

### Git Bash / Linux

```bash
cd /c/repos/df_core/.github

# Link to central memory
ln -s ../../../.copilot-shared/shared/memory/df_core copilot-memory
ln -s ../../../.copilot-shared/shared/learning learning
ln -s ../../../.copilot-shared/shared/cases cases
```

### Configure Git to Follow Symlinks

```bash
# In each repo
git config core.symlinks true
```

---

## Phase 4: Update .copilot-instructions.md

Add this section to each repo's `.github/.copilot-instructions.md`:

```markdown
## Memory & Learning Resources

### Central Memory Bank
- **Cross-Repo Learnings**: [/shared/memory/cross-repo/](../../.copilot-shared/shared/memory/cross-repo/)
- **This Repo's Memory**: [/shared/memory/df_core/](../../.copilot-shared/shared/memory/df_core/)
- **Learning Docs**: [/shared/learning/](../../.copilot-shared/shared/learning/)

### Case Documentation
- **Customer Cases**: [/shared/cases/customer-cases/](../../.copilot-shared/shared/cases/customer-cases/)
- **RCA Documents**: [/shared/cases/root-cause-analysis/](../../.copilot-shared/shared/cases/root-cause-analysis/)

### How to Access
1. **From Copilot Chat**: Reference files relative to `.copilot-shared/shared/memory/` and `.copilot-shared/shared/cases/`
2. **From IDE**: Navigate using symlinks in `.github/copilot-memory/`
3. **From Terminal**: Reference central paths or use symlinked directories
```

---

## Phase 5: Clean Up Local Copies

After verifying symlinks work:

```bash
# In each repo (after backing up):
cd C:\repos\df_core

# Remove local memory (now using symlink)
rm -r docs/memory              # if it exists
rm -r .agent_work/RSEG-*       # if using symlink
rm -r .github/copilot-memory.md # if duplicated

# Verify symlinks still work
ls -la .github/copilot-memory/
```

---

## Phase 6: Update .gitignore

In `.copilot-shared` and each repo, ensure `.gitignore` allows memory symlinks:

```gitignore
# Allow symlinks to be tracked
!.github/copilot-memory
!.github/learning
!.github/cases
```

---

## Verification Checklist

- [ ] Central directory structure created in `/.copilot-shared/shared/`
- [ ] All repo-specific memory files copied from individual repos
- [ ] All case docs consolidated to `/.copilot-shared/shared/cases/`
- [ ] Symlinks created in each repo's `.github/`
- [ ] `.copilot-instructions.md` updated with central references
- [ ] Local copies removed from individual repos
- [ ] Git symlinks configured (`core.symlinks = true`)
- [ ] `.gitignore` allows symlinks to be tracked
- [ ] Copilot can access central memory in each repo
- [ ] Cross-repo learning docs validated

---

## Folder Index Template

Create `/.copilot-shared/shared/memory/README.md`:

```markdown
# Central Memory Bank

**Organization:**
- `cross-repo/` - Learnings applicable across all repositories
- `df_core/` - Specific to df_core repository
- `kvision_*/` - Specific to kvision services
- `webui_components/` - Specific to webui_components
- `vision_core/` - Specific to vision_core

**Each repo folder contains:**
- `memory.md` - Accumulated learnings and patterns
- `performance-notes.md` - Performance observations
- `architecture.md` - Architectural decisions

**Accessed from individual repos via symlinks:**
- `.github/copilot-memory` → points to `/.copilot-shared/shared/memory/<repo-name>/`
- `.github/learning` → points to `/.copilot-shared/shared/learning/`
- `.github/cases` → points to `/.copilot-shared/shared/cases/`

**Last Updated:** [Date]
**Maintained By:** [Your team]
```

---

## Automation Script (PowerShell)

Save as `bin/centralize-memory.ps1`:

```powershell
# Centralize Memory & Cases from all repos

param(
    [string]$SourceRepos = "C:\repos",
    [string]$CentralRepo = "C:\rdwr-intelij\.copilot-shared"
)

$repos = @("df_core", "kvision_configuration_service", "kvision_incident_response", "webui_components", "vision_core")

foreach ($repo in $repos) {
    Write-Host "Processing $repo..." -ForegroundColor Cyan
    
    $repoPath = Join-Path $SourceRepos $repo
    $centralMemory = Join-Path $CentralRepo "shared\memory"
    
    # Copy memory
    if (Test-Path "$repoPath\.github\memory") {
        Copy-Item "$repoPath\.github\memory\*" "$centralMemory\$repo\" -Force -Recurse
        Write-Host "  ✓ Memory copied"
    }
    
    # Copy cases
    if (Test-Path "$repoPath\.agent_work") {
        $casesPath = Join-Path $CentralRepo "shared\cases\customer-cases"
        Copy-Item "$repoPath\.agent_work\*" "$casesPath\" -Force -Recurse -ErrorAction SilentlyContinue
        Write-Host "  ✓ Cases copied"
    }
    
    # Create symlinks
    Write-Host "  → Creating symlinks..."
    cmd /c mklink /d "$repoPath\.github\memory" "$centralMemory\$repo"
}

Write-Host "✓ Centralization complete" -ForegroundColor Green
```

---

## Expected Benefits

| Metric | Before | After |
|--------|--------|-------|
| Memory locations | 15+ separate locations | 1 central hub |
| Update time | 30 min (all repos) | 5 min (one place) |
| Consistency | Manual sync needed | Always in sync |
| Token bloat | Each repo loads own copy | Single load, shared |
| Discoverability | Hard to find | Organized structure |

