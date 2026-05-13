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

param(
    [ArgumentCompleter({
        param($wordToComplete, $commandAst, $cursorPosition)
        try {
            # Get the script path from the command being completed
            $scriptPath = $commandAst.CommandElements[0].Value
            if (-not [System.IO.Path]::IsPathRooted($scriptPath)) {
                $scriptPath = Join-Path (Get-Location) $scriptPath
            }
            $scriptPath = Resolve-Path $scriptPath -ErrorAction SilentlyContinue
            $scriptDir = Split-Path $scriptPath -Parent
            $parent = Split-Path $scriptDir -Parent
            
            Get-ChildItem -Path $parent -Directory -ErrorAction SilentlyContinue | 
                Where-Object { Test-Path (Join-Path $_.FullName '.git') } | 
                Select-Object -ExpandProperty Name | 
                Where-Object { $_ -like "$wordToComplete*" } | 
                ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
                }
        } catch { }
    })]
    [string]$Workspace,
    [switch]$Quick
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$BinDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SharedRoot = Split-Path -Parent $BinDir
$WorkspaceRoot = if ($Workspace) { $Workspace } else { Split-Path -Parent $SharedRoot }

# ============================================================================
# INTERACTIVE INPUT WITH TAB COMPLETION
# ============================================================================

function Read-WithCompletion {
    <#
    .SYNOPSIS
        Read user input with real Tab key completion from a list of options.
    #>
    param(
        [string]$Prompt,
        [string[]]$Options = @(),
        [string]$Default = ''
    )

    $promptText = if ($Default) { "$Prompt (default: $Default)" } else { $Prompt }
    Write-Host -NoNewline "$promptText`: " -ForegroundColor White

    $buffer = ''
    $tabIndex = -1
    $tabMatches = @()

    while ($true) {
        $key = [System.Console]::ReadKey($true)

        if ($key.Key -eq [System.ConsoleKey]::Enter) {
            Write-Host ''
            break
        }
        elseif ($key.Key -eq [System.ConsoleKey]::Tab) {
            if ($Options.Count -eq 0) { continue }

            if ($tabIndex -eq -1) {
                # First Tab press - find matches
                $tabMatches = @($Options | Where-Object { $_ -like "$buffer*" })
                if ($tabMatches.Count -eq 0) { continue }
                $tabIndex = 0
            } else {
                # Cycle through matches
                $tabIndex = ($tabIndex + 1) % $tabMatches.Count
            }

            # Replace current buffer with match
            $clear = "`b" * $buffer.Length + ' ' * $buffer.Length + "`b" * $buffer.Length
            Write-Host -NoNewline $clear
            $buffer = $tabMatches[$tabIndex]
            Write-Host -NoNewline $buffer

            # Show hint if multiple matches
            if ($tabMatches.Count -gt 1) {
                $pos = [System.Console]::CursorLeft
                Write-Host -NoNewline "  [Tab: $($tabIndex+1)/$($tabMatches.Count)]" -ForegroundColor DarkGray
                $extra = "  [Tab: $($tabIndex+1)/$($tabMatches.Count)]".Length
                Write-Host -NoNewline ("`b" * $extra + ' ' * $extra + "`b" * $extra)
            }
        }
        elseif ($key.Key -eq [System.ConsoleKey]::Backspace) {
            if ($buffer.Length -gt 0) {
                $buffer = $buffer.Substring(0, $buffer.Length - 1)
                Write-Host -NoNewline "`b `b"
                $tabIndex = -1
                $tabMatches = @()
            }
        }
        elseif ($key.Key -eq [System.ConsoleKey]::Escape) {
            # Clear buffer
            $clear = "`b" * $buffer.Length + ' ' * $buffer.Length + "`b" * $buffer.Length
            Write-Host -NoNewline $clear
            $buffer = ''
            $tabIndex = -1
            $tabMatches = @()
        }
        else {
            $ch = $key.KeyChar
            if ([char]::IsControl($ch)) { continue }
            $buffer += $ch
            Write-Host -NoNewline $ch
            $tabIndex = -1
            $tabMatches = @()
        }
    }

    if ([string]::IsNullOrWhiteSpace($buffer) -and $Default) {
        return $Default
    }
    return $buffer
}

