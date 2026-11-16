@echo off
title PeakCut Setup for Windows
cd /d "%~dp0..\.."
echo ==========================================================
echo   PeakCut Windows Automated Setup
echo ==========================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
echo.
pause
