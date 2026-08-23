@echo off
chcp 65001 >nul
title DSH
cd /d "%USERPROFILE%\Desktop"
netstat -ano | findstr ":3080" | findstr "LISTENING" >nul
if not errorlevel 1 goto open
echo 正在启动 DSH 服务（首次约需 10-30 秒）...
start "" /min cmd /c "npx --yes @deepseek-ai/dsh@latest web --no-open"
set tries=0
:wait
timeout /t 1 /nobreak >nul
netstat -ano | findstr ":3080" | findstr "LISTENING" >nul
if not errorlevel 1 goto open
set /a tries+=1
if %tries% lss 90 goto wait
echo 启动超时，请检查网络后重试。
pause
exit /b
:open
start "" "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" --app=http://127.0.0.1:3080