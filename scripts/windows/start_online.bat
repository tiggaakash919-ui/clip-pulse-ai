@echo off
title Clip Pulse AI Online 24/7 (Share with Phone)
cd /d "%~dp0..\.."
echo ==========================================================
echo   Starting Clip Pulse AI Online Access (Public HTTPS Link)
echo ==========================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start_online.ps1"
echo.
pause