function Read-RepositoryName {
    $repos = @(Get-WorkspaceRepos | Select-Object -ExpandProperty Name | Where-Object { $_ -ne ".copilot-shared" })
    if ($repos.Count -eq 0) { Write-Error-Custom "No repositories found"; return $null }

    Write-Host "   Available: $($repos -join ', ')" -ForegroundColor DarkGray
    Write-Host "   Press Tab to cycle through completions, Enter to confirm" -ForegroundColor DarkCyan
    Write-Host ''

    $input = Read-WithCompletion -Prompt "Repository name" -Options $repos
    if ([string]::IsNullOrWhiteSpace($input)) { return $null }

    $matched = @($repos | Where-Object { $_ -eq $input })
    if ($matched.Count -eq 0) { $matched = @($repos | Where-Object { $_ -like "$input*" }) }
    if ($matched.Count -eq 0) { Write-Warning "Repository not found: $input"; return $null }
    if ($matched.Count -gt 1) {
        Write-Warning "Multiple matches. Please be more specific:"
        $matched | ForEach-Object { Write-Host "   - $_" -ForegroundColor Yellow }
        return $null
    }
    return $matched[0]
}

function Read-PathWithCompletion {
    param([string]$Prompt = "Enter path", [string]$Filter = "*")
    $suggestions = @(Get-ChildItem -Path '.' -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
    Write-Host "   Press Tab to cycle through path completions" -ForegroundColor DarkCyan
    return Read-WithCompletion -Prompt $Prompt -Options $suggestions
}

function Read-ArchiveFile {
    $archives = @(Get-ChildItem -Path '.' -Filter '*.zip' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
    if ($archives.Count -gt 0) {
        Write-Host "   Available archives: $($archives -join ', ')" -ForegroundColor DarkGray
    }
    Write-Host "   Press Tab to cycle through archive files" -ForegroundColor DarkCyan
    Write-Host ''
    $input = Read-WithCompletion -Prompt "Archive path" -Options $archives
    if ([string]::IsNullOrWhiteSpace($input)) { return $null }
    return $input
}

function Read-OutputDirectory {
    $suggestions = @('.', $env:TEMP, (Get-Location).Path)
    Write-Host "   Common locations: $($suggestions -join ', ')" -ForegroundColor DarkGray
    Write-Host "   Press Tab to cycle through suggestions" -ForegroundColor DarkCyan
    Write-Host ''
    $input = Read-WithCompletion -Prompt "Output directory" -Options $suggestions -Default '.'
    if ([string]::IsNullOrWhiteSpace($input)) { return '.' }
    return $input
}

function Read-MenuChoice {
    param([string]$Prompt = "Enter your choice", [string[]]$ValidOptions = @())
    Write-Host ''
    if ($ValidOptions.Count -gt 0) {
        Write-Host "   Valid options: $($ValidOptions -join ', ')" -ForegroundColor DarkGray
        Write-Host "   Press Tab to cycle, Enter to confirm" -ForegroundColor DarkCyan
    }
    return Read-WithCompletion -Prompt $Prompt -Options $ValidOptions
}

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
    $linkedRepos = @(Get-ChildItem -Path $WorkspaceRoot -Directory -ErrorAction SilentlyContinue | Where-Object { 
        (Test-Path "$($_.FullName)\.github\copilot-instructions.md") 
    })
    
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
        Write-Host "   $($repos[$i].Name)" -ForegroundColor $Colors.Highlight
    }
    Write-Host ""
    Write-Host "   Enter the repository name. Press Tab to cycle through completions." -ForegroundColor DarkCyan
    Write-Host ''
    
    $repoName = Read-WithCompletion -Prompt "Repository name (empty to cancel)" -Options ($repos | Select-Object -ExpandProperty Name)
    
    if ([string]::IsNullOrWhiteSpace($repoName)) {
        return $null
    }
    
    # Match repo (force array to avoid single-object Count issues)
    $matched = @($repos | Where-Object { $_.Name -eq $repoName })
    
    if ($matched.Count -eq 0) {
        # Try prefix matching
        $matched = @($repos | Where-Object { $_.Name -like "$repoName*" })
    }
    
    if ($matched.Count -eq 0) {
        Write-Warning "Repository not found: $repoName"
        return $null
    }
    
    if ($matched.Count -gt 1) {
        Write-Warning "Multiple matches. Please be more specific:"
        $matched | Select-Object -ExpandProperty Name | ForEach-Object { Write-Host "   - $_" -ForegroundColor Yellow }
        return $null
    }
    
    return $matched[0]
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
    Write-Host "   W = Workspace (current default)" -ForegroundColor $Colors.Highlight
    Write-Host ""
    Write-Host "Available repositories:" -ForegroundColor $Colors.Info
    
    $counter = 1
    $repoMap = @{}
    foreach ($repo in $repos) {
        if ($repo.Name -ne ".copilot-shared") {
            Write-Host "   $($repo.Name)" -ForegroundColor $Colors.Highlight
            $repoMap[$repo.Name] = $repo
            $counter++
        }
    }
    
    Write-Host ""
    Write-Host "   Enter the repository name. Press Tab to cycle, Enter for workspace." -ForegroundColor DarkCyan
    Write-Host ''
    
    $repoOptions = @('W') + @($repoMap.Keys)
    $selection = Read-WithCompletion -Prompt "Repository (Enter for Workspace)" -Options $repoOptions
    
    if ($selection -eq "W" -or $selection -eq "w" -or [string]::IsNullOrWhiteSpace($selection)) {
        return $null
    }
    
    # Try exact match first
    if ($repoMap.ContainsKey($selection)) {
        return $repoMap[$selection]
    }
    
    # Try prefix match (force array to avoid single-object Count issues)
    $matches = @($repoMap.Keys | Where-Object { $_ -like "$selection*" })
    if ($matches.Count -eq 1) {
        return $repoMap[$matches[0]]
    }
    
    if ($matches.Count -gt 1) {
        Write-Warning "Multiple matches: $($matches -join ', ')"
        return $null
    }
    
    Write-Warning "Repository not found: $selection"
    return $null
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
    Write-Host "   💡 Tip: When prompted for repository names or paths, press Tab for completion!" -ForegroundColor DarkCyan
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
        "H" = "Help (command reference)"
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
        "H" = "Help"
    }
    
    Write-Host ""
    Write-Host "   💡 Tip: When prompted for paths/archives, press Tab for completion!" -ForegroundColor DarkCyan
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
        "H" = "Help"
    }
    
    Write-Host ""
    Write-Host "   💡 Tip: When prompted for paths, press Tab for completion!" -ForegroundColor DarkCyan
    Show-Menu -Options $menuOptions -Title "REPOSITORY SETUP"
}

