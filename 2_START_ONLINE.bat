@echo off
title PeakCut 24/7 Online Server
cd /d "%~dp0"
echo ==========================================================
echo   Starting PeakCut Online Server & Tunnel
echo ==========================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\windows\start_online.ps1"
echo.
pause
