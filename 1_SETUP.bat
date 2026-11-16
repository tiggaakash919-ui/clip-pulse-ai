@echo off
title PeakCut Setup for Windows
cd /d "%~dp0"
echo ==========================================================
echo   PeakCut Windows Automated Setup
echo ==========================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\windows\setup.ps1"
echo.
pause
