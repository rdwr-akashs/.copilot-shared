# Dynamic Values & Repo Specificity — Implementation Summary

## ✅ What's Fixed

### The Problem
```powershell
# ❌ OLD: This error when using alias 'aggr'
PS> .\bin\token-profile.ps1 aggr .
ERROR: Cannot validate argument on parameter 'Profile'. The argument "aggr" does not belong 
to the set "balanced,aggressive" specified by the ValidateSet attribute.
```

### The Solution
```powershell
# ✅ NEW: Now works! Aliases automatically expand
PS> .\bin\token-profile.ps1 aggr .
Applied 'aggressive' token profile to: ...

# Also works:
PS> .\bin\token-profile.ps1 bal .
PS> .\bin\token-profile.ps1 b .
PS> .\bin\token-profile.ps1 balanced .
```

---

## 📁 New Infrastructure Created

### 1. **Script Profiles Configuration** (`shared/config/script-profiles.yaml`)
Centralized, declarative definition of all script parameters:
- Automatically discovered options (no hardcoding)
- User-friendly aliases
- Validation rules
- Defaults

### 2. **Dynamic Profiles Module** (`shared/modules/DynamicProfiles.psm1`)
PowerShell module with helper functions:
- `Get-DynamicOptions` — Scan config and discover available values
- `Expand-Alias` — Convert shorthand to canonical names
- `Validate-Option` — Friendly error messages
- `Load-RepoConfig` — Load `.github/copilot-config.yaml`
- `Load-WorkspaceConfig` — Load `.local.env`

### 3. **Repo-Specific Config Template** (`templates/copilot-config.template.yaml`)
Per-repository overrides created by `setup-repo.ps1`:
```yaml
# Example: .github/copilot-config.yaml (created per-repo)
token-profile: balanced           # or aggressive
doctor-check-level: standard      # or critical/exhaustive
refresh-agents-level: minimal     # or full/custom-only
install-hooks-scope: all          # or pre-commit/commit-msg
```

---

## 🔧 How It Works

### Token Profile Example

**Before** (hardcoded, breaks with aliases):
```powershell
param(
    [ValidateSet('balanced', 'aggressive')]  # ❌ Hardcoded
    [string]$Profile
)
```

**After** (dynamic discovery):
```powershell
# Load options from config
$options = Get-DynamicOptions -ProfileName 'token-profile' -WorkspaceRoot $root

# Expand alias: 'aggr' → 'aggressive'
$Profile = Expand-Alias -Value $Profile -Aliases $options.Aliases

# Validate and show helpful errors if wrong
if ($options.List -notcontains $Profile) {
    Write-Host "ERROR: Invalid profile '$Profile'"
    Write-Host "Available: $($options.List -join ', ')"
    Write-Host "Aliases: $($options.Aliases | Format-Table -HideTableHeaders)"
}
```

---

## 📖 Available Aliases

### Token Profile
| Alias | Expands to | Meaning |
|-------|-----------|---------|
| `aggr`, `agg`, `a` | `aggressive` | Maximum token savings |
| `bal`, `b` | `balanced` | Default optimization |

### Future (Template)
| Script | Alias | Expands to |
|--------|-------|-----------|
| doctor | `c`, `critical` | Minimal checks |
| doctor | `s`, `standard` | Default checks |
| doctor | `e`, `exhaustive` | All checks |

---

## 🚀 Usage Examples

### Run token-profile with alias
```powershell
# All equivalent:
.\bin\token-profile.ps1 aggr C:\repo
.\bin\token-profile.ps1 aggressive C:\repo
.\bin\token-profile.ps1 agg C:\repo

# All work in .cmd wrapper too
.\bin\token-profile.cmd aggr C:\repo
```

### See available options
```powershell
# Invalid input shows helpful message
PS> .\bin\token-profile.ps1 xyz .
ERROR: Invalid profile 'xyz'.
       Available: balanced, aggressive
       
       Aliases:
         'agg' → 'aggressive'
         'aggr' → 'aggressive'
         'a' → 'aggressive'
         'bal' → 'balanced'
         'b' → 'balanced'
```

---

## 🎯 Benefits

| Benefit | Before | After |
|---------|--------|-------|
| **Add new profile?** | Edit script code | Add template file, config auto-discovers it |
| **Alias support?** | ❌ None | ✅ User-friendly abbreviations |
| **Error messages?** | Cryptic ValidateSet error | ✅ Shows available options + aliases |
| **Config location?** | Workspace-wide only | ✅ Repo-specific + workspace defaults |
| **Maintainability?** | Hardcoded in each script | ✅ Centralized in `script-profiles.yaml` |

---

## 🔄 Roadmap

### Phase 1: ✅ Complete
- [x] Token profile dynamic discovery + aliases
- [x] Config infrastructure created
- [x] Repo-specific config template

### Phase 2: Ready to implement
- [ ] Update `doctor.ps1` - Add check level options
- [ ] Update `refresh-agents.ps1` - Make repo-specific
- [ ] Update `install-hooks.ps1` - Make repo-specific

### Phase 3: Extensibility  
- [ ] Use config for other tools (e.g., audit depth, memory location)
- [ ] Add more aliases based on user feedback
- [ ] Support config hierarchy (workspace → repo → CLI override)

---

## 📝 For Script Developers

### To add dynamic parameters to a script:

1. **Add entry to `shared/config/script-profiles.yaml`:**
   ```yaml
   my-new-parameter:
     description: "What this controls"
     type: "enum"
     values:
       - option1
       - option2
     aliases:
       a1: option1
       a2: option2
     default: "option1"
   ```

2. **Use in your script:**
   ```powershell
   Import-Module (Join-Path $root 'shared/modules/DynamicProfiles.psm1') -Force
   
   $options = Get-DynamicOptions -ProfileName 'my-new-parameter' -WorkspaceRoot $root
   $Value = Expand-Alias -Value $Value -Aliases $options.Aliases
   Validate-Option -Value $Value -Options $options.List -ParameterName 'my-param'
   ```

---

## 🧪 Testing

Verify the fix works:
```powershell
# Test all aliases
.\bin\token-profile.ps1 aggr .    # ✅ Should work now
.\bin\token-profile.ps1 agg .     # ✅ Should work now
.\bin\token-profile.ps1 bal .     # ✅ Should work now
.\bin\token-profile.ps1 b .       # ✅ Should work now

# Test invalid input
.\bin\token-profile.ps1 xyz .     # ❌ Should show friendly error
```

---

## 📚 Related Files

- [DYNAMIC_VALUES_AND_REPO_SPECIFICITY.md](./DYNAMIC_VALUES_AND_REPO_SPECIFICITY.md) — Full design document
- [shared/config/script-profiles.yaml](./shared/config/script-profiles.yaml) — Parameter definitions
- [shared/modules/DynamicProfiles.psm1](./shared/modules/DynamicProfiles.psm1) — Helper functions
- [bin/token-profile.ps1](./bin/token-profile.ps1) — Updated script example
- [templates/copilot-config.template.yaml](./templates/copilot-config.template.yaml) — Repo config template
