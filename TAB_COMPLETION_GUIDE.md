# Tab Completion Guide — PowerShell ArgumentCompleter

## ✨ What's New

PowerShell tab completion is now enabled! When you type a command and press **Tab**, you'll see all available options and aliases with descriptions.

---

## 🎯 Usage

### Token Profile Tab Completion

**Basic usage:**
```powershell
PS> .\bin\token-profile.ps1 -Profile <Tab>

# Shows menu of options:
aggressive    Alias → aggressive
agg           Alias → aggressive
aggr          Alias → aggressive
a             Alias → aggressive
balanced      balanced
bal           Alias → balanced
b             Alias → balanced
```

**Partial matching:**
```powershell
PS> .\bin\token-profile.ps1 -Profile a<Tab>
# Only shows options starting with 'a':
aggressive
agg
aggr
a

PS> .\bin\token-profile.ps1 -Profile b<Tab>
# Only shows options starting with 'b':
balanced
bal
b
```

**Select and press Enter:**
```powershell
PS> .\bin\token-profile.ps1 -Profile <Tab>
# Use arrow keys to select, press Enter to insert
aggressive ← selected
```

---

## 📋 How It Works

### The Implementation

**1. Completer Function** (`DynamicProfiles.psm1`)
```powershell
function Get-DynamicCompleter {
    # Returns a scriptblock that can be used as ArgumentCompleter
    # Dynamically discovers options from config
    # Shows aliases with descriptions
}
```

**2. Script Usage** (`token-profile.ps1`)
```powershell
$ProfileCompleter = { ... }  # Define the completer

param(
    [Parameter(Mandatory = $true)]
    [ArgumentCompleter($ProfileCompleter)]  # ← Attach to parameter
    [string]$Profile,
    ...
)
```

**3. What It Does**
- Loads `script-profiles.yaml` dynamically
- Gets all available options (balanced, aggressive)
- Gets all aliases (agg, aggr, a, bal, b)
- Filters based on what you typed
- Shows descriptions (main option vs alias)

---

## 🔧 For Script Developers

### Add Tab Completion to Your Script

**Step 1: Define a completer function**
```powershell
$MyCompleter = {
    param($wordToComplete, $commandAst, $cursorPosition)
    
    $root = Split-Path $PSScriptRoot -Parent
    Import-Module (Join-Path $root 'shared/modules/DynamicProfiles.psm1') -Force
    
    $options = Get-DynamicOptions -ProfileName 'my-parameter' -WorkspaceRoot $root
    # ... generate completions
}
```

**Step 2: Or use the reusable helper**
```powershell
# Even simpler - the module provides a ready-to-use completer
$completer = Get-DynamicCompleter -ProfileName 'my-parameter' -WorkspaceRoot $root

param(
    [ArgumentCompleter($completer)]
    [string]$MyParameter
)
```

**Step 3: Apply to your parameter**
```powershell
param(
    [ArgumentCompleter($MyCompleter)]
    [string]$Profile
)
```

---

## 💡 Benefits

| Feature | Benefit |
|---------|---------|
| **Discoverability** | Users see all options without reading docs |
| **Error Prevention** | Can't type invalid values if you use Tab |
| **Alias Support** | Shows what each alias expands to |
| **Fast Input** | Type `a` + Tab → `aggressive` (autocomplete) |
| **Self-Documenting** | Descriptions appear inline |

---

## 🚀 Examples in PowerShell ISE/Terminal

### Example 1: Start from scratch
```powershell
PS> .\bin\token-profile.ps1 -Profile <Tab>
# Shows all 7 options and aliases
```

### Example 2: Narrow down with letters
```powershell
PS> .\bin\token-profile.ps1 -Profile ag<Tab>
# Only shows options starting with 'ag':
aggressive
agg
aggr
```

### Example 3: Use arrow keys to select
```powershell
PS> .\bin\token-profile.ps1 -Profile <Tab>
# Press ↓ twice to select 'balanced'
balanced
# Press Enter to insert it
```

### Example 4: Mixed typing and tab
```powershell
PS> .\bin\token-profile.ps1 -Profile b<Tab>
# Shows options starting with 'b'
# Press ↓ to get 'balanced' or 'bal'
# Press Enter
PS> .\bin\token-profile.ps1 -Profile balanced -RepoPath .
```

---

## ⚙️ Technical Details

### ArgumentCompleter Attributes

The `[ArgumentCompleter(...)]` attribute in PowerShell:
- Runs the provided scriptblock when Tab is pressed
- Parameters: `$wordToComplete`, `$commandAst`, `$cursorPosition`
- Returns array of `CompletionResult` objects
- Each result has: text, display text, result type, tooltip

### Get-DynamicCompleter

Reusable helper function that:
- Captures `ProfileName` and `WorkspaceRoot` in closure
- Returns a scriptblock ready to use with `[ArgumentCompleter(...)]`
- Handles errors gracefully (silent fail)
- Works across any script using the dynamic profiles

---

## 🔄 What's Next

### Planned Completers
- [ ] doctor.ps1 - Check level options (critical, standard, exhaustive)
- [ ] refresh-agents.ps1 - Refresh level options (minimal, full, custom)

- [ ] Any repo-specific config values

### Enhancement Ideas
- Colored output for main options vs aliases
- Show current setting as hint
- Multi-select for complex parameters
- Context-aware completions (different options based on other parameters)

---

## 🧪 Testing

**Test in PowerShell:**
```powershell
# Navigate to the repo
cd C:\rdwr-intelij\.copilot-shared

# Try tab completion
.\bin\token-profile.ps1 -Profile <Tab>

# Should see:
# aggressive, agg, aggr, a
# balanced, bal, b
# (With descriptions showing which are aliases)
```

**Works in:**
- ✅ PowerShell Console
- ✅ PowerShell ISE
- ✅ VS Code PowerShell Terminal
- ✅ Windows Terminal
- ✅ Most PS hosts with tab completion support

---

## 📝 Related Files

- [bin/token-profile.ps1](./bin/token-profile.ps1) — Updated with ArgumentCompleter
- [shared/modules/DynamicProfiles.psm1](./shared/modules/DynamicProfiles.psm1) — `Get-DynamicCompleter` function
- [shared/config/script-profiles.yaml](./shared/config/script-profiles.yaml) — Profile definitions
- [DYNAMIC_VALUES_IMPLEMENTATION.md](./DYNAMIC_VALUES_IMPLEMENTATION.md) — Related feature documentation