# ============================================================================
# PAUSE & CONTINUE
# ============================================================================

function Wait-ForMenuReturn {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host "  [R] Return to menu    [Q] Quit console" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    
    $choice = Read-WithCompletion -Prompt "Choose action" -Options @('R', 'Q')
    
    if ($choice -eq 'Q' -or $choice -eq 'q') {
        return 'quit'
    }
    return 'continue'
}

function Wait-ForSubmenuReturn {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host "  [C] Continue in submenu    [B] Back to main menu    [Q] Quit" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    
    $choice = Read-WithCompletion -Prompt "Choose action" -Options @('C', 'B', 'Q')
    
    return ($choice[0]).ToUpper()
}

# ============================================================================
# MENU HANDLERS
# ============================================================================

function Handle-MainMenu {
    param([string]$Choice)
    
    $commandExecuted = $false
    
    switch ($Choice) {
        "1" { Invoke-QuickRefresh; $commandExecuted = $true }
        "R" {
            $repo = Show-RepoSelector
            if ($repo) {
                Invoke-SmartRefreshForRepo -RepoPath $repo.Path
                $commandExecuted = $true
            }
        }
        "2" { Handle-RepoAwareCommand -ScriptPath (Join-Path $BinDir "full-context-refresh.ps1") -Description "Full Context Refresh"; $commandExecuted = $true }
        "3" { Handle-RepoAwareCommand -ScriptPath (Join-Path $BinDir "refresh-agents.cmd") -Description "Refresh Agents"; $commandExecuted = $true }
        "4" { Handle-RepoAwareCommand -ScriptPath (Join-Path $BinDir "generate-skill-index.ps1") -Description "Generate Skill Index"; $commandExecuted = $true }
        "5" { Handle-RepoAwareCommand -ScriptPath (Join-Path $BinDir "audit-copilot-assets.ps1") -Description "Audit Copilot Assets"; $commandExecuted = $true }
        "6" {
            Write-Host "   Tip: Type 'y' or 'n'" -ForegroundColor DarkCyan
            $fullDumps = Read-Host "Generate full content packs? (y/n, default n) "
            $args = @()
            if ($fullDumps -eq 'y' -or $fullDumps -eq 'Y') { $args += '-FullDumps' }
            Handle-RepoAwareCommand -ScriptPath (Join-Path $BinDir "full-context-refresh.ps1") -Description "Full Context Refresh" -Arguments $args
            $commandExecuted = $true
        }
        "7" { Handle-MemoryMenu; $commandExecuted = $true }
        "8" { Handle-RepositoryMenu; $commandExecuted = $true }
        "9" { Handle-RepoAwareCommand -ScriptPath (Join-Path $BinDir "doctor.ps1") -Description "Doctor (Diagnosis and Repair)"; $commandExecuted = $true }
        "A" { Handle-RepoAwareCommand -ScriptPath (Join-Path $BinDir "workspace-scan.ps1") -Description "Workspace Scan"; $commandExecuted = $true }
        "B" { Invoke-Script -ScriptPath (Join-Path $BinDir "token-profile.ps1") -Description "Token Profile"; $commandExecuted = $true }
        "C" { Invoke-Script -ScriptPath (Join-Path $BinDir "install-hooks.cmd") -Description "Git Hooks Setup"; $commandExecuted = $true }
        "D" { Invoke-Script -ScriptPath (Join-Path $BinDir "extract-support-bundle.ps1") -Description "Extract Support Bundle"; $commandExecuted = $true }
        "E" { Invoke-Script -ScriptPath (Join-Path $BinDir "setup-local.ps1") -Description "Local Setup"; $commandExecuted = $true }
        "H" { Show-HelpMainMenu }
        "0" { return $false }
        default {
            Write-Warning "Invalid option: $Choice"
            return $true
        }
    }
    
    # After command finishes, ask user to return or quit (skip for Help)
    if ($commandExecuted) {
        $action = Wait-ForMenuReturn
        if ($action -eq 'quit') {
            return $false
        }
    }
    
    return $true
}

