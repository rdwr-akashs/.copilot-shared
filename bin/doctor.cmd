@echo off
REM ============================================================================
REM doctor.cmd  --  Health check for a repo using the .copilot-shared layout.
REM   Verifies junctions, gitignore, required files, and template leakage.
REM
REM Usage:  doctor.cmd <full-path-to-repo>
REM Exit:   0 = all PASS, 1 = at least one FAIL, 2 = bad usage
REM ============================================================================

setlocal EnableDelayedExpansion

if "%~1"=="" (
    echo Usage: %~nx0 ^<full-path-to-repo^>
    exit /b 2
)
set "REPO=%~1"
set "BIN=%~dp0"
set "SHARED=%BIN%..\shared"
for %%I in ("%SHARED%") do set "SHARED=%%~fI"

if not exist "%REPO%" (
    echo FAIL: repo not found: %REPO%
    exit /b 2
)

set /a FAILS=0
set /a WARNS=0

echo === doctor: %REPO% ===
echo.

REM ---- 1. .github exists ----
if not exist "%REPO%\.github" (
    echo [FAIL] .github folder missing - run setup-repo.cmd first
    set /a FAILS+=1
    goto :Summary
)
echo [PASS] .github folder exists

REM ---- 2. Required per-repo files ----
call :CheckFile "%REPO%\.github\copilot-instructions.md" "copilot-instructions.md"
call :CheckFile "%REPO%\.github\COPILOT-SETUP.md"        "COPILOT-SETUP.md"
call :CheckDir  "%REPO%\.github\agents"                  "agents/"
call :CheckDir  "%REPO%\.github\instructions-local"      "instructions-local/"

REM At least one .instructions.md under instructions-local\ (any name)
dir /b "%REPO%\.github\instructions-local\*.instructions.md" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] instructions-local\ has no *.instructions.md file
    set /a FAILS+=1
) else (
    echo [PASS] instructions-local\ has at least one *.instructions.md
)

REM ---- 3. Junctions resolve to the shared store ----
call :CheckJunction skills
call :CheckJunction instructions
call :CheckJunction prompts
call :CheckJunction plans

REM ---- 4. .gitignore marker block ----
if not exist "%REPO%\.gitignore" (
    echo [WARN] .gitignore missing - junction folders may be committed
    set /a WARNS+=1
) else (
    findstr /c:"# >>> copilot-shared junctions" "%REPO%\.gitignore" >nul 2>&1
    if errorlevel 1 (
        echo [FAIL] .gitignore is missing the copilot-shared marker block
        set /a FAILS+=1
    ) else (
        set "GIOK=1"
        for %%E in (.github/skills .github/instructions .github/prompts .github/plans) do (
            findstr /c:"%%E" "%REPO%\.gitignore" >nul 2>&1
            if errorlevel 1 (
                echo [FAIL] .gitignore marker block missing entry: %%E
                set /a FAILS+=1
                set "GIOK="
            )
        )
        if defined GIOK echo [PASS] .gitignore marker block complete
    )
)

REM ---- 5. Unresolved placeholders in agents ----
set "PHFOUND="
for /f "tokens=*" %%L in ('findstr /r /c:"<[A-Za-z][A-Za-z-]*>" "%REPO%\.github\agents\*.agent.md" 2^>nul') do set "PHFOUND=1"
if defined PHFOUND (
    echo [WARN] Unresolved ^<placeholder^> tokens in .github\agents\
    echo        Run the customize-agents skill in Copilot Chat
    set /a WARNS+=1
) else (
    echo [PASS] No unresolved placeholders in agents
)

REM ---- 6. Old-template-term leakage ----
findstr /i /r /c:"PolicyTemplate" /c:"policy-bom" /c:"common_policy_editor" /c:"DefenseFlow" /c:"DefensePro" /c:"dpInline" "%REPO%\.github\agents\*.agent.md" >nul 2>&1
if not errorlevel 1 (
    echo [WARN] Old template terms still in agents - re-run customize-agents skill
    set /a WARNS+=1
) else (
    echo [PASS] No org-specific template terms in agents
)

REM ---- 7. Personal instructions present? (informational only) ----
if not exist "%REPO%\.github\personal-instructions.md" (
    echo [INFO] personal-instructions.md not set - copy from templates\ if you want one
)

:Summary
echo.
if !FAILS! equ 0 (
    if !WARNS! equ 0 (
        echo === RESULT: HEALTHY ===
        exit /b 0
    )
    echo === RESULT: !WARNS! warning^(s^) ===
    exit /b 0
)
echo === RESULT: !FAILS! fail^(s^), !WARNS! warning^(s^) ===
exit /b 1

REM ----------------------------------------------------------------------------
:CheckFile
if exist %1 (
    for %%S in (%1) do if %%~zS gtr 0 (
        echo [PASS] %~2
        exit /b 0
    )
    echo [FAIL] %~2 is empty
    set /a FAILS+=1
    exit /b 0
)
echo [FAIL] %~2 missing
set /a FAILS+=1
exit /b 0

:CheckDir
if not exist %1 (
    echo [FAIL] %~2 missing
    set /a FAILS+=1
    exit /b 0
)
dir /a /b %1 2>nul | findstr /r "." >nul
if errorlevel 1 (
    echo [FAIL] %~2 is empty
    set /a FAILS+=1
    exit /b 0
)
echo [PASS] %~2 has content
exit /b 0

:CheckJunction
set "NAME=%~1"
set "TARGET=%REPO%\.github\%NAME%"
if not exist "%TARGET%" (
    echo [FAIL] .github\%NAME% missing - run link-copilot.cmd
    set /a FAILS+=1
    exit /b 0
)
fsutil reparsepoint query "%TARGET%" >nul 2>&1
if errorlevel 1 (
    echo [WARN] .github\%NAME% is a real folder ^(override mode^), not a junction
    set /a WARNS+=1
    exit /b 0
)
REM Junction: confirm target is reachable inside shared\
if not exist "%SHARED%\%NAME%" (
    echo [WARN] .github\%NAME% junction exists but shared\%NAME% does not
    set /a WARNS+=1
    exit /b 0
)
fsutil reparsepoint query "%TARGET%" 2>nul | findstr /i /c:"copilot-shared\shared\%NAME%" >nul
if errorlevel 1 (
    echo [WARN] .github\%NAME% junction does not point at copilot-shared\shared\%NAME%
    set /a WARNS+=1
    exit /b 0
)
echo [PASS] .github\%NAME% -^> shared\%NAME%
exit /b 0
