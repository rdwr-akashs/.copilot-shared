<#
.SYNOPSIS
    Generates repo-mix context packs for ALL repos in the workspace,
    stored centrally in .copilot-shared/shared/memory/repo-contexts/.

.DESCRIPTION
    Walks the workspace root (parent of .copilot-shared), finds every git repo,
    and runs repo-mix.ps1 -Central on each. Results are stored as one markdown
    file per repo in shared/memory/repo-contexts/<repo-name>.md.

    This is the recommended way to build a complete workspace context that any
    linked repo can access.

.PARAMETER Root
    Workspace root to scan. Defaults to parent of .copilot-shared.

.PARAMETER MaxFiles
    Max files to include per repo (default 300).

.PARAMETER MaxFileSizeKB
    Max file size in KB to include (default 192).

.PARAMETER Include
    Optional list of repo names to include. If empty, all repos are scanned.

.PARAMETER Exclude
    Optional list of repo names to skip.

.EXAMPLE
    powershell -File bin\repo-mix-all.ps1
    powershell -File bin\repo-mix-all.ps1 -MaxFiles 200
    powershell -File bin\repo-mix-all.ps1 -Include df_core,war-room,bgp
    powershell -File bin\repo-mix-all.ps1 -Exclude large_repo,archive_repo
#>

$RootCompleter = {
    param($wordToComplete, $commandAst, $cursorPosition)
    try {
        $parent = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
        Get-ChildItem -Path $parent -Directory | Where-Object { Test-Path (Join-Path $_.FullName '.git') } | Select-Object -ExpandProperty Name | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', 'Repository')
        }
    } catch { }
}

param(
    [ArgumentCompleter($RootCompleter)]
    [string]$Root,
    [int]$MaxFiles = 300,
    [int]$MaxFileSizeKB = 192,
    [string[]]$Include = @(),
    [string[]]$Exclude = @(),
    # SummaryOnly (default ON): generates lightweight 1-2KB index files in repo-contexts/
    # Set -SummaryOnly:$false to generate full content dumps into repo-contexts/full/ instead
    [bool]$SummaryOnly = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$BinDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SharedRoot = Split-Path -Parent $BinDir
$RepoMixScript = Join-Path $BinDir 'repo-mix.ps1'

if (-not $Root) {
    $Root = Split-Path -Parent $SharedRoot
}

if (-not (Test-Path $Root)) {
    Write-Error "Workspace root not found: $Root"
    exit 1
}

if (-not (Test-Path $RepoMixScript)) {
    Write-Error "repo-mix.ps1 not found at $RepoMixScript"
    exit 1
}

$centralDir = Join-Path $SharedRoot 'shared\memory\repo-contexts'
if (-not (Test-Path $centralDir)) {
    New-Item -ItemType Directory -Path $centralDir -Force | Out-Null
}

Write-Host ""
$modeLabel = if ($SummaryOnly) { 'summary (lightweight, default)' } else { 'full dump  -> repo-contexts/full/' }
Write-Host "=== repo-mix-all ===" -ForegroundColor Cyan
Write-Host "  workspace: $Root"
Write-Host "  output:    $centralDir"
Write-Host "  mode:      $modeLabel"
Write-Host "  maxFiles:  $MaxFiles (full mode only)"
Write-Host "  maxSize:   ${MaxFileSizeKB}KB (full mode only)"
Write-Host ""

$dirs = Get-ChildItem -Path $Root -Directory |
    Where-Object { $_.Name -ne '.copilot-shared' } |
    Sort-Object Name

$processed = 0
$skipped = 0
$errors = @()

foreach ($dir in $dirs) {
    $repoName = $dir.Name

    # Skip non-git directories
    $gitDir = Join-Path $dir.FullName '.git'
    if (-not (Test-Path $gitDir)) {
        $skipped++
        continue
    }

    # Include/exclude filtering
    if ($Include.Count -gt 0 -and $Include -notcontains $repoName) {
        $skipped++
        continue
    }
    if ($Exclude -contains $repoName) {
        Write-Host "  [skip] $repoName (excluded)" -ForegroundColor DarkGray
        $skipped++
        continue
    }

    # Full dumps go to repo-contexts/full/ to protect hand-maintained summaries
    $outFile = if ($SummaryOnly) {
        Join-Path $centralDir "$repoName.md"
    } else {
        $fullDir = Join-Path $centralDir 'full'
        if (-not (Test-Path $fullDir)) { New-Item -ItemType Directory -Path $fullDir -Force | Out-Null }
        Join-Path $fullDir "$repoName.md"
    }
    Write-Host "  [scan] $repoName ..." -ForegroundColor Yellow -NoNewline

    try {
        $mixArgs = @{
            RepoPath      = $dir.FullName
            OutputFile    = $outFile
            MaxFiles      = $MaxFiles
            MaxFileSizeKB = $MaxFileSizeKB
            Central       = $true
            SummaryOnly   = $SummaryOnly
        }
        & $RepoMixScript @mixArgs

        $size = [math]::Round((Get-Item $outFile).Length / 1KB, 1)
        Write-Host " ${size}KB" -ForegroundColor Green
        $processed++
    }
    catch {
        Write-Host " FAILED" -ForegroundColor Red
        Write-Host "    $($_.Exception.Message)" -ForegroundColor Red
        $errors += "$repoName`: $($_.Exception.Message)"
    }
}

# Generate a central index file
$indexFile = Join-Path $centralDir '_index.md'
$indexSb = [System.Text.StringBuilder]::new()
[void]$indexSb.AppendLine("# Repo Context Index")
[void]$indexSb.AppendLine("")
[void]$indexSb.AppendLine("<!-- Auto-generated by bin/repo-mix-all.ps1 on $(Get-Date -Format 'yyyy-MM-dd HH:mm') | mode: $(if ($SummaryOnly) { 'summary' } else { 'full' }) -->")
[void]$indexSb.AppendLine("")
[void]$indexSb.AppendLine("| Repo | Size | Last Updated |")
[void]$indexSb.AppendLine("|------|------|--------------|")

$contextFiles = Get-ChildItem -Path $centralDir -Filter '*.md' |
    Where-Object { $_.Name -ne 'README.md' -and $_.Name -ne '_index.md' } |
    Sort-Object Name

foreach ($cf in $contextFiles) {
    $sizeKB = [math]::Round($cf.Length / 1KB, 1)
    $updated = $cf.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
    $name = [System.IO.Path]::GetFileNameWithoutExtension($cf.Name)
    [void]$indexSb.AppendLine("| ``$name`` | ${sizeKB}KB | $updated |")
}

[void]$indexSb.AppendLine("")
[void]$indexSb.AppendLine("**Total: $($contextFiles.Count) repos indexed**")
[System.IO.File]::WriteAllText($indexFile, $indexSb.ToString(), [System.Text.Encoding]::UTF8)

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  Processed: $processed repo(s)"
Write-Host "  Skipped:   $skipped (no .git or filtered)"
if ($errors.Count -gt 0) {
    Write-Host "  Errors:    $($errors.Count)" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
}
Write-Host "  Index:     $indexFile"
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Context packs stored at:" -ForegroundColor Green
Write-Host "  $centralDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "Access from any repo via:" -ForegroundColor Green
Write-Host "  `$env:COPILOT_WORKSPACE_ROOT\.copilot-shared\shared\memory\repo-contexts\<repo>.md" -ForegroundColor Cyan
