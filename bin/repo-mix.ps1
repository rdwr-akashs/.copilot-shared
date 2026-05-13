<#
.SYNOPSIS
    Creates a Repomix-style single markdown context file from a repository.

.DESCRIPTION
    Builds an AI-friendly bundle with:
      1) Repository metadata
      2) Directory tree (limited depth)
      3) File index
      4) File contents for selected text files

    By default, when inside a git repo it uses `git ls-files` so ignored files are
    skipped automatically. Binary files and files above the size limit are skipped.

.EXAMPLE
    powershell -File bin\repo-mix.ps1 -RepoPath C:\rdwr-intelij\.copilot-shared

.EXAMPLE
    powershell -File bin\repo-mix.ps1 -RepoPath . -OutputFile .agent_work\mix.md -MaxFiles 300 -WithLineNumbers
#>

[CmdletBinding()]
param(
    [ArgumentCompleter({
        param($wordToComplete, $commandAst, $cursorPosition)
        @('.', (Get-Location).Path) | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', 'Repository path')
        }
    })]
    [string]$RepoPath = (Get-Location).Path,
    [ArgumentCompleter({
        param($wordToComplete, $commandAst, $cursorPosition)
        @('.agent_work', (Get-Location).Path) | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', 'Output directory')
        }
    })]
    [string]$OutputFile,
    [int]$MaxFiles = 500,
    [int]$MaxFileSizeKB = 256,
    [int]$TreeDepth = 4,
    [switch]$WithLineNumbers,
    [switch]$UseAllFiles,
    [switch]$Central,
    [switch]$SummaryOnly,
    [string[]]$ExcludeDirs = @(
        '.git', 'node_modules', 'dist', 'build', 'out', '.next', '.nuxt',
        '.venv', 'venv', '__pycache__', 'target', 'coverage', '.idea', '.vscode'
    ),
    [string[]]$ExcludeExtensions = @(
        '.png', '.jpg', '.jpeg', '.gif', '.webp', '.ico', '.pdf',
        '.zip', '.tar', '.gz', '.7z', '.rar', '.jar', '.war', '.class',
        '.exe', '.dll', '.so', '.dylib', '.bin', '.woff', '.woff2', '.ttf', '.eot',
        '.mp3', '.wav', '.mp4', '.avi', '.mov', '.parquet', '.feather'
    )
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-AbsPath {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Path not found: $Path"
    }
    return (Resolve-Path -LiteralPath $Path).Path
}

function Test-IsGitRepo {
    param([Parameter(Mandatory)][string]$Root)
    try {
        $null = git -C $Root rev-parse --is-inside-work-tree 2>$null
        return ($LASTEXITCODE -eq 0)
    }
    catch {
        return $false
    }
}

function Get-RepoName {
    param([Parameter(Mandatory)][string]$Root)
    return (Split-Path -Path $Root -Leaf)
}

function New-DefaultOutputPath {
    param([Parameter(Mandatory)][string]$Root, [bool]$UseCentral = $false, [bool]$IsSummary = $false)
    $repoName = Get-RepoName -Root $Root

    if ($UseCentral) {
        # Summaries → repo-contexts/<repo>.md  (small, used by agents by default)
        # Full dumps → repo-contexts/full/<repo>.md  (large, only for deep dives)
        $binDir = Split-Path -Parent $MyInvocation.ScriptName
        $sharedRoot = Split-Path -Parent $binDir
        $centralDir = if ($IsSummary) {
            Join-Path $sharedRoot 'shared\memory\repo-contexts'
        } else {
            Join-Path $sharedRoot 'shared\memory\repo-contexts\full'
        }
        if (-not (Test-Path -LiteralPath $centralDir)) {
            New-Item -ItemType Directory -Path $centralDir -Force | Out-Null
        }
        return (Join-Path $centralDir "$repoName.md")
    }

    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $outDir = Join-Path $Root '.agent_work'
    if (-not (Test-Path -LiteralPath $outDir)) {
        New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    }
    return (Join-Path $outDir ("repo-mix-$repoName-$stamp.md"))
}

function Test-ExcludedPath {
    param(
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][string[]]$Dirs
    )

    $normalized = $RelativePath.Replace('\\', '/').TrimStart('./')
    $parts = $normalized.Split('/')
    foreach ($p in $parts) {
        if ($Dirs -contains $p) {
            return $true
        }
    }
    return $false
}

