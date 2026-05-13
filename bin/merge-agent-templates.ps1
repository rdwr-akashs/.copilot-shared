#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Auto-merges .agent.md.template.new conflict files into live agent files.

.DESCRIPTION
  Run this after refresh-agents.cmd reports CONFLICT files.

  Rules applied per diff hunk:
    PURE INSERTION (a)  -> always applied  (new sections, Pipeline Entry Gate,
                                            Mandatory Completion Protocol, etc.)
    REPLACEMENT    (c)  -> applied only if:
                           - new content has NO <Placeholder> patterns  AND
                           - new content has MORE lines than old content
                           (covers routing line cleanup + Entry Gate combos)
    DELETION       (d)  -> never applied   (conservative)

  Any rejected hunk is printed so you know what still needs manual review.
  All .template.new files are deleted after processing.

.PARAMETER AgentsDir
  Path to the .github/agents directory.
  Defaults to <cwd>\.github\agents, or the first repo passed as positional arg.

.PARAMETER RepoPath
  Alternative: pass the repo root and AgentsDir is inferred.

.EXAMPLE
  # From inside the repo:
  & C:\rdwr-intelij\.copilot-shared\bin\merge-agent-templates.ps1

  # From .copilot-shared:
  .\bin\merge-agent-templates.ps1 -RepoPath C:\rdwr-intelij\kvision_dp_inline_config

  # Piped from refresh-agents.cmd (see that script's comments):
  .\bin\merge-agent-templates.ps1 -AgentsDir C:\repo\.github\agents
#>

