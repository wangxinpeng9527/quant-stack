@echo off
setlocal enabledelayedexpansion

REM =========================================================
REM Collector Runner (Pure BAT) - no PowerShell
REM =========================================================

REM --- IMPORTANT ---
REM Save this .bat as ANSI / GBK (NOT UTF-8 with BOM).
REM If you ever see "???" at the start, it's BOM -> re-save.
REM -----------------

REM Use UTF-8 console output (optional). If your machine is legacy, you can comment it out.
chcp 65001 >nul

REM =========================
REM Base
REM =========================
set "BASE=C:\collect\collector"
set "PY=%BASE%\venv\Scripts\python.exe"
set "MODULE=app.main"

REM =========================
REM Chrome CDP
REM =========================
set "CDP_PORT=9222"
set "CHROME_PROFILE=%USERPROFILE%\chrome-cdp-profile"

set "CHROME_EXE=C:\Program Files\Google\Chrome\Application\chrome.exe"
if not exist "%CHROME_EXE%" (
  set "CHROME_EXE=C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
)

REM =========================
REM Logs
REM =========================
set "LOGDIR=%BASE%\logs"
set "CONSOLE_LOG=%LOGDIR%\collector.console.log"

REM =========================
REM Env for Python
REM =========================
set "POLL_SECONDS=1.0"
set "CDP_JSON=http://127.0.0.1:%CDP_PORT%/json"
set "ENGINE_PUSH_URL=http://localhost:8080/engine/push"
set "PYTHONIOENCODING=utf-8"

REM =========================
REM Banner
REM =========================
echo [bat] BASE=%BASE%
echo [bat] PY=%PY%
echo [bat] MODULE=%MODULE%
echo [bat] CDP_JSON=%CDP_JSON%
echo [bat] ENGINE_PUSH_URL=%ENGINE_PUSH_URL%
echo [bat] LOG=%CONSOLE_LOG%
echo.

REM =========================
REM Checks
REM =========================
if not exist "%BASE%" (
  echo [ERROR] BASE not found: %BASE%
  pause
  exit /b 1
)

cd /d "%BASE%" || (
  echo [ERROR] cd failed: %BASE%
  pause
  exit /b 1
)

if not exist "%LOGDIR%" mkdir "%LOGDIR%"

if not exist "%CHROME_EXE%" (
  echo [ERROR] Chrome not found: %CHROME_EXE%
  pause
  exit /b 1
)

if not exist "%PY%" (
  echo [ERROR] venv python not found: %PY%
  echo Please create venv and install deps:
  echo   cd /d %BASE%
  echo   py -m venv venv
  echo   venv\Scripts\python.exe -m pip install -r requirements.txt
  pause
  exit /b 1
)

REM =========================
REM Start Chrome CDP (best-effort)
REM =========================
echo [INFO] Starting Chrome with CDP port %CDP_PORT% ...
start "" "%CHROME_EXE%" ^
  --remote-debugging-port=%CDP_PORT% ^
  --user-data-dir="%CHROME_PROFILE%" ^
  --no-first-run ^
  --no-default-browser-check ^
  --disable-popup-blocking

REM =========================
REM Wait CDP /json ready (up to ~10s)
REM Uses curl if available; if not, we just sleep a bit.
REM =========================
set "HAS_CURL=0"
where curl >nul 2>nul && set "HAS_CURL=1"

if "%HAS_CURL%"=="1" (
  echo [INFO] Waiting Chrome CDP to be ready...
  set "READY=0"
  for /l %%i in (1,1,20) do (
    curl -s "%CDP_JSON%" >nul 2>nul && (
      set "READY=1"
      goto :CDP_READY
    )
    timeout /t 1 /nobreak >nul
  )
  :CDP_READY
  if "!READY!"=="0" (
    echo [ERROR] Chrome CDP not ready: %CDP_JSON%
    echo Tip: check if port %CDP_PORT% is blocked or Chrome failed to start.
    pause
    exit /b 2
  )
) else (
  echo [WARN] curl not found; skipping /json probe, sleeping 3s...
  timeout /t 3 /nobreak >nul
)

REM =========================
REM Run Collector (append log)
REM =========================
echo.>> "%CONSOLE_LOG%"
echo ========================================================>> "%CONSOLE_LOG%"
echo [START] %DATE% %TIME%>> "%CONSOLE_LOG%"
echo [CMD] "%PY%" -m %MODULE%>> "%CONSOLE_LOG%"
echo [ENV] CDP_JSON=%CDP_JSON%>> "%CONSOLE_LOG%"
echo [ENV] ENGINE_PUSH_URL=%ENGINE_PUSH_URL%>> "%CONSOLE_LOG%"
echo ========================================================>> "%CONSOLE_LOG%"

echo [INFO] Starting collector in foreground...
echo [INFO] Logs will be appended to: %CONSOLE_LOG%
echo.

"%PY%" -m %MODULE% >> "%CONSOLE_LOG%" 2>&1
set "EC=%ERRORLEVEL%"

echo.
echo [INFO] Collector exited. errorlevel=%EC%
echo.

REM =========================
REM Show last lines of log (use powershell ONLY if available, optional)
REM If you want absolutely no PowerShell usage at all, comment this block.
REM =========================
where powershell >nul 2>nul && (
  echo [INFO] Last 40 lines of log:
  echo --------------------------------------------------
  powershell -NoProfile -Command "Get-Content -Tail 40 '%CONSOLE_LOG%'" 2>nul
  echo --------------------------------------------------
)

pause
exit /b %EC%
