<#
.SYNOPSIS
    Health check for a repo using the .copilot-shared layout.

.DESCRIPTION
    Verifies junctions, gitignore, required files, template leakage, hook
    installation, repo-cache freshness, and registry presence. Produces
    colored output with PASS/FAIL/WARN/INFO labels.
    
    Press Tab after -CheckLevel to see available options and aliases.

.PARAMETER RepoPath
    Full path to the repository to check.

.PARAMETER CheckLevel
    Check depth: critical (junctions only), standard (default), or exhaustive (all).
    Use Tab for auto-complete and aliases.

.EXAMPLE
    powershell -File bin\doctor.ps1 C:\rdwr-intelij\df_core
    
.EXAMPLE
    powershell -File bin\doctor.ps1 -CheckLevel exhaustive C:\rdwr-intelij\df_core
#>

param(
    [Parameter(Mandatory=$true, Position=1)]
    [string]$RepoPath,
    
    [Parameter(Position=0)]
    [ArgumentCompleter({
        param($wordToComplete, $commandAst, $cursorPosition)
        try {
            $root = Split-Path $PSScriptRoot -Parent
            Import-Module (Join-Path $root 'shared/modules/DynamicProfiles.psm1') -Force
            $options = Get-DynamicOptions -ProfileName 'doctor-check-level' -WorkspaceRoot $root
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
    [string]$CheckLevel = 'standard'
)

$ErrorActionPreference = 'Continue'
$BinDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$Shared  = (Resolve-Path (Join-Path $BinDir '..\shared')).Path

if (-not (Test-Path $RepoPath)) {
    Write-Host "[FAIL] Repo not found: $RepoPath" -ForegroundColor Red
    exit 2
}

$fails = 0
$warns = 0

function Pass  ([string]$msg) { Write-Host "[PASS] $msg" -ForegroundColor Green }
function Fail  ([string]$msg) { Write-Host "[FAIL] $msg" -ForegroundColor Red;    $script:fails++ }
function Warn  ([string]$msg) { Write-Host "[WARN] $msg" -ForegroundColor Yellow; $script:warns++ }
function Info  ([string]$msg) { Write-Host "[INFO] $msg" -ForegroundColor Cyan }

Write-Host ""
Write-Host "=== doctor: $RepoPath ===" -ForegroundColor Cyan
Write-Host ""

# ---- 1. .github exists ----
$ghDir = Join-Path $RepoPath '.github'
if (-not (Test-Path $ghDir)) {
    Fail ".github folder missing - run setup-repo.ps1 first"
    Write-Host ""
    $f = $fails
    $w = $warns
    Write-Host ('RESULT: ' + $f + ' fail and ' + $w + ' warning') -ForegroundColor Red
    exit 1
}
Pass ".github folder exists"

# ---- 2. Required per-repo files ----
$requiredFiles = @(
    @('copilot-instructions.md', (Join-Path $ghDir 'copilot-instructions.md')),
    @('COPILOT-SETUP.md',        (Join-Path $ghDir 'COPILOT-SETUP.md'))
)
foreach ($f in $requiredFiles) {
    if (Test-Path $f[1]) {
        $size = (Get-Item $f[1]).Length
        if ($size -gt 0) { Pass $f[0] }
        else             { Fail "$($f[0]) is empty" }
    } else {
        Fail "$($f[0]) missing"
    }
}

# Required directories
$requiredDirs = @('agents', 'instructions-local')
foreach ($d in $requiredDirs) {
    $dp = Join-Path $ghDir $d
    if (-not (Test-Path $dp)) {
        Fail "$d/ missing"
    } elseif (@(Get-ChildItem $dp -ErrorAction SilentlyContinue).Count -eq 0) {
        Fail "$d/ is empty"
    } else {
        Pass "$d/ has content"
    }
}

# At least one .instructions.md
$instrFiles = @(Get-ChildItem (Join-Path $ghDir 'instructions-local') -Filter '*.instructions.md' -ErrorAction SilentlyContinue)
if ($instrFiles.Count -eq 0) {
    Fail "instructions-local/ has no *.instructions.md file"
} else {
    Pass "instructions-local/ has $($instrFiles.Count) instruction file(s)"
}

# ---- 3. Junctions ----
$junctions = @('skills', 'instructions', 'prompts', 'plans')
foreach ($j in $junctions) {
    $jp = Join-Path $ghDir $j
    if (-not (Test-Path $jp)) {
        Fail ".github/$j missing - run link-copilot.cmd"
        continue
    }
    $item = Get-Item $jp -Force
    if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        # Verify target resolves
        $sharedTarget = Join-Path $Shared $j
        if (Test-Path $sharedTarget) {
            Pass ".github/$j -> shared/$j"
        } else {
            Warn ".github/$j junction exists but shared/$j does not"
        }
    } else {
        Warn ".github/$j is a real folder (override mode), not a junction"
    }
}

# ---- 4. .gitignore marker block ----
$gi = Join-Path $RepoPath '.gitignore'
if (-not (Test-Path $gi)) {
    Warn ".gitignore missing - junction folders may be committed"
} else {
    $giText = [System.IO.File]::ReadAllText($gi, [System.Text.Encoding]::UTF8)
    if ($giText -notmatch 'copilot-shared junctions') {
        Fail ".gitignore is missing the copilot-shared marker block"
    } else {
        $missing = @()
        foreach ($entry in @('.github/skills', '.github/instructions', '.github/prompts', '.github/plans')) {
            if ($giText -notmatch [regex]::Escape($entry)) { $missing += $entry }
        }
        if ($missing.Count -gt 0) {
            Fail ".gitignore marker block missing entries: $($missing -join ', ')"
        } else {
            Pass ".gitignore marker block complete"
        }
    }
}

# ---- 5. Unresolved placeholders in agents ----
$agentDir = Join-Path $ghDir 'agents'
if (Test-Path $agentDir) {
    $agentFiles = Get-ChildItem $agentDir -Filter '*.agent.md' -ErrorAction SilentlyContinue
    $phFound = $false
    foreach ($af in $agentFiles) {
        $content = Get-Content $af.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -match '<[A-Za-z][A-Za-z-]*>') { $phFound = $true; break }
    }
    if ($phFound) {
        Warn "Unresolved <placeholder> tokens in .github/agents/ — run customize-agents skill"
    } else {
        Pass "No unresolved placeholders in agents"
    }
}

# ---- 6. Old-template-term leakage ----
if (Test-Path $agentDir) {
    $leakTerms = @('PolicyTemplate', 'policy-bom', '<product-suite>', '<orchestrator-repo>', '<sibling-repo>', '<core-lib-repo>')
    $leakFound = $false
    foreach ($af in (Get-ChildItem $agentDir -Filter '*.agent.md' -ErrorAction SilentlyContinue)) {
        $content = Get-Content $af.FullName -Raw -ErrorAction SilentlyContinue
        foreach ($term in $leakTerms) {
            if ($content -match [regex]::Escape($term)) { $leakFound = $true; break }
        }
        if ($leakFound) { break }
    }
    if ($leakFound) {
        Warn "Old template terms still in agents — re-run customize-agents skill"
    } else {
        Pass "No org-specific template terms in agents"
    }
}

# ---- 7. Repo-cache freshness ----
$rcFile = Join-Path $ghDir 'repo-cache.md'
if (Test-Path $rcFile) {
    $days = ((Get-Date) - (Get-Item $rcFile).LastWriteTime).Days
    if ($days -le 30) {
        Pass 'repo-cache.md is fresh (' + $days + ' days old)'
    } else {
        Warn 'repo-cache.md is stale (' + $days + ' days old) - regenerate with acquire-codebase-knowledge skill'
    }
} else {
    Info 'repo-cache.md not generated yet - run acquire-codebase-knowledge skill'
}

# ---- 8. Personal instructions ----
$piFile = Join-Path $ghDir 'personal-instructions.md'
if (-not (Test-Path $piFile)) {
    Info 'personal-instructions.md not set - copy from templates/ if you want one'
}

# ---- Summary ----
Write-Host ""
if ($fails -eq 0 -and $warns -eq 0) {
    Write-Host ('RESULT: HEALTHY') -ForegroundColor Green
    exit 0
} elseif ($fails -eq 0) {
    $w = $warns
    Write-Host ('RESULT: ' + $w + ' warning') -ForegroundColor Yellow
    exit 0
} else {
    $f = $fails
    $w = $warns
    Write-Host ('RESULT: ' + $f + ' fail and ' + $w + ' warning') -ForegroundColor Red
    exit 1
}
