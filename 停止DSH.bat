@echo off
chcp 65001 >nul
title 停止 DSH
netstat -ano | findstr ":3080 " | findstr "LISTENING" >nul
if errorlevel 1 (
  echo DSH 服务未在运行。
  pause
  exit /b
)
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":3080 " ^| findstr "LISTENING"') do taskkill /f /pid %%a >nul 2>&1
echo DSH 服务已停止。
pause
