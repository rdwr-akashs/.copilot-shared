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

param(
    [string]$RepoPath = '.',
    
    [ArgumentCompleter({
        param($wordToComplete, $commandAst, $cursorPosition)
        try {
            $root = Split-Path $PSScriptRoot -Parent
            Import-Module (Join-Path $root 'shared/modules/DynamicProfiles.psm1') -Force
            $options = Get-DynamicOptions -ProfileName 'refresh-agents-level' -WorkspaceRoot $root
            $allOptions = @() + $options.List + ($options.Aliases.Keys | ForEach-Object { $_ })
            $allOptions | Where-Object { $_ -like "$wordToComplete*" } | Sort-Object | ForEach-Object {
                if ($_ -in $options.List) {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
                } else {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "Alias → $($options.Aliases[$_])")
                }
            }
        } catch { }
    })]
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
    Write-Host "ERROR: Agent templates directory not found: $templatesDir" -ForegroundColor Red
    exit 2
}

if ((Get-ChildItem "$templatesDir\*.agent.md" -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) {
    Write-Host "ERROR: No agent templates found in: $templatesDir" -ForegroundColor Red
    exit 2
}

Write-Host "Refresh agents with level: $RefreshLevel" -ForegroundColor Green
Write-Host "Repository: $repoPath" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $agentsDir)) {
    Write-Host "ERROR: .github/agents/ not found. Nothing to refresh." -ForegroundColor Red
    exit 2
}

# Determine which agents to refresh based on level
$agentsToRefresh = @()

if ($RefreshLevel -eq 'full') {
    # Refresh all agents from templates
    $agentsToRefresh = @(Get-ChildItem "$templatesDir\*.agent.md" -ErrorAction SilentlyContinue | ForEach-Object { $_.Name })
} elseif ($RefreshLevel -eq 'minimal') {
    # Only refresh agents that don't exist in repo yet
    Get-ChildItem "$templatesDir\*.agent.md" -ErrorAction SilentlyContinue | ForEach-Object {
        $repoAgent = Join-Path $agentsDir $_.Name
        if (-not (Test-Path $repoAgent)) {
            $agentsToRefresh += $_.Name
        }
    }
} elseif ($RefreshLevel -eq 'custom-only') {
    # Refresh only agents marked as "custom" (contain [CUSTOM] tag)
    Get-ChildItem "$agentsDir\*.agent.md" -ErrorAction SilentlyContinue | ForEach-Object {
        $content = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
        if ($content -match '\[CUSTOM\]|custom-agent:\s*true') {
            $template = Join-Path $templatesDir $_.Name
            if (Test-Path $template) {
                $agentsToRefresh += $_.Name
            }
        }
    }
}

if ($agentsToRefresh.Count -eq 0) {
    Write-Host "No agents to refresh (level: $RefreshLevel)" -ForegroundColor DarkCyan
    exit 0
}

$copied = 0
$skipped = 0
foreach ($agentName in $agentsToRefresh) {
    $src = Join-Path $templatesDir $agentName
    $dest = Join-Path $agentsDir $agentName
    
    if (-not (Test-Path $src)) {
        Write-Host "  [warn] Template not found: $agentName" -ForegroundColor Yellow
        continue
    }
    
    Copy-Item $src $dest -Force
    Write-Host "  [ok]   $agentName" -ForegroundColor Green
    $copied++
}

Write-Host ""
Write-Host "Refreshed: $copied agent(s) (level: $RefreshLevel)" -ForegroundColor Green
