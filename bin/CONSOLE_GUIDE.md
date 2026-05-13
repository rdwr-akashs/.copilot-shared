# Copilot Shared Console — Quick Reference

## What is it?

A unified, interactive console for managing all copilot-shared operations. No more manually checking README files or remembering which script to run — just launch the console and choose what you need.

## Quick Start

### Option 1: Interactive Menu (Recommended)
```powershell
cd .copilot-shared\bin
.\console.ps1
```

Or simply **double-click** `console.cmd` from Windows Explorer.

### Option 2: Smart Auto-Fix
```powershell
cd .copilot-shared\bin
.\console.ps1 -Quick
```

The console automatically:
- 🔍 Detects what changed (instructions, agents, skills, memory)
- 🎯 Recommends the right sequence of commands
- ⚙️ Runs them in the correct order
- ✓ Shows progress and success/failure status

## Main Menu Options

| Option | What it does | When to use |
|--------|-------------|-----------|
| **1** | Smart Refresh | After ANY changes in .copilot-shared |
| **2** | Refresh Instructions | After editing `.instructions.md` files |
| **3** | Refresh Agents | After updating `.agent.md` files |
| **4** | Generate Skill Index | After adding new skills |
| **5** | Audit Copilot Assets | Verify all agents/skills are valid |
| **6** | Full Context Refresh | Weekly refresh (with optional full content dumps) |
| **7** | Memory Management | Sync/backup/verify shared knowledge |
| **8** | Repository Setup | Link/unlink repos or setup new ones |
| **9** | Doctor | Diagnose and auto-repair issues |
| **A** | Workspace Scan | Map all repos and their status |

## What Changed? Auto-Detection

The console watches for changes in:

| Type | Examples | Action Triggered |
|------|----------|------------------|
| **Instructions** | `*.instructions.md` | Full context refresh |
| **Agents** | `*.agent.md` files | Refresh agents + context |
| **Skills** | `SKILL.md` files | Reindex + audit + refresh |
| **Memory** | Cases, bugs, learning docs | Verify central memory sync |
| **Repos** | Linked repos missing | Offer setup for new repos |

## Common Workflows

### After cloning `.copilot-shared` for the first time
```
1. Open console
2. Select "Repository Setup" → "Setup All Repositories"
3. Select "Memory Management" → "Verify & Repair"
```

### After editing instruction files
```
1. Open console
2. Select "Smart Refresh" — it auto-detects and fixes everything
```

### After adding a new skill
```
1. Open console
2. Select "Generate Skill Index" (or just use Smart Refresh)
```

### Weekly housekeeping
```
1. Open console
2. Select "Full Context Refresh"
   (optionally enable -FullDumps for offline browsing)
```

### Troubleshooting issues
```
1. Open console
2. Select "Doctor" — auto-diagnoses and repairs
```

## File Locations

- **Console Scripts**: `.copilot-shared/bin/`
- **Configuration**: `.copilot-shared/shared/instructions/`
- **Central Memory**: `.copilot-shared/shared/memory/`
- **Agent Templates**: `.copilot-shared/agent-templates/`
- **Skills**: `.copilot-shared/shared/skills/`

## Tips

✅ **Use Smart Refresh** after almost any change — it's smart enough to detect what changed and run only what's needed.

✅ **Double-click `console.cmd`** on Windows for the easiest experience (no terminal needed).

✅ **Run Weekly** — `Full Context Refresh` keeps your documentation and memory synced.

✅ **Check Doctor** if anything seems broken — it auto-detects and repairs many issues.

## Keyboard Shortcuts in Console

- Type the number (1, 2, 3, etc.) to select an option
- Type **0** to go back or exit
- Press **Enter** to confirm
- Type **Q** to quit at any time

## Troubleshooting

### Console won't launch
```powershell
# Check if PowerShell can run scripts
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "File not found" errors
- Make sure you're in the `.copilot-shared\bin` folder
- Or use the full path: `powershell -File "C:\rdwr-intelij\.copilot-shared\bin\console.ps1"`

### Scripts fail but console shows success
- Check the detailed error message in the console output
- Run "Doctor" from the console to diagnose

## Environment Variable (Optional)

For scripts outside `.copilot-shared`, set:
```cmd
setx COPILOT_WORKSPACE_ROOT "C:\rdwr-intelij"
```

The console auto-detects the workspace root, but this env var helps other scripts find it.

## For More Details

See the full documentation:
- `README.md` — Overview and detailed setup
- `CENTRAL_MEMORY_SYNC_GUIDE.md` — Memory synchronization
- `CENTRAL_MEMORY_STRUCTURE.md` — Where files live
