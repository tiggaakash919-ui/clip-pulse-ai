@echo off
title Clip Pulse AI 24/7 Online Server
cd /d "%~dp0"
echo ==========================================================
echo   Starting Clip Pulse AI Online Server & Tunnel
echo ==========================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\windows\start_online.ps1"
echo.
pause
