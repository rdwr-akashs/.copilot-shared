<#
.SYNOPSIS
    Shared module for dynamic profile discovery and validation.

.DESCRIPTION
    Provides helper functions for all scripts to:
    - Discover available options from templates or config
    - Expand aliases to canonical names
    - Validate user input with helpful error messages
    - Load repo-specific or workspace-wide config
#>

function Get-DynamicOptions {
    <#
    .SYNOPSIS
        Load available options for a parameter from script-profiles.yaml
    #>
    param(
        [Parameter(Mandatory)][string]$ProfileName,
        [Parameter(Mandatory)][string]$WorkspaceRoot
    )

    $configFile = Join-Path $WorkspaceRoot 'shared/config/script-profiles.yaml'
    if (-not (Test-Path $configFile)) {
        throw "Config not found: $configFile"
    }

    # Read the YAML-like file and extract the profile section
    $lines = @(Get-Content $configFile)
    $inProfile = $false
    $profileLines = @()
    
    foreach ($line in $lines) {
        if ($line.StartsWith($ProfileName + ':')) {
            $inProfile = $true
            continue
        }
        
        if ($inProfile) {
            # Stop at next root-level entry (no leading spaces)
            if ($line -and -not $line.StartsWith(' ') -and $line.Contains(':')) {
                break
            }
            $profileLines += $line
        }
    }

    # Parse the profile section
    $type = ""
    $location = ""
    $values = @()
    $aliases = @{}
    $default = ""

    foreach ($line in $profileLines) {
        $trimmed = $line.TrimStart()
        
        # Simple key: value parsing
        if ($trimmed.StartsWith('type:')) {
            $parts = $trimmed -split ':', 2
            $type = $parts[1].Trim().Trim('"').Trim("'")
        }
        elseif ($trimmed.StartsWith('location:')) {
            $parts = $trimmed -split ':', 2
            $location = $parts[1].Trim().Trim('"').Trim("'")
        }
        elseif ($trimmed.StartsWith('default:')) {
            $parts = $trimmed -split ':', 2
            $default = $parts[1].Trim().Trim('"').Trim("'")
        }
        elseif ($trimmed.StartsWith('values:')) {
            # Start of values list
            $idx = [Array]::IndexOf($profileLines, $line)
            for ($i = $idx + 1; $i -lt $profileLines.Count; $i++) {
                $vline = $profileLines[$i]
                if (-not $vline.StartsWith('    ')) { break }
                $val = $vline.Trim()
                if ($val.StartsWith('- ')) {
                    $val = $val.Substring(2).Trim()
                }
                if ($val) { $values += $val }
            }
        }
        elseif ($trimmed.StartsWith('aliases:')) {
            # Start of aliases map
            $idx = [Array]::IndexOf($profileLines, $line)
            for ($i = $idx + 1; $i -lt $profileLines.Count; $i++) {
                $aline = $profileLines[$i]
                if (-not $aline.StartsWith('    ')) { break }
                # Simple key: value parsing for aliases
                if ($aline.Contains(':')) {
                    $parts = $aline -split ':', 2
                    if ($parts.Count -eq 2) {
                        $key = $parts[0].Trim()
                        $val = $parts[1].Trim().Trim('"').Trim("'")
                        $aliases[$key] = $val
                    }
                }
            }
        }
    }

    # If type is 'template', scan for actual files
    $discoveredList = @()
    if ($type -eq 'template' -and $location) {
        $fullPath = Join-Path $WorkspaceRoot $location
        $parentPath = Split-Path $fullPath
        $pattern = Split-Path $fullPath -Leaf
        
        if (Test-Path $parentPath) {
            Push-Location $parentPath
            $files = @(Get-Item $pattern -ErrorAction SilentlyContinue | ForEach-Object { $_.Name })
            Pop-Location
            
            foreach ($file in $files) {
                # Extract profile name from filename
                if ($file.Contains('token-profile-')) {
                    $extracted = $file.Replace('token-profile-', '').Split('.')[0]
                    if ($extracted -and -not ($discoveredList -contains $extracted)) {
                        $discoveredList += $extracted
                    }
                }
            }
        }
    }

    # Return results
    return @{
        Type     = $type
        Location = $location
        List     = if ($discoveredList.Count -gt 0) { $discoveredList } else { $values }
        Aliases  = $aliases
        Default  = $default
    }
}

