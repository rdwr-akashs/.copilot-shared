# 🎮 Copilot Shared Console — Master README

**The single unified interface for all copilot-shared operations.**

Stop checking README files. Stop remembering script names. Stop figuring out execution order. Just open the console and choose what you want.

## ⚡ 30-Second Quick Start

### On Windows (Easiest)
1. Open Windows Explorer
2. Navigate to `.copilot-shared\bin`
3. **Double-click `console.cmd`**
4. Choose what you want from the menu
5. ✅ Done!

### From PowerShell Terminal
```powershell
cd .copilot-shared\bin
.\console.ps1
```

## 🆕 Console Features: Workspace & Repo Modes

The console now supports **two powerful modes**:

### Mode 1: Workspace Operations (Default)
Run operations on your main `.copilot-shared` workspace:
```
Menu → Option 1, 2, 3, etc.
→ Runs automatically on workspace
→ No additional selection needed
```
**Best for:** Quick fixes, daily maintenance

### Mode 2: Repository-Specific Operations
Run **ANY command on ANY repo** in your workspace:
```
Menu → Pick ANY option (1-9, A-E)
→ Console asks: "Run on which repository?"
→ Select your repo: [W] Workspace  [1] df_core  [2] platform-tools  ...
→ Command runs on selected repo
→ Done!
```
**Best for:** Multi-repo management, selective fixes

### Mode 3: Smart Repo Selection (Fastest)
Use "R" for intelligent repo detection:
```
Menu → Option "R" (Smart Refresh for Specific Repo)
→ Displays all discovered repos
→ Pick one → Auto-detects changes → Auto-fixes
→ Done!
```
**Best for:** When you know which repo to target

## 📚 Documentation Files (Pick Your Style)


### Just Tell Me What to Do
👉 **[GET_STARTED.md](GET_STARTED.md)** — Quick scenarios & common workflows (5 min read)

### Show Me All Options
👉 **[CONSOLE_GUIDE.md](CONSOLE_GUIDE.md)** — Detailed menu reference & FAQ

### I Want to Understand Everything  
👉 **[CONSOLE_SUMMARY.md](CONSOLE_SUMMARY.md)** — What you got, how it works, architecture

### I Want to Setup Shortcuts / Auto-Run
👉 **[SHORTCUTS_AND_SCHEDULING.md](SHORTCUTS_AND_SCHEDULING.md)** — Desktop shortcuts, taskbar, Task Scheduler

### I'm Looking for Specific Info
👉 **[DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)** — Complete documentation map

### Verify Console Setup
👉 **Run validation:** `powershell -File validate-console.ps1`

## 🎯 What Problem Does This Solve?

### Before
```
User's workflow (the hard way):
1. "What script should I run?" → Check README
2. "What does it do?" → Search through 30+ scripts
3. "What order?" → Read documentation
4. "Why did it fail?" → Troubleshoot manually
5. Repeat every time 😩
```

### After
```
User's workflow (the easy way):
1. Double-click console.cmd
2. Choose what you want from the menu
3. Done! ✅
```

## 🚀 Main Features

| Feature | What It Does | When to Use |
|---------|-------------|-----------|
| **Smart Refresh** | Auto-detects changes & fixes them | After ANY changes (most common!) |
| **Smart Refresh (Repo)** | Smart refresh for specific repo | When targeting one repo |
| **Refresh Instructions** | Context refresh for instruction changes | After editing `.instructions.md` |
| **Refresh Agents** | Update agents + context | After modifying `.agent.md` |
| **Generate Skill Index** | Index and validate skills | After adding new skills |
| **Audit Copilot Assets** | Verify all components are valid | After major changes |
| **Full Context Refresh** | Deep refresh with optional dumps | Weekly housekeeping |
| **Memory Management** | Sync, backup, verify shared knowledge | Managing cases/bugs/learning |
| **Repository Setup** | Link, unlink, setup repos | Managing multiple repos |
| **Doctor** | Auto-diagnose & repair issues | Something seems broken |
| **Workspace Scan** | Map all repos and their status | Understanding structure |
| **Token Profile** | Analyze token usage | Performance optimization |
| **Git Hooks** | Setup pre-push & commit-msg hooks | Initial setup |
| **Extract Support** | Extract support bundles | Troubleshooting/analysis |
| **Local Setup** | Local development setup | First-time setup |

