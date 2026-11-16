@echo off
title Stop PeakCut
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\windows\stop.ps1"
pause
