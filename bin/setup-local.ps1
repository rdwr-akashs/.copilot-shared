<#
.SYNOPSIS
    One-time local personalisation of .copilot-shared after cloning from GitHub.

.DESCRIPTION
    Creates the gitignored files that make the toolkit org-specific and powerful:

    1. shared/instructions/copilot-local.instructions.md
         Injected into EVERY Copilot session in EVERY linked repo via the
         shared/instructions junction. Agents know your real workspace name,
         product names, and key repos without you repeating them each time.

    2. shared/memory/*.md  (customer-cases, known-bugs, tech-discoveries)
         Initialised from templates. Grows from real work via the save-learning
         skill. Share these via your internal Bitbucket — never GitHub.

    3. shared/skills/remote-repo-exploration/references/repo-categories.md
         Fetched from the Bitbucket API (optional) or built from your input.
         Used by remote-repo-exploration to filter which repos to search.

    4. .local.env
         BB_WORKSPACE and BB_BASE_URL — used by scripts that clone or call the
         Bitbucket API.

    Re-running is safe: existing files are preserved unless you pass -Force.

.PARAMETER Force
    Overwrite all generated files even if they already exist.

.PARAMETER BBWorkspace
    Your Bitbucket workspace slug (e.g. "mycompany"). Skips the prompt.

.PARAMETER BBBaseUrl
    Bitbucket base URL. Default: https://bitbucket.org

.EXAMPLE
    .\bin\setup-local.ps1
    .\bin\setup-local.ps1 -Force
    .\bin\setup-local.ps1 -BBWorkspace mycompany
#>

param(
    [string]$BBWorkspace,
    [string]$BBBaseUrl,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ROOT = Split-Path $PSScriptRoot -Parent  # .copilot-shared root

function Write-Step { param([string]$msg) Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Ok   { param([string]$msg) Write-Host "  [ok] $msg" -ForegroundColor Green }
function Write-Skip { param([string]$msg) Write-Host "  [skip] $msg (already exists — use -Force to overwrite)" -ForegroundColor DarkGray }
function Write-Info { param([string]$msg) Write-Host "  $msg" -ForegroundColor DarkYellow }
function Prompt-Input {
    param([string]$Question, [string]$Default = '')
    $hint = if ($Default) { " [$Default]" } else { '' }
    Write-Host "  $Question$hint : " -NoNewline -ForegroundColor White
    $val = Read-Host
    if (-not $val -and $Default) { $val = $Default }
    return $val
}

# ---------------------------------------------------------------------------
Write-Host "`n.copilot-shared local setup" -ForegroundColor White
Write-Host "===========================" -ForegroundColor White

# ---------------------------------------------------------------------------
# Load existing .local.env if present
$localEnvPath = Join-Path $ROOT '.local.env'
$savedWorkspace = ''
$savedBaseUrl   = 'https://bitbucket.org'
if (Test-Path $localEnvPath) {
    Get-Content $localEnvPath | ForEach-Object {
        if ($_ -match '^BB_WORKSPACE=(.+)') { $savedWorkspace = $Matches[1] }
        if ($_ -match '^BB_BASE_URL=(.+)')  { $savedBaseUrl   = $Matches[1] }
    }
}

# ---------------------------------------------------------------------------
Write-Step "Step 1: Bitbucket workspace"

if (-not $BBWorkspace) {
    $BBWorkspace = Prompt-Input "Bitbucket workspace slug (e.g. mycompany)" $savedWorkspace
}
if (-not $BBWorkspace) { Write-Host "ERROR: workspace is required." -ForegroundColor Red; exit 1 }

if (-not $BBBaseUrl) {
    $BBBaseUrl = Prompt-Input "Bitbucket base URL" $savedBaseUrl
}

# ---------------------------------------------------------------------------
Write-Step "Step 2: Product / project names"
Write-Info "(used in agent context so Copilot knows what your repos build)"

$product1 = Prompt-Input "Primary product name (e.g. MyProduct)"
$product2 = Prompt-Input "Secondary product name (optional, press Enter to skip)"

# ---------------------------------------------------------------------------
Write-Step "Step 3: Fetch repo list from Bitbucket API (optional)"
Write-Info "Creates repo-categories.md and the Repo Registry in tech-discoveries.md."
Write-Info "Requires a Bitbucket App Password (read-only 'Repositories' scope)."
Write-Info "Create one at: $BBBaseUrl/account/settings/app-passwords"

$fetchRepos = $false
$allRepos   = @()

$doFetch = Prompt-Input "Fetch repo list now? [y/N]" "N"
if ($doFetch -match '^[Yy]') {
    $bbUser = Prompt-Input "Bitbucket username"
    Write-Host "  App password (input hidden): " -NoNewline -ForegroundColor White
    $bbPassSecure = Read-Host -AsSecureString
    $bbPass = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                  [Runtime.InteropServices.Marshal]::SecureStringToBSTR($bbPassSecure))

    $authBytes  = [Text.Encoding]::ASCII.GetBytes("${bbUser}:${bbPass}")
    $authHeader = @{ Authorization = "Basic " + [Convert]::ToBase64String($authBytes) }

    Write-Info "Fetching repos from $BBBaseUrl/2.0/repositories/$BBWorkspace ..."
    try {
        $url = "$BBBaseUrl/2.0/repositories/$BBWorkspace`?pagelen=100&fields=values.slug,values.description,values.project.key,next"
        do {
            $resp    = Invoke-RestMethod -Uri $url -Headers $authHeader -TimeoutSec 30
            $allRepos += $resp.values
            $url = if ($resp.PSObject.Properties['next']) { $resp.next } else { $null }
        } while ($url)
        Write-Ok "Fetched $($allRepos.Count) repos"
        $fetchRepos = $true
    } catch {
        Write-Host "  [warn] API call failed: $_" -ForegroundColor Yellow
        Write-Info "Continuing without live repo list — you can re-run with -Force later."
    }
}

# ---------------------------------------------------------------------------
# Categorise repos
function Get-Category {
    param([string]$slug)
    if ($slug -match '^df_|^df-')   { return 'core-primary' }
    if ($slug -match '^kvision_|^kvision-') {
        if ($slug -match 'infra_|_infra|_deploy|_nginx|_redis|_rabbit|_postgres|_monitor|_fluentd|_efk|_kibana|_base_image|_cadvisor|_metallb|_ansible|_3rd|_lls') { return 'infra' }
        if ($slug -match '_webui|webui_') { return 'ui' }
        if ($slug -match '_libs$|_core$|_api$|_drivers$') { return 'libs' }
        if ($slug -match '_alert|_events') { return 'alerts' }
        if ($slug -match '_deploy|_upgrade|_manifest|_tools|_cli') { return 'tools' }
        if ($slug -match '_health|_ha_|_es_|_tor_|_vantage') { return 'ops' }
        return 'core-secondary'
    }
    if ($slug -match '^vision_')  { return 'vision-legacy' }
    if ($slug -match '^webui_')   { return 'ui' }
    if ($slug -match '^common_') {
        if ($slug -match 'infra|deploy|cluster|nexus|metallb') { return 'infra' }
        if ($slug -match 'kautomation|automation') { return 'testing' }
        return 'shared'
    }
    if ($slug -match '^auto-|^auto_') { return 'testing' }
    if ($slug -match '_docs$|_help$|_doc$|ai_resources|aae_') { return 'docs' }
    return 'other'
}

# ---------------------------------------------------------------------------
Write-Step "Step 4: Initialising shared/memory/ from templates"

$memDir      = Join-Path $ROOT 'shared\memory'
$tplDir      = Join-Path $ROOT 'shared\memory\templates'
$memFiles    = @('customer-cases.md', 'known-bugs.md', 'tech-discoveries.md')

if (-not (Test-Path $memDir)) { New-Item -ItemType Directory -Path $memDir -Force | Out-Null }

foreach ($f in $memFiles) {
    $dest = Join-Path $memDir $f
    $tpl  = Join-Path $tplDir $f
    if ((Test-Path $dest) -and -not $Force) {
        Write-Skip $f
    } elseif (Test-Path $tpl) {
        Copy-Item $tpl $dest -Force
        Write-Ok "initialised $f from template"
    } else {
        Write-Info "template not found for $f — skipping (run acquire-codebase-knowledge + save-learning to populate)"
    }
}

# Inject fetched repos into tech-discoveries.md Repo Registry
$tdPath = Join-Path $memDir 'tech-discoveries.md'
if ($fetchRepos -and (Test-Path $tdPath)) {
    $categories = @{
        'core-primary'   = @{ Title = "Core Services — Primary Product"; Repos = @() }
        'core-secondary' = @{ Title = "Core Services — Secondary Product"; Repos = @() }
        'libs'           = @{ Title = "Shared Libraries & APIs"; Repos = @() }
        'ui'             = @{ Title = "UI / Frontend"; Repos = @() }
        'infra'          = @{ Title = "Infrastructure & Deployment"; Repos = @() }
        'alerts'         = @{ Title = "Alerts & Events"; Repos = @() }
        'ops'            = @{ Title = "Operations & Health"; Repos = @() }
        'tools'          = @{ Title = "Tools, CI & Automation"; Repos = @() }
        'testing'        = @{ Title = "Testing & Automation"; Repos = @() }
        'vision-legacy'  = @{ Title = "Legacy / Related Services"; Repos = @() }
        'shared'         = @{ Title = "Shared Utilities"; Repos = @() }
        'docs'           = @{ Title = "Documentation"; Repos = @() }
        'other'          = @{ Title = "Other"; Repos = @() }
    }
    foreach ($r in $allRepos) {
        $cat = Get-Category $r.slug
        $desc = if ($r.description) { $r.description.Trim() } else { '' }
        $categories[$cat].Repos += "| ``$($r.slug)`` | $desc |"
    }

    $regLines = @('', '## Repo Registry', '', "All repos in Bitbucket workspace ``$BBWorkspace``. Auto-fetched $(Get-Date -Format 'yyyy-MM-dd').", "Full category filter: ``shared/skills/remote-repo-exploration/references/repo-categories.md``", '')
    $order = @('core-primary','core-secondary','libs','alerts','ui','infra','ops','tools','testing','vision-legacy','shared','docs','other')
    foreach ($cat in $order) {
        if ($categories[$cat].Repos.Count -eq 0) { continue }
        $regLines += "### $($categories[$cat].Title)"
        $regLines += ''
        $regLines += '| Repo | Description |'
        $regLines += '|------|-------------|'
        $regLines += $categories[$cat].Repos
        $regLines += ''
    }
    $regLines += '---'

    # Replace the existing Repo Registry section (between ## Repo Registry and the next ---)
    $tdContent = Get-Content $tdPath -Raw
    $tdContent  = $tdContent -replace '(?ms)## Repo Registry.*?^---', ($regLines -join "`n")
    Set-Content $tdPath $tdContent -NoNewline
    Write-Ok "Repo Registry updated in tech-discoveries.md ($($allRepos.Count) repos)"
}

# ---------------------------------------------------------------------------
Write-Step "Step 5: Writing repo-categories.md"

$catFile = Join-Path $ROOT 'shared\skills\remote-repo-exploration\references\repo-categories.md'
if ((Test-Path $catFile) -and -not $Force) {
    Write-Skip 'repo-categories.md'
} else {
    $catLines = @(
        "# Repository Categories — $BBWorkspace Bitbucket Workspace",
        "> Last updated: $(Get-Date -Format 'yyyy-MM-dd') | Workspace: ``$BBWorkspace``",
        "> Quick grep: ``shared/memory/tech-discoveries.md`` → Repo Registry",
        ''
    )
    if ($fetchRepos) {
        $order = @('core-primary','core-secondary','libs','alerts','ui','infra','ops','tools','testing','vision-legacy','shared','docs','other')
        foreach ($cat in $order) {
            if ($categories[$cat].Repos.Count -eq 0) { continue }
            $catLines += "## Category: $($categories[$cat].Title)"
            $catLines += ''
            $catLines += '| Repo | Description | Search Priority |'
            $catLines += '|------|-------------|----------------|'
            foreach ($row in $categories[$cat].Repos) {
                $catLines += $row -replace '\|$', '| ✅ |'
            }
            $catLines += ''
        }
    } else {
        $catLines += '<!-- Run setup-local.ps1 with Bitbucket credentials to auto-populate this file -->'
        $catLines += '<!-- Or add your repos manually below -->'
        $catLines += ''
        $catLines += '## Category: Core Services'
        $catLines += ''
        $catLines += '| Repo | Description | Search Priority |'
        $catLines += '|------|-------------|----------------|'
        $catLines += '| _(add your repos here)_ | | ✅ |'
    }
    New-Item -ItemType Directory -Force -Path (Split-Path $catFile) | Out-Null
    Set-Content $catFile ($catLines -join "`n")
    if ($fetchRepos) {
        Write-Ok "repo-categories.md written ($($allRepos.Count) repos, categorised)"
    } else {
        Write-Ok "repo-categories.md written (template — add repos or re-run with credentials)"
    }
}

# ---------------------------------------------------------------------------
Write-Step "Step 6: Writing copilot-local.instructions.md"
Write-Info "This is the KEY file — junctioned into every linked repo so agents"
Write-Info "always know your workspace and key repos without extra prompting."

$localInstrPath = Join-Path $ROOT 'shared\instructions\copilot-local.instructions.md'
if ((Test-Path $localInstrPath) -and -not $Force) {
    Write-Skip 'copilot-local.instructions.md'
} else {
    # Pick out key repos for agent context (first 3 per major category)
    $keyRepos = @()
    if ($fetchRepos) {
        $keyCategories = @('core-primary','core-secondary','libs','ui')
        foreach ($cat in $keyCategories) {
            $keyRepos += $categories[$cat].Repos | Select-Object -First 3 | ForEach-Object {
                ($_ -split '\|')[1].Trim().Trim('`')
            }
        }
    }
    $keyRepoList = if ($keyRepos) { ($keyRepos | Where-Object { $_ } | Select-Object -First 12) -join ', ' } else { '_(run setup-local.ps1 with credentials to auto-populate)_' }

    $products = @($product1) + @($product2) | Where-Object { $_ }
    $productLine = if ($products) { $products -join ', ' } else { '_(not configured)_' }

    $content = @"
---
applyTo: "**"
---
# Org Context — Local Configuration
# Generated by bin/setup-local.ps1 on $(Get-Date -Format 'yyyy-MM-dd').
# This file is gitignored. Re-run setup-local.ps1 -Force to regenerate.

## Bitbucket Workspace
- **Workspace slug:** ``$BBWorkspace``
- **Base URL:** $BBBaseUrl
- **Clone pattern:** ``git clone $BBBaseUrl/$BBWorkspace/<repo>.git``
- **MCP pattern:** ``workspace: $BBWorkspace``

## Products
$productLine

## Key Repos
$keyRepoList

## Repo Discovery
- Full list: ``shared/memory/tech-discoveries.md`` → Repo Registry ($(if ($fetchRepos) { $allRepos.Count.ToString() + ' repos' } else { 'run setup-local.ps1 to populate' }))
- Category filter: ``shared/skills/remote-repo-exploration/references/repo-categories.md``
- All repos live under: ``%COPILOT_WORKSPACE_ROOT%\``

## Agent Behaviour Notes
- Use the actual workspace slug ``$BBWorkspace`` in all Bitbucket API calls and git clone URLs.
- When the user says "sibling repo" or "other service", check the Repo Registry first.
- Grep ``shared/memory/tech-discoveries.md`` before any cross-repo investigation.
"@
    Set-Content $localInstrPath $content
    Write-Ok "copilot-local.instructions.md written"
    Write-Info "Agents in every linked repo will now see your workspace context."
}

# ---------------------------------------------------------------------------
Write-Step "Step 7: Writing .local.env"

$envContent = @"
# Local environment — generated by bin/setup-local.ps1
# Used by scripts that call the Bitbucket API or clone repos.
BB_WORKSPACE=$BBWorkspace
BB_BASE_URL=$BBBaseUrl
"@

if ((Test-Path $localEnvPath) -and -not $Force) {
    Write-Skip '.local.env'
} else {
    Set-Content $localEnvPath $envContent
    Write-Ok ".local.env written"
}

# ---------------------------------------------------------------------------
Write-Host "`n=== Setup complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Generated files (all gitignored):"
Write-Host "  shared/instructions/copilot-local.instructions.md  <- agents read this in every session"
Write-Host "  shared/memory/customer-cases.md                    <- populate via save-learning skill"
Write-Host "  shared/memory/known-bugs.md                        <- populate via save-learning skill"
Write-Host "  shared/memory/tech-discoveries.md                  <- $(if ($fetchRepos) { $allRepos.Count.ToString() + ' repos injected' } else { 'populate via acquire-codebase-knowledge' })"
Write-Host "  shared/skills/remote-repo-exploration/references/repo-categories.md"
Write-Host "  .local.env"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Link your repos:  bin\link-copilot.cmd <repo-path>"
Write-Host "     Or all at once:   bin\link-all-copilot.cmd"
Write-Host "  2. Open a linked repo in your IDE and ask Copilot:"
Write-Host "     'Run the customize-agents skill on this repo.'"
Write-Host "  3. As you investigate cases and bugs, run the save-learning skill."
Write-Host "     Your shared/memory/ files will grow and agents get faster over time."
if (-not $fetchRepos) {
    Write-Host ""
    Write-Host "Tip: Re-run with Bitbucket credentials to auto-populate the repo list:" -ForegroundColor DarkYellow
    Write-Host "  .\bin\setup-local.ps1 -Force" -ForegroundColor DarkYellow
}