function Handle-MemoryMenu {
    $running = $true
    $backToMain = $false
    
    do {
        Show-MemoryMenu
        $choice = Read-MenuChoice -Prompt "Choose action" -ValidOptions @("1", "2", "3", "4", "5", "H", "0")
        
        $commandExecuted = $false
        
        switch ($choice) {
            "1" { Handle-RepoAwareCommand -ScriptPath (Join-Path $BinDir "verify-central-memory.ps1") -Description "Verify Central Memory"; $commandExecuted = $true }
            "2" { Handle-RepoAwareCommand -ScriptPath (Join-Path $BinDir "verify-central-memory.ps1") -Description "Verify and Repair Central Memory" -Arguments @('-Repair'); $commandExecuted = $true }
            "3" { Handle-RepoAwareCommand -ScriptPath (Join-Path $BinDir "centralize-memory.ps1") -Description "Centralize Memory"; $commandExecuted = $true }
            "4" {
                $outDir = Read-OutputDirectory
                if ($outDir) {
                    Handle-RepoAwareCommand -ScriptPath (Join-Path $BinDir "export-memory.ps1") -Description "Export Memory" -Arguments @('-OutputDir', $outDir)
                    $commandExecuted = $true
                }
            }
            "5" {
                $archivePath = Read-ArchiveFile
                if ($archivePath) {
                    Handle-RepoAwareCommand -ScriptPath (Join-Path $BinDir "import-memory.ps1") -Description "Import Memory" -Arguments @('-ArchivePath', $archivePath)
                    $commandExecuted = $true
                }
            }
            "H" { Show-HelpMemory }
            "0" { $running = $false }
            default { Write-Warning "Invalid option: $choice" }
        }
        
        if ($commandExecuted) {
            $action = Wait-ForSubmenuReturn
            if ($action -eq 'B') {
                $running = $false
            }
            elseif ($action -eq 'Q') {
                $running = $false
                $backToMain = $false
                exit 0
            }
        }
    } while ($running)
}

