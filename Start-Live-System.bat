@echo off
setlocal enabledelayedexpansion
title MTMMS Live System Launcher

:: ========================================================
:: 1. DYNAMIC PROJECT ROOT DETECTION
:: ========================================================
set "PROJECT_ROOT=%~dp0"
if "%PROJECT_ROOT:~-1%"=="\" set "PROJECT_ROOT=%PROJECT_ROOT:~0,-1%"
cd /d "%PROJECT_ROOT%"

cls
echo ================================================================
echo                   MTMMS LIVE SYSTEM INITIALIZATION
echo ================================================================
echo.
echo [1/6] Verifying Project Environment and Toolchains...
echo       Project Root: %PROJECT_ROOT%

:: Refresh user PATH for standard Python and Node install locations if not present
if exist "%LOCALAPPDATA%\Programs\Python\Python312" set "PATH=!PATH!;%LOCALAPPDATA%\Programs\Python\Python312;%LOCALAPPDATA%\Programs\Python\Python312\Scripts"
if exist "%LOCALAPPDATA%\Programs\Python\Python311" set "PATH=!PATH!;%LOCALAPPDATA%\Programs\Python\Python311;%LOCALAPPDATA%\Programs\Python\Python311\Scripts"
if exist "%ProgramFiles%\nodejs" set "PATH=!PATH!;%ProgramFiles%\nodejs"
if exist "%ProgramFiles(x86)%\nodejs" set "PATH=!PATH!;%ProgramFiles(x86)%\nodejs"
if exist "%APPDATA%\npm" set "PATH=!PATH!;%APPDATA%\npm"

:: ========================================================
:: 2. DEPENDENCY CHECKS
:: ========================================================
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python was not found in PATH!
    echo Please install Python 3.10+ and check "Add Python to PATH" during installation.
    pause
    exit /b 1
)

python -m pip --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] pip was not found!
    pause
    exit /b 1
)

node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Node.js was not found in PATH!
    echo Please install Node.js 18+ to run the React/Vite web application.
    pause
    exit /b 1
)

call npm --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] npm was not found in PATH!
    pause
    exit /b 1
)

echo [OK] Python, Pip, Node.js, and npm detected.

:: Verify Django & Required Python Packages
echo [2/6] Verifying Django and Python dependencies...
python -c "import django, rest_framework, corsheaders" >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] Installing required Python dependencies...
    python -m pip install -r "%PROJECT_ROOT%\mtmms_api\requirements.txt" --quiet
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to install required Python dependencies from requirements.txt!
        pause
        exit /b 1
    )
)
echo [OK] Django and API dependencies verified.

:: Verify Node dependencies in web folder
if exist "%PROJECT_ROOT%\web\package.json" (
    if not exist "%PROJECT_ROOT%\web\node_modules" (
        echo [INFO] Installing web portal node dependencies - first-time setup...
        cd /d "%PROJECT_ROOT%\web" && call npm install --quiet
        cd /d "%PROJECT_ROOT%"
    )
)

:: Test MySQL connectivity
python -c "import sys; sys.path.insert(0, r'%PROJECT_ROOT%\mtmms_api'); import os, django; os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'mtmms_project.settings'); django.setup(); from django.db import connection; connection.cursor()" >nul 2>&1
if !errorlevel! neq 0 (
    echo [WARNING] MySQL database connection could not be established.
    echo Please ensure MySQL / MariaDB service is running and database 'mtmms' exists.
    echo Continuing startup attempt...
) else (
    echo [OK] MySQL database connection verified.
)

:: Run Syncdb / Migrations
python "%PROJECT_ROOT%\mtmms_api\manage.py" migrate --run-syncdb >nul 2>&1

:: ========================================================
:: 3. DYNAMIC LAN IP DETECTION & RUNTIME CONFIG GENERATION
:: ========================================================
echo [3/6] Detecting active LAN / Wi-Fi IPv4 address...

python "%PROJECT_ROOT%\mtmms_api\network_utils.py" generate "%PROJECT_ROOT%" >nul 2>&1
if !errorlevel! neq 0 (
    echo [ERROR] Failed to dynamically detect network IP.
    pause
    exit /b 1
)

