<#
.SYNOPSIS
    One-shot per-repo .github/ setup for a .copilot-shared-linked repository.

.DESCRIPTION
    Creates and populates .github/ with everything Copilot needs to be maximally
    useful in this repository -- no manual editing required for the boilerplate.

    1. Detects repo name + category from repo-categories.md / tech-discoveries.md
    2. Creates .github/ structure (agents, instructions-local)
    3. Writes copilot-instructions.md pre-filled with tech stack, BB URL, build commands
    4. Writes instructions-local/project-rules.instructions.md (stub)
    5. Writes instructions-local/cli-commands.instructions.md (build/test commands)
    6. Copies all agent templates (skip if already customised)
    7. Junctions shared/{skills,instructions,prompts,plans} via link-copilot.cmd
    8. Writes COPILOT-SETUP.md with repo-specific onboarding
    9. Appends personal-instructions.md to .gitignore

    Re-running is safe: existing files are never overwritten unless -Force is used.

.PARAMETER RepoPath
    Full path to the repo to set up. Required.

.PARAMETER Force
    Overwrite all generated files even if they already exist.

.EXAMPLE
    .\bin\setup-repo.ps1 C:\rdwr-intelij\df_core
    .\bin\setup-repo.ps1 C:\rdwr-intelij\kvision_collector -Force
#>
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$RepoPath,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ROOT   = Split-Path $PSScriptRoot -Parent
$SHARED = Join-Path $ROOT 'shared'

function Write-Step { param([string]$m) Write-Host "`n==> $m" -ForegroundColor Cyan }
function Write-Ok   { param([string]$m) Write-Host "  [ok]   $m" -ForegroundColor Green }
function Write-Skip { param([string]$m) Write-Host "  [skip] $m (exists -- use -Force to overwrite)" -ForegroundColor DarkGray }
function Write-Info { param([string]$m) Write-Host "  $m" -ForegroundColor DarkYellow }
function Save-File {
    param([string]$Path, [string]$Content, [string]$Label)
    if ((Test-Path $Path) -and -not $Force) { Write-Skip $Label; return }
    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.Encoding]::UTF8)
    Write-Ok $Label
}

# Resolve and validate repo path
$RepoPath = [IO.Path]::GetFullPath($RepoPath)
if (-not (Test-Path $RepoPath)) {
    Write-Host "ERROR: Repo not found: $RepoPath" -ForegroundColor Red; exit 2
}
$repoName = Split-Path $RepoPath -Leaf

Write-Host ""
Write-Host ".copilot-shared repo setup -- $repoName" -ForegroundColor White
Write-Host "===========================================" -ForegroundColor White

# Load .local.env
$bbWorkspace = 'your-workspace'
$bbBaseUrl   = 'https://bitbucket.org'
$envPath = Join-Path $ROOT '.local.env'
if (Test-Path $envPath) {
    Get-Content $envPath | ForEach-Object {
        if ($_ -match '^BB_WORKSPACE=(.+)') { $bbWorkspace = $Matches[1] }
        if ($_ -match '^BB_BASE_URL=(.+)')  { $bbBaseUrl   = $Matches[1] }
    }
}
$bbRepoUrl = "$bbBaseUrl/$bbWorkspace/$repoName"

# ---- Step 1: Registry lookup ----
Write-Step "Step 1: Looking up $repoName in registry"
$repoDesc  = ''
$repoBuild = ''
$repoTest  = ''
$repoRun   = ''

