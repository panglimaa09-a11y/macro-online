@echo off
title Macro Online - Runtime Launcher
setlocal
cd /d "%~dp0"

echo ========================================
echo          MACRO ONLINE
echo ========================================
echo.
echo Starting Runtime + Engine + Tunnel...
echo.

set "RUNTIME_PS1=%~dp0Runtime\START-PUBLIC-RUNTIME.ps1"
if not exist "%RUNTIME_PS1%" (
    echo [ERROR] Runtime launcher tidak ditemukan:
    echo %RUNTIME_PS1%
    echo.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%RUNTIME_PS1%"
set "EXITCODE=%ERRORLEVEL%"

echo.
echo Runtime berhenti. Exit code: %EXITCODE%
pause
exit /b %EXITCODE%
