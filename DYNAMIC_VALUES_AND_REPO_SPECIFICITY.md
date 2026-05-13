# Dynamic Values & Repo Specificity Strategy

## Problem Statement

Current approach has two issues:

1. **Hardcoded parameters** (e.g., `ValidateSet('balanced', 'aggressive')`) 
   - Adding new profiles requires code changes
   - Not discoverable from available templates/configs
   - Error messages confusing (`'aggr'` rejected)

2. **Workspace-wide vs Repo-specific confusion**
   - Some tools should be workspace-wide (shared across all repos)
   - Some tools should be repo-specific (run per repo, store in `.github/`)
   - Currently mixed and unclear

---

## Classification: Workspace-wide vs Repo-specific

### **WORKSPACE-WIDE** (Shared, Environment-level)
- `setup-local.ps1` - One-time workspace init (BB credentials, memory setup)
- `setup-all-repos.ps1` - Bulk repo initialization
- `centralize-memory.ps1` - Centralized memory management
- `link-all-copilot.cmd` - Bulk junction creation
- `verify-central-memory.ps1` - Central memory validation
- `export-memory.ps1` / `import-memory.ps1` - Memory transport
- `audit.ps1` / `audit-copilot-assets.ps1` - Workspace audit

### **REPO-SPECIFIC** (Per-repository)
- `token-profile.ps1` - ✅ Already repo-specific (targets `.github/`)
- `doctor.ps1` - ✅ Already repo-specific (checks `.github/`)
- `setup-repo.ps1` - ✅ Already repo-specific
- **NEEDS FIX**: `refresh-agents.ps1` - Should be repo-specific
- **NEEDS FIX**: `install-hooks.cmd` - Should be repo-specific
- **UNCLEAR**: `generate-skill-index.ps1` - Could be either

---

## Solution 1: Dynamic Parameter Discovery Pattern

### Current (BAD - Hardcoded)
```powershell
[ValidateSet('balanced', 'aggressive')]
[string]$Profile
```

### New Pattern 1: Scan Templates Directory
```powershell
# Build available profiles from template files
$profileFiles = Get-Item "$TemplateRoot\token-profile-*.template.instructions.md" -ErrorAction SilentlyContinue |
    ForEach-Object { $_.BaseName -replace 'token-profile-|\.template\.instructions\.md' }

if ($profileFiles.Count -eq 0) {
    Write-Error "No token profile templates found"
    exit 1
}

$ProfileList = @($profileFiles)

# Validate input against discovered list
if ($ProfileList -notcontains $Profile) {
    Write-Error "Invalid profile '$Profile'. Available: $($ProfileList -join ', ')"
    exit 1
}
```

### New Pattern 2: Config-Driven (Better for extensibility)
Create `shared/config/script-profiles.yaml`:
```yaml
token-profile:
  description: "Copilot token usage profile"
  location: "templates/token-profile-*.template.instructions.md"
  aliases:
    bal: balanced
    agg: aggressive
    b: balanced
    a: aggressive

refresh-agents:
  description: "Agent refresh level"
  location: ".github/agents/"
  aliases:
    min: minimal
    full: full
    custom: custom

doctor:
  description: "Doctor check level"
  options:
    - critical
    - standard
    - exhaustive
  aliases:
    c: critical
    s: standard
    e: exhaustive
```

Then all scripts can use:
```powershell
function Get-DynamicOptions {
    param([string]$ScriptName, [string]$ParamName)
    
    $config = Get-Content 'shared/config/script-profiles.yaml' | ConvertFrom-Yaml
    $options = $config[$ScriptName][$ParamName]
    
    return @{
        List = $options.options -or (Get-ChildItem $options.location | ForEach-Object { ... })
        Aliases = $options.aliases
    }
}
```

---

## Solution 2: Repo-Specific Config Files

### Pattern: `.github/copilot-config.yaml`

Store per-repo overrides in repo-specific location:

```yaml
# .github/copilot-config.yaml (repo-specific)
token-profile: aggressive
doctor-level: exhaustive
agent-refresh: full
excluded-agents:
  - story-writer
  - tester
```

Then scripts read:
```powershell
$configFile = Join-Path $RepoPath '.github/copilot-config.yaml'
if (Test-Path $configFile) {
    $config = Get-Content $configFile | ConvertFrom-Yaml
    $profile = $config['token-profile'] ?? 'balanced'
} else {
    $profile = 'balanced'  # Default
}
```

---

## Solution 3: Script-Specific vs Shared Parameters

### SCRIPT-SPECIFIC PARAMETERS (Repo-specific)
These vary per-repo and should be stored in `.github/`:

| Script | Parameter | Should be in `.github/copilot-config.yaml` |
|--------|-----------|------------------------------------------|
| token-profile.ps1 | Profile | ✅ Yes |
| doctor.ps1 | CheckLevel | ✅ Yes (minimal/standard/exhaustive) |
| refresh-agents.ps1 | RefreshLevel | ✅ Yes (minimal/full/custom) |
| install-hooks.ps1 | HookType | ✅ Yes (pre-commit/commit-msg/all) |
| generate-skill-index.ps1 | IndexType | ✅ Yes |

### SHARED PARAMETERS (Workspace-wide)
These are environment-level and belong in `.local.env`:

| Script | Parameter | Should be in `.local.env` |
|--------|-----------|--------------------------|
| setup-local.ps1 | BBWorkspace | ✅ Yes |
| setup-local.ps1 | BBBaseUrl | ✅ Yes |
| audit.ps1 | AuditLevel | ✅ Yes (if applies) |
| centralize-memory.ps1 | TargetLocation | ✅ Yes |

---

## Action Plan

### Phase 1: Create Config Infrastructure
- [ ] Create `shared/config/script-profiles.yaml` with all script profiles
- [ ] Update `.github/copilot-config.yaml` template with repo-specific overrides
- [ ] Create helper function `Load-DynamicProfile` in shared module

### Phase 2: Update Token Profile Script
- [ ] Remove hardcoded ValidateSet
- [ ] Add alias support (`bal` → `balanced`, `agg` → `aggressive`)
- [ ] Scan templates directory for available profiles
- [ ] Read repo-specific override from `.github/copilot-config.yaml`

### Phase 3: Update Other Scripts
- [ ] doctor.ps1 - Read check level from config
- [ ] refresh-agents.ps1 - Make repo-specific
- [ ] install-hooks.ps1 - Make repo-specific, store in `.github/`
- [ ] generate-skill-index.ps1 - Read from config

### Phase 4: Update Templates
- [ ] Add `.github/copilot-config.yaml` to `setup-repo.ps1`
- [ ] Document config options in README

---

## Benefits

✅ **No more hardcoded values** - All configs are discoverable  
✅ **Add new profiles without code changes** - Just add templates or config entries  
✅ **User-friendly aliases** - `aggr` → `aggressive`, `bal` → `balanced`  
✅ **Clear workspace vs repo boundaries** - Config location defines scope  
✅ **Override capability** - Workspace defaults + repo-specific overrides  
✅ **Self-documenting** - Scripts show available options if invalid input  

---

## Implementation Priority

1. **CRITICAL**: token-profile.ps1 (currently broken with aliases)
2. **HIGH**: Create config infrastructure 
3. **HIGH**: doctor.ps1 (add check level options)
4. **MEDIUM**: refresh-agents.ps1 (make repo-specific)
5. **MEDIUM**: Other scripts (as needed)