function Get-CandidateFiles {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][bool]$UseGit,
        [Parameter(Mandatory)][string[]]$Dirs,
        [Parameter(Mandatory)][string[]]$Exts
    )

    $results = @()

    if ($UseGit) {
        $gitFiles = git -C $Root ls-files
        foreach ($rel in $gitFiles) {
            if ([string]::IsNullOrWhiteSpace($rel)) { continue }
            if (Test-ExcludedPath -RelativePath $rel -Dirs $Dirs) { continue }

            $ext = [System.IO.Path]::GetExtension($rel)
            if ($Exts -contains $ext.ToLowerInvariant()) { continue }

            $abs = Join-Path $Root $rel
            if (-not (Test-Path -LiteralPath $abs)) { continue }

            $item = Get-Item -LiteralPath $abs
            if ($item.PSIsContainer) { continue }

            $results += [PSCustomObject]@{
                RelativePath = $rel.Replace('\\', '/')
                AbsolutePath = $abs
                SizeBytes    = $item.Length
            }
        }
    }
    else {
        $all = Get-ChildItem -LiteralPath $Root -Recurse -File
        foreach ($item in $all) {
            $rel = $item.FullName.Substring($Root.Length).TrimStart('\\','/').Replace('\\','/')
            if (Test-ExcludedPath -RelativePath $rel -Dirs $Dirs) { continue }

            $ext = [System.IO.Path]::GetExtension($item.FullName)
            if ($Exts -contains $ext.ToLowerInvariant()) { continue }

            $results += [PSCustomObject]@{
                RelativePath = $rel
                AbsolutePath = $item.FullName
                SizeBytes    = $item.Length
            }
        }
    }

    return ($results | Sort-Object RelativePath)
}

function Test-IsProbablyBinary {
    param([Parameter(Mandatory)][string]$FilePath)

    $stream = $null
    try {
        $stream = [System.IO.File]::OpenRead($FilePath)
        $length = [Math]::Min(4096, [int]$stream.Length)
        if ($length -le 0) { return $false }

        $buffer = New-Object byte[] $length
        $null = $stream.Read($buffer, 0, $length)

        for ($i = 0; $i -lt $length; $i++) {
            if ($buffer[$i] -eq 0) {
                return $true
            }
        }

        return $false
    }
    finally {
        if ($stream) { $stream.Dispose() }
    }
}

function Get-DirectoryTreeLines {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][int]$MaxDepth,
        [Parameter(Mandatory)][string[]]$Dirs
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add((Split-Path -Path $Root -Leaf) + '/')

    function Walk {
        param([string]$DirPath, [string]$Prefix, [int]$Depth)

        if ($Depth -ge $MaxDepth) { return }

        $children = @(
            Get-ChildItem -LiteralPath $DirPath -Force |
                Where-Object {
                    if ($_.Name -eq '.git') { return $false }
                    if ($_.PSIsContainer -and ($Dirs -contains $_.Name)) { return $false }
                    return $true
                } |
                Sort-Object @{Expression = { -not $_.PSIsContainer }}, Name
        )

        for ($i = 0; $i -lt $children.Count; $i++) {
            $child = $children[$i]
            $isLast = ($i -eq ($children.Count - 1))
            $branch = if ($isLast) { '\--- ' } else { '+--- ' }
            $name = if ($child.PSIsContainer) { $child.Name + '/' } else { $child.Name }

            $lines.Add($Prefix + $branch + $name)

            if ($child.PSIsContainer) {
                $nextPrefix = if ($isLast) { $Prefix + '     ' } else { $Prefix + '|    ' }
                Walk -DirPath $child.FullName -Prefix $nextPrefix -Depth ($Depth + 1)
            }
        }
    }

    Walk -DirPath $Root -Prefix '' -Depth 0
    return $lines
}

function Format-FileContent {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][bool]$LineNumbers
    )

    $content = Get-Content -LiteralPath $FilePath -Raw -Encoding UTF8
    if (-not $LineNumbers) {
        return $content
    }

    $lines = $content -split "`r?`n", -1
    $numWidth = [Math]::Max(3, ($lines.Count.ToString().Length))
    $sb = [System.Text.StringBuilder]::new()

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $n = ($i + 1).ToString().PadLeft($numWidth)
        [void]$sb.Append($n)
        [void]$sb.Append(' | ')
        [void]$sb.AppendLine($lines[$i])
    }

    return $sb.ToString()
}

$repoRoot = Resolve-AbsPath -Path $RepoPath
$isGitRepo = Test-IsGitRepo -Root $repoRoot
$useGit = $isGitRepo -and (-not $UseAllFiles)

if (-not $OutputFile) {
    $OutputFile = New-DefaultOutputPath -Root $repoRoot -UseCentral:$Central -IsSummary:$SummaryOnly
}

