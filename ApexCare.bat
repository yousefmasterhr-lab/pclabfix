@echo off
setlocal
title ApexCare Engine (Beast Edition)

:: ApexCare.ps1 requests Administrator through a visible UAC prompt.
set "SCRIPT=%~dp0ApexCare.ps1"
if not exist "%SCRIPT%" (
    echo [X] ApexCare.ps1 was not found beside this launcher.
    echo     Expected: "%SCRIPT%"
    pause
    exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
if errorlevel 1 pause
endlocal