:: Read generated variables from single source of truth (.mtmms-runtime.env)
set "MTMMS_SERVER_IP=127.0.0.1"
set "MTMMS_API_PORT=8000"
set "MTMMS_API_URL=http://127.0.0.1:8000/api"
set "MTMMS_WEB_PORT=5174"
set "MTMMS_WEB_URL=http://127.0.0.1:5174"
set "MTMMS_HEALTH_URL=http://127.0.0.1:8000/api/health/"

if exist "%PROJECT_ROOT%\.mtmms-runtime.env" (
    for /f "usebackq tokens=1,* delims==" %%A in ("%PROJECT_ROOT%\.mtmms-runtime.env") do (
        if "%%A"=="MTMMS_SERVER_IP" set "MTMMS_SERVER_IP=%%B"
        if "%%A"=="MTMMS_API_PORT" set "MTMMS_API_PORT=%%B"
        if "%%A"=="MTMMS_API_URL" set "MTMMS_API_URL=%%B"
        if "%%A"=="MTMMS_WEB_PORT" set "MTMMS_WEB_PORT=%%B"
        if "%%A"=="MTMMS_WEB_URL" set "MTMMS_WEB_URL=%%B"
        if "%%A"=="MTMMS_HEALTH_URL" set "MTMMS_HEALTH_URL=%%B"
    )
)

echo [OK] Detected Active LAN IP: %MTMMS_SERVER_IP%
echo [OK] Generated .mtmms-runtime.env, web\.env, and Flutter server_config.dart

:: ========================================================
:: 4. WINDOWS DEFENDER FIREWALL RULES CHECK
:: ========================================================
netsh advfirewall firewall show rule name="MTMMS-Django-API" >nul 2>&1
if !errorlevel! neq 0 (
    echo [INFO] Attempting to configure Windows Firewall rules...
    netsh advfirewall firewall add rule name="MTMMS-Django-API" dir=in action=allow protocol=TCP localport=8000 profile=any >nul 2>&1
    netsh advfirewall firewall add rule name="MTMMS-Web-Portal-5174" dir=in action=allow protocol=TCP localport=5174 profile=any >nul 2>&1
    netsh advfirewall firewall add rule name="MTMMS-Web-Portal-5173" dir=in action=allow protocol=TCP localport=5173 profile=any >nul 2>&1
    netsh advfirewall firewall add rule name="MTMMS-UDP-Discovery" dir=in action=allow protocol=UDP localport=41588 profile=any >nul 2>&1
)

:: ========================================================
:: 5. START SERVER SERVICES
:: ========================================================
echo [4/6] Starting Django REST API on 0.0.0.0:%MTMMS_API_PORT%...
:: Clean up any existing instances or occupied ports
taskkill /F /FI "WINDOWTITLE eq MTMMS Backend API*" >nul 2>&1
taskkill /F /FI "WINDOWTITLE eq MTMMS Discovery Service*" >nul 2>&1
taskkill /F /FI "WINDOWTITLE eq MTMMS Web Portal*" >nul 2>&1
powershell -NoProfile -Command "Get-NetTCPConnection -LocalPort %MTMMS_API_PORT%, %MTMMS_WEB_PORT% -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }" >nul 2>&1
powershell -NoProfile -Command "Get-NetUDPEndpoint -LocalPort 41588 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }" >nul 2>&1

start "MTMMS Backend API (%MTMMS_SERVER_IP%:%MTMMS_API_PORT%)" /min cmd /k "title MTMMS Backend API (%MTMMS_SERVER_IP%:%MTMMS_API_PORT%) && cd /d "%PROJECT_ROOT%\mtmms_api" && python manage.py runserver 0.0.0.0:%MTMMS_API_PORT%"

echo [5/6] Starting LAN Server Discovery Service on UDP 41588...
start "MTMMS Discovery Service (UDP 41588)" /min cmd /k "title MTMMS Discovery Service (UDP 41588) && cd /d "%PROJECT_ROOT%\mtmms_api" && python discovery_service.py %MTMMS_API_PORT% %MTMMS_WEB_PORT%"

