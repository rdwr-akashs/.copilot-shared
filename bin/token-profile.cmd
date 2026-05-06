@echo off
setlocal

set "BIN=%~dp0"
set "PS1=%BIN%token-profile.ps1"

if "%~1"=="" (
    echo Usage: %~nx0 ^<balanced^|aggressive^> [repo-path]
    exit /b 2
)

if not exist "%PS1%" (
    echo ERROR: token-profile.ps1 not found: %PS1%
    exit /b 1
)

set "PROFILE=%~1"
set "REPO=%~2"
if "%REPO%"=="" set "REPO=."

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -Profile "%PROFILE%" -RepoPath "%REPO%"
exit /b %ERRORLEVEL%
