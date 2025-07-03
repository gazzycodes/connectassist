@echo off
REM ConnectAssist Service Installation Batch Script
REM This script provides a simple interface for customers to install ConnectAssist

title ConnectAssist Remote Support Installation

echo.
echo  ====================================================
echo   ConnectAssist Remote Support Installation
echo  ====================================================
echo.
echo  This will install ConnectAssist as a background service
echo  to allow your technician to provide remote support.
echo.
echo  What this does:
echo  - Installs ConnectAssist as a Windows service
echo  - Starts automatically when your computer boots
echo  - Runs quietly in the background
echo  - Allows your technician to connect when needed
echo.
echo  This is SAFE and SECURE:
echo  - Only authorized technicians can connect
echo  - You can uninstall it anytime
echo  - No personal data is accessed without permission
echo.

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo  ✓ Administrator privileges detected
    goto :install
) else (
    echo  ⚠ This installation requires administrator privileges.
    echo.
    echo  Please right-click this file and select "Run as administrator"
    echo  or click "Yes" when Windows asks for permission.
    echo.
    pause
    
    REM Try to restart as administrator
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:install
echo.
echo  📋 Starting installation...
echo.

REM Check if PowerShell is available
powershell -Command "Write-Host 'PowerShell is available'" >nul 2>&1
if %errorLevel% neq 0 (
    echo  ❌ Error: PowerShell is required but not available.
    echo  Please ensure PowerShell is installed on this system.
    pause
    exit /b 1
)

REM Check if ConnectAssist executable exists
if not exist "connectassist-windows.exe" (
    echo  ❌ Error: ConnectAssist executable not found.
    echo  Please ensure 'connectassist-windows.exe' is in the same folder as this installer.
    echo.
    echo  Current folder: %~dp0
    echo.
    pause
    exit /b 1
)

echo  ✓ ConnectAssist executable found
echo  ✓ PowerShell available
echo.

REM Ask for user confirmation
set /p confirm="Do you want to install ConnectAssist Remote Support? (Y/N): "
if /i not "%confirm%"=="Y" (
    echo.
    echo  Installation cancelled by user.
    pause
    exit /b 0
)

echo.
echo  🔧 Installing ConnectAssist service...
echo.

REM Run the PowerShell installation script
powershell -ExecutionPolicy Bypass -File "%~dp0install-service.ps1" -ExecutablePath "%~dp0connectassist-windows.exe"

if %errorLevel% == 0 (
    echo.
    echo  🎉 Installation completed successfully!
    echo.
    echo  ConnectAssist is now running as a background service.
    echo  Your technician can now connect to provide remote support.
    echo.
    echo  The service will start automatically when you restart your computer.
    echo.
) else (
    echo.
    echo  ❌ Installation failed. Please contact your technician for assistance.
    echo.
)

echo  Press any key to close this window...
pause >nul
