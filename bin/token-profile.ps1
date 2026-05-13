<#
.SYNOPSIS
    Switches Copilot token usage profile for a target repo.

.DESCRIPTION
    Copies one template into:
    .github/instructions-local/token-profile.instructions.md

    Profiles:
    - balanced   (recommended default)
    - aggressive (maximum token savings)

.PARAMETER Profile
    Profile name to apply: balanced or aggressive.

.PARAMETER RepoPath
    Target repository path. Defaults to current working directory.

.EXAMPLE
    .\bin\token-profile.ps1 -Profile balanced -RepoPath C:\rdwr-intelij\df_core

.EXAMPLE
    .\bin\token-profile.ps1 -Profile aggressive
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$Profile,

    [string]$RepoPath = '.'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path $PSScriptRoot -Parent
$repoPath = [IO.Path]::GetFullPath($RepoPath)

# Load dynamic profile discovery module
Import-Module (Join-Path $root 'shared/modules/DynamicProfiles.psm1') -Force

# Get available profiles and aliases
try {
    $options = Get-DynamicOptions -ProfileName 'token-profile' -WorkspaceRoot $root
} catch {
    Write-Host "ERROR: Could not load profile options: $_" -ForegroundColor Red
    exit 1
}

# Expand aliases (e.g., 'aggr' → 'aggressive', 'bal' → 'balanced')
$Profile = Expand-Alias -Value $Profile -Aliases $options.Aliases

# Validate the profile
if ($options.List -notcontains $Profile) {
    Write-Host "ERROR: Invalid profile '$Profile'." -ForegroundColor Red
    Write-Host "       Available: $($options.List -join ', ')" -ForegroundColor Yellow
    Write-Host "" -ForegroundColor Yellow
    Write-Host "       Aliases:" -ForegroundColor Yellow
    $options.Aliases.GetEnumerator() | ForEach-Object {
        Write-Host "         '$($_.Key)' → '$($_.Value)'" -ForegroundColor DarkYellow
    }
    exit 1
}

if (-not (Test-Path $repoPath)) {
    Write-Host "ERROR: repo not found: $repoPath" -ForegroundColor Red
    exit 2
}

# Build template filename based on profile name
$templateFile = "token-profile-$Profile.template.instructions.md"
$templatePath = Join-Path $root "templates\$templateFile"

if (-not (Test-Path $templatePath)) {
    Write-Host "ERROR: template not found: $templatePath" -ForegroundColor Red
    Write-Host "       This may indicate the profile was discovered but template is missing." -ForegroundColor Yellow
    exit 2
}

$targetDir = Join-Path $repoPath '.github\instructions-local'
if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

$targetPath = Join-Path $targetDir 'token-profile.instructions.md'
Copy-Item -Path $templatePath -Destination $targetPath -Force

Write-Host "Applied '$Profile' token profile to: $targetPath" -ForegroundColor Green
Write-Host "Restart Copilot Chat in this repo so the new profile is picked up." -ForegroundColor Yellow
