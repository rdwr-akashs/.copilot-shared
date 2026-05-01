@echo off
REM ============================================================================
REM link-copilot.cmd  --  Junction a single repo's .github/{skills,instructions,
REM                       prompts} folders to the central .copilot-shared store.
REM
REM Usage:  link-copilot.cmd <full-path-to-repo>
REM         link-copilot.cmd %COPILOT_WORKSPACE_ROOT%\my_repo
REM
REM Behaviour:
REM   - Creates .github\ if missing.
REM   - For each shared subfolder (skills, instructions, prompts):
REM       * If a real folder already exists with content -> SKIPPED (override).
REM       * If a junction already exists                 -> refreshed.
REM       * Else                                          -> junctioned.
REM   - Agents are NOT junctioned (they are per-repo customisations); use
REM     copy-agents.cmd to seed them once from agent-templates/.
REM   - Appends required entries to .gitignore (idempotent).
REM   - Prints a summary line.
REM ============================================================================

setlocal EnableDelayedExpansion

if "%~1"=="" (
    echo ERROR: repo path argument required.
    echo Usage: %~nx0 ^<full-path-to-repo^>
    exit /b 2
)

set "REPO=%~1"
set "SHARED=%~dp0..\shared"
for %%I in ("%SHARED%") do set "SHARED=%%~fI"

if not exist "%REPO%" (
    echo ERROR: repo not found: %REPO%
    exit /b 2
)
if not exist "%SHARED%" (
    echo ERROR: shared folder not found: %SHARED%
    exit /b 2
)

if not exist "%REPO%\.github" mkdir "%REPO%\.github"

set "LINKED="
set "SKIPPED="
set "REFRESHED="

call :LinkOne skills
call :LinkOne instructions
call :LinkOne prompts
call :LinkOne plans

call :EnsureGitignore
call :EnsureLocalExclude

echo.
echo === %REPO% ===
echo   linked    : %LINKED%
echo   refreshed : %REFRESHED%
echo   skipped   : %SKIPPED%
echo   shared    : %SHARED%
exit /b 0

REM ----------------------------------------------------------------------------
:LinkOne
set "NAME=%~1"
set "TARGET=%REPO%\.github\%NAME%"
set "SOURCE=%SHARED%\%NAME%"

if not exist "%SOURCE%" (
    echo   WARN: shared\%NAME% missing, skipping.
    exit /b 0
)

REM Already a junction?
fsutil reparsepoint query "%TARGET%" >nul 2>&1
if not errorlevel 1 (
    rmdir "%TARGET%" 2>nul
    mklink /J "%TARGET%" "%SOURCE%" >nul
    set "REFRESHED=!REFRESHED! %NAME%"
    exit /b 0
)

REM Real folder existing with content -> override, skip
if exist "%TARGET%" (
    dir /a /b "%TARGET%" 2>nul | findstr /r "." >nul
    if not errorlevel 1 (
        set "SKIPPED=!SKIPPED! %NAME%(override)"
        exit /b 0
    )
    rmdir "%TARGET%" 2>nul
)

mklink /J "%TARGET%" "%SOURCE%" >nul
if errorlevel 1 (
    echo   ERROR creating junction for %NAME%
    set "SKIPPED=!SKIPPED! %NAME%(error)"
    exit /b 0
)
set "LINKED=!LINKED! %NAME%"
exit /b 0

REM ----------------------------------------------------------------------------
:EnsureGitignore
set "GI=%REPO%\.gitignore"
if not exist "%GI%" type nul > "%GI%"

REM If our marker block exists but is missing .github/plans, rewrite the block.
findstr /c:"# >>> copilot-shared junctions" "%GI%" >nul 2>&1
if not errorlevel 1 (
    findstr /c:".github/plans" "%GI%" >nul 2>&1
    if not errorlevel 1 exit /b 0
    REM Strip old block and fall through to rewrite
    powershell -NoProfile -Command "$p='%GI%'; $c=Get-Content -Raw $p; $c=[regex]::Replace($c, '(?ms)# >>> copilot-shared junctions.*?# <<< copilot-shared junctions\r?\n?', ''); Set-Content -Path $p -Value $c -NoNewline"
)

(
  echo.
  echo # ^>^>^> copilot-shared junctions ^(managed by .copilot-shared/bin/link-copilot.cmd^)
  echo .github/skills
  echo .github/instructions
  echo .github/prompts
  echo .github/plans
  echo # ^<^<^< copilot-shared junctions
) >> "%GI%"
exit /b 0

REM ----------------------------------------------------------------------------
:EnsureLocalExclude
REM .git/info/exclude is machine-local and never committed -- use it for
REM codebase knowledge files that must NOT go to GitHub.
set "EX=%REPO%\.git\info\exclude"
if not exist "%REPO%\.git" exit /b 0
if not exist "%REPO%\.git\info" mkdir "%REPO%\.git\info"
if not exist "%EX%" type nul > "%EX%"
findstr /c:"copilot-generated knowledge" "%EX%" >nul 2>&1
if not errorlevel 1 exit /b 0
(
  echo.
  echo # copilot-generated knowledge -- local only, never committed
  echo .github/repo-cache.md
  echo docs/codebase/
) >> "%EX%"
exit /b 0