echo [6/6] Starting React/Vite Web Portal on 0.0.0.0:%MTMMS_WEB_PORT%...
start "MTMMS Web Portal (%MTMMS_SERVER_IP%:%MTMMS_WEB_PORT%)" /min cmd /k "title MTMMS Web Portal (%MTMMS_SERVER_IP%:%MTMMS_WEB_PORT%) && cd /d "%PROJECT_ROOT%\web" && npm run dev"

:: ========================================================
:: 6. HEALTH CHECK VERIFICATION
:: ========================================================
echo.
echo Verifying system health and connectivity...
set /a attempts=0
:health_loop
set /a attempts+=1
ping 127.0.0.1 -n 2 >nul
python "%PROJECT_ROOT%\mtmms_api\network_utils.py" health "%MTMMS_HEALTH_URL%" >nul 2>&1
if !errorlevel! equ 0 (
    goto health_success
)
if %attempts% lss 15 (
    echo Waiting for API to become ready... attempt %attempts% of 15
    goto health_loop
)

echo [WARNING] API health check did not respond within expected time.
echo Possible causes:
echo - Django is still compiling / starting up
echo - MySQL server is stopped or misconfigured
echo - Port %MTMMS_API_PORT% is already occupied by another program
echo - Windows Firewall blocked the connection
echo Run Setup-Firewall.bat as Administrator if mobile devices cannot connect.
goto display_banner

:health_success
echo [OK] Django API is running.
echo [OK] LAN connection verified.

:display_banner
cls
echo ================================================================
echo                    MTMMS LIVE SYSTEM
echo ================================================================
echo.
echo [OK] Project root detected
echo [OK] Python detected
echo [OK] MySQL detected
echo [OK] Node.js detected
echo [OK] LAN IP detected
echo.
echo ----------------------------------------------------------------
echo  NETWORK ACCESS ENDPOINTS
echo ----------------------------------------------------------------
echo.
echo   SERVER IP:
echo       %MTMMS_SERVER_IP%
echo.
echo   DJANGO API:
echo       %MTMMS_API_URL%
echo.
echo   WEB APPLICATION:
echo       %MTMMS_WEB_URL%
echo.
echo   HEALTH CHECK:
echo       %MTMMS_HEALTH_URL%
echo.
echo   FLUTTER API:
echo       %MTMMS_API_URL%
echo.
echo   SERVER DISCOVERY:
echo       UDP Port 41588 (Active)
echo.
echo ================================================================
echo  Connect your mobile phone or other laptops to the SAME Wi-Fi.
echo  The Flutter APK will AUTOMATICALLY discover this computer!
echo ================================================================
echo.
echo Options:
echo   [1] Open Web Application in Default Browser
echo   [2] Launch Electron Desktop Application
echo   [3] Test API Health Check Endpoint
echo   [4] Configure Windows Firewall (Run as Admin)
echo   [5] Stop / Shutdown All MTMMS Services
echo   [Q] Quit Launcher Menu (Leave Services Running)
echo.

:menu_loop
set "choice="
set /p choice="Select an option (1-5, Q): "
if not defined choice (
    ping 127.0.0.1 -n 2 >nul
    goto menu_loop
)
set "choice=!choice: =!"
if /i "!choice!"=="1" (
    start "" "%MTMMS_WEB_URL%"
    goto display_banner
)
if /i "!choice!"=="2" (
    call "%PROJECT_ROOT%\Launch-Desktop-App.bat"
    goto display_banner
)
if /i "!choice!"=="3" (
    start "" "%MTMMS_HEALTH_URL%"
    goto display_banner
)
if /i "!choice!"=="4" (
    call "%PROJECT_ROOT%\Setup-Firewall.bat"
    goto display_banner
)
if /i "!choice!"=="5" (
    call "%PROJECT_ROOT%\Stop-System.bat"
    exit /b
)
if /i "!choice!"=="Q" (
    echo MTMMS services remain running in background.
    exit /b
)
goto menu_loop
