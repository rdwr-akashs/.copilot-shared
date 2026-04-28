@echo off
REM ============================================================================
REM copy-agents.cmd  --  Seed a repo's .github\agents folder from
REM                       agent-templates/. Copies only files that don't
REM                       already exist (never overwrites).
REM
REM Usage:  copy-agents.cmd <full-path-to-repo>
REM ============================================================================

setlocal EnableDelayedExpansion

if "%~1"=="" (
    echo Usage: %~nx0 ^<full-path-to-repo^>
    exit /b 2
)

set "REPO=%~1"
set "SRC=%~dp0..\agent-templates"
for %%I in ("%SRC%") do set "SRC=%%~fI"

if not exist "%SRC%" (
    echo ERROR: agent-templates not found at %SRC%
    exit /b 2
)
if not exist "%REPO%\.github\agents" mkdir "%REPO%\.github\agents"

set "COPIED=0"
set "SKIPPED=0"
for %%F in ("%SRC%\*.agent.md") do (
    if exist "%REPO%\.github\agents\%%~nxF" (
        set /a SKIPPED+=1
    ) else (
        copy /y "%%F" "%REPO%\.github\agents\%%~nxF" >nul
        set /a COPIED+=1
    )
)
echo === %REPO% ===
echo   copied  : !COPIED!
echo   skipped : !SKIPPED!  ^(already present - left untouched^)
echo.
echo Customise the copied agents for THIS repo's tech stack ^& conventions.
exit /b 0