## 🎪 The Three Most Important Commands

### 1️⃣ Smart Refresh (Use This 90% of the Time)
```
Option "1" → Workspace refresh (or "R" for repo-specific)
→ Auto-detects what changed
→ Runs the right sequence
→ Shows progress
→ Done!
```
**When:** After editing anything (instructions, agents, skills, memory)  
**Time:** 30 seconds to 2 minutes

### 2️⃣ Full Context Refresh (Weekly Housekeeping)
```
Option "6" in the menu
→ Deep scan of all repos
→ Rebuild knowledge base
→ Optional: full content dumps
→ Done!
```
**When:** Once a week, or after major repo changes  
**Time:** 2-5 minutes

### 3️⃣ Doctor (Something Broke)
```
Option "9" in the menu
→ Auto-diagnoses problems
→ Suggests fixes
→ Applies them
→ Done!
```
**When:** Something seems broken or wrong  
**Time:** 1-2 minutes

## 📋 All Console Options

```
MAIN MENU
├─ 1. Smart Refresh (workspace)
│   └─ Detect changes and auto-fix
├─ R. Smart Refresh (specific repo)
│   └─ Select repo and auto-fix
├─ 2. Refresh Instructions
│   └─ After editing instruction files
├─ 3. Refresh Agents
│   └─ After modifying agent files
├─ 4. Generate Skill Index
│   └─ After adding new skills
├─ 5. Audit Copilot Assets
│   └─ Validate all components
├─ 6. Full Context Refresh
│   └─ Deep refresh with optional dumps
├─ 7. Memory Management
│   ├─ Verify Central Memory
│   ├─ Verify and Repair
│   ├─ Centralize Memory
│   ├─ Export Memory
│   └─ Import Memory
├─ 8. Repository Setup
│   ├─ Setup New Repository
│   ├─ Setup All Repositories
│   ├─ Link Repository
│   ├─ Link All Repositories
│   ├─ Unlink Repository
│   ├─ Copy Agents
│   ├─ Repo Mix (one)
│   └─ Repo Mix All
├─ 9. Doctor (diagnosis and repair)
│   └─ Auto-diagnose and fix issues
├─ A. Workspace Scan
│   └─ Map all repos and status
├─ B. Token Profile
│   └─ Analyze token usage
├─ C. Git Hooks Setup
│   └─ Install pre-push and commit-msg hooks
├─ D. Extract Support Bundle
│   └─ Extract support files for analysis
├─ E. Local Setup
│   └─ Local development setup
└─ 0. Exit
```

## 🎓 Common Scenarios

### Scenario: "I just edited an instruction file"
```
→ Open console (double-click console.cmd)
→ Press "1" for Smart Refresh
→ Wait 1 minute
→ ✓ Done! Agents see the change
```

### Scenario: "I added a new skill"
```
→ Open console
→ Press "1" for Smart Refresh
→ Wait 1 minute
→ ✓ Done! New skill is indexed & available
```

### Scenario: "Something feels broken"
```
→ Open console
→ Press "9" for Doctor
→ Wait 2-3 minutes
→ ✓ Done! Doctor diagnosed & fixed it
```

### Scenario: "It's Sunday morning"
```
→ Open console
→ Press "6" for Full Context Refresh
→ Wait 3-5 minutes
→ ✓ Done! Knowledge base refreshed for the week
```

### Scenario: "I need to setup a new repository"
```
→ Open console
→ Press "8" for Repository Setup
→ Press "1" for Setup New Repository
→ Enter the repo path
→ Wait 2-3 minutes
→ ✓ Done! Repo is wired and ready
```

## ✅ Getting Started Checklist

