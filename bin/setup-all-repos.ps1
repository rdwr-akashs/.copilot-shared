<#
.SYNOPSIS
    Runs setup-repo.ps1 on every git repo under the workspace root that is missing .github/copilot-instructions.md.

.DESCRIPTION
    Walks the parent directory (one level above .copilot-shared) looking for
    sibling repos that have a .git folder but no .github/copilot-instructions.md.
    For each, it invokes setup-repo.ps1 non-interactively.

.PARAMETER Root
    Workspace root to scan. Defaults to parent of .copilot-shared.

.EXAMPLE
    powershell -File bin\setup-all-repos.ps1
    powershell -File bin\setup-all-repos.ps1 -Root D:\projects
    powershell -File bin\setup-all-repos.ps1 -GenerateRepoMix
#>
param(
    [string]$Root,
    [switch]$GenerateRepoMix
)

$ErrorActionPreference = 'Stop'
$BinDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SharedRoot = Split-Path -Parent $BinDir

if (-not $Root) {
    $Root = Split-Path -Parent $SharedRoot
}

$setupScript = Join-Path $BinDir 'setup-repo.ps1'
if (-not (Test-Path $setupScript)) {
    Write-Error "Cannot find setup-repo.ps1 at $setupScript"
    exit 1
}

Write-Host ""
Write-Host "=== setup-all-repos ===" -ForegroundColor Cyan
Write-Host "Scanning: $Root"
Write-Host ""

$dirs = Get-ChildItem -Path $Root -Directory | Where-Object { $_.Name -ne '.copilot-shared' }

$setup = 0
$skipped = 0
$already = 0
$errors = @()

foreach ($dir in $dirs) {
    $gitDir = Join-Path $dir.FullName '.git'
    $ciFile = Join-Path $dir.FullName '.github\copilot-instructions.md'

    if (-not (Test-Path $gitDir)) {
        $skipped++
        continue
    }

    if (Test-Path $ciFile) {
        Write-Host "  OK   $($dir.Name)" -ForegroundColor Green
        $already++
        continue
    }

    Write-Host "  SETUP $($dir.Name)" -ForegroundColor Yellow
    try {
        if ($GenerateRepoMix) {
            & $setupScript -RepoPath $dir.FullName -GenerateRepoMix
        } else {
            & $setupScript -RepoPath $dir.FullName
        }
        $setup++
    } catch {
        Write-Host "  ERROR $($dir.Name): $_" -ForegroundColor Red
        $errors += "$($dir.Name): $_"
    }
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  Already set up:  $already"
Write-Host "  Newly set up:    $setup"
Write-Host "  Skipped (no .git): $skipped"
if ($errors.Count -gt 0) {
    Write-Host "  Errors:          $($errors.Count)" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
}
Write-Host "=====================================" -ForegroundColor Cyan