function Handle-RepositoryMenu {
    $running = $true
    do {
        Show-RepositoryMenu
        $choice = Read-MenuChoice -Prompt "Choose action" -ValidOptions @("1", "2", "3", "4", "5", "6", "7", "8", "H", "0")
        
        $commandExecuted = $false
        
        switch ($choice) {
            "1" {
                $repoPath = Read-PathWithCompletion "Enter repository path"
                if ($repoPath) {
                    Invoke-Script -ScriptPath (Join-Path $BinDir "setup-repo.ps1") -Description "Setup Repository" -Arguments @($repoPath)
                    $commandExecuted = $true
                }
            }
            "2" { Invoke-Script -ScriptPath (Join-Path $BinDir "setup-all-repos.ps1") -Description "Setup All Repositories"; $commandExecuted = $true }
            "3" {
                $repoPath = Read-PathWithCompletion "Enter repository path"
                if ($repoPath) {
                    Invoke-Script -ScriptPath (Join-Path $BinDir "link-copilot.cmd") -Description "Link Repository" -Arguments @($repoPath)
                    $commandExecuted = $true
                }
            }
            "4" { Invoke-Script -ScriptPath (Join-Path $BinDir "link-all-copilot.cmd") -Description "Link All Repositories"; $commandExecuted = $true }
            "5" {
                $repoPath = Read-PathWithCompletion "Enter repository path"
                if ($repoPath) {
                    Invoke-Script -ScriptPath (Join-Path $BinDir "unlink-copilot.cmd") -Description "Unlink Repository" -Arguments @($repoPath)
                    $commandExecuted = $true
                }
            }
            "6" {
                $repoPath = Read-PathWithCompletion "Enter repository path"
                if ($repoPath) {
                    Invoke-Script -ScriptPath (Join-Path $BinDir "copy-agents.cmd") -Description "Copy Agents to Repository" -Arguments @($repoPath)
                    $commandExecuted = $true
                }
            }
            "7" {
                $repoPath = Read-PathWithCompletion "Enter repository path (relative to workspace)"
                if ($repoPath) {
                    Invoke-Script -ScriptPath (Join-Path $BinDir "repo-mix.ps1") -Description "Repo Mix" -Arguments @('-RepoPath', $repoPath)
                    $commandExecuted = $true
                }
            }
            "8" {
                Write-Host "   Tip: Type 'y' or 'n'" -ForegroundColor DarkCyan
                $fullDumps = Read-Host "Generate full content packs? (y/n, default n) "
                $args = @()
                if ($fullDumps -eq 'y' -or $fullDumps -eq 'Y') { $args += '-FullDumps' }
                Invoke-Script -ScriptPath (Join-Path $BinDir "repo-mix-all.ps1") -Description "Repo Mix All" -Arguments $args
                $commandExecuted = $true
            }
            "H" { Show-HelpRepository }
            "0" { $running = $false }
            default { Write-Warning "Invalid option: $choice" }
        }
        
        if ($commandExecuted) {
            $action = Wait-ForSubmenuReturn
            if ($action -eq 'B') {
                $running = $false
            }
            elseif ($action -eq 'Q') {
                $running = $false
                exit 0
            }
        }
    } while ($running)
}

