@echo off
title PeakCut 24/7 Live Clipper
cd /d "%~dp0..\.."
echo ==========================================================
echo   Starting PeakCut Local Studio (Windows 24/7 Mode)
echo ==========================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start.ps1"
echo.
pause