$tdPath = Join-Path $SHARED 'memory\tech-discoveries.md'
if (Test-Path $tdPath) {
    # Process line-by-line to avoid cross-line regex ambiguity
    $tdLines = [System.IO.File]::ReadAllLines($tdPath, [System.Text.Encoding]::UTF8)
    $escapedName = [regex]::Escape($repoName)

    # Split into sections by "## " headers
    $inRepoRegistry  = $false
    $inBuildCommands = $false
    $repoFoundInRegistry = $false
    foreach ($line in $tdLines) {
        if ($line -match '^##\s+') {
            $inRepoRegistry  = $line -match 'Repo Registry|Repository Registry'
            $inBuildCommands = $line -match 'Build.*Test|Test.*Build|Commands'
            continue
        }
        if ($line -notmatch "^\|\s+``$escapedName``\s+\|") { continue }

        # Split all columns including empty ones (don't filter blank cells)
        $rawCols = @($line -split '\|' | ForEach-Object { ($_ -replace '``', '').Trim() })
        # rawCols[0] is empty (before first |), rawCols[1] is repo name, rawCols[2] is first data col
        $cols = @(($line -split '\|') |
                ForEach-Object { ($_ -replace '``', '').Trim() } |
                Where-Object { $_ -ne '' })

        if ($inBuildCommands -and $rawCols.Count -ge 6) {
            $b = $rawCols[2]; if ($b -and $b -notmatch '^\(|^_') { $repoBuild = $b }
            $t = $rawCols[3]; if ($t -and $t -notmatch '^\(|^_') { $repoTest  = $t }
            $r = $rawCols[5]; if ($r -and $r -notmatch '^\(|^_') { $repoRun   = $r }
            if ($repoBuild) { Write-Ok "Build command: $repoBuild" }
        } elseif ($inRepoRegistry) {
            $repoFoundInRegistry = $true
            # rawCols[2] is the description column (may be blank)
            if ($rawCols.Count -ge 3 -and -not $repoDesc) {
                $candidate = $rawCols[2]
                if ($candidate -and $candidate -notmatch '^\(|^_') {
                    $repoDesc = $candidate
                    Write-Ok "Registry description: $repoDesc"
                } else {
                    Write-Info "Found in registry -- no description yet (add one to tech-discoveries.md)"
                }
            }
        }
    }
    if (-not $repoFoundInRegistry -and -not $repoBuild) {
        Write-Info "Not in Repo Registry -- generic template used (run setup-local.ps1 to populate)"
    }
} else {
    Write-Info "tech-discoveries.md not found -- run setup-local.ps1 for best results"
}

# ---- Detect category and infer stack ----
$repoCategory = 'service'
$catFile = Join-Path $SHARED 'skills\remote-repo-exploration\references\repo-categories.md'
if (Test-Path $catFile) {
    $catLines = [System.IO.File]::ReadAllLines($catFile, [System.Text.Encoding]::UTF8)
    $currentCat = ''
    $escapedName2 = [regex]::Escape($repoName)
    foreach ($line in $catLines) {
        if ($line -match '^##\s+Category:\s*(.+)') { $currentCat = $Matches[1].Trim(); continue }
        if ($currentCat -and $line -match "``$escapedName2``") {
            $repoCategory = $currentCat
            Write-Ok "Category: $repoCategory"
            break
        }
    }
}

$isFrontend = $repoName -match 'webui|_webui$|^webui_'
$isInfra    = $repoName -match 'infra|deploy|nginx|redis|rabbit|postgres|monitor|ansible'

$stackLang  = if ($isFrontend) { 'TypeScript / React 18' } else { 'Java 17' }
$stackFW    = if ($isFrontend) { 'React, Styled Components, Vite' } else { 'Spring Boot 2.x, JAX-RS (Jersey), Spring Data JPA' }
$stackDB    = if ($isFrontend) { 'N/A (UI only)' } elseif ($isInfra) { 'N/A' } else { 'PostgreSQL (via Spring Data JPA)' }
$stackBld   = if ($isFrontend) { 'npm (Vite)' } else { 'Maven (./mvnw)' }
$stackTst   = if ($isFrontend) { 'Vitest, React Testing Library' } else { 'JUnit 5, Mockito, Spring Boot Test' }

if (-not $repoBuild) { $repoBuild = if ($isFrontend) { 'npm install && npm start' } else { './mvnw clean package -DskipTests' } }
if (-not $repoTest)  { $repoTest  = if ($isFrontend) { 'npm test' } else { './mvnw test' } }

