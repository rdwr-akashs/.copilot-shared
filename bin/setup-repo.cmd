@echo off
REM ============================================================================
REM setup-repo.cmd  --  One-shot setup for a repo that has no .github yet.
REM   1. Creates .github\, copies copilot-instructions template
REM   2. Creates instructions-local/ for repo-specific overrides
REM   3. Drops in COPILOT-SETUP.md and customize-agents.prompt.md
REM   4. Copies agents from agent-templates/
REM   5. Junctions skills/instructions/prompts/plans
REM
REM Usage:  setup-repo.cmd <full-path-to-repo>
REM ============================================================================

setlocal EnableDelayedExpansion

if "%~1"=="" (
    echo Usage: %~nx0 ^<full-path-to-repo^>
    exit /b 2
)
set "REPO=%~1"
set "BIN=%~dp0"
set "TPL=%BIN%..\templates"
for %%I in ("%TPL%") do set "TPL=%%~fI"

if not exist "%REPO%" (
    echo ERROR: repo not found: %REPO%
    exit /b 2
)

if not exist "%REPO%\.github" mkdir "%REPO%\.github"

if not exist "%REPO%\.github\copilot-instructions.md" (
    copy /y "%TPL%\copilot-instructions.template.md" "%REPO%\.github\copilot-instructions.md" >nul
    echo   created copilot-instructions.md  ^(EDIT THIS to describe the project^)
)

if not exist "%REPO%\.github\instructions-local" (
    mkdir "%REPO%\.github\instructions-local"
    copy /y "%TPL%\project-rules.template.instructions.md" "%REPO%\.github\instructions-local\project-rules.instructions.md" >nul
    copy /y "%TPL%\instructions-local.README.md" "%REPO%\.github\instructions-local\README.md" >nul
    echo   created instructions-local\  ^(repo-specific rules go here^)
)

if not exist "%REPO%\.github\COPILOT-SETUP.md" (
    copy /y "%TPL%\COPILOT-SETUP.template.md" "%REPO%\.github\COPILOT-SETUP.md" >nul
    echo   created COPILOT-SETUP.md      ^(team onboarding doc^)
)

call "%BIN%copy-agents.cmd" "%REPO%"
call "%BIN%link-copilot.cmd" "%REPO%"

echo.
echo === %REPO% ready ===
echo   1. Edit .github\copilot-instructions.md        ^(project overview^)
echo   2. Edit .github\instructions-local\*.md         ^(project rules^)
echo   3. Open the repo in JetBrains and ask Copilot Chat:
echo        "Run the customize-agents skill on this repo."
echo      It will tailor .github\agents\ for THIS repo.
echo   4. Read .github\COPILOT-SETUP.md for full team onboarding instructions.
exit /b 0
