<#
.SYNOPSIS
    Install or update Git hooks in a repository.

.DESCRIPTION
    Installs Git hooks (pre-commit, commit-msg, etc.) into a repo's .git/hooks directory.
    
    Press Tab after -HookScope to see available options and aliases.

.PARAMETER RepoPath
    Full path to the repository. Defaults to current directory.

.PARAMETER HookScope
    Which hooks to install: pre-commit, commit-msg, or all.
    Use Tab for auto-complete and aliases (pre, msg, all).

.EXAMPLE
    .\bin\install-hooks.ps1 C:\rdwr-intelij\df_core
    
.EXAMPLE
    .\bin\install-hooks.ps1 -HookScope all C:\rdwr-intelij\df_core
#>

# Tab completion for HookScope
$HookScopeCompleter = {
    param($wordToComplete, $commandAst, $cursorPosition)
    
    try {
        $root = Split-Path $PSScriptRoot -Parent
        Import-Module (Join-Path $root 'shared/modules/DynamicProfiles.psm1') -Force
        
        $options = Get-DynamicOptions -ProfileName 'install-hooks-scope' -WorkspaceRoot $root
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
    
    [ArgumentCompleter($HookScopeCompleter)]
    [string]$HookScope = 'all'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoPath = [IO.Path]::GetFullPath($RepoPath)
$root = Split-Path $PSScriptRoot -Parent

# Load options and expand alias
Import-Module (Join-Path $root 'shared/modules/DynamicProfiles.psm1') -Force
$options = Get-DynamicOptions -ProfileName 'install-hooks-scope' -WorkspaceRoot $root
$HookScope = Expand-Alias -Value $HookScope -Aliases $options.Aliases

if (-not (Test-Path $repoPath)) {
    Write-Host "ERROR: Repo not found: $repoPath" -ForegroundColor Red
    exit 2
}

if ($options.List -notcontains $HookScope) {
    Write-Host "ERROR: Invalid hook scope '$HookScope'." -ForegroundColor Red
    Write-Host "       Available: $($options.List -join ', ')" -ForegroundColor Yellow
    exit 1
}

$gitDir = Join-Path $repoPath '.git'
$hooksDir = Join-Path $gitDir 'hooks'

if (-not (Test-Path $gitDir)) {
    Write-Host "ERROR: Not a Git repository: $repoPath" -ForegroundColor Red
    exit 2
}

if (-not (Test-Path $hooksDir)) {
    New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null
}

Write-Host "Install Git hooks with scope: $HookScope" -ForegroundColor Green
Write-Host "Repository: $repoPath" -ForegroundColor Cyan
Write-Host ""

# Implementation: hook installation logic would go here
Write-Host "[TODO] Hook installation logic for scope '$HookScope'" -ForegroundColor Yellow
Write-Host "Hooks directory: $hooksDir" -ForegroundColor DarkGray
