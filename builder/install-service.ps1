# ConnectAssist Service Installation Script
# This script installs ConnectAssist as a persistent Windows service

param(
    [string]$ServiceName = "ConnectAssistService",
    [string]$DisplayName = "ConnectAssist Remote Support",
    [string]$Description = "ConnectAssist remote support service for technical assistance",
    [string]$ExecutablePath = "",
    [string]$PermanentPassword = "ConnectAssist2024!",
    [string]$ServerHost = "connectassist.live"
)

# Ensure running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrator privileges. Restarting as administrator..." -ForegroundColor Yellow
    Start-Process PowerShell -Verb RunAs "-File `"$PSCommandPath`" $args"
    exit
}

Write-Host "🔗 ConnectAssist Service Installation" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

# Get the current executable path if not provided
if ([string]::IsNullOrEmpty($ExecutablePath)) {
    $ExecutablePath = $MyInvocation.MyCommand.Path -replace '\.ps1$', '.exe'
    if (-not (Test-Path $ExecutablePath)) {
        $ExecutablePath = Join-Path (Get-Location) "connectassist-windows.exe"
    }
}

Write-Host "Executable Path: $ExecutablePath" -ForegroundColor Green

# Check if executable exists
if (-not (Test-Path $ExecutablePath)) {
    Write-Host "❌ Error: ConnectAssist executable not found at: $ExecutablePath" -ForegroundColor Red
    Write-Host "Please ensure the ConnectAssist client is in the same directory as this script." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Stop existing service if running
Write-Host "🛑 Stopping existing ConnectAssist service (if running)..." -ForegroundColor Yellow
try {
    $existingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($existingService) {
        Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Existing service stopped" -ForegroundColor Green
    }
} catch {
    Write-Host "ℹ️ No existing service found" -ForegroundColor Gray
}

# Remove existing service if it exists
Write-Host "🗑️ Removing existing service registration..." -ForegroundColor Yellow
try {
    $service = Get-WmiObject -Class Win32_Service -Filter "Name='$ServiceName'"
    if ($service) {
        $service.Delete()
        Write-Host "✅ Existing service removed" -ForegroundColor Green
    }
} catch {
    Write-Host "ℹ️ No existing service registration found" -ForegroundColor Gray
}

# Create the service
Write-Host "🔧 Installing ConnectAssist as Windows service..." -ForegroundColor Yellow
try {
    $serviceArgs = "--service --password `"$PermanentPassword`" --server `"$ServerHost`""
    
    New-Service -Name $ServiceName `
                -DisplayName $DisplayName `
                -Description $Description `
                -BinaryPathName "`"$ExecutablePath`" $serviceArgs" `
                -StartupType Automatic `
                -ErrorAction Stop
    
    Write-Host "✅ Service installed successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Error installing service: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Configure service recovery options
Write-Host "⚙️ Configuring service recovery options..." -ForegroundColor Yellow
try {
    # Set service to restart on failure
    sc.exe failure $ServiceName reset= 86400 actions= restart/5000/restart/10000/restart/30000
    Write-Host "✅ Service recovery configured" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Warning: Could not configure service recovery options" -ForegroundColor Yellow
}

# Add firewall exception
Write-Host "🔥 Adding Windows Firewall exception..." -ForegroundColor Yellow
try {
    $firewallRuleName = "ConnectAssist Remote Support"
    
    # Remove existing rule if it exists
    Remove-NetFirewallRule -DisplayName $firewallRuleName -ErrorAction SilentlyContinue
    
    # Add new firewall rule
    New-NetFirewallRule -DisplayName $firewallRuleName `
                        -Direction Inbound `
                        -Program $ExecutablePath `
                        -Action Allow `
                        -Profile Any `
                        -ErrorAction Stop
    
    Write-Host "✅ Firewall exception added" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Warning: Could not add firewall exception: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Add registry entries for persistence
Write-Host "📝 Adding registry entries for persistence..." -ForegroundColor Yellow
try {
    $registryPath = "HKLM:\SOFTWARE\ConnectAssist"
    
    # Create registry key if it doesn't exist
    if (-not (Test-Path $registryPath)) {
        New-Item -Path $registryPath -Force | Out-Null
    }
    
    # Set registry values
    Set-ItemProperty -Path $registryPath -Name "ServiceInstalled" -Value "True"
    Set-ItemProperty -Path $registryPath -Name "InstallDate" -Value (Get-Date).ToString()
    Set-ItemProperty -Path $registryPath -Name "ServerHost" -Value $ServerHost
    Set-ItemProperty -Path $registryPath -Name "Version" -Value "1.0.0"
    
    Write-Host "✅ Registry entries created" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Warning: Could not create registry entries: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Start the service
Write-Host "🚀 Starting ConnectAssist service..." -ForegroundColor Yellow
try {
    Start-Service -Name $ServiceName -ErrorAction Stop
    
    # Wait a moment and check service status
    Start-Sleep -Seconds 3
    $serviceStatus = Get-Service -Name $ServiceName
    
    if ($serviceStatus.Status -eq "Running") {
        Write-Host "✅ ConnectAssist service started successfully" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Warning: Service installed but not running. Status: $($serviceStatus.Status)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Error starting service: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "The service is installed but failed to start. You may need to start it manually." -ForegroundColor Yellow
}

# Display installation summary
Write-Host ""
Write-Host "🎉 ConnectAssist Installation Complete!" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green
Write-Host "Service Name: $ServiceName" -ForegroundColor White
Write-Host "Display Name: $DisplayName" -ForegroundColor White
Write-Host "Status: $($(Get-Service -Name $ServiceName).Status)" -ForegroundColor White
Write-Host "Startup Type: Automatic" -ForegroundColor White
Write-Host "Server: $ServerHost" -ForegroundColor White
Write-Host ""
Write-Host "✅ ConnectAssist is now installed as a persistent service" -ForegroundColor Green
Write-Host "✅ The service will start automatically when Windows boots" -ForegroundColor Green
Write-Host "✅ Technicians can now connect remotely without user interaction" -ForegroundColor Green
Write-Host "✅ The service runs in the background (hidden from user)" -ForegroundColor Green
Write-Host ""
Write-Host "🔒 Security: Only authorized technicians with the correct credentials can connect" -ForegroundColor Cyan
Write-Host ""
Write-Host "To uninstall: Run 'sc delete $ServiceName' as administrator" -ForegroundColor Gray
Write-Host ""

# Keep window open for user to read
Write-Host "Press Enter to close this window..." -ForegroundColor Yellow
Read-Host
