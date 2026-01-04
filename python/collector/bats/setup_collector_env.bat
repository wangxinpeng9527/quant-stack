@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
title Collector venv Setup (DEBUG)

REM ===== base =====
set "BASE=%~dp0.."
set "LOGDIR=%BASE%\logs"
if not exist "%LOGDIR%" mkdir "%LOGDIR%" >nul 2>nul
set "DBG=%LOGDIR%\setup.debug.log"

REM ===== start log =====
> "%DBG%" echo ====== setup debug ======
>>"%DBG%" echo DATE=%DATE% TIME=%TIME%
>>"%DBG%" echo SCRIPT=%~f0
>>"%DBG%" echo BASE=%BASE%
>>"%DBG%" echo.

echo [DEBUG] log file: "%DBG%"
echo [DEBUG] BASE: "%BASE%"
echo.
echo (If this window used to flash-close, it should NOT now.)
pause

REM helper: print to screen + log
call :LOG "=========================================="
call :LOG "Collector Python venv Setup (DEBUG)"
call :LOG "=========================================="
call :LOG ""

REM cd
cd /d "%BASE%" >>"%DBG%" 2>&1
if not "%ERRORLEVEL%"=="0" (
  call :LOG "[ERROR] cd failed: %BASE% (errorlevel=%ERRORLEVEL%)"
  goto :END
)

call :LOG "[OK] cd: %CD%"

REM ==================================================
REM Step 1: Locate python
REM ==================================================
set "PYTHON_EXE="
call :LOG ""
call :LOG "[1/3] Locating python.exe ..."

REM 1) py launcher
where py >>"%DBG%" 2>&1
if "%ERRORLEVEL%"=="0" (
  call :LOG "[INFO] py launcher exists."
  call :LOG "[INFO] py -0p output:"
  for /f "delims=" %%L in ('py -0p 2^>nul') do (
    call :LOG "  %%L"
  )

  for /f "usebackq tokens=1,* delims= " %%A in (`py -0p 2^>nul`) do (
    set "VER=%%A"
    set "PTH=%%B"
    REM trim quotes/spaces not needed; keep as-is
    if /i "!VER!"=="-3.12-64" if exist "!PTH!" set "PYTHON_EXE=!PTH!"
    if not defined PYTHON_EXE if /i "!VER!"=="-3.12"    if exist "!PTH!" set "PYTHON_EXE=!PTH!"
    if not defined PYTHON_EXE if /i "!VER!"=="-3.11-64" if exist "!PTH!" set "PYTHON_EXE=!PTH!"
    if not defined PYTHON_EXE if /i "!VER!"=="-3.11"    if exist "!PTH!" set "PYTHON_EXE=!PTH!"
    if not defined PYTHON_EXE if /i "!VER!"=="-3.10-64" if exist "!PTH!" set "PYTHON_EXE=!PTH!"
    if not defined PYTHON_EXE if /i "!VER!"=="-3.10"    if exist "!PTH!" set "PYTHON_EXE=!PTH!"
  )
) else (
  call :LOG "[WARN] py launcher NOT found."
)

REM 2) where python
if not defined PYTHON_EXE (
  call :LOG ""
  call :LOG "[INFO] where python output:"
  for /f "delims=" %%P in ('where python 2^>nul') do (
    call :LOG "  %%P"
    if not defined PYTHON_EXE if exist "%%P" set "PYTHON_EXE=%%P"
  )
)

REM 3) fallback paths
if not defined PYTHON_EXE (
  call :LOG ""
  call :LOG "[INFO] fallback paths check..."
  for %%P in (
    "%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
    "%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
    "%LOCALAPPDATA%\Programs\Python\Python310\python.exe"
    "C:\Python312\python.exe"
    "C:\Python311\python.exe"
    "C:\Python310\python.exe"
    "%ProgramFiles%\Python312\python.exe"
    "%ProgramFiles%\Python311\python.exe"
    "%ProgramFiles%\Python310\python.exe"
  ) do (
    if exist "%%~P" (
      call :LOG "  [HIT] %%~P"
      set "PYTHON_EXE=%%~P"
      goto :PY_FOUND
    ) else (
      call :LOG "  [MISS] %%~P"
    )
  )
)

:PY_FOUND
if not defined PYTHON_EXE (
  call :LOG ""
  call :LOG "[ERROR] python.exe NOT FOUND."
  call :LOG "Tips: open cmd and run: py -0p  /  where python"
  goto :END
)

call :LOG ""
call :LOG "[OK] Using python: %PYTHON_EXE%"
"%PYTHON_EXE%" -V >>"%DBG%" 2>&1
call :LOG "[OK] python -V written to log."

REM ==================================================
REM Step 2: Create venv
REM ==================================================
call :LOG ""
call :LOG "[2/3] Creating virtual environment..."

if exist "venv\Scripts\python.exe" (
  call :LOG "[SKIP] venv already exists"
) else (
  "%PYTHON_EXE%" -m venv venv >>"%DBG%" 2>&1
  if not "%ERRORLEVEL%"=="0" (
    call :LOG "[ERROR] Failed to create venv (see log)."
    goto :END
  )
  call :LOG "[OK] venv created"
)

REM ==================================================
REM Step 3: Install requirements
REM ==================================================
call :LOG ""
call :LOG "[3/3] Installing requirements..."

if not exist "requirements.txt" (
  call :LOG "[WARN] requirements.txt not found, skipping"
) else (
  "venv\Scripts\python.exe" -m pip install --upgrade pip >>"%DBG%" 2>&1
  "venv\Scripts\python.exe" -m pip install -r requirements.txt >>"%DBG%" 2>&1
  if not "%ERRORLEVEL%"=="0" (
    call :LOG "[ERROR] Failed to install requirements (see log)."
    goto :END
  )
  call :LOG "[OK] requirements installed"
)

call :LOG ""
call :LOG "=========================================="
call :LOG "Setup COMPLETE"
call :LOG "Next: Double-click bats\start_collector.bat"
call :LOG "=========================================="

:END
call :LOG ""
call :LOG "[DONE] errorlevel=%ERRORLEVEL%"
call :LOG "Log saved: %DBG%"
echo.
pause
exit /b %ERRORLEVEL%

:LOG
echo %~1
>>"%DBG%" echo %~1
exit /b 0