$outAbs = [System.IO.Path]::GetFullPath($OutputFile)
$outDir = Split-Path -Parent $outAbs
if ($outDir -and -not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$candidates = Get-CandidateFiles -Root $repoRoot -UseGit:$useGit -Dirs $ExcludeDirs -Exts $ExcludeExtensions
if ($candidates.Count -eq 0) {
    throw "No candidate files found in $repoRoot"
}

$maxBytes = $MaxFileSizeKB * 1024
$selected = New-Object System.Collections.Generic.List[object]
$skippedLarge = 0
$skippedBinary = 0

foreach ($f in $candidates) {
    if ($selected.Count -ge $MaxFiles) { break }

    if ($f.SizeBytes -gt $maxBytes) {
        $skippedLarge++
        continue
    }

    if (Test-IsProbablyBinary -FilePath $f.AbsolutePath) {
        $skippedBinary++
        continue
    }

    $selected.Add($f)
}

$treeLines = Get-DirectoryTreeLines -Root $repoRoot -MaxDepth $TreeDepth -Dirs $ExcludeDirs

$sb = [System.Text.StringBuilder]::new()

# -----------------------------------------------------------------------
# SUMMARY-ONLY MODE — lightweight index used by agents by default
# -----------------------------------------------------------------------
if ($SummaryOnly) {
    $repoName = Get-RepoName -Root $repoRoot

    # Detect language/build
    $isMaven   = Test-Path (Join-Path $repoRoot 'pom.xml')
    $isGradle  = Test-Path (Join-Path $repoRoot 'build.gradle')
    $isNpm     = Test-Path (Join-Path $repoRoot 'package.json')
    $lang     = if ($isMaven -or $isGradle) { 'Java' } elseif ($isNpm) { 'Node/React' } else { 'Unknown' }
    $buildCmd = if ($isMaven) { 'mvn clean install -DskipTests' } elseif ($isGradle) { './gradlew build -x test' } elseif ($isNpm) { 'npm install && npm run build' } else { 'see README' }

    # Top-level modules — use @() to guarantee array even when 0 or 1 result
    $modules = @(
        Get-ChildItem -LiteralPath $repoRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notmatch '^\.' -and $_.Name -notin @('node_modules','target','dist','build') } |
            Where-Object {
                (Test-Path (Join-Path $_.FullName 'pom.xml')) -or
                (Test-Path (Join-Path $_.FullName 'src')) -or
                (Test-Path (Join-Path $_.FullName 'package.json'))
            } |
            Select-Object -ExpandProperty Name
    )

    # Key Java packages — collect top-level package roots under src/main/java
    $javaPkgs = @(
        Get-ChildItem -LiteralPath $repoRoot -Recurse -Filter 'pom.xml' -ErrorAction SilentlyContinue |
            Select-Object -First 5 |
            ForEach-Object {
                $srcPath = Join-Path (Split-Path $_.FullName) 'src\main\java'
                if (Test-Path $srcPath) {
                    Get-ChildItem $srcPath -Directory -Recurse -ErrorAction SilentlyContinue |
                        Where-Object {
                            @(Get-ChildItem $_.FullName -Filter '*.java' -ErrorAction SilentlyContinue).Count -gt 0
                        } |
                        ForEach-Object {
                            $rel = $_.FullName.Substring($srcPath.Length).TrimStart('\','/').Replace('\','.')
                            if ($rel -notmatch '\.') { $rel }
                        }
                }
            } |
            Sort-Object -Unique |
            Select-Object -First 10
    )

    # Entry point detection
    $entryPoint = ''
    $mainClass = @(Get-ChildItem -LiteralPath $repoRoot -Recurse -Filter '*Application.java' -ErrorAction SilentlyContinue) | Select-Object -First 1
    if ($mainClass) { $entryPoint = $mainClass.FullName.Substring($repoRoot.Length).TrimStart('\','/').Replace('\','/') }

    # Spring Boot detection
    $isSpring = (@(Get-ChildItem -LiteralPath $repoRoot -Recurse -Filter 'application.properties' -ErrorAction SilentlyContinue).Count -gt 0) -or
                (@(Get-ChildItem -LiteralPath $repoRoot -Recurse -Filter 'application.yml'        -ErrorAction SilentlyContinue).Count -gt 0)

    # Count files by type
    $javaCount = @(Get-ChildItem -LiteralPath $repoRoot -Recurse -Filter '*.java' -ErrorAction SilentlyContinue).Count
    $tsCount   = @(Get-ChildItem -LiteralPath $repoRoot -Recurse -Filter '*.ts'   -ErrorAction SilentlyContinue).Count
    $tsxCount  = @(Get-ChildItem -LiteralPath $repoRoot -Recurse -Filter '*.tsx'  -ErrorAction SilentlyContinue).Count

    [void]$sb.AppendLine("# $repoName - Index")
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine("**Repo root:** ``$repoRoot``  ")
    [void]$sb.AppendLine("**Language:** $lang$(if ($isSpring) { ' (Spring Boot)' })  ")
    [void]$sb.AppendLine("**Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm')  ")
    [void]$sb.AppendLine("**Files:** $(if ($javaCount -gt 0) { "$javaCount .java" })$(if ($tsCount+$tsxCount -gt 0) { ", $($tsCount+$tsxCount) .ts/tsx" })  ")
    [void]$sb.AppendLine('')

    if (@($modules).Count -gt 0) {
        [void]$sb.AppendLine('## Key Modules')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('| Module | Purpose |')
        [void]$sb.AppendLine('|--------|---------|')
        foreach ($m in $modules) {
            [void]$sb.AppendLine("| ``$m/`` | |")
        }
        [void]$sb.AppendLine('')
    }

    if (@($javaPkgs).Count -gt 0) {
        [void]$sb.AppendLine('## Key Packages')
        [void]$sb.AppendLine('')
        foreach ($p in $javaPkgs) {
            [void]$sb.AppendLine("- ``$p``")
        }
        [void]$sb.AppendLine('')
    }

    if ($entryPoint) {
        [void]$sb.AppendLine('## Entry Point')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine("``$entryPoint``")
        [void]$sb.AppendLine('')
    }

    [void]$sb.AppendLine('## Build & Run')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('```bash')
    [void]$sb.AppendLine($buildCmd)
    [void]$sb.AppendLine('```')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Live File Structure')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('```bash')
    [void]$sb.AppendLine("cd $repoRoot && git ls-files | grep `"^[^/]*/`" | cut -d/ -f1 | sort -u")
    [void]$sb.AppendLine('```')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine("**Full dump (when deep code browsing needed):** ``repo-contexts/full/$repoName.md``")

    [System.IO.File]::WriteAllText($outAbs, $sb.ToString(), [System.Text.Encoding]::UTF8)

    Write-Host "repo-mix (summary) completed" -ForegroundColor Green
    Write-Host "  output: $outAbs" -ForegroundColor Cyan
    Write-Host "  modules detected: $($modules.Count)" -ForegroundColor Cyan
    return
}

# -----------------------------------------------------------------------
# FULL DUMP MODE — directory tree + all file contents (large, on-demand)
# -----------------------------------------------------------------------
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## Metadata')
[void]$sb.AppendLine('')
[void]$sb.AppendLine("- Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
[void]$sb.AppendLine("- Repo root: $repoRoot")
[void]$sb.AppendLine("- Source mode: $(if ($useGit) { 'git ls-files' } else { 'filesystem recursive scan' })")
[void]$sb.AppendLine("- Included files: $($selected.Count)")
[void]$sb.AppendLine("- Candidate files: $($candidates.Count)")
[void]$sb.AppendLine("- Skipped (too large): $skippedLarge")
[void]$sb.AppendLine("- Skipped (binary): $skippedBinary")
[void]$sb.AppendLine("- Max files: $MaxFiles")
[void]$sb.AppendLine("- Max file size: ${MaxFileSizeKB}KB")
[void]$sb.AppendLine('')

[void]$sb.AppendLine('## Directory Tree')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('```text')
foreach ($line in $treeLines) {
    [void]$sb.AppendLine($line)
}
[void]$sb.AppendLine('```')
[void]$sb.AppendLine('')

[void]$sb.AppendLine('## File Index')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('| # | Path | Size (bytes) |')
[void]$sb.AppendLine('|---|------|--------------|')
for ($i = 0; $i -lt $selected.Count; $i++) {
    $item = $selected[$i]
    [void]$sb.AppendLine("| $($i + 1) | $($item.RelativePath) | $($item.SizeBytes) |")
}
[void]$sb.AppendLine('')

[void]$sb.AppendLine('## File Contents')
[void]$sb.AppendLine('')

foreach ($item in $selected) {
    [void]$sb.AppendLine("### File: $($item.RelativePath)")
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('```text')

    try {
        $content = Format-FileContent -FilePath $item.AbsolutePath -LineNumbers:$WithLineNumbers
        [void]$sb.Append($content)
        if (-not $content.EndsWith("`n")) {
            [void]$sb.AppendLine('')
        }
    }
    catch {
        [void]$sb.AppendLine("[Read error: $($_.Exception.Message)]")
    }

    [void]$sb.AppendLine('```')
    [void]$sb.AppendLine('')
}

[System.IO.File]::WriteAllText($outAbs, $sb.ToString(), [System.Text.Encoding]::UTF8)

Write-Host "repo-mix completed" -ForegroundColor Green
Write-Host "  output: $outAbs" -ForegroundColor Cyan
Write-Host "  included: $($selected.Count) file(s)" -ForegroundColor Cyan
Write-Host "  candidates: $($candidates.Count)" -ForegroundColor Cyan
Write-Host "  skipped large: $skippedLarge" -ForegroundColor Cyan
Write-Host "  skipped binary: $skippedBinary" -ForegroundColor Cyan
