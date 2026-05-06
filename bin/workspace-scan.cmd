@echo off
setlocal
set "BIN=%~dp0"
set "PS1=%BIN%workspace-scan.ps1"
if not exist "%PS1%" (
    echo ERROR: workspace-scan.ps1 not found: %PS1%
    exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %*
exit /b %ERRORLEVEL%
