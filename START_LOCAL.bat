@echo off
title PeakCut 24/7 Local Studio
cd /d "%~dp0"
echo ==========================================================
echo   Starting PeakCut Local Studio (24/7 Mode)
echo ==========================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\windows\start.ps1"
echo.
pause
