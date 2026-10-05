@echo off
setlocal enabledelayedexpansion
title MTMMS Desktop Launcher

set "PROJECT_ROOT=%~dp0"
if "%PROJECT_ROOT:~-1%"=="\" set "PROJECT_ROOT=%PROJECT_ROOT:~0,-1%"

:: Load active runtime configuration from single source of truth
if exist "%PROJECT_ROOT%\.mtmms-runtime.env" (
    for /f "usebackq tokens=1,* delims==" %%A in ("%PROJECT_ROOT%\.mtmms-runtime.env") do (
        if "%%A"=="MTMMS_SERVER_IP" set "MTMMS_SERVER_IP=%%B"
        if "%%A"=="MTMMS_API_PORT" set "MTMMS_API_PORT=%%B"
        if "%%A"=="MTMMS_API_URL" set "MTMMS_API_URL=%%B"
        if "%%A"=="MTMMS_WEB_URL" set "MTMMS_WEB_URL=%%B"
    )
)

if not defined MTMMS_API_URL set "MTMMS_API_URL=http://127.0.0.1:8000/api"

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
