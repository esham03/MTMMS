@echo off
title MTMMS Desktop Dev Runner
cd /d "%~dp0web"
echo Starting MTMMS Desktop (Vite + Electron)...
call npm run electron:dev
pause
