@echo off
REM ============================================================================
REM link-all-copilot.cmd  --  Walk all sibling repos under C:\rdwr-intelij\
REM                          and run link-copilot.cmd for each one that has
REM                          (or wants) a .github folder.
REM
REM Usage:  link-all-copilot.cmd            (default root: C:\rdwr-intelij)
REM         link-all-copilot.cmd D:\code    (custom root)
REM ============================================================================

setlocal EnableDelayedExpansion

set "ROOT=%~1"
if "%ROOT%"=="" set "ROOT=C:\rdwr-intelij"

if not exist "%ROOT%" (
    echo ERROR: root not found: %ROOT%
    exit /b 2
)

set "BIN=%~dp0"
set "COUNT=0"

for /d %%R in ("%ROOT%\*") do (
    if exist "%%R\.github\copilot-instructions.md" (
        call "%BIN%link-copilot.cmd" "%%R"
        set /a COUNT+=1
    ) else if exist "%%R\.git" (
        echo SKIP: %%R  ^(no .github\copilot-instructions.md - run setup-repo.cmd first^)
    )
)

echo.
echo === processed !COUNT! repos under %ROOT% ===
exit /b 0
