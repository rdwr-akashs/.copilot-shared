# Central Memory Synchronization Guide

**Goal:** Ensure all repository memory files (cases, bugs, learning) are consolidated in `.copilot-shared/shared/` and shared across all repos via filesystem junctions.

---

## 📋 Quick Status Check

Run this to see which repos are synced:

```powershell
powershell -File .copilot-shared\bin\audit-copilot-assets.ps1
```

This shows:
- ✅ Repos properly linked to central memory
- ⚠️ Repos with local memory not yet centralized
- ❌ Repos missing junctions

---

## 🔧 Setup Path: New Repo

For a freshly cloned repo that has no existing memory setup:

```powershell
# One command does everything
.copilot-shared\bin\setup-repo.ps1 C:\rdwr-intelij\<repo-name>
```

This automatically:
1. Creates `.copilot-shared/shared/memory/<repo-name>/`
2. Creates `.copilot-shared/shared/cases/` (customer-cases/, root-cause-analysis/)
3. Creates `.copilot-shared/shared/learning/` (best-practices/, design-patterns/, troubleshooting/)
4. Wires `.github/copilot-memory/` → `shared/memory/<repo-name>/`
5. Wires `.github/learning/` → `shared/learning/`
6. Wires `.github/cases/` → `shared/cases/`
7. Wires `memory-bank/` → `shared/memory/<repo-name>/` (read-only, .gitignored)
8. Copies agent templates to `.github/agents/`
9. Generates `copilot-instructions.md` with tech stack

---

## 🔗 Setup Path: Existing Repo (with local memory)

For repos that already have memory but aren't linked to central:

### Step 1: Wire Shared Structures

```cmd
# Creates junctions for skills, instructions, prompts, plans
.copilot-shared\bin\link-copilot.cmd C:\rdwr-intelij\<repo-name>
```

### Step 2: Migrate Memory to Central

```powershell
# This script:
# 1. Copies any existing memory-bank/, .github/memory/, docs/memory/ → central
# 2. Replaces local folders with junctions → central
# 3. Updates .gitignore
# 4. Verifies junction integrity

powershell -File .copilot-shared\bin\centralize-memory.ps1 `
  -RepoPath "C:\rdwr-intelij" `
  -Repos "<repo-name>" `
  -CreateSymlinks 1 `
  -DeleteLocal 0 `
  -Verify 1
```

**Parameters explained:**
- `-CreateSymlinks 1`: Create filesystem junctions (required)
- `-DeleteLocal 0`: Keep local copies for safety (set to 1 after verification)
- `-Verify 1`: Generate verification report

### Step 3: Verify Integration

After the script completes, verify junctions:

```cmd
# Windows: Show junction targets
dir /AL C:\rdwr-intelij\<repo-name>\.github\copilot-memory
dir /AL C:\rdwr-intelij\<repo-name>\.github\learning
dir /AL C:\rdwr-intelij\<repo-name>\.github\cases
dir /AL C:\rdwr-intelij\<repo-name>\memory-bank
```

Expected output:
```
copilot-memory → ..\..\..\.copilot-shared\shared\memory\<repo-name>
learning → ..\..\..\.copilot-shared\shared\learning
cases → ..\..\..\.copilot-shared\shared\cases
memory-bank → ..\..\..\.copilot-shared\shared\memory\<repo-name>
```

---

## 🎯 Setup Path: Batch Setup (Multiple Repos)

To sync all repos at once:

```powershell
# Create .copilot-shared\repos-to-setup.txt with repo names (one per line):
# df_core
# kvision_collector
# webui_components
# vision_core

# Then run:
powershell -File .copilot-shared\bin\centralize-memory.ps1 `
  -RepoPath "C:\rdwr-intelij" `
  -Repos "df_core,kvision_collector,webui_components,vision_core" `
  -CreateSymlinks 1 `
  -DeleteLocal 0 `
  -Verify 1
```

Or edit the script's default `$Repos` array to loop all:

```powershell
# In centralize-memory.ps1, change:
$Repos = @("common_policy_editor")
# To:
$Repos = @("df_core", "kvision_collector", "webui_components", "vision_core", "kafka_events")
```

---

## 📁 Central Memory Structure After Setup

