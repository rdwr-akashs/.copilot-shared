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

param(
    [string]$RepoPath = '.',
    
    [ArgumentCompleter({
        param($wordToComplete, $commandAst, $cursorPosition)
        try {
            $root = Split-Path $PSScriptRoot -Parent
            Import-Module (Join-Path $root 'shared/modules/DynamicProfiles.psm1') -Force
            $options = Get-DynamicOptions -ProfileName 'install-hooks-scope' -WorkspaceRoot $root
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

# Map scope to hook files
$hookMap = @{
    'pre-commit' = @('pre-push', 'commit-msg')
    'commit-msg' = @('commit-msg')
    'pre-push'   = @('pre-push')
    'all'        = @('pre-push', 'commit-msg')
}

$hooksToInstall = $hookMap[$HookScope]
if (-not $hooksToInstall) {
    Write-Host "ERROR: Unknown scope '$HookScope'" -ForegroundColor Red
    exit 1
}

$sharedHooksDir = Join-Path $root 'shared\hooks'
if (-not (Test-Path $sharedHooksDir)) {
    Write-Host "ERROR: Shared hooks directory not found: $sharedHooksDir" -ForegroundColor Red
    exit 2
}

$installed = 0
$skipped = 0
foreach ($hookName in $hooksToInstall) {
    $src = Join-Path $sharedHooksDir $hookName
    $dest = Join-Path $hooksDir $hookName
    
    if (-not (Test-Path $src)) {
        Write-Host "  [warn] Hook template not found: $hookName" -ForegroundColor Yellow
        continue
    }
    
    if ((Test-Path $dest) -and (Get-Item $src -ErrorAction SilentlyContinue).LastWriteTime -le (Get-Item $dest -ErrorAction SilentlyContinue).LastWriteTime) {
        Write-Host "  [skip] $hookName (already up-to-date)" -ForegroundColor DarkGray
        $skipped++
    } else {
        Copy-Item $src $dest -Force
        # Make executable on Unix/Git Bash
        if ($PSVersionTable.Platform -eq 'Unix' -or (Get-Command git -ErrorAction SilentlyContinue)) {
            & cmd /c "icacls '$dest' /grant:r $env:USERNAME`:F 2>nul" | Out-Null
        }
        Write-Host "  [ok]   $hookName" -ForegroundColor Green
        $installed++
    }
}

Write-Host ""
if ($installed -eq 0 -and $skipped -gt 0) {
    Write-Host "All hooks already up-to-date." -ForegroundColor Green
} else {
    Write-Host "Installed: $installed, Skipped: $skipped" -ForegroundColor Green
}

Write-Host ""
Write-Host "Note: Hooks are shell scripts (.git/hooks/ are executed by git, not PowerShell)." -ForegroundColor DarkCyan
Write-Host "      On Windows, ensure Git for Windows (bash) is available for hooks to run." -ForegroundColor DarkCyan
