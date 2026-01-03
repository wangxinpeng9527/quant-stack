@echo off
setlocal enabledelayedexpansion

REM =========================================================
REM =============== 基础配置（按需修改） ====================
REM =========================================================

REM Collector 根目录
set BASE=D:\collector

REM venv Python
set PY=%BASE%\venv\Scripts\python.exe

REM Python 模块入口（与 mac 对齐）
set MODULE=app.main

REM Chrome CDP 端口
set CDP_PORT=9222

REM Chrome 独立 profile（不污染日常）
set CHROME_PROFILE=%USERPROFILE%\chrome-cdp-profile

REM Chrome 路径（64/32 位兜底）
set CHROME_EXE=C:\Program Files\Google\Chrome\Application\chrome.exe
if not exist "%CHROME_EXE%" (
  set CHROME_EXE=C:\Program Files (x86)\Google\Chrome\Application\chrome.exe
)

REM 日志
set LOGDIR=%BASE%\logs
set CONSOLE_LOG=%LOGDIR%\collector.console.log

REM 环境变量（传给 Python）
set POLL_SECONDS=1.0
set CDP_JSON=http://127.0.0.1:%CDP_PORT%/json
set ENGINE_PUSH_URL=http://localhost:8080/engine/push

REM =========================================================
REM ====================== 检查 =============================
REM =========================================================

if not exist "%BASE%" (
  echo [ERROR] BASE not found: %BASE%
  pause
  exit /b 1
)

if not exist "%LOGDIR%" mkdir "%LOGDIR%"

if not exist "%CHROME_EXE%" (
  echo [ERROR] Chrome not found.
  pause
  exit /b 1
)

if not exist "%PY%" (
  echo [ERROR] venv python not found: %PY%
  echo Please create venv first:
  echo   cd %BASE%
  echo   python -m venv venv
  echo   venv\Scripts\pip install -r requirements.txt
  pause
  exit /b 1
)

REM =========================================================
REM ============ 启动 Chrome CDP（如未启动） ================
REM =========================================================

netstat -ano | findstr :%CDP_PORT% >nul
if %ERRORLEVEL%==0 (
  echo [INFO] CDP port %CDP_PORT% already listening.
) else (
  echo [INFO] Starting Chrome with CDP on port %CDP_PORT% ...
  start "" "%CHROME_EXE%" ^
    --remote-debugging-port=%CDP_PORT% ^
    --user-data-dir="%CHROME_PROFILE%" ^
    --no-first-run ^
    --no-default-browser-check ^
    --disable-popup-blocking

  echo [INFO] Waiting Chrome CDP to be ready...
  timeout /t 3 >nul
)

REM =========================================================
REM ================= 启动 Collector ========================
REM =========================================================

echo [INFO] Starting collector...
echo [INFO] %PY% -m %MODULE%
echo [INFO] Log file: %CONSOLE_LOG%

"%PY%" -m %MODULE% >> "%CONSOLE_LOG%" 2>&1

endlocal
