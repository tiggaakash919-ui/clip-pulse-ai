@echo off
title Clip Pulse AI Setup for Windows
cd /d "%~dp0"
echo ==========================================================
echo   Clip Pulse AI Windows Automated Setup
echo ==========================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\windows\setup.ps1"
echo.
pause
