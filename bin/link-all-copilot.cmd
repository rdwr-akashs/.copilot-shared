@echo off
REM ============================================================================
REM link-all-copilot.cmd  --  Walk all sibling repos under the workspace root
REM                          and run link-copilot.cmd for each one that has
REM                          (or wants) a .github folder.
REM
REM Usage:  link-all-copilot.cmd                   (auto-detect root)
REM         link-all-copilot.cmd D:\code           (custom root)
REM         set COPILOT_WORKSPACE_ROOT=D:\code     (env var)
REM ============================================================================

setlocal EnableDelayedExpansion

set "ROOT=%~1"
if "%ROOT%"=="" (
    if defined COPILOT_WORKSPACE_ROOT (
        set "ROOT=%COPILOT_WORKSPACE_ROOT%"
    ) else (
        REM Auto-detect: parent of .copilot-shared (i.e. parent of bin's parent)
        set "ROOT=%~dp0..\..\"
        for %%I in ("!ROOT!") do set "ROOT=%%~fI"
    )
)

if not exist "%ROOT%" (
    echo ERROR: root not found: %ROOT%
    exit /b 2
)

set "BIN=%~dp0"
set "COUNT=0"
set "SKIPPED=0"
set "NEEDSETUP=0"

for /d %%R in ("%ROOT%\*") do (
    if exist "%%R\.github\copilot-instructions.md" (
        call "%BIN%link-copilot.cmd" "%%R"
        set /a COUNT+=1
    ) else if exist "%%R\.git" (
        echo SKIP: %%R  ^(no .github\copilot-instructions.md - run setup-repo.ps1 first^)
        echo       powershell -File "%BIN%setup-repo.ps1" "%%R"
        set /a SKIPPED+=1
        set /a NEEDSETUP+=1
    ) else (
        set /a SKIPPED+=1
    )
)

echo.
echo ====================================
echo   SUMMARY
echo ====================================
echo   Linked:      !COUNT! repos
echo   Skipped:     !SKIPPED! ^(no .github or not a git repo^)
echo   Need setup:  !NEEDSETUP! ^(have .git but no .github^)
echo ====================================
if !NEEDSETUP! gtr 0 (
    echo.
    echo To set up the remaining repos, run:
    echo   powershell -File "%BIN%setup-repo.ps1" ^<repo-path^>
)
exit /b 0
