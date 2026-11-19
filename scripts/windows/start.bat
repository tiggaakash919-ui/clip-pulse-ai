@echo off
title Clip Pulse AI 24/7 Live Clipper
cd /d "%~dp0..\.."
echo ==========================================================
echo   Starting Clip Pulse AI Local Studio (Windows 24/7 Mode)
echo ==========================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start.ps1"
echo.
pause
