@echo off
setlocal

REM 当前 bat 所在目录
set BATDIR=%~dp0
REM collector 根目录 = bats 的上一级
for %%I in ("%BATDIR%..") do set BASE=%%~fI

set SAVED=%BASE%\bats_saved
if not exist "%SAVED%" mkdir "%SAVED%"

REM 时间戳（简单版：YYYYMMDD_HHMMSS）
for /f "tokens=1-3 delims=/ " %%a in ("%date%") do (
  set yyyy=%%c
  set mm=%%a
  set dd=%%b
)
for /f "tokens=1-3 delims=:." %%a in ("%time%") do (
  set hh=%%a
  set mi=%%b
  set ss=%%c
)
set ts=%yyyy%%mm%%dd%_%hh%%mi%%ss%
set ts=%ts: =0%

copy "%BASE%\bats\start_chrome.bat" "%SAVED%\start_chrome_%ts%.bat" >nul
copy "%BASE%\bats\run_collector.bat" "%SAVED%\run_collector_%ts%.bat" >nul

echo [save_bats] Saved to: %SAVED%
dir "%SAVED%" | findstr /i ".bat"

endlocal