# ---- Step 2: Create .github/ structure ----
Write-Step "Step 2: Creating .github/ structure"
$github    = Join-Path $RepoPath '.github'
$agentsDir = Join-Path $github 'agents'
$localDir  = Join-Path $github 'instructions-local'
foreach ($d in @($github, $agentsDir, $localDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}
Write-Ok ".github/ structure ready"

# ---- Step 3: copilot-instructions.md ----
Write-Step "Step 3: Writing copilot-instructions.md"
$descLine = if ($repoDesc) { $repoDesc } else { '<!-- TODO: one paragraph describing what this service does, who calls it, what it depends on. -->' }
$ciContent = @"
---
applyTo: '**'
---
# Copilot Instructions -- $repoName
<!-- Auto-generated by bin/setup-repo.ps1 on $(Get-Date -Format 'yyyy-MM-dd'). Edit freely. -->

## Auto-Agent Dispatch

When the user sends a message **without** an explicit ``@agent`` prefix:
1. Classify using the routing table in ``orchestrator.instructions.md``
2. Announce: **"[Agent: ``<name>``] -- <one-line task summary>"**
3. Act as that agent immediately

## Context-First Rule

Before writing any code, check ``.github/repo-cache.md``:
- **< 30 days old**: read it -- it has the module map, patterns, and commands
- **Absent or stale**: run ``acquire-codebase-knowledge`` skill to generate it
- After each task: append one line to ``## Recent Context`` in the cache

> **Routing:** ``orchestrator.instructions.md``  
> **Rules:** ``instructions-local/project-rules.instructions.md``  
> **Org context:** ``instructions/copilot-local.instructions.md``

## Project Overview

$descLine

**Bitbucket:** $bbRepoUrl  
**Category:** $repoCategory

## Tech Stack

- **Language:** $stackLang
- **Framework:** $stackFW
- **Database:** $stackDB
- **Build:** $stackBld (``$repoBuild``)
- **Test:** $stackTst (``$repoTest``)
- **CI:** Jenkins / Bitbucket Pipelines

## Project Structure

``````
<!-- Run 'acquire-codebase-knowledge skill' to auto-generate this section. -->
``````

## Architecture Notes

<!-- Anything agents must know: inter-service calls, event flows, HA behaviour, key dependencies. -->
"@
Save-File (Join-Path $github 'copilot-instructions.md') $ciContent 'copilot-instructions.md'

# ---- Step 4: project-rules.instructions.md ----
Write-Step "Step 4: Writing instructions-local/project-rules.instructions.md"
$prContent = @"
---
applyTo: '**'
---
# Project Rules -- $repoName
<!-- Repo-specific rules. Override shared instructions when there is a conflict. -->
<!-- Fill in after exploring the codebase, or run customize-agents skill in Copilot Chat. -->

## Error Handling

<!-- e.g. Throw ProjectException with HTTP status constant. No new exception classes. -->
<!-- Discover: grep -rn 'extends.*Exception' src/main/java --include='*.java' -->

## Dependency Management

<!-- e.g. All versions in bom/pom.xml. Never declare versions in child poms. -->

## Module Boundaries

<!-- e.g. Controllers -> Services -> Repositories. No cross-layer direct calls. -->

## Domain-Specific Patterns

<!-- Patterns agents get wrong without being told.
     Example: two FooModel classes (DTO vs JPA entity). -->

## Don'ts

<!-- Hard rules. Examples:
     - Never use @Autowired on fields
     - Never return null from public methods -->
"@
Save-File (Join-Path $localDir 'project-rules.instructions.md') $prContent 'project-rules.instructions.md'

# ---- Step 5: cli-commands.instructions.md ----
Write-Step "Step 5: Writing instructions-local/cli-commands.instructions.md"
if ($repoRun -and $repoRun -notmatch '^\(|^_') {
    $runBlock = $repoRun
} elseif ($isFrontend) {
    $runBlock = "# Terminal 1 -- library (keep running):`ncd ui/<app>-<version>`nnpm install && npm start`n`n# Terminal 2 -- example app (after dist/ is built):`ncd ui/<app>-<version>/example`nnpm install && npm run dev"
} else {
    $runBlock = "# Docker Compose (preferred):`ndocker-compose up`n`n# Or Spring Boot direct:`n./mvnw spring-boot:run -pl <service-module>"
}
$cliContent = @"
---
applyTo: '**'
---
# CLI Commands -- $repoName
<!-- Pre-filled by bin/setup-repo.ps1 on $(Get-Date -Format 'yyyy-MM-dd'). Verify and correct these. -->
<!-- These override any generic commands suggested by shared instructions. -->

## Build

``````bash
$repoBuild
``````

## Test -- All

``````bash
$repoTest
``````

## Test -- Single Module / Class

``````bash
# Maven: run one module
./mvnw test -pl <module-name>

# Maven: run one test class
./mvnw test -pl <module-name> -Dtest=MyClassTest

# npm: run with filter
npm test -- --testNamePattern='<pattern>'
``````

## Run Locally

``````bash
$runBlock
``````

## Useful Grep Patterns (update <org> with actual package root)

``````bash
# REST endpoints
grep -rn '@(GET|POST|PUT|DELETE|Path)' src/main/java --include='*.java' | grep -v test

# Exception classes
grep -rn 'extends.*Exception' src/main/java --include='*.java'

# Akka actor classes
grep -rn 'extends AbstractActor' src/main/java --include='*.java'

# RabbitMQ listeners
grep -rn '@RabbitListener' src/main/java --include='*.java'
``````
"@
Save-File (Join-Path $localDir 'cli-commands.instructions.md') $cliContent 'cli-commands.instructions.md'

# instructions-local README
$lrPath = Join-Path $localDir 'README.md'
if (-not (Test-Path $lrPath)) {
    $lrContent = @"
# .github/instructions-local/

Repo-specific Copilot instructions for ``$repoName``.
Tracked by THIS repo's git. Loaded automatically by Copilot.
Override shared instructions when there is a conflict.

| File | Purpose |
|------|---------|
| ``project-rules.instructions.md`` | Error types, dependency management, naming |
| ``cli-commands.instructions.md``  | Build, test, run commands |

Never edit files under ``.github/instructions/`` -- that is the shared junction.
"@
    [System.IO.File]::WriteAllText($lrPath, $lrContent, [System.Text.Encoding]::UTF8)
    Write-Ok "instructions-local/README.md written"
}

# ---- Step 6: COPILOT-SETUP.md ----
Write-Step "Step 6: Writing COPILOT-SETUP.md"
$csContent = @"
# GitHub Copilot Setup -- $repoName

Shared configuration from ``.copilot-shared``. Skills, instructions, prompts, and plans are
**junctioned** from the shared store. Agents are per-repo copies that you customise.

---

## New developer: 5-minute setup

``````cmd
:: 1. Clone .copilot-shared (once per machine)
git clone https://github.com/rdwr-akashs/.copilot-shared.git %COPILOT_WORKSPACE_ROOT%\.copilot-shared

:: 2. Personalise (workspace slug, products, optional repo fetch from Bitbucket API)
powershell -File %COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\setup-local.ps1

:: 3. Set up this repo
powershell -File %COPILOT_WORKSPACE_ROOT%\.copilot-shared\bin\setup-repo.ps1 %COPILOT_WORKSPACE_ROOT%\$repoName

:: 4. Restart IDE.
``````

---

## What is junctioned vs. per-repo

| Path | Type | Edit? |
|------|------|-------|
| ``.github/instructions/`` | Junction to shared | Never |
| ``.github/skills/`` | Junction to shared | Never |
| ``.github/agents/*.agent.md`` | Per-repo copy | Yes |
| ``.github/copilot-instructions.md`` | Per-repo | Yes |
| ``.github/instructions-local/*.md`` | Per-repo | Yes |
| ``.github/personal-instructions.md`` | Per-developer (gitignored) | Yes |

---

## After setup: 3 Copilot Chat commands (one-time per repo)

``````
Run the customize-agents skill on this repo.
Run the acquire-codebase-knowledge skill.
Fill in the project overview in .github/copilot-instructions.md based on this codebase.
``````

Bitbucket: $bbRepoUrl
"@
Save-File (Join-Path $github 'COPILOT-SETUP.md') $csContent 'COPILOT-SETUP.md'

# ---- Step 7: Copy agent templates ----
Write-Step "Step 7: Copying agent templates"
$agentSrc = Join-Path $ROOT 'agent-templates'
$copied = 0; $skipped = 0
if (Test-Path $agentSrc) {
    Get-ChildItem "$agentSrc\*.agent.md" | ForEach-Object {
        $dest = Join-Path $agentsDir $_.Name
        if ((Test-Path $dest) -and -not $Force) { $skipped++ }
        else { Copy-Item $_.FullName $dest -Force; $copied++ }
    }
}
Write-Ok "Agents: copied=$copied, skipped=$skipped"

# ---- Step 8: Junction via link-copilot.cmd ----
Write-Step "Step 8: Creating junctions"
$linkScript = Join-Path $PSScriptRoot 'link-copilot.cmd'
if (Test-Path $linkScript) {
    & cmd.exe /c "$linkScript" "$RepoPath"
    # Verify at least the critical junctions were created
    $missingJunctions = @()
    foreach ($jName in @('skills', 'instructions', 'prompts', 'plans')) {
        $jPath = Join-Path $github $jName
        if (-not (Test-Path $jPath)) { $missingJunctions += $jName }
    }
    if ($missingJunctions.Count -gt 0) {
        Write-Host "  [warn] Junctions missing after link-copilot.cmd: $($missingJunctions -join ', ')" -ForegroundColor Yellow
        Write-Host "         Try running link-copilot.cmd manually from an elevated prompt." -ForegroundColor Yellow
    }
} else {
    Write-Host "  [warn] link-copilot.cmd not found -- run it manually" -ForegroundColor Yellow
}

# ---- Step 9: .gitignore ----
Write-Step "Step 9: Updating .gitignore"
$gi = Join-Path $RepoPath '.gitignore'
if (-not (Test-Path $gi)) { New-Item -ItemType File -Path $gi -Force | Out-Null }
$giText = [System.IO.File]::ReadAllText($gi, [System.Text.Encoding]::UTF8)
if ($giText -notmatch 'personal-instructions\.md') {
    [System.IO.File]::AppendAllText($gi, "`n# Copilot personal instructions (per-developer, never commit)`n.github/personal-instructions.md`n", [System.Text.Encoding]::UTF8)
    Write-Ok ".gitignore updated"
} else {
    Write-Ok ".gitignore already correct"
}

# ---- Step 10: Install git hooks ----
Write-Step "Step 10: Installing git hooks"
$hookScript = Join-Path $PSScriptRoot 'install-hooks.cmd'
if ((Test-Path $hookScript) -and (Test-Path (Join-Path $RepoPath '.git'))) {
    & cmd.exe /c "$hookScript" "$RepoPath"
} elseif (-not (Test-Path (Join-Path $RepoPath '.git'))) {
    Write-Info "Not a git repo yet -- run install-hooks.cmd after git init"
} else {
    Write-Info "install-hooks.cmd not found -- install hooks manually"
}

# ---- Summary ----
Write-Host ""
Write-Host "=== $repoName is ready ===" -ForegroundColor Green
Write-Host ""
Write-Host "Files created:"
Write-Host "  .github/copilot-instructions.md"
Write-Host "  .github/instructions-local/project-rules.instructions.md"
Write-Host "  .github/instructions-local/cli-commands.instructions.md"
Write-Host "  .github/agents/  ($copied agents)"
Write-Host "  .github/COPILOT-SETUP.md"
Write-Host ""
Write-Host "Next -- open $repoName in IDE and run in Copilot Chat:" -ForegroundColor White
Write-Host ""
Write-Host "  1.  Run the customize-agents skill on this repo." -ForegroundColor Yellow
Write-Host "      Replaces <placeholders> in agents/ with real names from this codebase."
Write-Host ""
Write-Host "  2.  Run the acquire-codebase-knowledge skill." -ForegroundColor Yellow
Write-Host "      Builds .github/repo-cache.md -- makes every future session instant."
Write-Host ""
Write-Host "  3.  Verify .github/instructions-local/cli-commands.instructions.md" -ForegroundColor Yellow
Write-Host "      (auto-detected build/test commands -- check they are correct)"
if (-not $repoDesc) {
    Write-Host ""
    Write-Host "  Tip: project overview is a placeholder -- ask Copilot:" -ForegroundColor DarkYellow
    Write-Host "       'Fill in the project overview in copilot-instructions.md based on this codebase.'" -ForegroundColor DarkYellow
}
