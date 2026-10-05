@echo off
title MTMMS Firewall Rule Configuration
echo ========================================================
echo  MTMMS Windows Defender Firewall Configuration
echo ========================================================
echo.
echo Requesting administrator privileges...

:: Check for administrative rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Elevating to Administrator...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo [1/4] Adding inbound rule for Django REST API (TCP 8000)...
netsh advfirewall firewall delete rule name="MTMMS-Django-API" >nul 2>&1
netsh advfirewall firewall add rule name="MTMMS-Django-API" dir=in action=allow protocol=TCP localport=8000 profile=any >nul
if %errorlevel% equ 0 (
    echo [OK] Django REST API port 8000 opened.
) else (
    echo [WARNING] Could not add rule for port 8000.
)

echo [2/4] Adding inbound rule for React/Vite Web Portal (TCP 5174)...
netsh advfirewall firewall delete rule name="MTMMS-Web-Portal-5174" >nul 2>&1
netsh advfirewall firewall add rule name="MTMMS-Web-Portal-5174" dir=in action=allow protocol=TCP localport=5174 profile=any >nul
if %errorlevel% equ 0 (
    echo [OK] Web Portal port 5174 opened.
) else (
    echo [WARNING] Could not add rule for port 5174.
)

echo [3/4] Adding inbound rule for Alternate Web Port (TCP 5173)...
netsh advfirewall firewall delete rule name="MTMMS-Web-Portal-5173" >nul 2>&1
netsh advfirewall firewall add rule name="MTMMS-Web-Portal-5173" dir=in action=allow protocol=TCP localport=5173 profile=any >nul
if %errorlevel% equ 0 (
    echo [OK] Web Portal port 5173 opened.
) else (
    echo [WARNING] Could not add rule for port 5173.
)

echo [4/4] Adding inbound rule for LAN Server Discovery (UDP 41588)...
netsh advfirewall firewall delete rule name="MTMMS-UDP-Discovery" >nul 2>&1
netsh advfirewall firewall add rule name="MTMMS-UDP-Discovery" dir=in action=allow protocol=UDP localport=41588 profile=any >nul
if %errorlevel% equ 0 (
    echo [OK] UDP Server Discovery port 41588 opened.
) else (
    echo [WARNING] Could not add rule for UDP port 41588.
)

echo.
echo ========================================================
echo [SUCCESS] Windows Defender Firewall rules created!
echo Other devices on your Wi-Fi/LAN can now connect to MTMMS.
echo ========================================================
echo.
pause
