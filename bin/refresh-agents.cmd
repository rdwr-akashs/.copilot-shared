@echo off
REM ============================================================================
REM refresh-agents.cmd  --  Pull updates from agent-templates/ into a repo's
REM                          .github/agents/ when shared templates have been
REM                          improved upstream.
REM
REM Usage:  refresh-agents.cmd <full-path-to-repo>
REM
REM Behaviour (per agent file):
REM   - If repo is missing the agent  -> copy the template in (NEW)
REM   - If template is unchanged       -> skip (UNCHANGED)
REM   - If repo's copy == template     -> skip (SAME)
REM   - Otherwise                      -> save template to <agent>.template.new
REM                                      next to the repo's customised copy and
REM                                      tell the user to diff & merge manually
REM
REM Never overwrites a customised agent. After running, ask Copilot Chat to
REM "run the customize-agents skill" to re-apply this repo's substitutions to
REM any newly imported templates.
REM ============================================================================

setlocal EnableDelayedExpansion

if "%~1"=="" (
    echo Usage: %~nx0 ^<full-path-to-repo^>
    exit /b 2
)
set "REPO=%~1"
set "BIN=%~dp0"
set "TPL=%BIN%..\agent-templates"
for %%I in ("%TPL%") do set "TPL=%%~fI"

if not exist "%REPO%\.github" (
    echo ERROR: %REPO%\.github not found - run setup-repo.cmd first
    exit /b 2
)
if not exist "%TPL%" (
    echo ERROR: agent-templates not found at %TPL%
    exit /b 2
)

if not exist "%REPO%\.github\agents" mkdir "%REPO%\.github\agents"

set /a NEW=0
set /a SAME=0
set /a CONFLICT=0

echo === refresh-agents: %REPO% ===
echo.

for %%F in ("%TPL%\*.agent.md") do (
    set "BASE=%%~nxF"
    set "REPOFILE=%REPO%\.github\agents\!BASE!"
    if not exist "!REPOFILE!" (
        copy /y "%%F" "!REPOFILE!" >nul
        echo   [NEW]      !BASE!
        set /a NEW+=1
    ) else (
        REM Compare with fc: errorlevel 0 = identical, 1 = differ, 2 = error
        fc /b "%%F" "!REPOFILE!" >nul 2>&1
        if not errorlevel 1 (
            echo   [SAME]     !BASE!  ^(no upstream change^)
            set /a SAME+=1
        ) else (
            copy /y "%%F" "!REPOFILE!.template.new" >nul
            echo   [CONFLICT] !BASE!  ^(saved upstream as !BASE!.template.new^)
            set /a CONFLICT+=1
        )
    )
)

echo.
echo === Summary ===
echo   NEW       : !NEW!   ^(imported, then run customize-agents skill^)
echo   SAME      : !SAME!  ^(no upstream change^)
echo   CONFLICT  : !CONFLICT!  ^(diff *.template.new vs the live agent, merge manually^)
echo.

if !CONFLICT! gtr 0 (
    echo Next steps for each conflict:
    echo   1. cd %REPO%\.github\agents
    echo   2. diff ^<agent^>.agent.md ^<agent^>.agent.md.template.new
    echo   3. Merge wanted changes into the live file
    echo   4. del ^<agent^>.agent.md.template.new
    echo   5. In Copilot Chat: "Run the customize-agents skill on this repo"
    echo      ^(re-substitutes placeholders in any newly imported sections^)
    echo.
)

if !NEW! gtr 0 (
    echo Newly imported agents still contain placeholders.
    echo In Copilot Chat: "Run the customize-agents skill on this repo"
)

exit /b 0