param(
    [ArgumentCompleter({
        param($wordToComplete, $commandAst, $cursorPosition)
        try {
            $cur = $PWD.Path
            while ($cur) {
                $candidate = Join-Path $cur '.github\agents'
                if (Test-Path $candidate) {
                    [System.Management.Automation.CompletionResult]::new($candidate, $candidate, 'ParameterValue', 'Auto-detected agents directory')
                }
                $parent = Split-Path $cur -Parent
                if ($parent -eq $cur) { break }
                $cur = $parent
            }
        } catch { }
    })]
    [string]$AgentsDir  = "",
    [ArgumentCompleter({
        param($wordToComplete, $commandAst, $cursorPosition)
        try {
            $cur = $PWD.Path
            while ($cur) {
                $candidate = Join-Path $cur '.github\agents'
                if (Test-Path $candidate) {
                    [System.Management.Automation.CompletionResult]::new($candidate, $candidate, 'ParameterValue', 'Auto-detected agents directory')
                }
                $parent = Split-Path $cur -Parent
                if ($parent -eq $cur) { break }
                $cur = $parent
            }
        } catch { }
    })]
    [string]$RepoPath   = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Resolve agents directory
# ---------------------------------------------------------------------------
if (-not $AgentsDir) {
    if ($RepoPath) {
        $AgentsDir = Join-Path $RepoPath ".github\agents"
    } else {
        # Walk up from cwd looking for .github/agents
        $cur = $PWD.Path
        while ($cur) {
            $candidate = Join-Path $cur ".github\agents"
            if (Test-Path $candidate) { $AgentsDir = $candidate; break }
            $parent = Split-Path $cur -Parent
            if ($parent -eq $cur) { break }
            $cur = $parent
        }
    }
}

if (-not $AgentsDir -or -not (Test-Path $AgentsDir)) {
    Write-Host "ERROR: Could not find .github/agents. Pass -AgentsDir or -RepoPath." -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------------------------
# Find GNU diff (not PowerShell's Compare-Object alias)
# ---------------------------------------------------------------------------
function Find-GnuDiff {
    $found = Get-Command "diff" -ErrorAction SilentlyContinue
    if ($found -and $found.CommandType -eq "Application") { return $found.Source }
    foreach ($p in @(
        "C:\Program Files\Git\usr\bin\diff.exe",
        "C:\Program Files (x86)\Git\usr\bin\diff.exe"
    )) {
        if (Test-Path $p) { return $p }
    }
    return $null
}

$diffExe = Find-GnuDiff
if (-not $diffExe) {
    Write-Host "ERROR: GNU diff not found. Install Git for Windows." -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------------------------
# Diff hunk parser  (normal diff format, not unified)
# ---------------------------------------------------------------------------
function Parse-DiffHunks {
    param([string[]]$DiffLines)

    $hunks   = [System.Collections.Generic.List[object]]::new()
    $current = $null

    foreach ($line in $DiffLines) {
        if ($line -match '^(\d+(?:,\d+)?)([acd])(\d+(?:,\d+)?)$') {
            if ($current) { $hunks.Add($current) }

            $oldParts  = $Matches[1] -split ','
            $newParts  = $Matches[3] -split ','

            $current = [PSCustomObject]@{
                Op       = $Matches[2]
                OldStart = [int]$oldParts[0]
                OldEnd   = if ($oldParts.Count -gt 1) { [int]$oldParts[1] } else { [int]$oldParts[0] }
                NewStart = [int]$newParts[0]
                NewEnd   = if ($newParts.Count -gt 1) { [int]$newParts[1] } else { [int]$newParts[0] }
                OldLines = [System.Collections.Generic.List[string]]::new()
                NewLines = [System.Collections.Generic.List[string]]::new()
            }
        }
        elseif ($line -match '^< ?(.*)$' -and $current) {
            $current.OldLines.Add(($line -replace '^< ?', ''))
        }
        elseif ($line -match '^> ?(.*)$' -and $current) {
            $current.NewLines.Add(($line -replace '^> ?', ''))
        }
        # '---' separator lines are ignored
    }
    if ($current) { $hunks.Add($current) }
    return $hunks
}

# ---------------------------------------------------------------------------
# Hunk acceptance logic
# ---------------------------------------------------------------------------

# Matches template placeholders like <ProjectException>, <calling-service>, <DomainObject>
# but NOT simple angle-bracket math or HTML tags (those don't appear in agent files)
$placeholderRx = '<[A-Za-z][A-Za-z0-9]*(?:[A-Z\-][a-z0-9]+)+'  #  camelCase or kebab-case word inside <>

function Should-ApplyHunk {
    param([object]$Hunk)

    switch ($Hunk.Op) {
        'a' { return $true }   # Pure insertion - always safe
        'd' { return $false }  # Deletion - never auto-apply
        'c' {
            $newText = $Hunk.NewLines -join "`n"
            if ($newText -match $placeholderRx) { return $false }  # Contains placeholder
            if ($Hunk.NewLines.Count -gt $Hunk.OldLines.Count) { return $true }  # Expansion
            return $false  # Same-length or shrinking replacement - skip
        }
    }
    return $false
}

# ---------------------------------------------------------------------------
# Apply accepted hunks to a list of lines (hunks must be in REVERSE order)
# ---------------------------------------------------------------------------
function Apply-Hunk {
    param([System.Collections.Generic.List[string]]$Lines, [object]$Hunk)

    switch ($Hunk.Op) {
        'a' {
            $idx = $Hunk.OldStart  # insert after line OldStart (1-based) = index OldStart (0-based)
            foreach ($i in ($Hunk.NewLines.Count - 1)..0) {
                $Lines.Insert($idx, $Hunk.NewLines[$i])
            }
        }
        'c' {
            $idx   = $Hunk.OldStart - 1
            $count = $Hunk.OldEnd - $Hunk.OldStart + 1
            $Lines.RemoveRange($idx, $count)
            foreach ($i in ($Hunk.NewLines.Count - 1)..0) {
                $Lines.Insert($idx, $Hunk.NewLines[$i])
            }
        }
    }
}

# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "merge-agent-templates: $AgentsDir" -ForegroundColor Cyan
Write-Host ""

$templateFiles = @(Get-ChildItem -Path $AgentsDir -Filter "*.agent.md.template.new" |
                   Sort-Object Name)

if ($templateFiles.Count -eq 0) {
    Write-Host "No .template.new files found - nothing to do." -ForegroundColor Green
    exit 0
}

Write-Host "Found $($templateFiles.Count) conflict file(s)`n" -ForegroundColor Yellow

$totalApplied   = 0
$totalRejected  = 0
$needsReview    = [System.Collections.Generic.List[string]]::new()

foreach ($tf in $templateFiles) {
    $baseName  = $tf.Name -replace '\.template\.new$', ''
    $liveFile  = Join-Path $AgentsDir $baseName
    $shortName = $baseName

    Write-Host "[$shortName]" -ForegroundColor White

    # New file (no live copy) - just copy template in
    if (-not (Test-Path $liveFile)) {
        Copy-Item $tf.FullName $liveFile
        Remove-Item $tf.FullPath
        Write-Host "  NEW - copied template as live file" -ForegroundColor Green
        continue
    }

    # Run GNU diff
    $rawDiff     = & $diffExe $liveFile $tf.FullName 2>&1
    $diffExit    = $LASTEXITCODE

    if ($diffExit -eq 2) {
        Write-Host "  ERROR running diff - skipping (manual review needed)" -ForegroundColor Red
        $needsReview.Add($baseName)
        continue
    }

    if ($diffExit -eq 0) {
        Write-Host "  Identical - deleting template file" -ForegroundColor DarkGray
        Remove-Item $tf.FullName
        continue
    }

    $hunks = @(Parse-DiffHunks -DiffLines ($rawDiff | ForEach-Object { "$_" }))

    if ($hunks.Count -eq 0) {
        Write-Host "  Could not parse diff - skipping (manual review needed)" -ForegroundColor Yellow
        $needsReview.Add($baseName)
        continue
    }

    # Sort DESCENDING so applying bottom hunks first keeps earlier line numbers valid
    $sortedHunks = @($hunks | Sort-Object -Property OldStart -Descending)

    $accepted = @($sortedHunks | Where-Object { Should-ApplyHunk $_ })
    $rejected = @($sortedHunks | Where-Object { -not (Should-ApplyHunk $_) })

    if ($accepted.Count -eq 0 -and $rejected.Count -gt 0) {
        Write-Host "  All $($rejected.Count) hunk(s) are repo-specific - no auto changes" -ForegroundColor DarkGray
        foreach ($h in $rejected) {
            $preview = if ($h.OldLines.Count -gt 0) { ($h.OldLines[0] -replace '^(.{70}).*', '$1...') } else { "(empty)" }
            Write-Host "    SKIPPED [$($h.Op)] line $($h.OldStart): $preview" -ForegroundColor DarkYellow
        }
        Write-Host "  .template.new kept - diff it manually then delete it" -ForegroundColor Yellow
        $totalRejected += $rejected.Count
        $needsReview.Add($baseName)
        continue
    }

    # Load live file
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.AddRange([string[]](Get-Content $liveFile -Encoding UTF8))

    foreach ($h in $accepted) {
        Apply-Hunk -Lines $lines -Hunk $h
    }

    # Write back (LF endings, no BOM)
    [System.IO.File]::WriteAllLines(
        $liveFile,
        $lines,
        (New-Object System.Text.UTF8Encoding $false)
    )

    Remove-Item $tf.FullName

    $totalApplied  += $accepted.Count
    $totalRejected += $rejected.Count

    if ($rejected.Count -gt 0) {
        Write-Host ("  Applied {0} hunk(s), skipped {1} (repo-specific content preserved)" `
            -f $accepted.Count, $rejected.Count) -ForegroundColor Yellow
        foreach ($h in $rejected) {
            $preview = if ($h.OldLines.Count -gt 0) { ($h.OldLines[0] -replace '^(.{70}).*', '$1...') } else { "(empty)" }
            Write-Host "    SKIPPED [$($h.Op)] line $($h.OldStart): $preview" -ForegroundColor DarkYellow
        }
        $needsReview.Add($baseName)
    } else {
        Write-Host "  Applied $($accepted.Count) hunk(s) - clean merge" -ForegroundColor Green
    }
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "  Auto-applied hunks : $totalApplied"
Write-Host "  Skipped hunks      : $totalRejected  (repo-specific content, preserved as-is)"

if ($needsReview.Count -gt 0) {
    Write-Host ""
    Write-Host "The following files had skipped hunks - spot-check them:" -ForegroundColor Yellow
    foreach ($f in $needsReview) { Write-Host "  $f" -ForegroundColor DarkYellow }
}

Write-Host ""
Write-Host "Next: In Copilot Chat run: 'Run the customize-agents skill on this repo'" -ForegroundColor Cyan
