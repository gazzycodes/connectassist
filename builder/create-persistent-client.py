#!/usr/bin/env python3
"""
ConnectAssist Persistent Client Creator
Creates Windows clients with automatic service installation for persistent access
"""

import os
import sys
import json
import shutil
import zipfile
import tempfile
import urllib.request
from pathlib import Path

def download_rustdesk_binary():
    """Download the latest RustDesk Windows binary"""
    print("📥 Downloading RustDesk Windows binary...")
    
    # RustDesk GitHub releases URL (use a working version)
    download_url = "https://github.com/rustdesk/rustdesk/releases/download/1.2.3/rustdesk-1.2.3-x86_64.exe"
    
    # Create downloads directory
    downloads_dir = Path("downloads")
    downloads_dir.mkdir(exist_ok=True)
    
    binary_path = downloads_dir / "rustdesk-windows.exe"
    
    try:
        urllib.request.urlretrieve(download_url, binary_path)
        print(f"✅ Downloaded: {binary_path}")
        return binary_path
    except Exception as e:
        print(f"❌ Download failed: {e}")
        return None

def create_persistent_client_package(support_code=None, customer_info=None):
    """Create a persistent client package with service installation"""
    print("🔧 Creating persistent ConnectAssist client package...")
    
    # Load configuration
    config_path = Path("builder-config.json")
    if not config_path.exists():
        print("❌ builder-config.json not found")
        return None
    
    with open(config_path, 'r') as f:
        config = json.load(f)
    
    # Create output directory
    output_dir = Path("output") / "persistent-client"
    if output_dir.exists():
        shutil.rmtree(output_dir)
    output_dir.mkdir(parents=True)
    
    # Download RustDesk binary if not exists
    binary_path = Path("downloads/rustdesk-windows.exe")
    if not binary_path.exists():
        binary_path = download_rustdesk_binary()
        if not binary_path:
            return None
    
    # Copy RustDesk binary to output
    client_exe = output_dir / "connectassist-windows.exe"
    shutil.copy2(binary_path, client_exe)
    print(f"✅ Client executable: {client_exe}")
    
    # Copy service installation scripts
    script_files = [
        "install-service.ps1",
        "install-connectassist.bat"
    ]
    
    for script_file in script_files:
        src_path = Path(script_file)
        if src_path.exists():
            dst_path = output_dir / script_file
            shutil.copy2(src_path, dst_path)
            print(f"✅ Copied: {script_file}")
    
    # Create client configuration file
    client_config = {
        "server": config["domain"],
        "relay_server": f"{config['domain']}:21117",
        "signal_server": f"{config['domain']}:21115",
        "api_server": f"https://{config['domain']}",
        "permanent_password": config.get("unattended_password", "ConnectAssist2024!"),
        "auto_connect": True,
        "unattended_access": True,
        "install_service": True,
        "auto_start": True,
        "start_minimized": True,
        "service_name": "ConnectAssist Remote Support",
        "support_code": support_code,
        "customer_info": customer_info
    }
    
    config_file = output_dir / "connectassist-config.json"
    with open(config_file, 'w') as f:
        json.dump(client_config, f, indent=2)
    print(f"✅ Configuration: {config_file}")
    
    # Create customer instructions
    instructions = f"""# ConnectAssist Remote Support Installation

## IMPORTANT: This will install persistent remote support access

### What this does:
- Installs ConnectAssist as a Windows service
- Starts automatically when your computer boots
- Runs quietly in the background
- Allows your technician to connect for support

### Installation Steps:
1. **Right-click** on 'install-connectassist.bat'
2. **Select** "Run as administrator"
3. **Click "Yes"** when Windows asks for permission
4. **Follow** the on-screen instructions
5. **Wait** for "Installation completed successfully!" message

### After Installation:
- ConnectAssist runs automatically in the background
- Your technician can connect when you need support
- No further action needed from you
- The service starts automatically when you restart your computer

### Security:
- Only authorized technicians with correct credentials can connect
- All connections are encrypted and secure
- You can uninstall anytime if needed

### Support Information:
- Server: {config['domain']}
- Support Code: {support_code or 'N/A'}
- Customer: {customer_info or 'N/A'}

### Need Help?
Contact your technician for assistance with installation.

### To Uninstall:
1. Press Windows + R
2. Type: cmd
3. Right-click "Command Prompt" and select "Run as administrator"
4. Type: sc delete ConnectAssistService
5. Press Enter

---
ConnectAssist Remote Support - Secure, Professional, Reliable
"""
    
    instructions_file = output_dir / "INSTALLATION-INSTRUCTIONS.txt"
    with open(instructions_file, 'w') as f:
        f.write(instructions)
    print(f"✅ Instructions: {instructions_file}")
    
    # Create a simple launcher script that configures RustDesk before service installation
    launcher_script = f"""@echo off
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
reg add "HKCU\\Software\\RustDesk\\config" /v "custom-rendezvous-server" /t REG_SZ /d "{config['domain']}" /f >nul 2>&1
reg add "HKCU\\Software\\RustDesk\\config" /v "relay-server" /t REG_SZ /d "{config['domain']}:21117" /f >nul 2>&1
reg add "HKCU\\Software\\RustDesk\\config" /v "api-server" /t REG_SZ /d "https://{config['domain']}" /f >nul 2>&1

REM Set permanent password
reg add "HKCU\\Software\\RustDesk\\config" /v "permanent_password" /t REG_SZ /d "{config.get('unattended_password', 'ConnectAssist2024!')}" /f >nul 2>&1

REM Enable unattended access
reg add "HKCU\\Software\\RustDesk\\config" /v "enable-unattended-access" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\\Software\\RustDesk\\config" /v "enable-auto-connect" /t REG_DWORD /d 1 /f >nul 2>&1

echo  [SUCCESS] ConnectAssist configured successfully
echo.

REM Now run the service installation
echo  [INFO] Starting service installation...
echo.
call install-connectassist.bat
"""
    
    launcher_file = output_dir / "setup-connectassist.bat"
    with open(launcher_file, 'w', encoding='utf-8') as f:
        f.write(launcher_script)
    print(f"✅ Launcher: {launcher_file}")
    
    # Create ZIP package for easy distribution
    zip_path = Path("output") / f"ConnectAssist-Persistent-Client-{support_code or 'Generic'}.zip"
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for file_path in output_dir.rglob('*'):
            if file_path.is_file():
                arcname = file_path.relative_to(output_dir)
                zipf.write(file_path, arcname)
    
    print(f"✅ Package created: {zip_path}")
    
    return {
        "package_path": str(zip_path),
        "output_dir": str(output_dir),
        "client_exe": str(client_exe),
        "config": client_config
    }

def main():
    """Main function"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Create persistent ConnectAssist client")
    parser.add_argument("--support-code", help="Support code for this client")
    parser.add_argument("--customer-info", help="Customer information")
    
    args = parser.parse_args()
    
    result = create_persistent_client_package(
        support_code=args.support_code,
        customer_info=args.customer_info
    )
    
    if result:
        print("\n🎉 Persistent ConnectAssist client created successfully!")
        print(f"📦 Package: {result['package_path']}")
        print(f"📁 Files: {result['output_dir']}")
        print("\n📋 Customer Instructions:")
        print("1. Extract the ZIP file")
        print("2. Right-click 'setup-connectassist.bat' and select 'Run as administrator'")
        print("3. Follow the installation prompts")
        print("4. ConnectAssist will be installed as a persistent service")
        print("\n✅ After installation, technicians can connect anytime without customer interaction!")
    else:
        print("❌ Failed to create persistent client package")
        sys.exit(1)

if __name__ == "__main__":
    main()
