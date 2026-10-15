@echo off
setlocal
title Wand Gaming Account Setup
echo Wand Enhancer - Gaming account setup
echo Double-click this from Gaming. Administrator approval is requested at the patch step.
echo.
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-GamingSetup.ps1"
set "setupExit=%ERRORLEVEL%"
echo.
if not "%setupExit%"=="0" echo Setup stopped. Read the message above before retrying.
pause
exit /b %setupExit%
