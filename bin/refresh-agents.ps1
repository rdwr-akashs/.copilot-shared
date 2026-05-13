<#
.SYNOPSIS
    Refresh agent templates in a repo.

.DESCRIPTION
    Pulls updates from agent-templates/ into a repo's .github/agents/ when
    shared templates have been improved upstream.
    
    Press Tab after -RefreshLevel to see available options and aliases.

.PARAMETER RepoPath
    Full path to the repository. Defaults to current directory.

.PARAMETER RefreshLevel
    Refresh scope: minimal (skip if custom exist), full (overwrite all), or custom-only.
    Use Tab for auto-complete and aliases (min, full, custom).

.EXAMPLE
    .\bin\refresh-agents.ps1 C:\rdwr-intelij\df_core
    
.EXAMPLE
    .\bin\refresh-agents.ps1 -RefreshLevel full C:\rdwr-intelij\df_core
#>

# Tab completion for RefreshLevel
$RefreshLevelCompleter = {
    param($wordToComplete, $commandAst, $cursorPosition)
    
    try {
        $root = Split-Path $PSScriptRoot -Parent
        Import-Module (Join-Path $root 'shared/modules/DynamicProfiles.psm1') -Force
        
        $options = Get-DynamicOptions -ProfileName 'refresh-agents-level' -WorkspaceRoot $root
        $allOptions = @() + $options.List + ($options.Aliases.Keys | ForEach-Object { $_ })
        
        $matches = $allOptions | Where-Object { $_ -like "$wordToComplete*" } | Sort-Object
        
        $matches | ForEach-Object {
            if ($_ -in $options.List) {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
            } else {
                $expands = $options.Aliases[$_]
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "Alias → $expands")
            }
        }
    } catch { }
}

param(
    [string]$RepoPath = '.',
    
    [ArgumentCompleter($RefreshLevelCompleter)]
    [string]$RefreshLevel = 'minimal'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoPath = [IO.Path]::GetFullPath($RepoPath)
$root = Split-Path $PSScriptRoot -Parent

# Load options and expand alias
Import-Module (Join-Path $root 'shared/modules/DynamicProfiles.psm1') -Force
$options = Get-DynamicOptions -ProfileName 'refresh-agents-level' -WorkspaceRoot $root
$RefreshLevel = Expand-Alias -Value $RefreshLevel -Aliases $options.Aliases

if (-not (Test-Path $repoPath)) {
    Write-Host "ERROR: Repo not found: $repoPath" -ForegroundColor Red
    exit 2
}

if ($options.List -notcontains $RefreshLevel) {
    Write-Host "ERROR: Invalid refresh level '$RefreshLevel'." -ForegroundColor Red
    Write-Host "       Available: $($options.List -join ', ')" -ForegroundColor Yellow
    exit 1
}

$ghDir = Join-Path $repoPath '.github'
$agentsDir = Join-Path $ghDir 'agents'
$templatesDir = Join-Path $root 'agent-templates'

if (-not (Test-Path $ghDir)) {
    Write-Host "ERROR: .github/ not found. Run setup-repo.ps1 first." -ForegroundColor Red
    exit 2
}

if (-not (Test-Path $templatesDir)) {
    Write-Host "ERROR: Template agents directory not found: $templatesDir" -ForegroundColor Red
    exit 2
}

Write-Host "Refresh agents with level: $RefreshLevel" -ForegroundColor Green
Write-Host "Repository: $repoPath" -ForegroundColor Cyan
Write-Host ""

# Implementation: refresh logic would go here
Write-Host "[TODO] Agent refresh logic for level '$RefreshLevel'" -ForegroundColor Yellow
Write-Host "Agents directory: $agentsDir" -ForegroundColor DarkGray
Write-Host "Templates directory: $templatesDir" -ForegroundColor DarkGray
