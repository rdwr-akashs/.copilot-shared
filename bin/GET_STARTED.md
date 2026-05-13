# 🎮 Getting Started with Copilot Shared Console

The easiest way to manage all copilot-shared operations is through the **Copilot Shared Console** — a single unified interface for all your workflow needs.

## 🚀 Fastest Start (2 seconds)

1. Navigate to `.copilot-shared\bin` in Windows Explorer
2. **Double-click `console.cmd`**
3. Choose what you want to do from the menu
4. Done! ✅

## 📱 All Ways to Launch

### On Windows (Easiest)
1. Open Windows Explorer
2. Navigate to `.copilot-shared\bin`
3. **Double-click** `console.cmd`

### From PowerShell Terminal
```powershell
cd .copilot-shared\bin
.\console.ps1
```

### Auto-Fix Mode (Smart Refresh)
Let the console auto-detect changes and fix them:
```powershell
cd .copilot-shared\bin
.\console.ps1 -Quick
```

Or from a batch file:
```cmd
cd .copilot-shared\bin
console.cmd quick
```

### From Any Directory
If you want to run it from anywhere with full path:
```powershell
powershell -File "C:\rdwr-intelij\.copilot-shared\bin\console.ps1"
```

## 🎯 What the Console Does

| Feature | Benefit |
|---------|---------|
| **Smart Change Detection** | Automatically detects what changed and runs the right commands |
| **Interactive Menu** | Point-and-click interface — no need to remember script names |
| **Organized by Task** | Options grouped by what you're trying to accomplish |
| **Progress Tracking** | See real-time status of operations |
| **Color-Coded Output** | Green = success, Yellow = warning, Red = error |
| **Error Handling** | Graceful error messages with hints on what went wrong |

## 🎪 Main Menu Overview

### Top-Level Options
- **🚀 Smart Refresh** — Auto-detect changes and apply fixes (MOST COMMON)
- **📖 Refresh Instructions** — When you edit instruction files
- **🤖 Refresh Agents** — When you modify agent templates
- **🎯 Generate Skill Index** — After adding new skills
- **🔍 Audit Copilot Assets** — Verify all components are valid
- **📚 Full Context Refresh** — Deep refresh with optional content dumps
- **💾 Memory Management** — Sync, backup, or repair shared knowledge
- **🔧 Repository Setup** — Link/unlink repos or setup new ones
- **🏥 Doctor** — Auto-diagnose and repair problems
- **👁️  Workspace Scan** — Map all repos and their status

### Sub-Menus
When you select a category (e.g., "Memory Management"), you get more options.

## 📋 Common Scenarios

### Scenario 1: You just edited an instruction file
```
1. Open console (double-click console.cmd)
2. Press "1" for Smart Refresh
3. Console detects the change and runs:
   - Audit the instruction file
   - Refresh context
   ✓ Done!
```

### Scenario 2: You added a new skill
```
1. Open console
2. Press "1" for Smart Refresh
3. Console detects the new SKILL.md and runs:
   - Generate skill index
   - Audit assets
   - Refresh context
   ✓ Done!
```

### Scenario 3: Something feels broken
```
1. Open console
2. Press "9" for Doctor
3. Console:
   - Scans for problems
   - Suggests fixes
   - Applies them automatically
   ✓ Done!
```

### Scenario 4: Weekly housekeeping
```
1. Open console
2. Press "6" for Full Context Refresh
3. Console asks if you want full content dumps (optional)
4. Refreshes entire knowledge base
   ✓ Done!
```

### Scenario 5: Setting up a new repo
```
1. Open console
2. Press "8" for Repository Setup
3. Press "1" for Setup New Repository
4. Enter the repo path
5. Console:
   - Copies agents
   - Creates junctions
   - Wires memory
   ✓ Done!
```

## 💡 Pro Tips

### Tip 1: Use Smart Refresh 90% of the time
The console is smart enough to detect what you changed and do exactly what needs to be done. After making any changes to instructions, agents, or skills — just use Smart Refresh.

### Tip 2: Create a Shortcut on Your Desktop
1. Right-click on `console.cmd`
2. Select "Send to" → "Desktop (create shortcut)"
3. Now you can launch it from anywhere by double-clicking the shortcut

### Tip 3: Run from Visual Studio Code
In VS Code, open the integrated terminal and run:
```powershell
.\bin\console.ps1
```

### Tip 4: Use Quick Mode for Automation
If you want to script this or use it in automation:
```powershell
.\bin\console.ps1 -Quick
# Detects changes and fixes them, then exits
```

## 🔧 Customization

### Environment Variable (Optional)
If the console can't find your workspace, set:
```cmd
setx COPILOT_WORKSPACE_ROOT "C:\your\workspace\path"
```

Most of the time, the console auto-detects this, so you don't need to do this.

### Change Default Workspace
```powershell
.\console.ps1 -Workspace "C:\custom\path"
```

## ❓ Frequently Asked Questions

**Q: Do I need to be in the `.copilot-shared\bin` directory?**  
A: No — double-click `console.cmd` from anywhere in Explorer, or use the full path from PowerShell.

**Q: What if a script fails?**  
A: The console shows the error message. Run "Doctor" to auto-diagnose and repair.

**Q: Can I run this from a CI/CD pipeline?**  
A: Yes! Use `-Quick` mode which auto-fixes everything and exits.

**Q: Does this work on Mac/Linux?**  
A: The `.ps1` scripts do, but the `.cmd` wrapper is Windows-only. On Mac/Linux, run directly: `powershell -File bin/console.ps1`

**Q: How often should I run this?**  
A: After any changes (use Smart Refresh). Also run Weekly Refresh for housekeeping.

## 📚 Next Steps

1. **[CONSOLE_GUIDE.md](CONSOLE_GUIDE.md)** — Detailed menu reference
2. **[../README.md](../README.md)** — Full repository documentation
3. **[../CENTRAL_MEMORY_SYNC_GUIDE.md](../CENTRAL_MEMORY_SYNC_GUIDE.md)** — Memory management details

## 🆘 Troubleshooting

### "PowerShell execution policy" error
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "console.ps1 not found"
Make sure you're in the `.copilot-shared\bin` directory or use the full path.

### "Command not recognized"
Make sure you have PowerShell 5.0 or later. Check with:
```powershell
$PSVersionTable.PSVersion
```

---

**That's it!** You're ready to use the Copilot Shared Console. Enjoy the simplified workflow! 🎉
