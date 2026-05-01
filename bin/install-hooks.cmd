@echo off
setlocal

REM install-hooks.cmd — Install shared git hooks into a repo's .git/hooks/
REM Usage:   install-hooks.cmd <repo-path>
REM Example: install-hooks.cmd C:\workspace\my-repo
REM
REM Hooks installed:
REM   commit-msg  — enforces Conventional Commits format
REM   pre-push    — runs tests before push (SKIP_TESTS=1 to bypass)

if "%~1"=="" (
    echo ERROR: Missing argument.
    echo.
    echo Usage: install-hooks.cmd ^<repo-path^>
    echo.
    echo Example: install-hooks.cmd C:\workspace\my-repo
    exit /b 1
)

set REPO_PATH=%~1
set HOOKS_SRC=%~dp0..\shared\hooks
set HOOKS_DEST=%REPO_PATH%\.git\hooks

REM Validate repo path
if not exist "%REPO_PATH%\.git" (
    echo ERROR: %REPO_PATH% is not a git repository ^(no .git folder found^).
    exit /b 1
)

REM Validate hooks source
if not exist "%HOOKS_SRC%" (
    echo ERROR: Hooks source not found: %HOOKS_SRC%
    exit /b 1
)

echo Installing git hooks into %HOOKS_DEST%
echo Source: %HOOKS_SRC%
echo.

REM Install each hook
for %%H in (commit-msg pre-push) do (
    if exist "%HOOKS_SRC%\%%H" (
        copy /Y "%HOOKS_SRC%\%%H" "%HOOKS_DEST%\%%H" >nul
        echo   [OK] %%H
    ) else (
        echo   [SKIP] %%H ^(not found in shared/hooks/^)
    )
)

echo.
echo Done. Hooks installed in %HOOKS_DEST%
echo.
echo Note: On Windows, git hooks run via Git Bash (sh). 
echo       Ensure Git Bash is installed (comes with Git for Windows).
echo.
echo To bypass tests on push (WIP only):
echo   SKIP_TESTS=1 git push
echo.

endlocal
exit /b 0
