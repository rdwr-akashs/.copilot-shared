# 🔗 Creating Desktop Shortcuts & Task Scheduling

Make launching the console even easier by creating shortcuts or automating it with Windows Task Scheduler.

## Option 1: Desktop Shortcut (Easiest - 30 seconds)

### Method A: Right-Click & Send To
1. Open Windows Explorer
2. Navigate to `.copilot-shared\bin`
3. Right-click on **`console.cmd`**
4. Select **"Send to"** → **"Desktop (create shortcut)"**
5. A shortcut appears on your desktop ✓
6. Now you can **double-click it anytime** to launch the console

### Method B: Manual Shortcut
1. Right-click on your **Desktop**
2. Select **"New"** → **"Shortcut"**
3. In "Location of item", paste:
   ```
   %COMSPEC% /c "C:\rdwr-intelij\.copilot-shared\bin\console.cmd"
   ```
   *(Replace `C:\rdwr-intelij` with your actual workspace path)*
4. Click **Next**
5. Name it: **"Copilot Console"** (or whatever you like)
6. Click **Finish**
7. Done! ✓

### Method C: PowerShell Shortcut
If you prefer to keep PowerShell visible:
1. Right-click on your **Desktop**
2. Select **"New"** → **"Shortcut"**
3. In "Location of item", paste:
   ```
   powershell.exe -NoExit -Command "& 'C:\rdwr-intelij\.copilot-shared\bin\console.ps1'"
   ```
4. Click **Next**
5. Name it: **"Copilot Console"**
6. Click **Finish**
7. Right-click the shortcut → **"Properties"**
8. Change **"Run"** to **"Minimized"** (optional)
9. Click **Apply** → **OK**
10. Done! ✓

## Option 2: Taskbar Pinning

Want quick access from your taskbar?

1. Create a shortcut using Method A or B above
2. Right-click the desktop shortcut
3. Select **"Pin to taskbar"** or **"Pin to Start menu"**
4. The console now appears in your taskbar! ✓
5. Click it anytime to launch

## Option 3: Quick Launch (Windows + R)

Add the console to your Quick Run list:

1. Open Windows Explorer
2. Navigate to: `%APPDATA%\Microsoft\Windows\SendTo`
3. Right-click in the empty space
4. Select **"New"** → **"Shortcut"**
5. Paste:
   ```
   C:\rdwr-intelij\.copilot-shared\bin\console.cmd
   ```
6. Name it: **"Copilot Console"**
7. Now you can press **Windows + R**, type parts of the name, and hit Enter ✓

## Option 4: Auto-Refresh on Schedule (Windows Task Scheduler)

Set up automatic smart refresh every week:

### Step 1: Create the batch file
1. Navigate to `.copilot-shared\bin`
2. Create a new file: **`auto-refresh.cmd`**
3. Paste this:
   ```batch
   @echo off
   REM Auto-refresh on schedule
   powershell -NoProfile -ExecutionPolicy Bypass -File "C:\rdwr-intelij\.copilot-shared\bin\console.ps1" -Quick
   exit /b 0
   ```

### Step 2: Create Windows Task
1. Open **Windows Task Scheduler**
   - Press **Windows + S**, search for "Task Scheduler", open it
   - Or: Settings → System → "Task Scheduler" (easier search)
2. Click **"Create Basic Task"** (on the right panel)
3. **Name:** `Copilot Smart Refresh`
4. **Description:** `Auto-refresh copilot-shared changes`
5. Click **Next**
6. **Trigger:** Select when you want this to run
   - Weekly: Every Sunday 1:00 AM *(recommended)*
   - Daily: 2:00 AM
   - On logon: Every time you start your computer
7. Click **Next**
8. **Action:** Select **"Start a program"**
9. **Program/script:** Paste the full path:
   ```
   C:\rdwr-intelij\.copilot-shared\bin\auto-refresh.cmd
   ```
10. Click **Next** → **Finish**
11. Done! ✓ The console will now auto-run on your schedule

### Verify It Worked
1. Open Task Scheduler
2. Look for **"Copilot Smart Refresh"** in the list
3. Right-click → **"Run"** to test it immediately
4. Check that it completes successfully

## Option 5: Context Menu Integration

Add "Refresh Copilot" directly to Windows context menu:

### Step 1: Create Registry Entry
1. Open **Notepad**
2. Paste this:
   ```reg
   Windows Registry Editor Version 5.00

   [HKEY_CLASSES_ROOT\Directory\Background\shell\CopilotRefresh]
   @="Refresh Copilot"
   "Icon"="C:\\rdwr-intelij\\.copilot-shared\\bin\\console.cmd"

   [HKEY_CLASSES_ROOT\Directory\Background\shell\CopilotRefresh\command]
   @="cmd /c \"C:\\rdwr-intelij\\.copilot-shared\\bin\\console.cmd\""
   ```
3. Save as: **`add-context-menu.reg`** (in `.copilot-shared\bin`)
4. Double-click to import
5. Click **Yes** when prompted

### Now:
Right-click on any folder background → **"Refresh Copilot"** launches the console ✓

### Undo:
Delete the same registry entry by creating a file **`remove-context-menu.reg`**:
```reg
Windows Registry Editor Version 5.00

[-HKEY_CLASSES_ROOT\Directory\Background\shell\CopilotRefresh]
```
Double-click to remove.

## Quick Reference

| Method | Time to Launch | Effort to Setup | Best For |
|--------|---|---|---|
| Double-click `.cmd` in Explorer | 5 seconds | None | Daily use |
| Desktop shortcut | 2 seconds | 30 seconds | Most common |
| Taskbar shortcut | 1 second | 1 minute | Power users |
| Windows + R | 3 seconds | 2 minutes | Minimalists |
| Auto-scheduled | 0 (automatic) | 5 minutes | Set & forget |
| Context menu | 3 seconds | 2 minutes | Frequent use |

## Tips & Tricks

### Tip 1: Rename for Clarity
- Rename shortcut to **"🎮 Copilot"** (emoji for easier finding)
- Or **"Fix Copilot"** if you're troubleshooting
- Or **"Refresh Now"** for auto-refresh versions

### Tip 2: Change Icon
For visual distinction:
1. Right-click shortcut → **Properties**
2. Click **"Change Icon..."**
3. Browse to a icon (or find one online and save it locally)
4. Select and click **OK**

Popular choices:
- Command prompt icon (usually in `C:\Windows\System32\cmd.exe`)
- PowerShell icon (in `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe`)
- Or use an online icon and save as `.ico` file

### Tip 3: Minimize on Startup
If using PowerShell shortcut:
1. Right-click → **Properties**
2. In **"Start in"** field, enter:
   ```
   C:\rdwr-intelij\.copilot-shared\bin
   ```
3. Set **"Run"** to **"Minimized"**
4. Click **OK**

### Tip 4: Add to Quick Access (Windows 11)
1. Create a shortcut on Desktop
2. Drag it to Windows Explorer's **"Quick Access"** sidebar
3. Now it appears in File Explorer for quick access ✓

### Tip 5: Keyboard Shortcut
Make a desktop shortcut, then:
1. Right-click it → **Properties**
2. Click in **"Shortcut key"** field
3. Press your desired combo (e.g., **Ctrl+Alt+C**)
4. Click **OK**
5. Now **Ctrl+Alt+C** launches the console from anywhere! ✓

## Troubleshooting

### Shortcut doesn't work
- Check that the path exists: `C:\rdwr-intelij\.copilot-shared\bin\console.cmd`
- Make sure the path doesn't have spaces or special characters
- If using UNC paths, make sure the network drive is accessible

### Task Scheduler doesn't run
- Open Task Scheduler and check the **"Last Run Result"** (should be 0)
- Right-click task → **"Run"** to test manually
- Check **"History"** tab for error details
- Ensure your Windows user has permission to run scripts

### Context menu doesn't appear
- Restart Windows Explorer: Right-click taskbar → restart Explorer
- Or restart your computer
- Check that registry entry was added correctly (regedit)

### Permission denied errors
Set execution policy:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

## One-Liner for Busy People

Want everything set up in one command? Here's a PowerShell script:

```powershell
# Creates shortcut on Desktop automatically
$Shell = New-Object -ComObject WScript.Shell
$Shortcut = $Shell.CreateShortcut("$env:USERPROFILE\Desktop\Copilot Console.lnk")
$Shortcut.TargetPath = "C:\rdwr-intelij\.copilot-shared\bin\console.cmd"
$Shortcut.WorkingDirectory = "C:\rdwr-intelij\.copilot-shared\bin"
$Shortcut.IconLocation = "$env:SystemRoot\System32\cmd.exe,0"
$Shortcut.Save()

Write-Host "✓ Shortcut created on Desktop!" -ForegroundColor Green
```

Copy & paste this into PowerShell (as admin recommended), and it creates everything for you.

---

**Choose your preferred method and enjoy quick access to the console!** 🚀
