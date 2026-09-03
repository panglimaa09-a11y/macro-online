@echo off
title Macro Online
cd /d "%~dp0"

echo ========================================
echo          MACRO ONLINE
echo ========================================
echo.
echo Starting Runtime...
echo.

dotnet run --project "Runtime\MacroOnline.Runtime.csproj"

pause
