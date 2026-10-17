@echo off
setlocal enabledelayedexpansion
title MTMMS Desktop Launcher

set "PROJECT_ROOT=%~dp0"
if "%PROJECT_ROOT:~-1%"=="\" set "PROJECT_ROOT=%PROJECT_ROOT:~0,-1%"

:: Clean up any existing instances of Electron to prevent disk cache lock collisions
taskkill /F /IM "MTMMS Desktop.exe" >nul 2>&1
taskkill /F /FI "WINDOWTITLE eq MTMMS Desktop*" >nul 2>&1

:: Load active runtime configuration from single source of truth
set "MTMMS_API_PORT=8000"
if exist "%PROJECT_ROOT%\.mtmms-runtime.env" (
    for /f "usebackq tokens=1,* delims==" %%A in ("%PROJECT_ROOT%\.mtmms-runtime.env") do (
        if "%%A"=="MTMMS_API_PORT" set "MTMMS_API_PORT=%%B"
    )
)

:: For the local desktop application running on this host PC, always use loopback (127.0.0.1)
:: to ensure instant response without dependency on router NAT hairpinning or hotspot isolation.
set "MTMMS_API_URL=http://127.0.0.1:%MTMMS_API_PORT%/api"

echo ========================================================
echo         MTMMS DESKTOP APPLICATION LAUNCHER
echo ========================================================
echo Connecting Desktop Client to MTMMS API:
echo   %MTMMS_API_URL%
echo.

set "DESKTOP_EXE=%PROJECT_ROOT%\web\dist-desktop\MTMMS Desktop-win32-x64\MTMMS Desktop.exe"

if exist "%DESKTOP_EXE%" (
    echo Launching standalone MTMMS Desktop application...
    start "" "%DESKTOP_EXE%"
    exit /b 0
)

:: Fallback to running via Electron in web directory
if exist "%PROJECT_ROOT%\web\package.json" (
    echo [INFO] Standalone .exe not found, launching Electron dev runtime...
    cd /d "%PROJECT_ROOT%\web"
    start "MTMMS Desktop" npm run electron:start
    exit /b 0
)

echo [ERROR] MTMMS Desktop application could not be located!
echo Expected path: %DESKTOP_EXE%
pause
exit /b 1
