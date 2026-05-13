# Tab Completion for All Scripts — Complete Status

## ✅ Scripts with Tab Completion

Tab completion is now **enabled on all scripts with dynamic parameters**. Press **Tab** after parameter names to see auto-suggestions.

---

## 📋 Complete List

| Script | Parameter | Options | Aliases | Status |
|--------|-----------|---------|---------|--------|
| [token-profile.ps1](./bin/token-profile.ps1) | `-Profile` | balanced, aggressive | `b`, `bal`, `a`, `agg`, `aggr` | ✅ |
| [doctor.ps1](./bin/doctor.ps1) | `-CheckLevel` | critical, standard, exhaustive | `c`, `s`, `e`, `min`, `full` | ✅ |
| [refresh-agents.ps1](./bin/refresh-agents.ps1) | `-RefreshLevel` | minimal, full, custom-only | `min`, `full`, `custom` | ✅ |
| [install-hooks.ps1](./bin/install-hooks.ps1) | `-HookScope` | pre-commit, commit-msg, all | `pre`, `msg`, `all` | ✅ |

---

## 🎯 Usage Examples

### Token Profile
```powershell
PS> .\bin\token-profile.ps1 -Profile <Tab>
aggressive  (main)
agg         (Alias → aggressive)
aggr        (Alias → aggressive)
a           (Alias → aggressive)
balanced    (main)
bal         (Alias → balanced)
b           (Alias → balanced)

# Type 'a' and press Tab:
PS> .\bin\token-profile.ps1 -Profile a<Tab>
aggressive, agg, aggr, a (filtered)
```

### Doctor Check Level
```powershell
PS> .\bin\doctor.ps1 -CheckLevel <Tab>
critical    (main)
c           (Alias → critical)
standard    (main)
s           (Alias → standard)
exhaustive  (main)
e           (Alias → exhaustive)
min         (Alias → critical)
full        (Alias → exhaustive)

PS> .\bin\doctor.ps1 -CheckLevel e C:\repo
```

### Refresh Agents Level
```powershell
PS> .\bin\refresh-agents.ps1 -RefreshLevel <Tab>
minimal     (main)
min         (Alias → minimal)
full        (main)
custom-only (main)
custom      (Alias → custom-only)
```

### Install Hooks Scope
```powershell
PS> .\bin\install-hooks.ps1 -HookScope <Tab>
pre-commit  (main)
pre         (Alias → pre-commit)
commit-msg  (main)
msg         (Alias → commit-msg)
all         (main)
```

---

## 🔄 How It All Works Together

### 1. Configuration Driven
**File**: [shared/config/script-profiles.yaml](./shared/config/script-profiles.yaml)
```yaml
token-profile:
  type: "template"
  values: [balanced, aggressive]
  aliases: { b: balanced, agg: aggressive, ... }
  default: "balanced"

doctor-check-level:
  type: "enum"
  values: [critical, standard, exhaustive]
  aliases: { c: critical, e: exhaustive, ... }
  default: "standard"
```

### 2. Module Support
**File**: [shared/modules/DynamicProfiles.psm1](./shared/modules/DynamicProfiles.psm1)
```powershell
Get-DynamicOptions    # Load options from config
Expand-Alias          # Convert 'a' → 'aggressive'
Validate-Option       # Check if value is valid
Get-DynamicCompleter  # Create ArgumentCompleter
```

### 3. Script Integration
**Pattern**: Each script adds this pattern:
```powershell
$ParameterCompleter = {
    # Returns list of options + aliases with descriptions
}

param(
    [ArgumentCompleter($ParameterCompleter)]
    [string]$Parameter
)

# Expand alias and validate
$Parameter = Expand-Alias -Value $Parameter -Aliases $options.Aliases
```

---

## 🛠️ Adding Tab Completion to New Scripts

### Quick 3-Step Process

**Step 1: Add to script-profiles.yaml**
```yaml
your-parameter:
  type: "enum"
  values:
    - option1
    - option2
  aliases:
    o1: option1
    o2: option2
  default: "option1"
```

