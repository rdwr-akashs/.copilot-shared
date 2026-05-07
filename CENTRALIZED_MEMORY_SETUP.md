# Centralized Memory Setup

**Single source of truth** for all AI context across every linked repo. Memory written in any repo flows automatically to `.copilot-shared/shared/memory/` — no manual sync.

## Architecture

```
<workspace>/
├── .copilot-shared/
│   └── shared/
│       ├── memory/
│       │   ├── active-context.md         ← current work focus (global)
│       │   ├── architecture-map.md       ← auto-generated service topology
│       │   ├── cross-repo-learnings.md   ← patterns spanning repos
│       │   ├── customer-cases.md         ← solved case patterns
│       │   ├── known-bugs.md             ← bug reference
│       │   ├── tech-discoveries.md       ← repo registry & tech stacks
│       │   ├── cross-repo/               ← shared architectural learnings
│       │   ├── <repo-name>/              ← per-repo memory (see below)
│       │   └── repo-contexts/            ← auto-generated context packs
│       ├── learning/
│       │   ├── best-practices/
│       │   ├── troubleshooting/
│       │   └── design-patterns/
│       └── cases/
│           ├── customer-cases/
│           └── root-cause-analysis/
│
├── <repo>/
│   ├── memory-bank/          ← JUNCTION → shared/memory/<repo>/
│   └── .github/
│       ├── copilot-memory/   ← JUNCTION → shared/memory/<repo>/
│       ├── learning/         ← JUNCTION → shared/learning/
│       └── cases/            ← JUNCTION → shared/cases/
```

When an agent writes `memory-bank/activeContext.md` in any repo, the file physically lives in `shared/memory/<repo>/activeContext.md` and is immediately readable from every other linked repo.

---

## Setup: New Repo

Run this one command after cloning a new repo:

```powershell
.copilot-shared\bin\setup-repo.ps1 C:\your\workspace\<repo-name>
```

This automatically:
- Creates `.copilot-shared/shared/memory/<repo-name>/` if missing
- Migrates any existing `memory-bank/` content to central
- Replaces `memory-bank/` with a junction → central
- Creates `.github/copilot-memory`, `.github/learning`, `.github/cases` junctions
- Adds `memory-bank/` to `.gitignore`
- Junctions `skills/`, `instructions/`, `prompts/`, `plans/`
- Copies agent templates and writes `copilot-instructions.md`

---

## Setup: Existing Repo

For repos that already have `.github/` set up but aren't wired to central memory:

```powershell
# Step 1: shared junctions (skills, instructions, prompts, plans)
.copilot-shared\bin\link-copilot.cmd C:\your\workspace\<repo-name>

# Step 2: seed agents (skips any already customised)
.copilot-shared\bin\copy-agents.cmd C:\your\workspace\<repo-name>

# Step 3: wire up central memory
powershell -File .copilot-shared\bin\centralize-memory.ps1 `
  -RepoPath "C:\your\workspace" `
  -Repos "<repo-name>" `
  -CreateSymlinks 1 -DeleteLocal 0 -Verify 1
```

Step 3 will:
1. Copy any content from `memory-bank/`, `.github/memory/`, `docs/memory/` into central
2. Replace `memory-bank/` with a junction → `shared/memory/<repo-name>/`
3. Create `.github/copilot-memory`, `.github/learning`, `.github/cases` junctions
4. Print a verification report

---

## Setup: Multiple Repos at Once

```powershell
powershell -File .copilot-shared\bin\centralize-memory.ps1 `
  -RepoPath "C:\your\workspace" `
  -Repos "repo1,repo2,repo3" `
  -CreateSymlinks 1 -DeleteLocal 0 -Verify 1
```

---

## Verification

After running setup, verify junctions are wired correctly:

```bash
# List junction targets
fsutil reparsepoint query C:\workspace\repo1\memory-bank | findstr "Print Name"
fsutil reparsepoint query C:\workspace\repo1\.github\copilot-memory | findstr "Print Name"

# Confirm files appear in both places (same physical location)
ls C:\workspace\repo1\memory-bank\
ls C:\workspace\.copilot-shared\shared\memory\repo1\
```

---

## Per-Repo Memory Files

Agents write these files inside `memory-bank/` (→ central):

| File | Purpose |
|------|---------|
| `activeContext.md` | Current session: what's being worked on, recent decisions |
| `projectbrief.md` | Project goals, scope, core requirements |
| `systemPatterns.md` | Architecture, design patterns, component relationships |
| `techContext.md` | Tech stack, dependencies, build setup |
| `progress.md` | What works, what's left, known issues |
| `tasks/_index.md` | Task list with statuses |
| `tasks/<TASKID>-name.md` | One file per task with full history |

---

## Cross-Repo Memory Files (read from any repo)

These live directly in `shared/memory/` and are read-only for most agents:

| File | Updated by |
|------|-----------|
| `active-context.md` | Agent or user at session start/end |
| `architecture-map.md` | `bin/workspace-scan.ps1` (auto) |
| `cross-repo-learnings.md` | `save-learning` skill |
| `customer-cases.md` | `save-learning` skill after case resolution |
| `known-bugs.md` | `save-learning` skill after bug diagnosis |
| `tech-discoveries.md` | `save-learning` skill / `setup-local.ps1` |
| `repo-contexts/<repo>.md` | `bin/repo-mix-all.ps1` (auto) |

---

## Refresh Central Store

```powershell
# Full refresh: architecture map + all repo context packs
.copilot-shared\bin\full-context-refresh.cmd

# Architecture map only
.copilot-shared\bin\workspace-scan.cmd

# All repo context packs
.copilot-shared\bin\repo-mix-all.cmd

# One specific repo
.copilot-shared\bin\repo-mix.cmd -RepoPath C:\workspace\<repo> -Central
```

---

## .gitignore

`memory-bank/` is a junction and must not be committed. The scripts handle this automatically, but verify:

```gitignore
# Central memory junction -- do not commit
memory-bank/

# >>> copilot-shared junctions (managed by link-copilot.cmd)
.github/skills
.github/instructions
.github/prompts
.github/plans
# <<< copilot-shared junctions
```

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

