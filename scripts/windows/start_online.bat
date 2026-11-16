@echo off
title PeakCut Online 24/7 (Share with Phone)
cd /d "%~dp0..\.."
echo ==========================================================
echo   Starting PeakCut Online Access (Public HTTPS Link)
echo ==========================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start_online.ps1"
echo.
pause
