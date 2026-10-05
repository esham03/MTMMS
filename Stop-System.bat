@echo off
title Stop MTMMS Services
echo ========================================================
echo  Stopping MTMMS Services
echo ========================================================
echo.

echo [1/3] Terminating MTMMS Backend API and Discovery Service...
taskkill /F /FI "WINDOWTITLE eq MTMMS Backend API*" >nul 2>&1
taskkill /F /FI "WINDOWTITLE eq MTMMS Discovery Service*" >nul 2>&1
powershell -NoProfile -Command "Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }" >nul 2>&1
powershell -NoProfile -Command "Get-NetUDPEndpoint -LocalPort 41588 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }" >nul 2>&1

echo [2/3] Terminating MTMMS Web Portal (Vite / Node)...
taskkill /F /FI "WINDOWTITLE eq MTMMS Web Portal*" >nul 2>&1
powershell -NoProfile -Command "Get-NetTCPConnection -LocalPort 5174, 5173 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }" >nul 2>&1

echo [3/3] Terminating MTMMS Desktop instances...
taskkill /F /IM "MTMMS Desktop.exe" >nul 2>&1
taskkill /F /IM "electron.exe" >nul 2>&1

echo.
echo [OK] All MTMMS services stopped successfully.
echo ========================================================
pause