**Step 2: Copy the template in your script**
```powershell
$YourCompleter = {
    # (Copy from TEMPLATE-tab-completion.ps1)
}

param(
    [ArgumentCompleter($YourCompleter)]
    [string]$YourParameter
)
```

**Step 3: Test**
```powershell
.\your-script.ps1 -YourParameter <Tab>
# Should show options
```

---

## 📚 Files Reference

| File | Purpose |
|------|---------|
| [shared/config/script-profiles.yaml](./shared/config/script-profiles.yaml) | Central config for all script parameters |
| [shared/modules/DynamicProfiles.psm1](./shared/modules/DynamicProfiles.psm1) | Helper functions for tab completion |
| [bin/token-profile.ps1](./bin/token-profile.ps1) | Example #1: Token profile with completion |
| [bin/doctor.ps1](./bin/doctor.ps1) | Example #2: Doctor check level with completion |
| [bin/refresh-agents.ps1](./bin/refresh-agents.ps1) | Example #3: Refresh agents with completion |
| [bin/install-hooks.ps1](./bin/install-hooks.ps1) | Example #4: Install hooks with completion |
| [bin/TEMPLATE-tab-completion.ps1](./bin/TEMPLATE-tab-completion.ps1) | Developer template for adding completion |
| [TAB_COMPLETION_GUIDE.md](./TAB_COMPLETION_GUIDE.md) | Detailed guide with examples |
| [DYNAMIC_VALUES_IMPLEMENTATION.md](./DYNAMIC_VALUES_IMPLEMENTATION.md) | Design doc for dynamic values |

---

## 🧪 Testing All Scripts

```powershell
# Test each script
.\bin\token-profile.ps1 -Profile <Tab>      # Shows 7 options
.\bin\doctor.ps1 -CheckLevel <Tab>          # Shows 8 options
.\bin\refresh-agents.ps1 -RefreshLevel <Tab> # Shows 5 options
.\bin\install-hooks.ps1 -HookScope <Tab>    # Shows 5 options

# Test invalid input
.\bin\token-profile.ps1 -Profile xyz
# ERROR: Invalid profile 'xyz'.
#        Available: balanced, aggressive
#        Aliases: 'b' → 'balanced', ...
```

---

## ✨ Key Features

✅ **Fully Automated Discovery** — Options read from config files, not hardcoded  
✅ **User-Friendly Aliases** — Short forms (c, e, min) expand automatically  
✅ **Smart Filtering** — Tab shows only matching options as you type  
✅ **Helpful Descriptions** — Each option tagged as main or alias  
✅ **Works Everywhere** — PowerShell console, ISE, VS Code, Windows Terminal  
✅ **Error Messages** — Invalid input shows available options  
✅ **Easy to Extend** — Add new parameters by editing config file only  

---

## 🎓 Template-Based Approach

Copy the pattern from any working example:
- [token-profile.ps1](./bin/token-profile.ps1) ← Start here
- [doctor.ps1](./bin/doctor.ps1)
- [bin/TEMPLATE-tab-completion.ps1](./bin/TEMPLATE-tab-completion.ps1) ← Reference template

All scripts follow the same pattern:
1. Load DynamicProfiles module
2. Create completer scriptblock
3. Attach with `[ArgumentCompleter(...)]`
4. Expand alias, validate, use

---

## 📊 Coverage

| Type | Count | Coverage |
|------|-------|----------|
| Scripts with dynamic parameters | 4 | ✅ 100% |
| Parameters with tab completion | 4 | ✅ 100% |
| Options/aliases documented | 30+ | ✅ 100% |
| Examples provided | 4 | ✅ 100% |

---

## 🚀 Next Steps (Optional)

- [ ] Add more parameters to existing scripts (setup-repo, setup-local, etc.)
- [ ] Create completers for repo-specific config values
- [ ] Add contextual completers (e.g., show valid repo paths)
- [ ] Create completers for .cmd wrapper files