- [ ] Read [GET_STARTED.md](GET_STARTED.md) (5 min)
- [ ] Launch console: `.\console.ps1` or double-click `console.cmd`
- [ ] Try option "1" (Smart Refresh) to see it in action
- [ ] (Optional) Create a desktop shortcut (see SHORTCUTS_AND_SCHEDULING.md)
- [ ] (Optional) Setup auto-refresh via Task Scheduler (see SHORTCUTS_AND_SCHEDULING.md)
- [ ] ✓ You're done!

## 🔧 How to Launch

| Method | Command | Time | Best For |
|--------|---------|------|----------|
| **Windows Explorer** | Double-click `console.cmd` | 2 sec | Daily use |
| **PowerShell Terminal** | `.\console.ps1` | 2 sec | Developers |
| **Desktop Shortcut** | Click shortcut on desktop | 1 sec | Power users |
| **Auto-scheduled** | Task Scheduler | 0 sec | Hands-off |
| **Command Line** | `console.cmd quick` | Instant | CI/CD pipes |

Details: See [SHORTCUTS_AND_SCHEDULING.md](SHORTCUTS_AND_SCHEDULING.md)

## 🎯 What It Detects Automatically

The console is smart enough to detect:

✅ Changed instruction files → triggers context refresh  
✅ New agent templates → triggers agent refresh + context  
✅ New skills → triggers indexing + auditing + context  
✅ Memory changes → triggers verification & sync  
✅ Missing repos → suggests setup  

**Just use Smart Refresh** and the console figures out what needs to happen!

## 🔄 What Actually Happens

When you run **Smart Refresh**, the console:

1. 🔍 Scans for changes in instructions, agents, skills, memory
2. 🎯 Determines optimal sequence of operations
3. ⚙️ Runs each operation in order
4. 📊 Shows real-time progress
5. ✅ Reports success/failure

Example: If you edit 2 instruction files + add 1 new skill:
```
Change detected: 2 instruction files changed
Change detected: 1 new skill added
Recommended actions:
  → generate-skill-index
  → audit-copilot-assets
  → full-context-refresh
Running: generate-skill-index... ✓
Running: audit-copilot-assets... ✓
Running: full-context-refresh... ✓
Smart refresh completed!
```

## ❓ FAQ

**Q: Do I really need to read all the documentation?**  
A: No! Just read [GET_STARTED.md](GET_STARTED.md) (~5 min), then use Smart Refresh. That covers 90% of use cases.

**Q: What if I don't know which option to choose?**  
A: Use **Smart Refresh** (option "1"). It's smart enough for 95% of situations.

**Q: Can I run this in the background / automatically?**  
A: Yes! See [SHORTCUTS_AND_SCHEDULING.md](SHORTCUTS_AND_SCHEDULING.md) for Windows Task Scheduler setup.

**Q: What if something breaks?**  
A: Use **Doctor** (option "9"). It auto-diagnoses and repairs most issues.

**Q: Do I need to remember which script to run?**  
A: No! The console handles that for you. Just pick from the menu.

**Q: Can I create a desktop shortcut?**  
A: Yes! Multiple methods explained in [SHORTCUTS_AND_SCHEDULING.md](SHORTCUTS_AND_SCHEDULING.md).

**Q: Does this work on Mac/Linux?**  
A: `.ps1` scripts work on all platforms. Windows `.cmd` wrapper is Windows-only.

**Q: How often should I run this?**  
A: After any changes (use Smart Refresh). Also run Weekly Refresh for housekeeping.

## 🏗️ File Structure

```
bin/
├── console.ps1                    ← Main console (runs on all platforms)
├── console.cmd                    ← Windows launcher (DOUBLE-CLICK THIS!)
├── validate-console.ps1           ← Test console setup
│
├── README.md                       ← This file (overview)
├── GET_STARTED.md                 ← Start here! (quick start)
├── CONSOLE_GUIDE.md               ← Detailed menu reference
├── CONSOLE_SUMMARY.md             ← What you got & how it works
├── DOCUMENTATION_INDEX.md         ← Complete documentation map
├── SHORTCUTS_AND_SCHEDULING.md    ← Desktop shortcuts & auto-run
│
├── (all other existing scripts)
└── ...
```

