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
    [ValidateSet('balanced', 'aggressive')]
    [string]$Profile,

    [string]$RepoPath = '.'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path $PSScriptRoot -Parent
$repoPath = [IO.Path]::GetFullPath($RepoPath)

if (-not (Test-Path $repoPath)) {
    Write-Host "ERROR: repo not found: $repoPath" -ForegroundColor Red
    exit 2
}

$templateFile = if ($Profile -eq 'balanced') {
    'token-profile-balanced.template.instructions.md'
} else {
    'token-profile-aggressive.template.instructions.md'
}

$templatePath = Join-Path $root "templates\$templateFile"
if (-not (Test-Path $templatePath)) {
    Write-Host "ERROR: template not found: $templatePath" -ForegroundColor Red
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