```
.copilot-shared/shared/
├── memory/
│   ├── active-context.md
│   ├── architecture-map.md
│   ├── customer-cases.md
│   ├── known-bugs.md
│   ├── tech-discoveries.md
│   ├── cross-repo-learnings.md
│   ├── cross-repo/
│   │   ├── architecture-patterns.md
│   │   ├── deployment-learnings.md
│   │   └── incident-retrospectives.md
│   ├── df_core/              ← repo-specific memory
│   │   ├── memory.md
│   │   ├── performance-notes.md
│   │   └── bugs-and-patterns.md
│   ├── kvision_collector/    ← repo-specific memory
│   ├── webui_components/     ← repo-specific memory
│   ├── vision_core/          ← repo-specific memory
│   ├── repo-contexts/        ← auto-generated context packs
│   │   ├── _index.md
│   │   ├── df_core.md
│   │   └── kvision_collector.md
│   └── logs/                 ← centralize-memory.ps1 logs
│
├── cases/                    ← SHARED across all repos
│   ├── customer-cases/
│   │   ├── RSEG-1234.md
│   │   └── SC-5678.md
│   └── root-cause-analysis/
│       ├── rca-RSEG-1234.md
│       └── rca-SC-5678.md
│
└── learning/                 ← SHARED across all repos
    ├── best-practices/
    │   ├── java-patterns.md
    │   └── performance-tuning.md
    ├── design-patterns/
    │   ├── event-handling.md
    │   └── state-management.md
    └── troubleshooting/
        ├── common-errors.md
        └── debugging-guide.md
```

**Key insight:** `cases/` and `learning/` are **shared across all repos**. When any agent writes to `.github/cases/` or `.github/learning/` in ANY repo, that file appears in the central location and is instantly visible to all other repos.

---

## ✅ Verification Checklist

After centralizing each repo, verify:

### 1. Junctions Exist

```powershell
# Check each repo
Get-ChildItem -Path C:\rdwr-intelij\<repo-name>\.github -Attributes ReparsePoint
Get-ChildItem -Path C:\rdwr-intelij\<repo-name> -Attributes ReparsePoint | Where-Object { $_.Name -eq "memory-bank" }
```

Expected:
- `.github/copilot-memory` → junction
- `.github/learning` → junction
- `.github/cases` → junction
- `memory-bank/` → junction

### 2. Files Are Accessible

From within the repo:

```powershell
# Check that memory files are readable
Test-Path -Path "C:\rdwr-intelij\<repo-name>\.github\copilot-memory\memory.md"
Test-Path -Path "C:\rdwr-intelij\<repo-name>\.github\learning\best-practices"
Test-Path -Path "C:\rdwr-intelij\<repo-name>\.github\cases\customer-cases"
```

All should return `True`.

### 3. Central Mirror Works

```powershell
# Files also accessible from central location
Test-Path -Path "C:\rdwr-intelij\.copilot-shared\shared\memory\<repo-name>\memory.md"
Test-Path -Path "C:\rdwr-intelij\.copilot-shared\shared\learning\best-practices"
Test-Path -Path "C:\rdwr-intelij\.copilot-shared\shared\cases\customer-cases"
```

### 4. .gitignore Updated

```bash
# In repo root, verify .gitignore contains:
memory-bank/
.github/copilot-memory/
.github/learning/
.github/cases/
personal-instructions.md
.local.env
```

### 5: copilot-instructions.md Exists

```powershell
Test-Path -Path "C:\rdwr-intelij\<repo-name>\.github\copilot-instructions.md"
```

---

## 🔄 Daily Sync: Keep Memory in Sync

Memory stays in sync automatically via junctions. However, **when you write to memory from any repo**, it instantly propagates to:
- The central location
- All other repos pointing to the same junctions

### Example Workflow

**In repo df_core:**
```powershell
# Write a learning note
echo "Found pattern: BGP restarts on failover" > .github/learning/best-practices/bgp-patterns.md

# This file NOW EXISTS in:
# ✅ C:\rdwr-intelij\df_core\.github\learning\best-practices\bgp-patterns.md
# ✅ C:\rdwr-intelij\.copilot-shared\shared\learning\best-practices\bgp-patterns.md
# ✅ C:\rdwr-intelij\kvision_collector\.github\learning\best-practices\bgp-patterns.md  (via junction)
# ✅ All other repos that have junctions set up
```