function Expand-Alias {
    <#
    .SYNOPSIS
        Expand a user-provided alias to its canonical form.
        E.g., 'aggr' → 'aggressive', 'bal' → 'balanced'
    #>
    param(
        [Parameter(Mandatory)][string]$Value,
        [Parameter(Mandatory)][hashtable]$Aliases
    )

    if ($Aliases.ContainsKey($Value)) {
        return $Aliases[$Value]
    }
    return $Value
}

function Validate-Option {
    <#
    .SYNOPSIS
        Validate user input against available options.
        Provides helpful error message if invalid.
    #>
    param(
        [Parameter(Mandatory)][string]$Value,
        [Parameter(Mandatory)][string[]]$Options,
        [string]$ParameterName = 'Value',
        [string]$Context = ''
    )

    if ($Options -contains $Value) {
        return $true
    }

    $msg = "ERROR: Invalid $ParameterName '$Value'"
    if ($Context) { $msg += " for $Context" }
    $msg += ". Available: $($Options -join ', ')"

    throw $msg
}

function Load-RepoConfig {
    <#
    .SYNOPSIS
        Load repo-specific configuration from .github/copilot-config.yaml
    #>
    param(
        [Parameter(Mandatory)][string]$RepoPath
    )

    $configFile = Join-Path $RepoPath '.github/copilot-config.yaml'
    
    if (-not (Test-Path $configFile)) {
        return @{}
    }

    # Simple config parsing
    $config = @{}
    Get-Content $configFile | ForEach-Object {
        $line = $_
        if ($line.StartsWith('#')) { return }  # Skip comments
        if ($line.Contains(':')) {
            $parts = $line -split ':', 2
            if ($parts.Count -eq 2) {
                $key = $parts[0].Trim()
                $value = $parts[1].Trim().Trim('"').Trim("'")
                if ($value) {
                    $config[$key] = $value
                }
            }
        }
    }

    return $config
}

function Load-WorkspaceConfig {
    <#
    .SYNOPSIS
        Load workspace-wide configuration from .local.env
    #>
    param(
        [Parameter(Mandatory)][string]$WorkspaceRoot
    )

    $envFile = Join-Path $WorkspaceRoot '.local.env'
    
    if (-not (Test-Path $envFile)) {
        return @{}
    }

    $config = @{}
    Get-Content $envFile | ForEach-Object {
        $line = $_
        if ($line.StartsWith('#')) { return }  # Skip comments
        if ($line.Contains('=')) {
            $parts = $line -split '=', 2
            if ($parts.Count -eq 2) {
                $key = $parts[0].Trim().Replace('export ', '')
                $value = $parts[1].Trim().Trim('"').Trim("'")
                if ($value) {
                    $config[$key] = $value
                }
            }
        }
    }

    return $config
}

function Get-DynamicCompleter {
    <#
    .SYNOPSIS
        Get an ArgumentCompleter scriptblock for a dynamic parameter.
        Use this to enable tab completion in any script.
    #>
    param(
        [Parameter(Mandatory)][string]$ProfileName,
        [Parameter(Mandatory)][string]$WorkspaceRoot
    )

    # Return a scriptblock that can be used as ArgumentCompleter
    $completerBlock = {
        param($wordToComplete, $commandAst, $cursorPosition)
        
        try {
            # These are captured from the outer scope
            $opts = Get-DynamicOptions -ProfileName $using:ProfileName -WorkspaceRoot $using:WorkspaceRoot
            $allOptions = @() + $opts.List + ($opts.Aliases.Keys | ForEach-Object { $_ })
            
            # Filter based on what user typed
            $matches = $allOptions | Where-Object { $_ -like "$wordToComplete*" } | Sort-Object
            
            # Return as CompletionResult objects with descriptions
            $matches | ForEach-Object {
                if ($_ -in $opts.List) {
                    # Main option
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
                } else {
                    # Alias - show what it expands to
                    $expands = $opts.Aliases[$_]
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "Alias → $expands")
                }
            }
        } catch {
            # Silent fail - no completions
        }
    }
    
    return $completerBlock
}




Export-ModuleMember -Function @(
    'Get-DynamicOptions',
    'Get-DynamicCompleter',
    'Expand-Alias',
    'Validate-Option',
    'Load-RepoConfig',
    'Load-WorkspaceConfig'
)
