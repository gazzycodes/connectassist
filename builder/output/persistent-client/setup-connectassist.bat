@echo off
REM ConnectAssist Configuration and Service Launcher

title ConnectAssist Setup

echo.
echo  ====================================================
echo   ConnectAssist Remote Support Setup
echo  ====================================================
echo.

REM Configure RustDesk with ConnectAssist settings
echo  [INFO] Configuring ConnectAssist settings...

REM Set server configuration
reg add "HKCU\Software\RustDesk\config" /v "custom-rendezvous-server" /t REG_SZ /d "connectassist.live" /f >nul 2>&1
reg add "HKCU\Software\RustDesk\config" /v "relay-server" /t REG_SZ /d "connectassist.live:21117" /f >nul 2>&1
reg add "HKCU\Software\RustDesk\config" /v "api-server" /t REG_SZ /d "https://connectassist.live" /f >nul 2>&1

REM Set permanent password
reg add "HKCU\Software\RustDesk\config" /v "permanent_password" /t REG_SZ /d "ConnectAssist2024!" /f >nul 2>&1

REM Enable unattended access
reg add "HKCU\Software\RustDesk\config" /v "enable-unattended-access" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\RustDesk\config" /v "enable-auto-connect" /t REG_DWORD /d 1 /f >nul 2>&1

echo  [SUCCESS] ConnectAssist configured successfully
echo.

REM Now run the service installation
echo  [INFO] Starting service installation...
echo.
call install-connectassist.bat