function Show-HelpMainMenu {
    Write-Title "HELP: MAIN MENU COMMANDS"
    Write-Host ""
    Write-Host "REFRESH OPERATIONS" -ForegroundColor Cyan
    Write-Host "  [1] Smart Refresh (current workspace)" -ForegroundColor White
    Write-Host "      Analyzes the workspace for changes and runs recommended fixes automatically." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [R] Smart Refresh for Specific Repo" -ForegroundColor White
    Write-Host "      Select a repo and run smart refresh targeting that repo only." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [2] Refresh Instructions" -ForegroundColor White
    Write-Host "      Rebuilds instruction files from templates. Use when agent instructions change." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [3] Refresh Agents" -ForegroundColor White
    Write-Host "      Updates agent templates in repos. Use after modifying shared agent templates." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [4] Generate Skill Index" -ForegroundColor White
    Write-Host "      Generates an index of all available skills for quick reference." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [6] Full Context Refresh (workspace + repo-mix)" -ForegroundColor White
    Write-Host "      Comprehensive refresh: rescans architecture, regenerates all repo context packs." -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Host "SETUP & CONFIGURATION" -ForegroundColor Cyan
    Write-Host "  [5] Audit Copilot Assets" -ForegroundColor White
    Write-Host "      Scans all repos for Copilot configuration issues. Generates audit report." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [7] Memory Management" -ForegroundColor White
    Write-Host "      Central hub for memory operations: verify, centralize, export, import." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [8] Repository Setup" -ForegroundColor White
    Write-Host "      Setup repos, link/unlink to Copilot, copy agents, generate context packs." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [9] Doctor (diagnosis and repair)" -ForegroundColor White
    Write-Host "      Health check: validates junctions, gitignore, hooks, repo-cache. Finds & fixes issues." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [E] Local Setup" -ForegroundColor White
    Write-Host "      One-time: personalizes .copilot-shared after cloning (Bitbucket config, local instructions)." -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Host "ANALYSIS & MONITORING" -ForegroundColor Cyan
    Write-Host "  [A] Workspace Scan" -ForegroundColor White
    Write-Host "      Generates architecture map: tech stacks, service ports, APIs, inter-service dependencies." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [B] Token Profile (usage analysis)" -ForegroundColor White
    Write-Host "      Switches between token usage profiles (balanced vs aggressive) for cost control." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [C] Git Hooks Setup" -ForegroundColor White
    Write-Host "      Installs pre-commit and commit-msg hooks for automated quality checks." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [D] Extract Support Bundle" -ForegroundColor White
    Write-Host "      Extracts RCA-critical files from DefenseFlow/Vision support bundles for analysis." -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

function Show-HelpMemory {
    Write-Title "HELP: MEMORY MANAGEMENT COMMANDS"
    Write-Host ""
    Write-Host "CORE OPERATIONS" -ForegroundColor Cyan
    Write-Host "  [1] Verify Central Memory" -ForegroundColor White
    Write-Host "      Checks all repos for proper central memory configuration." -ForegroundColor DarkGray
    Write-Host "      Verifies junctions exist and point to correct central locations." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [2] Verify and Repair Central Memory" -ForegroundColor White
    Write-Host "      Like [1] but also auto-fixes issues found (re-creates junctions, repairs symlinks)." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [3] Centralize Memory" -ForegroundColor White
    Write-Host "      Migrates memory/learning/cases from individual repos to central location." -ForegroundColor DarkGray
    Write-Host "      Creates symlinks in repos pointing back to central store." -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Host "BACKUP & RESTORE" -ForegroundColor Cyan
    Write-Host "  [4] Export Memory" -ForegroundColor White
    Write-Host "      Backs up all central memory files to a timestamped ZIP archive." -ForegroundColor DarkGray
    Write-Host "      Use for sharing memory with teammates or as a safety net." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [5] Import Memory" -ForegroundColor White
    Write-Host "      Restores memory from a previously exported ZIP archive." -ForegroundColor DarkGray
    Write-Host "      Useful for syncing memory across team members or machines." -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

function Show-HelpRepository {
    Write-Title "HELP: REPOSITORY SETUP COMMANDS"
    Write-Host ""
    Write-Host "INITIAL SETUP" -ForegroundColor Cyan
    Write-Host "  [1] Setup New Repository" -ForegroundColor White
    Write-Host "      One-time: creates .github/ structure, writes copilot-instructions.md, copies agents." -ForegroundColor DarkGray
    Write-Host "      Run once per repo after linking to .copilot-shared." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [2] Setup All Repositories" -ForegroundColor White
    Write-Host "      Runs setup on every repo in workspace that lacks copilot-instructions.md." -ForegroundColor DarkGray
    Write-Host "      Batch operation for fresh workspace setup." -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Host "LINKING & CONFIGURATION" -ForegroundColor Cyan
    Write-Host "  [3] Link Repository to Copilot" -ForegroundColor White
    Write-Host "      Creates junctions from repo to shared skills, instructions, prompts, plans." -ForegroundColor DarkGray
    Write-Host "      Enables Copilot to access workspace-wide resources." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [4] Link All Repositories" -ForegroundColor White
    Write-Host "      Links every repo in workspace to Copilot (batch operation)." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [5] Unlink Repository" -ForegroundColor White
    Write-Host "      Removes junctions: repo becomes standalone, doesn't access shared resources." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [6] Copy Agents to Repository" -ForegroundColor White
    Write-Host "      Copies latest agent templates to a repo's .github/agents/ directory." -ForegroundColor DarkGray
    Write-Host "      Use to refresh agents or onboard a new repo." -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Host "CONTEXT & ANALYSIS" -ForegroundColor Cyan
    Write-Host "  [7] Repo Mix (context pack for one repo)" -ForegroundColor White
    Write-Host "      Generates a single markdown file bundling repo structure + file contents." -ForegroundColor DarkGray
    Write-Host "      Use for sharing repo context or feeding into external analysis." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [8] Repo Mix All (context packs for all)" -ForegroundColor White
    Write-Host "      Generates context packs for every repo in workspace, stores in shared/memory/repo-contexts/." -ForegroundColor DarkGray
    Write-Host "      Weekly refresh recommended for keeping AI context up-to-date." -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}



function Start-Console {
    if ($Quick) {
        Invoke-QuickRefresh
        return
    }
    
    do {
        Show-MainMenu
        $validOptions = @("1", "R", "r", "2", "3", "4", "5", "6", "7", "8", "9", "A", "a", "B", "b", "C", "c", "D", "d", "E", "e", "0")
        $choice = Read-MenuChoice -Prompt "Enter your choice" -ValidOptions $validOptions
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
