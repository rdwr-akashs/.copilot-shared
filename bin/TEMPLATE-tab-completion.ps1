<#
.SYNOPSIS
    Template: How to add tab completion to any PowerShell script using DynamicProfiles.

.DESCRIPTION
    This template shows the standard pattern for adding tab completion to scripts.
    Copy this template and customize for your script and parameter.

.PATTERN
    1. Define a completer scriptblock (see $YourParameterCompleter below)
    2. Add [ArgumentCompleter($YourParameterCompleter)] to your parameter
    3. Load DynamicProfiles module and expand aliases
    4. Validate the parameter value
    
    That's it! Tab completion now works.

.REFERENCE
    Related files:
    - shared/config/script-profiles.yaml         Define available parameters
    - shared/modules/DynamicProfiles.psm1        Helper functions for tab completion
    - bin/token-profile.ps1                      Working example #1
    - bin/doctor.ps1                             Working example #2
    - bin/refresh-agents.ps1                     Working example #3
#>

# ============================================================================
# STEP 1: Define Tab Completer Scriptblock
# ============================================================================
# This runs when the user presses Tab. It returns a list of available options.
#
# Change 'your-profile-name' to match the entry in script-profiles.yaml
#
$YourParameterCompleter = {
    param($wordToComplete, $commandAst, $cursorPosition)
    
    try {
        # Load the DynamicProfiles module
        $root = Split-Path $PSScriptRoot -Parent
        Import-Module (Join-Path $root 'shared/modules/DynamicProfiles.psm1') -Force
        
        # Get available options from script-profiles.yaml
        # Change 'your-profile-name' to match your entry in script-profiles.yaml
        $options = Get-DynamicOptions -ProfileName 'your-profile-name' -WorkspaceRoot $root
        
        # Build list: main options + all aliases
        $allOptions = @() + $options.List + ($options.Aliases.Keys | ForEach-Object { $_ })
        
        # Filter based on what user typed so far
        $matches = $allOptions | Where-Object { $_ -like "$wordToComplete*" } | Sort-Object
        
        # Return results with descriptions
        $matches | ForEach-Object {
            if ($_ -in $options.List) {
                # Main option - just show the name
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
            } else {
                # Alias - show what it expands to
                $expands = $options.Aliases[$_]
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "Alias → $expands")
            }
        }
    } catch {
        # Silently fail - user can still type manually
    }
}

# ============================================================================
# STEP 2: Use [ArgumentCompleter] Attribute on Parameter
# ============================================================================
# This tells PowerShell to use $YourParameterCompleter when Tab is pressed
#
param(
    [ArgumentCompleter($YourParameterCompleter)]     # ← ADD THIS LINE
    [string]$YourParameter = 'default-value'
)

# ============================================================================
# STEP 3: Load Module and Expand Alias
# ============================================================================
# Inside your script, when you receive the parameter:
#
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path $PSScriptRoot -Parent

# Load the module
Import-Module (Join-Path $root 'shared/modules/DynamicProfiles.psm1') -Force

# Get the options again (or reuse from completer if desired)
$options = Get-DynamicOptions -ProfileName 'your-profile-name' -WorkspaceRoot $root

# Expand alias: if user typed 'a' and it maps to 'aggressive', convert it
$YourParameter = Expand-Alias -Value $YourParameter -Aliases $options.Aliases

# ============================================================================
# STEP 4: Validate the Parameter
# ============================================================================
# After expansion, validate that it's actually a valid option
#
if ($options.List -notcontains $YourParameter) {
    Write-Host "ERROR: Invalid value '$YourParameter'." -ForegroundColor Red
    Write-Host "       Available: $($options.List -join ', ')" -ForegroundColor Yellow
    Write-Host "" -ForegroundColor Yellow
    Write-Host "       Aliases:" -ForegroundColor Yellow
    $options.Aliases.GetEnumerator() | ForEach-Object {
        Write-Host "         '$($_.Key)' → '$($_.Value)'" -ForegroundColor DarkYellow
    }
    exit 1
}

# Now you can use $YourParameter safely!
Write-Host "Using: $YourParameter" -ForegroundColor Green

# ============================================================================
# COPY-PASTE QUICK REFERENCE
# ============================================================================
# To add tab completion to a new script:
#
# 1. Add entry to shared/config/script-profiles.yaml:
#    ```yaml
#    your-profile-name:
#      description: "What this parameter controls"
#      type: "enum"
#      values:
#        - option1
#        - option2
#      aliases:
#        alias1: option1
#        alias2: option2
#      default: "option1"
#    ```
#
# 2. In your script, copy the pattern above:
#    - Define $YourParameterCompleter
#    - Add [ArgumentCompleter($YourParameterCompleter)]
#    - Load module and expand alias
#    - Validate
#
# 3. Test in PowerShell:
#    PS> .\your-script.ps1 -YourParameter <Tab>
#    # Should show: option1, option2, alias1, alias2 (filtered)
#
# ============================================================================
