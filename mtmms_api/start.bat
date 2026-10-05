@echo off
setlocal enabledelayedexpansion
echo ========================================
echo  MTMMS Python Backend Startup
echo ========================================

:: Refresh PATH so Python is found
set "PATH=%PATH%;%LOCALAPPDATA%\Programs\Python\Python312;%LOCALAPPDATA%\Programs\Python\Python312\Scripts;%LOCALAPPDATA%\Programs\Python\Python311;%LOCALAPPDATA%\Programs\Python\Python311\Scripts"

cd /d "%~dp0"

:: Check Python
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python not found. Please install Python 3.10+ and add it to PATH.
    pause
    exit /b 1
)

:: Install packages if needed
echo Installing/verifying packages...
python -m pip install -r requirements.txt --quiet

:: Check DB connection then run migrations
echo Running migrations...
python manage.py migrate --run-syncdb 2>nul

set PORT=%1
if "%PORT%"=="" (
    if defined MTMMS_API_PORT (
        set "PORT=%MTMMS_API_PORT%"
    ) else (
        set "PORT=8000"
    )
)

echo.
echo Starting Django server on 0.0.0.0:%PORT%
echo Accessible via local network / Wi-Fi.
echo Press Ctrl+C to stop.
echo.
python manage.py runserver 0.0.0.0:%PORT%
