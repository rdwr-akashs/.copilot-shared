<#
.SYNOPSIS
    Master Console for Copilot Shared Operations
.DESCRIPTION
    Interactive console providing a unified interface for all copilot-shared operations.
.PARAMETER Quick
    Skip menu and run smart detection plus recommended fixes
.PARAMETER Workspace
    Workspace root. Defaults to parent of .copilot-shared.
.EXAMPLE
    powershell -File bin\console.ps1
    powershell -File bin\console.ps1 -Quick
#>

$WorkspaceCompleter = {
    param($wordToComplete, $commandAst, $cursorPosition)
    try {
        $parent = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
        Get-ChildItem -Path $parent -Directory -ErrorAction SilentlyContinue | Where-Object { Test-Path (Join-Path $_.FullName '.git') } | Select-Object -ExpandProperty Name | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "Repository")
        }
    } catch { }
}

param(
    [ArgumentCompleter($WorkspaceCompleter)]
    [string]$Workspace,
    [switch]$Quick
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$BinDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SharedRoot = Split-Path -Parent $BinDir
$WorkspaceRoot = if ($Workspace) { $Workspace } else { Split-Path -Parent $SharedRoot }

$Colors = @{
    Title       = 'Cyan'
    Success     = 'Green'
    Warning     = 'Yellow'
    Error       = 'Red'
    Info        = 'Blue'
    Menu        = 'Magenta'
    Highlight   = 'White'
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

function Write-Title {
    param([string]$Text)
    Write-Host ""
    Write-Host ("=" * 72) -ForegroundColor $Colors.Title
    Write-Host "   $Text" -ForegroundColor $Colors.Title
    Write-Host ("=" * 72) -ForegroundColor $Colors.Title
}

function Write-Section {
    param([string]$Text)
    Write-Host "`n$Text" -ForegroundColor $Colors.Menu
    Write-Host ("-" * 70) -ForegroundColor $Colors.Menu
}

function Write-Success {
    param([string]$Text)
    Write-Host "   [OK] $Text" -ForegroundColor $Colors.Success
}

function Write-Warning {
    param([string]$Text)
    Write-Host "   [!] $Text" -ForegroundColor $Colors.Warning
}

function Write-Error-Custom {
    param([string]$Text)
    Write-Host "   [X] $Text" -ForegroundColor $Colors.Error
}

function Write-Info {
    param([string]$Text)
    Write-Host "   [i] $Text" -ForegroundColor $Colors.Info
}

function Show-Menu {
    param(
        [hashtable]$Options,
        [string]$Title = "Select an option"
    )
    
    Write-Host "`n$Title" -ForegroundColor $Colors.Menu
    Write-Host ("-" * 70) -ForegroundColor $Colors.Menu
    
    $options.GetEnumerator() | Sort-Object Name | ForEach-Object {
        Write-Host "   [$($_.Name)] $($_.Value)" -ForegroundColor $Colors.Highlight
    }
    Write-Host "   [0] Exit" -ForegroundColor $Colors.Highlight
    Write-Host ""
}

function Invoke-Script {
    param(
        [string]$ScriptPath,
        [string]$Description,
        [string[]]$Arguments = @()
    )
    
    Write-Host ""
    Write-Info "Running: $Description"
    Write-Host "   Location: $ScriptPath" -ForegroundColor DarkGray
    
    try {
        if ($Arguments.Count -gt 0) {
            & $ScriptPath @Arguments
        }
        else {
            & $ScriptPath
        }
        Write-Success "$Description completed successfully"
        return $true
    }
    catch {
        Write-Error-Custom "$Description failed: $_"
        return $false
    }
}

function Get-ChangedItems {
    # Detect what has changed since last run
    $changes = @{
        Instructions = @()
        Agents       = @()
        Skills       = @()
        Memory       = @()
        Repos        = @()
    }
    
    # Check for unstaged changes
    $gitStatus = & git -C $SharedRoot status --porcelain 2>$null
    
    if ($gitStatus) {
        foreach ($line in $gitStatus) {
            $file = $line.Substring(3)
            
            if ($file -match '\.instructions\.md$|copilot-local\.instructions\.md$') {
                $changes.Instructions += $file
            }
            elseif ($file -match '\.agent\.md$') {
                $changes.Agents += $file
            }
            elseif ($file -match 'SKILL\.md$') {
                $changes.Skills += $file
            }
            elseif ($file -match 'shared/memory/') {
                $changes.Memory += $file
            }
        }
    }
    
    # Check for new/missing repos
    $linkedRepos = Get-ChildItem -Path $WorkspaceRoot -Directory -ErrorAction SilentlyContinue | Where-Object { 
        (Test-Path "$($_.FullName)\.github\copilot-instructions.md") 
    }
    
    if ($linkedRepos.Count -lt 5) {  # Heuristic: assumes at least 5 repos
        $changes.Repos += "Possible missing repos detected"
    }
    
    return $changes
}

function Show-ChangeSummary {
    param([hashtable]$Changes)
    
    $hasChanges = $Changes.Values | Where-Object { $_.Count -gt 0 } | Measure-Object | Select-Object -ExpandProperty Count
    
    if ($hasChanges -eq 0) {
        Write-Info "No changes detected since last run"
        return $false
    }
    
    Write-Section "Detected Changes"
    
    if ($Changes.Instructions.Count -gt 0) {
        Write-Warning "Instructions changed ($($Changes.Instructions.Count) file(s))"
        $Changes.Instructions | ForEach-Object { Write-Host "       - $_" -ForegroundColor DarkYellow }
    }
    
    if ($Changes.Agents.Count -gt 0) {
        Write-Warning "Agents changed ($($Changes.Agents.Count) file(s))"
        $Changes.Agents | ForEach-Object { Write-Host "       - $_" -ForegroundColor DarkYellow }
    }
    
    if ($Changes.Skills.Count -gt 0) {
        Write-Warning "Skills changed ($($Changes.Skills.Count) file(s))"
        $Changes.Skills | ForEach-Object { Write-Host "       - $_" -ForegroundColor DarkYellow }
    }
    
    if ($Changes.Memory.Count -gt 0) {
        Write-Warning "Memory changed ($($Changes.Memory.Count) file(s))"
        $Changes.Memory | ForEach-Object { Write-Host "       - $_" -ForegroundColor DarkYellow }
    }
    
    if ($Changes.Repos.Count -gt 0) {
        Write-Warning "Repository issues detected"
        $Changes.Repos | ForEach-Object { Write-Host "       - $_" -ForegroundColor DarkYellow }
    }
    
    return $true
}

function Get-WorkspaceRepos {
    Write-Info "Scanning for repositories..."
    $repos = @()
    
    Get-ChildItem -Path $WorkspaceRoot -Attributes Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $gitPath = Join-Path $_.FullName ".git"
        if (Test-Path $gitPath) {
            $repos += @{
                Name = $_.Name
                Path = $_.FullName
            }
        }
    }
    
    return $repos | Sort-Object Name
}

function Show-RepoSelector {
    Write-Title "SELECT REPOSITORY FOR SMART REFRESH"
    
    $repos = Get-WorkspaceRepos
    
    if ($repos.Count -eq 0) {
        Write-Error-Custom "No repositories found in workspace"
        return $null
    }
    
    Write-Host "Available repositories:" -ForegroundColor $Colors.Info
    Write-Host ""
    for ($i = 0; $i -lt $repos.Count; $i++) {
        Write-Host "   [$($i+1)] $($repos[$i].Name)" -ForegroundColor $Colors.Highlight
    }
    Write-Host "   [0] Cancel" -ForegroundColor $Colors.Highlight
    Write-Host ""
    
    do {
        $selection = Read-Host "Select repository"
        if ($selection -eq "0") { return $null }
        
        $index = [int]$selection - 1
        if ($index -ge 0 -and $index -lt $repos.Count) {
            return $repos[$index]
        }
        Write-Warning "Invalid selection"
    } while ($true)
}

function Invoke-SmartRefreshForRepo {
    param([string]$RepoPath)
    
    if (-not (Test-Path $RepoPath)) {
        Write-Error-Custom "Repository path not found: $RepoPath"
        return
    }
    
    Write-Title "SMART REFRESH - Repository: $(Split-Path -Leaf $RepoPath)"
    
    Push-Location $RepoPath
    try {
        $changes = Get-ChangedItems
        $hasChanges = Show-ChangeSummary -Changes $changes
        
        if (-not $hasChanges) {
            Write-Info "Nothing to do!"
            return
        }
        
        Write-Section "Running Recommended Actions"
        
        $recommended = Get-RecommendedActions -Changes $changes
        
        if ($recommended.Count -eq 0) {
            Write-Info "No actions needed"
            return
        }
        
        foreach ($action in $recommended) {
            $scriptPath = Join-Path $BinDir "$action.ps1"
            if (Test-Path $scriptPath) {
                Invoke-Script -ScriptPath $scriptPath -Description $action
            }
        }
        
        Write-Success "Smart refresh completed for repo!"
    }
    finally {
        Pop-Location
    }
}

function Get-SelectedRepo {
    $repos = Get-WorkspaceRepos
    
    if ($repos.Count -eq 0) {
        return $null
    }
    
    if ($repos.Count -eq 1 -and $repos[0].Name -eq ".copilot-shared") {
        return $null
    }
    
    Write-Host ""
    Write-Host "Run on which repository?" -ForegroundColor $Colors.Info
    Write-Host "   [W] Workspace (current default)" -ForegroundColor $Colors.Highlight
    
    $counter = 1
    $repoMap = @{}
    foreach ($repo in $repos) {
        if ($repo.Name -ne ".copilot-shared") {
            Write-Host "   [$counter] $($repo.Name)" -ForegroundColor $Colors.Highlight
            $repoMap[$counter.ToString()] = $repo
            $counter++
        }
    }
    Write-Host ""
    
    $selection = Read-Host "Select repository"
    
    if ($selection -eq "W" -or $selection -eq "") {
        return $null
    }
    
    return $repoMap[$selection]
}

function Invoke-ScriptOnRepo {
    param(
        [string]$ScriptPath,
        [string]$Description,
        [string[]]$Arguments = @(),
        [object]$Repo = $null
    )
    
    if ($Repo) {
        Write-Host "   [i] Running on repo: $($Repo.Name)" -ForegroundColor $Colors.Info
        Push-Location $Repo.Path
        try {
            Invoke-Script -ScriptPath $ScriptPath -Description $Description -Arguments $Arguments
        }
        finally {
            Pop-Location
        }
    }
    else {
        Invoke-Script -ScriptPath $ScriptPath -Description $Description -Arguments $Arguments
    }
}

function Handle-RepoAwareCommand {
    param(
        [string]$ScriptPath,
        [string]$Description,
        [string[]]$Arguments = @()
    )
    
    $repo = Get-SelectedRepo
    Invoke-ScriptOnRepo -ScriptPath $ScriptPath -Description $Description -Arguments $Arguments -Repo $repo
}

# ============================================================================
# MAIN MENU HELPERS
# ============================================================================

function Get-RecommendedActions {
    param([hashtable]$Changes)
    
    $recommended = @()
    
    if ($Changes.Instructions.Count -gt 0) {
        $recommended += @{
            Order = 1
            Name  = "full-context-refresh"
            Desc  = "Refresh context for instruction changes"
        }
    }
    
    if ($Changes.Agents.Count -gt 0) {
        $recommended += @{
            Order = 1
            Name  = "full-context-refresh"
            Desc  = "Refresh context for agent changes"
        }
    }
    
    if ($Changes.Skills.Count -gt 0) {
        $recommended += @{
            Order = 1
            Name  = "generate-skill-index"
            Desc  = "Index new skills"
        }
        $recommended += @{
            Order = 2
            Name  = "audit-copilot-assets"
            Desc  = "Audit skill configuration"
        }
        $recommended += @{
            Order = 3
            Name  = "full-context-refresh"
            Desc  = "Refresh context for skill changes"
        }
    }
    
    if ($Changes.Memory.Count -gt 0) {
        $recommended += @{
            Order = 1
            Name  = "verify-central-memory"
            Desc  = "Verify memory synchronization"
        }
    }
    
    if ($Changes.Repos.Count -gt 0) {
        $recommended += @{
            Order = 1
            Name  = "setup-repo"
            Desc  = "Setup repository wiring"
        }
    }
    
    # Remove duplicates and sort
    return $recommended | Sort-Object Order -Unique | Select-Object -ExpandProperty Name
}

# ============================================================================
# MAIN OPERATIONS
# ============================================================================

function Invoke-QuickRefresh {
    Write-Title "SMART REFRESH - Detecting Changes"
    
    $changes = Get-ChangedItems
    $hasChanges = Show-ChangeSummary -Changes $changes
    
    if (-not $hasChanges) {
        Write-Info "Nothing to do!"
        return
    }
    
    Write-Section "Running Recommended Actions"
    
    $recommended = Get-RecommendedActions -Changes $changes
    
    if ($recommended.Count -eq 0) {
        Write-Info "No actions needed"
        return
    }
    
    foreach ($action in $recommended) {
        $scriptPath = Join-Path $BinDir "$action.ps1"
        if (Test-Path $scriptPath) {
            Invoke-Script -ScriptPath $scriptPath -Description $action
        }
    }
    
    Write-Success "Smart refresh completed!"
}

function Show-MainMenu {
    Write-Title "COPILOT SHARED CONSOLE"
    Write-Host "   Workspace: $WorkspaceRoot" -ForegroundColor DarkGray
    Write-Host ""
    
    $menuOptions = @{
        "1" = "Smart Refresh (current workspace)"
        "R" = "Smart Refresh for Specific Repo"
        "2" = "Refresh Instructions (full-context-refresh)"
        "3" = "Refresh Agents (refresh-agents)"
        "4" = "Generate Skill Index"
        "5" = "Audit Copilot Assets"
        "6" = "Full Context Refresh (workspace + repo-mix)"
        "7" = "Memory Management"
        "8" = "Repository Setup"
        "9" = "Doctor (diagnosis and repair)"
        "A" = "Workspace Scan"
        "B" = "Token Profile (usage analysis)"
        "C" = "Git Hooks Setup"
        "D" = "Extract Support Bundle"
        "E" = "Local Setup"
    }
    
    Show-Menu -Options $menuOptions -Title "MAIN MENU"
}

function Show-MemoryMenu {
    $menuOptions = @{
        "1" = "Verify Central Memory"
        "2" = "Verify and Repair Central Memory"
        "3" = "Centralize Memory"
        "4" = "Export Memory"
        "5" = "Import Memory"
    }
    
    Show-Menu -Options $menuOptions -Title "MEMORY MANAGEMENT"
}

function Show-RepositoryMenu {
    $menuOptions = @{
        "1" = "Setup New Repository"
        "2" = "Setup All Repositories"
        "3" = "Link Repository to Copilot"
        "4" = "Link All Repositories"
        "5" = "Unlink Repository"
        "6" = "Copy Agents to Repository"
        "7" = "Repo Mix (context pack for one repo)"
        "8" = "Repo Mix All (context packs for all)"
    }
    
    Show-Menu -Options $menuOptions -Title "REPOSITORY SETUP"
}

# ============================================================================
# MENU HANDLERS
# ============================================================================

function Handle-MainMenu {
    param([string]$Choice)
    
    switch ($Choice) {
        "1" { Invoke-QuickRefresh }
        "R" {
            $repo = Show-RepoSelector
            if ($repo) {
                Invoke-SmartRefreshForRepo -RepoPath $repo.Path
            }
        }
        "2" { Handle-RepoAwareCommand -ScriptPath (Join-Path $BinDir "full-context-refresh.ps1") -Description "Full Context Refresh" }
        "3" { Handle-RepoAwareCommand -ScriptPath (Join-Path $BinDir "refresh-agents.cmd") -Description "Refresh Agents" }
        "4" { Handle-RepoAwareCommand -ScriptPath (Join-Path $BinDir "generate-skill-index.ps1") -Description "Generate Skill Index" }
        "5" { Handle-RepoAwareCommand -ScriptPath (Join-Path $BinDir "audit-copilot-assets.ps1") -Description "Audit Copilot Assets" }
        "6" {
            $fullDumps = Read-Host "Generate full content packs? (y/n, default n) "
            $args = @()
            if ($fullDumps -eq 'y') { $args += '-FullDumps' }
            Handle-RepoAwareCommand -ScriptPath (Join-Path $BinDir "full-context-refresh.ps1") -Description "Full Context Refresh" -Arguments $args
        }
        "7" { Handle-MemoryMenu }
        "8" { Handle-RepositoryMenu }
        "9" { Handle-RepoAwareCommand -ScriptPath (Join-Path $BinDir "doctor.ps1") -Description "Doctor (Diagnosis and Repair)" }
        "A" { Handle-RepoAwareCommand -ScriptPath (Join-Path $BinDir "workspace-scan.ps1") -Description "Workspace Scan" }
        "B" { Invoke-Script -ScriptPath (Join-Path $BinDir "token-profile.ps1") -Description "Token Profile" }
        "C" { Invoke-Script -ScriptPath (Join-Path $BinDir "install-hooks.cmd") -Description "Git Hooks Setup" }
        "D" { Invoke-Script -ScriptPath (Join-Path $BinDir "extract-support-bundle.ps1") -Description "Extract Support Bundle" }
        "E" { Invoke-Script -ScriptPath (Join-Path $BinDir "setup-local.ps1") -Description "Local Setup" }
        "0" { return $false }
        default {
            Write-Warning "Invalid option: $Choice"
            return $true
        }
    }
    
    return $true
}

function Handle-MemoryMenu {
    do {
        Show-MemoryMenu
        $choice = Read-Host "Choose action"
        
        switch ($choice) {
            "1" { Handle-RepoAwareCommand -ScriptPath (Join-Path $BinDir "verify-central-memory.ps1") -Description "Verify Central Memory" }
            "2" { Handle-RepoAwareCommand -ScriptPath (Join-Path $BinDir "verify-central-memory.ps1") -Description "Verify and Repair Central Memory" -Arguments @('-Repair') }
            "3" { Handle-RepoAwareCommand -ScriptPath (Join-Path $BinDir "centralize-memory.ps1") -Description "Centralize Memory" }
            "4" { Handle-RepoAwareCommand -ScriptPath (Join-Path $BinDir "export-memory.ps1") -Description "Export Memory" }
            "5" { Handle-RepoAwareCommand -ScriptPath (Join-Path $BinDir "import-memory.ps1") -Description "Import Memory" }
            "0" { break }
            default { Write-Warning "Invalid option: $choice" }
        }
    } while ($true)
}

function Handle-RepositoryMenu {
    do {
        Show-RepositoryMenu
        $choice = Read-Host "Choose action"
        
        switch ($choice) {
            "1" {
                $repoPath = Read-Host "Enter repository path"
                Invoke-Script -ScriptPath (Join-Path $BinDir "setup-repo.ps1") -Description "Setup Repository" -Arguments @($repoPath)
            }
            "2" { Invoke-Script -ScriptPath (Join-Path $BinDir "setup-all-repos.ps1") -Description "Setup All Repositories" }
            "3" {
                $repoPath = Read-Host "Enter repository path"
                Invoke-Script -ScriptPath (Join-Path $BinDir "link-copilot.cmd") -Description "Link Repository" -Arguments @($repoPath)
            }
            "4" { Invoke-Script -ScriptPath (Join-Path $BinDir "link-all-copilot.cmd") -Description "Link All Repositories" }
            "5" {
                $repoPath = Read-Host "Enter repository path"
                Invoke-Script -ScriptPath (Join-Path $BinDir "unlink-copilot.cmd") -Description "Unlink Repository" -Arguments @($repoPath)
            }
            "6" {
                $repoPath = Read-Host "Enter repository path"
                Invoke-Script -ScriptPath (Join-Path $BinDir "copy-agents.cmd") -Description "Copy Agents to Repository" -Arguments @($repoPath)
            }
            "7" {
                $repoPath = Read-Host "Enter repository path (relative to workspace)"
                Invoke-Script -ScriptPath (Join-Path $BinDir "repo-mix.ps1") -Description "Repo Mix" -Arguments @('-Repo', $repoPath)
            }
            "8" {
                $fullDumps = Read-Host "Generate full content packs? (y/n, default n) "
                $args = @()
                if ($fullDumps -eq 'y') { $args += '-FullDumps' }
                Invoke-Script -ScriptPath (Join-Path $BinDir "repo-mix-all.ps1") -Description "Repo Mix All" -Arguments $args
            }
            "0" { break }
            default { Write-Warning "Invalid option: $choice" }
        }
    } while ($true)
}

# ============================================================================
# MAIN LOOP
# ============================================================================

function Start-Console {
    if ($Quick) {
        Invoke-QuickRefresh
        return
    }
    
    do {
        Show-MainMenu
        $choice = Read-Host "Enter your choice"
        $continue = Handle-MainMenu -Choice $choice
    } while ($continue)
    
    Write-Title "Goodbye!"
    Write-Success "Session completed"
}

# ============================================================================
# ENTRY POINT
# ============================================================================

try {
    Start-Console
}
catch {
    Write-Error-Custom "Fatal error: $_"
    exit 1
}
