@echo off
REM ============================================================================
REM Master Console Launcher for Copilot Shared Operations
REM ============================================================================
REM
REM Double-click this file to launch the interactive console.
REM Or run from PowerShell: .\console.cmd [quick]
REM
REM Usage:
REM   console.cmd              - Launch interactive menu
REM   console.cmd quick        - Auto-detect changes and apply fixes
REM

setlocal enabledelayedexpansion

REM Detect script location
set "BinDir=%~dp0"
set "PowerShellScript=%BinDir%console.ps1"

REM Handle quick mode
set "Args="
if "%1"=="quick" (
    set "Args=-Quick"
    echo Launching Smart Refresh...
) else (
    echo Launching Copilot Shared Console...
)

REM Launch PowerShell script
powershell -NoProfile -ExecutionPolicy Bypass -File "%PowerShellScript%" %Args%

if errorlevel 1 (
    echo.
    echo Error: Console exited with error code !errorlevel!
    pause
    exit /b !errorlevel!
)

exit /b 0
