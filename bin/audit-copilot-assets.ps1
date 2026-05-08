<#
.SYNOPSIS
    Audits shared Copilot skills, agents, instructions, and prompts.

.DESCRIPTION
    This is a repository-maintainer check for .copilot-shared. It catches
    broken skill frontmatter, stale generated indexes, oversized skills, and
    malformed agent/prompt files before the shared configuration is pushed to
    the whole team.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File bin\audit-copilot-assets.ps1
#>

$ErrorActionPreference = 'Stop'

$BinDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $BinDir
$SkillsDir = Join-Path $RepoRoot 'shared\skills'
$AgentsDir = Join-Path $RepoRoot 'agent-templates'
$InstructionsDir = Join-Path $RepoRoot 'shared\instructions'
$PromptsDir = Join-Path $RepoRoot 'shared\prompts'
$SkillIndex = Join-Path $SkillsDir 'INDEX.md'

$errors = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

function Add-Error {
    param([string]$Message)
    $script:errors.Add($Message) | Out-Null
}

function Add-Warning {
    param([string]$Message)
    $script:warnings.Add($Message) | Out-Null
}

function Get-RelativePath {
    param([string]$Path)
    return $Path.Replace($RepoRoot + '\', '')
}

function Get-Frontmatter {
    param([string]$Content)

    if ($Content -match '(?ms)^---\s*\r?\n(.*?)\r?\n---') {
        return $Matches[1]
    }

    return $null
}

function Get-FrontmatterValue {
    param(
        [string]$Frontmatter,
        [string]$Key
    )

    if (-not $Frontmatter) { return '' }

    $lines = $Frontmatter -split "`r?`n"
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -notmatch "^$([regex]::Escape($Key)):\s*(.*)$") {
            continue
        }

        $value = $Matches[1].Trim()
        if ($value -in @('>-', '>', '|-', '|')) {
            $parts = @()
            for ($j = $i + 1; $j -lt $lines.Count; $j++) {
                if ($lines[$j] -match '^[A-Za-z_-]+:') { break }
                $parts += $lines[$j].Trim()
            }
            return (($parts -join ' ') -replace '\s+', ' ').Trim()
        }

        return $value.Trim("'").Trim('"')
    }

    return ''
}

function Get-FrontmatterKeys {
    param([string]$Frontmatter)

    if (-not $Frontmatter) { return @() }

    return @(
        $Frontmatter -split "`r?`n" |
            Where-Object { $_ -match '^[A-Za-z_-]+:' } |
            ForEach-Object { ($_ -split ':', 2)[0] }
    )
}

Write-Host "Auditing shared Copilot assets..." -ForegroundColor Cyan

# Skills
$skillFiles = Get-ChildItem -Path $SkillsDir -Recurse -Filter SKILL.md | Sort-Object FullName
foreach ($skillFile in $skillFiles) {
    $relative = Get-RelativePath $skillFile.FullName
    $content = Get-Content $skillFile.FullName -Raw -Encoding UTF8
    $frontmatter = Get-Frontmatter $content
    $name = Get-FrontmatterValue $frontmatter 'name'
    $description = Get-FrontmatterValue $frontmatter 'description'
    $lineCount = (Get-Content $skillFile.FullName -Encoding UTF8).Count
    $folderName = Split-Path -Leaf (Split-Path -Parent $skillFile.FullName)

    if (-not $frontmatter) {
        Add-Error "$relative is missing YAML frontmatter."
        continue
    }

    if ($frontmatter -match "\\'") {
        Add-Warning "$relative contains backslash-escaped apostrophes in frontmatter. Use double quotes or YAML single-quote escaping."
    }

    if (-not $name) {
        Add-Error "$relative is missing frontmatter field 'name'."
    } elseif ($name -notmatch '^[a-z0-9][a-z0-9-]{0,63}$') {
        Add-Error "$relative has invalid skill name '$name'. Use lowercase letters, digits, and hyphens only."
    } elseif ($name -ne $folderName) {
        Add-Error "$relative name '$name' does not match folder '$folderName'."
    }

    if (-not $description) {
        Add-Error "$relative is missing frontmatter field 'description'."
    } elseif ($description.Length -lt 10 -or $description.Length -gt 1024) {
        Add-Error "$relative description length is $($description.Length); expected 10-1024 characters."
    } elseif ($description.Length -lt 80) {
        Add-Warning "$relative description is very short ($($description.Length) chars); discovery may be weak."
    }

    $extraKeys = @(Get-FrontmatterKeys $frontmatter | Where-Object { $_ -notin @('name', 'description') })
    if ($extraKeys.Count -gt 0) {
        Add-Warning "$relative has non-discovery frontmatter fields: $($extraKeys -join ', '). Keep only if the target client reads them."
    }

    if ($lineCount -gt 500) {
        Add-Error "$relative has $lineCount lines; split details into references/ before publishing."
    } elseif ($lineCount -gt 300) {
        Add-Warning "$relative has $lineCount lines; consider moving detailed examples to references/."
    }

    $skillRoot = Split-Path -Parent $skillFile.FullName
    $auxDocs = Get-ChildItem -Path $skillRoot -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -in @('README.md', 'CHANGELOG.md', 'CREATION-SUMMARY.md', 'EXAMPLE.md') }
    foreach ($doc in $auxDocs) {
        Add-Warning "$(Get-RelativePath $doc.FullName) is auxiliary documentation inside a skill. Prefer SKILL.md plus references/ only."
    }
}

