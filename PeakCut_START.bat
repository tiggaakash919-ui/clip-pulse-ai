@echo off
setlocal EnableExtensions
cd /d "%~dp0"
title PeakCut Launcher
set PORT=8765
set "VPY=.venv\Scripts\python.exe"
if /i "%~1"=="online" set PEAKCUT_ACCOUNTS=1

rem ---- Add local data\bin to PATH if present (e.g. ffmpeg/cloudflared)
if exist "%~dp0data\bin" set "PATH=%~dp0data\bin;%PATH%"

rem ---- Pehle se chal raha hai?
call :portup && goto ready

rem ---- Python 3.10+
set "PY="
py -3 -c "import sys;assert sys.version_info>=(3,10)" >nul 2>&1 && set "PY=py -3"
if not defined PY python -c "import sys;assert sys.version_info>=(3,10)" >nul 2>&1 && set "PY=python"
if not defined PY if exist "%LOCALAPPDATA%\Programs\Python\Python312\python.exe" set "PY=%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
if not defined PY if exist "%LOCALAPPDATA%\Programs\Python\Python311\python.exe" set "PY=%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
if not defined PY if exist "C:\Python312\python.exe" set "PY=C:\Python312\python.exe"
if not defined PY if exist "C:\Python311\python.exe" set "PY=C:\Python311\python.exe"
if not defined PY (
  echo [..] Python install ho raha hai...
  winget install -e --id Python.Python.3.12 --accept-source-agreements --accept-package-agreements
  echo [!] Python install hua. Window band karke yeh file dobara chalayein.
  pause & exit /b 1
)

rem ---- FFmpeg
where ffmpeg >nul 2>&1 || (
  echo [..] FFmpeg install ho raha hai...
  winget install -e --id Gyan.FFmpeg --accept-source-agreements --accept-package-agreements
)

rem ---- Virtual env + packages (requirements.txt badle to dobara install)
if not exist "%VPY%" (
  echo [..] .venv ban raha hai...
  %PY% -m venv .venv || goto fail
)
fc /b requirements.txt .venv\req.lock >nul 2>&1
if errorlevel 1 (
  echo [..] Packages install ho rahe hain, pehli baar kuch minute lagenge...
  "%VPY%" -m pip install --upgrade pip
  "%VPY%" -m pip install -r requirements.txt || goto fail
  copy /y requirements.txt .venv\req.lock >nul
)

rem ---- Speech model (480 MB, ek baar)
"%VPY%" -m studio.fetch_model || goto fail

rem ---- Server alag window me (error wahi dikhega)
start "PeakCut Server" cmd /k ".venv\Scripts\python.exe -m studio.server"

echo [..] Server start hone ka intezaar...
set /a N=0
:wait
call :portup && goto ready
set /a N+=1
if %N% geq 150 (
  echo [X] Server 5 minute me start nahi hua. "PeakCut Server" window me error dekhein.
  pause & exit /b 1
)
timeout /t 2 /nobreak >nul
goto wait

:ready
echo [OK] PeakCut chal raha hai: http://127.0.0.1:%PORT%
if /i not "%~1"=="online" (
  start "" http://127.0.0.1:%PORT%
  exit /b 0
)
where cloudflared >nul 2>&1 || (
  echo [..] Cloudflare tunnel engine install ho raha hai...
  winget install -e --id Cloudflare.cloudflared --accept-source-agreements --accept-package-agreements
)
echo [..] Public link ban raha hai, neeche "trycloudflare.com" wala link dekhein:
cloudflared tunnel --url http://127.0.0.1:%PORT%
pause & exit /b 0

:portup
powershell -NoProfile -Command "try{$c=New-Object Net.Sockets.TcpClient;$c.Connect('127.0.0.1',%PORT%);$c.Close();exit 0}catch{exit 1}" >nul 2>&1
exit /b %errorlevel%

:fail
echo [X] Setup fail hua. Upar ka error dekhein.
pause & exit /b 1
