@echo off
title Clip Pulse AI Setup for Windows
cd /d "%~dp0..\.."
echo ==========================================================
echo   Clip Pulse AI Windows Automated Setup
echo ==========================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
echo.
pause
