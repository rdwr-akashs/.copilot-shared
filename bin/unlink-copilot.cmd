@echo off
REM ============================================================================
REM unlink-copilot.cmd  --  Remove copilot-shared junctions from a repo.
REM
REM Usage:  unlink-copilot.cmd <full-path-to-repo>
REM
REM Removes only the three junctions (skills, instructions, prompts).
REM Real folders and agents/ are left untouched.
REM ============================================================================

setlocal EnableDelayedExpansion

if "%~1"=="" (
    echo Usage: %~nx0 ^<full-path-to-repo^>
    exit /b 2
)
set "REPO=%~1"

for %%N in (skills instructions prompts) do (
    set "T=%REPO%\.github\%%N"
    if exist "!T!" (
        fsutil reparsepoint query "!T!" >nul 2>&1
        if not errorlevel 1 (
            rmdir "!T!" 2>nul
            echo   removed junction: %%N
        ) else (
            echo   skipped real folder: %%N
        )
    )
)
exit /b 0
