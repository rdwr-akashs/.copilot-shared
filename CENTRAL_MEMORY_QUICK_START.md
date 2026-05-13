# Central Memory Quick Checklist

**Objective:** Ensure all repos have **cases**, **bugs**, and **learning** centralized and shared.

---

## ✅ Immediate Actions

### 1. Check Current Status

```powershell
cd C:\rdwr-intelij\.copilot-shared
powershell -File bin\verify-central-memory.ps1
```

This will show:
- ✅ Which repos are fully configured
- ⚠️  Which repos are partially configured
- ❌ Which repos need setup

### 2. Auto-Repair (Optional)

If repos are missing central memory connections:

```powershell
powershell -File bin\verify-central-memory.ps1 -Repair
```

This automatically:
- Runs `setup-repo.ps1` on unconfigured repos
- Creates junctions to central memory
- Wires `.github/copilot-memory/`, `.github/learning/`, `.github/cases/`

### 3. Manual Setup (For Individual Repos)

If you prefer to set up a specific repo manually:

```powershell
# Brand new repo (never had .github setup)
.copilot-shared\bin\setup-repo.ps1 C:\rdwr-intelij\<repo-name>

# Existing repo with memory that needs centralization
powershell -File .copilot-shared\bin\centralize-memory.ps1 `
  -RepoPath "C:\rdwr-intelij" `
  -Repos "<repo-name>" `
  -CreateSymlinks 1 `
  -DeleteLocal 0 `
  -Verify 1
```

---

## 📋 What Gets Centralized

| Item | Location | Shared? | Who uses it |
|------|----------|---------|------------|
| **Customer cases** | `shared/cases/customer-cases/` | ✅ All repos | Case investigators |
| **RCA documents** | `shared/cases/root-cause-analysis/` | ✅ All repos | Support/DevOps |
| **Best practices** | `shared/learning/best-practices/` | ✅ All repos | All engineers |
| **Design patterns** | `shared/learning/design-patterns/` | ✅ All repos | Architects |
| **Troubleshooting** | `shared/learning/troubleshooting/` | ✅ All repos | Developers |
| **Known bugs** | `shared/memory/known-bugs.md` | ✅ All repos | QA/Developers |
| **Repo-specific notes** | `shared/memory/<repo-name>/` | ❌ Repo only | Maintainers |

---

## 🎯 How It Works

### From Any Repo

When you (or Copilot) write to:
```
.github/cases/customer-cases/RSEG-1234.md
```

It's instantly available at:
```
✅ <repo>/.github/cases/customer-cases/RSEG-1234.md       (via junction)
✅ .copilot-shared/shared/cases/customer-cases/RSEG-1234.md  (central)
✅ <other-repo>/.github/cases/customer-cases/RSEG-1234.md    (via their junction)
```

**No manual sync needed** — it's automatic via filesystem junctions.

---

## 🔗 How Junctions Work

```
C:\rdwr-intelij\df_core\.github\cases
    ↓ (filesystem junction)
C:\rdwr-intelij\.copilot-shared\shared\cases
```

**Writing to either location updates the same files.** All repos that have the junction see the change instantly.

---

## ✨ Example: Contributing a Case Resolution

**In df_core:**
```powershell
# Create a customer case analysis
@"
# RSEG-2024-001: BGP Failover Issue

**Symptom:** BGP peers disappear after HA failover

**Root Cause:** BgpPeer table not in HA sync list

**Fix:** Add BgpPeer to HaSyncHandler.java:342
"@ | Out-File ".github/cases/customer-cases/RSEG-2024-001.md"

git add .github/cases/
git commit -m "docs: RSEG-2024-001 case analysis"
git push
```

**Instantly visible to all repos:**
```powershell
# In kvision_collector:
Get-Content ".github/cases/customer-cases/RSEG-2024-001.md"
# ✅ Works! File is visible

# In vision_core:
Get-Content ".github/cases/customer-cases/RSEG-2024-001.md"
# ✅ Works! File is visible

# From central:
Get-Content ".copilot-shared/shared/cases/customer-cases/RSEG-2024-001.md"
# ✅ Works! Central has it too
```

---

## 🚨 Troubleshooting

| Issue | Solution |
|-------|----------|
| Memory files not visible | Restart VS Code to refresh junction paths |
| Junction creation fails | Run PowerShell as Administrator |
| Files visible locally but not in other repos | Run `verify-central-memory.ps1` to check junctions |
| Repo shows "unconfigured" in verification | Run `verify-central-memory.ps1 -Repair` |

---

## 📚 More Info

- **Detailed guide:** [CENTRAL_MEMORY_SYNC_GUIDE.md](CENTRAL_MEMORY_SYNC_GUIDE.md)
- **Architecture details:** [CENTRALIZED_MEMORY_SETUP.md](CENTRALIZED_MEMORY_SETUP.md)
- **Memory store docs:** [shared/memory/README.md](shared/memory/README.md)

---

## 🎓 Key Concepts

### Filesystem Junctions (Symlinks on Windows)
A junction is a **transparent pointer** from one location to another. When you write to either location, both see the same files.

### Single Source of Truth
All cases, bugs, and learning docs live once in `.copilot-shared/shared/`. Each repo's `.github/` points to them via junctions.

### Instant Propagation
Write a file in `df_core/.github/cases/` → it appears in `kvision_collector/.github/cases/` → it appears in `.copilot-shared/shared/cases/` simultaneously.

---

## ✅ Success Criteria

After setup, you should be able to:

1. ✅ Write a case analysis in **any repo**
2. ✅ See that file in **all other repos** without any copy/sync
3. ✅ Agents in every repo see the same **cases**, **bugs**, **learning** docs
4. ✅ Run `verify-central-memory.ps1` with all repos showing "fully-configured"

---

**Ready to sync?** Start with: `powershell -File .copilot-shared\bin\verify-central-memory.ps1`