No manual sync needed — it's automatic!

---

## 🚨 Troubleshooting

### Problem: Junction Creation Failed

```
Error: Access denied creating junction
```

**Solution:** Run PowerShell as Administrator.

### Problem: Files Appear Twice (Local + Central)

```
$<repo-name>/
  └── memory-bank/  (local files)
$<repo-name>/
  └── .github/copilot-memory/  (junction)
```

**Solution:** Delete the local `memory-bank/` folder after verifying central has the content:

```powershell
# After setup and verification, delete:
Remove-Item -Path "C:\rdwr-intelij\<repo-name>\memory-bank" -Recurse -Force
```

The junction will still work because it points to central.

### Problem: Repo Not Appearing in Central Memory

```
.copilot-shared/shared/memory/
  (where is <repo-name>/ folder?)
```

**Solution:** Run setup again with `-CreateSymlinks 1`:

```powershell
powershell -File .copilot-shared\bin\centralize-memory.ps1 `
  -RepoPath "C:\rdwr-intelij" `
  -Repos "<repo-name>" `
  -CreateSymlinks 1 `
  -DeleteLocal 0 `
  -Verify 1
```

### Problem: Memory Files Not Visible in Copilot

**Solution:** Restart VS Code to refresh the junction paths.

---

## 📊 Maintenance: Scheduled Sync

### Weekly
```powershell
# Regenerate architecture map
powershell -File .copilot-shared\bin\workspace-scan.ps1
```

### Monthly
```powershell
# Full refresh: update context packs for all repos
powershell -File .copilot-shared\bin\full-context-refresh.ps1

# Or just audit assets
powershell -File .copilot-shared\bin\audit-copilot-assets.ps1
```

---

## 🎓 What Lives Where: Decision Table

| Content Type | Location | Shared? | Edited By |
|---|---|---|---|
| Bug fix patterns | `shared/memory/known-bugs.md` | ✅ All repos | Any agent/developer |
| Case solutions | `shared/cases/customer-cases/` | ✅ All repos | Case investigator agent |
| RCA documents | `shared/cases/root-cause-analysis/` | ✅ All repos | Case investigator agent |
| Best practices | `shared/learning/best-practices/` | ✅ All repos | Any agent/developer |
| Design patterns | `shared/learning/design-patterns/` | ✅ All repos | Architects/leads |
| Repo architecture | `shared/memory/<repo>/architecture.md` | ❌ Repo-specific | Repo maintainers |
| Repo performance | `shared/memory/<repo>/performance-notes.md` | ❌ Repo-specific | Performance team |
| Repo bugs | `shared/memory/<repo>/bugs-and-patterns.md` | ❌ Repo-specific | Repo developers |

---

## ✨ Example: Contributing to Shared Learning

**Scenario:** You solve a bug in df_core that affects multiple repos.

1. **Write the solution**
   ```bash
   # In df_core repo
   echo "## BGP Peer State Lost After HA Failover
   
   **Symptom:** BGP peers disappear on standby after failover
   **Root Cause:** BgpPeer table not included in HA sync list
   **Fix:** Add BgpPeer to HaSyncHandler.java line 342
   " > .github/learning/troubleshooting/bgp-failover.md
   ```

2. **Commit the change**
   ```bash
   git add .
   git commit -m "docs: BGP failover troubleshooting guide"
   git push
   ```

3. **Verify it's shared**
   ```powershell
   # From kvision_collector repo:
   Get-Content "C:\rdwr-intelij\kvision_collector\.github\learning\troubleshooting\bgp-failover.md"
   
   # From central location:
   Get-Content "C:\rdwr-intelij\.copilot-shared\shared\learning\troubleshooting\bgp-failover.md"
   ```

4. **Agents in all repos now use it**
   - Copilot reads `.github/learning/` instructions at session start
   - All repos see the same files via junctions
   - Knowledge propagates instantly

---

## 🔗 Related Documentation

- [CENTRALIZED_MEMORY_SETUP.md](CENTRALIZED_MEMORY_SETUP.md) — Detailed architecture
- [shared/memory/README.md](shared/memory/README.md) — Central knowledge store guide
- [README.md](README.md) — Quick reference for when to refresh