## 🔍 Verification

Want to make sure everything is set up correctly?

```powershell
cd .copilot-shared\bin
powershell -File validate-console.ps1
```

The validator checks:
- ✓ All console files present
- ✓ Dependent scripts available
- ✓ PowerShell version compatible
- ✓ Execution policy allows scripts
- ✓ Git repository status
- ✓ Directory structure correct
- ✓ File permissions okay
- ✓ Documentation complete

## � Advanced: Running Commands Manually

The console is the **recommended way**, but you can still run individual scripts directly if needed:

### Direct Script Execution

**Smart Detection & Auto-Fix:**
```powershell
cd .copilot-shared
powershell -File bin\console.ps1 -Quick
```

**Full Context Refresh:**
```powershell
powershell -File bin\full-context-refresh.ps1
powershell -File bin\full-context-refresh.ps1 -FullDumps
```

**Generate Skill Index:**
```powershell
powershell -File bin\generate-skill-index.ps1
```

**Audit Copilot Assets:**
```powershell
powershell -File bin\audit-copilot-assets.ps1
```

**Memory Management:**
```powershell
powershell -File bin\verify-central-memory.ps1
powershell -File bin\verify-central-memory.ps1 -Repair
powershell -File bin\centralize-memory.ps1
powershell -File bin\export-memory.ps1
powershell -File bin\import-memory.ps1
```

**Repository Setup:**
```powershell
powershell -File bin\setup-repo.ps1 -RepoPath "path\to\repo"
powershell -File bin\setup-all-repos.ps1
powershell -File bin\repo-mix.ps1 -Repo "repo-name"
powershell -File bin\repo-mix-all.ps1
```

**Diagnosis & Repair:**
```powershell
powershell -File bin\doctor.ps1
```

**Workspace Analysis:**
```powershell
powershell -File bin\workspace-scan.ps1
```

**Other Tools:**
```powershell
powershell -File bin\token-profile.ps1
powershell -File bin\extract-support-bundle.ps1
cmd /c bin\install-hooks.cmd
powershell -File bin\setup-local.ps1
```

### Running on Specific Repos

When executing scripts manually on specific repos, use the repo-aware parameters:
```powershell
cd "path\to\specific\repo"
powershell -File ..\bin\full-context-refresh.ps1
powershell -File ..\bin\repo-mix.ps1
```

**Note:** The console's **repo selector** handles all of this automatically, so you don't need to navigate manually!

## 🚀 Next Steps


1. **👉 Read:** [GET_STARTED.md](GET_STARTED.md) (5 minutes)
2. **👉 Launch:** Double-click `console.cmd` (2 seconds)
3. **👉 Try:** Option "1" (Smart Refresh) (30 seconds)
4. **👉 Reference:** [CONSOLE_GUIDE.md](CONSOLE_GUIDE.md) as needed

## 📊 Impact Summary

| Aspect | Before | After |
|--------|--------|-------|
| **Learning curve** | 30 minutes | 5 minutes |
| **Time per operation** | 5-10 minutes | 30 seconds - 2 minutes |
| **Scripts to remember** | 30+ | 0 (menu-driven) |
| **README checking** | Every time | Never |
| **Troubleshooting** | Manual | Automatic via Doctor |
| **Error recovery** | Complex | Press button, done |

## 🎉 Summary

**Before:** Users had to manually check README files, remember 30+ script names, figure out execution order, and troubleshoot failures.

**After:** Users just open the console, pick what they want from a menu, and the console handles everything else.

---

**Ready to get started?** 👉 [GET_STARTED.md](GET_STARTED.md)

**Questions?** 👉 [CONSOLE_GUIDE.md](CONSOLE_GUIDE.md)

**Looking for something specific?** 👉 [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)

**Want desktop shortcuts?** 👉 [SHORTCUTS_AND_SCHEDULING.md](SHORTCUTS_AND_SCHEDULING.md)

Happy automating! 🚀
