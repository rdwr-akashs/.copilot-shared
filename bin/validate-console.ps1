<#
.SYNOPSIS
    Validate that the Copilot Shared Console is properly set up and functional.
    
.DESCRIPTION
    Runs a series of checks to ensure the console and all its dependencies are working correctly.
#>

param([switch]$Repair)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$BinDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PassCount = 0
$FailCount = 0
$WarnCount = 0

function Write-Pass {
    param([string]$Text)
    Write-Host "[OK] $Text" -ForegroundColor Green
    $script:PassCount++
}

function Write-Fail {
    param([string]$Text)
    Write-Host "[FAIL] $Text" -ForegroundColor Red
    $script:FailCount++
}

function Write-Warn {
    param([string]$Text)
    Write-Host "[WARN] $Text" -ForegroundColor Yellow
    $script:WarnCount++
}

function Write-Section {
    param([string]$Text)
    Write-Host "`n=== $Text ===" -ForegroundColor Cyan
}

# Check console files exist
Write-Section "Console Files"
$files = @("console.ps1", "console.cmd", "doctor.ps1")
foreach ($f in $files) {
    $path = Join-Path $BinDir $f
    if (Test-Path $path) {
        $size = (Get-Item $path).Length
        Write-Pass "$f exists"
    } else {
        Write-Fail "$f MISSING"
    }
}

# Check documentation
Write-Section "Documentation"
$docs = @("GET_STARTED.md", "CONSOLE_GUIDE.md", "CONSOLE_SUMMARY.md")
foreach ($d in $docs) {
    $path = Join-Path $BinDir $d
    if (Test-Path $path) {
        $size = (Get-Item $path).Length
        if ($size -gt 500) {
            Write-Pass "$d is complete"
        } else {
            Write-Warn "$d seems small"
        }
    } else {
        Write-Fail "$d MISSING"
    }
}

# Check PowerShell version
Write-Section "PowerShell Version"
if ($PSVersionTable.PSVersion.Major -ge 5) {
    Write-Pass "PowerShell 5.0+ available"
} else {
    Write-Fail "PowerShell 5.0+ required"
}

# Check git availability
Write-Section "Git Repository"
try {
    $gitTest = & git status 2>&1
    Write-Pass "Git is available"
} catch {
    Write-Fail "Git not found"
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "VALIDATION SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Passed: $PassCount" -ForegroundColor Green
Write-Host "Failed: $FailCount" -ForegroundColor Red
Write-Host "Warnings: $WarnCount" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

if ($FailCount -gt 0) {
    exit 1
}
exit 0