# Agent templates
$agentFiles = Get-ChildItem -Path $AgentsDir -Filter *.agent.md | Sort-Object FullName
foreach ($agentFile in $agentFiles) {
    $relative = Get-RelativePath $agentFile.FullName
    $content = Get-Content $agentFile.FullName -Raw -Encoding UTF8
    $frontmatter = Get-Frontmatter $content
    $name = Get-FrontmatterValue $frontmatter 'name'
    $description = Get-FrontmatterValue $frontmatter 'description'

    if (-not $frontmatter) {
        Add-Error "$relative is missing YAML frontmatter."
        continue
    }
    if (-not $name) { Add-Error "$relative is missing frontmatter field 'name'." }
    if (-not $description) { Add-Error "$relative is missing frontmatter field 'description'." }
}

# Instructions
$instructionFiles = Get-ChildItem -Path $InstructionsDir -Filter *.instructions.md | Sort-Object FullName
foreach ($instructionFile in $instructionFiles) {
    $relative = Get-RelativePath $instructionFile.FullName
    $content = Get-Content $instructionFile.FullName -Raw -Encoding UTF8
    $frontmatter = Get-Frontmatter $content
    $applyTo = Get-FrontmatterValue $frontmatter 'applyTo'

    if (-not $frontmatter) {
        Add-Warning "$relative has no frontmatter. Add applyTo if it should be auto-applied."
    } elseif (-not $applyTo) {
        Add-Warning "$relative frontmatter has no applyTo field."
    }
}

# Prompts
$promptFiles = Get-ChildItem -Path $PromptsDir -Filter *.md | Sort-Object FullName
foreach ($promptFile in $promptFiles) {
    $relative = Get-RelativePath $promptFile.FullName
    $content = Get-Content $promptFile.FullName -Raw -Encoding UTF8

    if ($content -notmatch '(?m)^#\s+\S') {
        Add-Warning "$relative has no level-1 title."
    }
    if ($content -notmatch '(?is)```.+?```') {
        Add-Warning "$relative has no fenced copy-paste prompt block."
    }
}

if (-not (Test-Path $SkillIndex)) {
    Add-Warning "shared\skills\INDEX.md is missing. Run bin\generate-skill-index.ps1."
}

Write-Host ""
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "  Skills:       $($skillFiles.Count)"
Write-Host "  Agents:       $($agentFiles.Count)"
Write-Host "  Instructions: $($instructionFiles.Count)"
Write-Host "  Prompts:      $($promptFiles.Count)"
Write-Host "  Warnings:     $($warnings.Count)"
Write-Host "  Errors:       $($errors.Count)"

if ($warnings.Count -gt 0) {
    Write-Host ""
    Write-Host "Warnings" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "  - $warning" -ForegroundColor Yellow
    }
}

if ($errors.Count -gt 0) {
    Write-Host ""
    Write-Host "Errors" -ForegroundColor Red
    foreach ($errorMessage in $errors) {
        Write-Host "  - $errorMessage" -ForegroundColor Red
    }
    exit 1
}

Write-Host ""
Write-Host "Audit passed." -ForegroundColor Green
