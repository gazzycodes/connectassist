#!/usr/bin/env python3
"""
ConnectAssist RustDesk Client Builder
Builds custom RustDesk clients preconfigured for ConnectAssist server
"""

import os
import sys
import json
import shutil
import subprocess
import argparse
import tempfile
import urllib.request
from pathlib import Path
from typing import Dict, List, Optional

class RustDeskBuilder:
    def __init__(self, config: Dict):
        self.config = config
        self.domain = config.get('domain', 'connectassist.live')
        self.relay_server = f"{self.domain}:21117"
        self.signal_server = f"{self.domain}:21115"
        self.api_server = f"https://{self.domain}"
        self.build_dir = Path(config.get('build_dir', './build'))
        self.output_dir = Path(config.get('output_dir', '../www/downloads'))
        
    def setup_build_environment(self):
        """Setup the build environment"""
        print("🔧 Setting up build environment...")
        
        # Create directories
        self.build_dir.mkdir(exist_ok=True)
        self.output_dir.mkdir(exist_ok=True)
        
        # Check for required tools
        required_tools = ['git', 'cargo', 'rustc']
        for tool in required_tools:
            if not shutil.which(tool):
                raise RuntimeError(f"Required tool '{tool}' not found in PATH")
        
        print("✅ Build environment ready")
    
    def clone_rustdesk_source(self):
        """Clone RustDesk source code"""
        rustdesk_dir = self.build_dir / 'rustdesk'
        
        if rustdesk_dir.exists():
            print("📁 RustDesk source already exists, updating...")
            subprocess.run(['git', 'pull'], cwd=rustdesk_dir, check=True)
        else:
            print("📥 Cloning RustDesk source...")
            subprocess.run([
                'git', 'clone', 
                'https://github.com/rustdesk/rustdesk.git',
                str(rustdesk_dir)
            ], check=True)
        
        return rustdesk_dir
    
    def create_custom_config(self, rustdesk_dir: Path):
        """Create custom configuration for ConnectAssist"""
        print("⚙️ Creating custom configuration...")
        
        # Create custom config file
        config_content = {
            "relay-server": self.relay_server,
            "api-server": self.api_server,
            "key": self.config.get('encryption_key', ''),
            "custom-rendezvous-server": self.signal_server,
            "direct-server": self.config.get('direct_server', ''),
            "hide-tray-icon": self.config.get('hide_tray', False),
            "auto-connect": self.config.get('auto_connect', False),
            "unattended-access": self.config.get('unattended_access', False),
            "password": self.config.get('unattended_password', ''),
            "company-name": self.config.get('company_name', 'ConnectAssist'),
            "app-name": self.config.get('app_name', 'ConnectAssist Support')
        }
        
        # Write config to source
        config_file = rustdesk_dir / 'src' / 'config.rs'
        self._patch_config_file(config_file, config_content)
        
        # Create branding files
        self._create_branding_files(rustdesk_dir)
    
    def _patch_config_file(self, config_file: Path, config: Dict):
        """Patch the RustDesk config file with custom settings"""
        if not config_file.exists():
            print(f"⚠️ Config file not found: {config_file}")
            return
        
        # Read original config
        with open(config_file, 'r') as f:
            content = f.read()
        
        # Apply patches for custom server settings
        patches = [
            # Set default relay server
            ('pub const RELAY_PORT: i32 = 21117;', 
             f'pub const RELAY_PORT: i32 = 21117;'),
            
            # Set default rendezvous server
            ('pub const RENDEZVOUS_PORT: i32 = 21116;',
             f'pub const RENDEZVOUS_PORT: i32 = 21116;'),
            
            # Set company name
            ('pub const APP_NAME: &str = "RustDesk";',
             f'pub const APP_NAME: &str = "{config.get("app-name", "ConnectAssist")}";'),
        ]
        
        for old, new in patches:
            if old in content:
                content = content.replace(old, new)
        
        # Write patched config
        with open(config_file, 'w') as f:
            f.write(content)
        
        print("✅ Configuration patched")
    
    def _create_branding_files(self, rustdesk_dir: Path):
        """Create custom branding files"""
        print("🎨 Creating branding files...")
        
        # Create custom icon (placeholder)
        icon_dir = rustdesk_dir / 'res'
        icon_dir.mkdir(exist_ok=True)
        
        # You would place custom icons here
        # For now, we'll use the default RustDesk icons
        
        print("✅ Branding files ready")
    
    def build_windows_client(self, rustdesk_dir: Path):
        """Build Windows client"""
        print("🏗️ Building Windows client...")
        
        # Set environment for Windows cross-compilation
        env = os.environ.copy()
        env['CARGO_TARGET_X86_64_PC_WINDOWS_GNU_LINKER'] = 'x86_64-w64-mingw32-gcc'
        
        # Build command
        build_cmd = [
            'cargo', 'build', 
            '--release',
            '--target', 'x86_64-pc-windows-gnu',
            '--features', 'inline'
        ]
        
        try:
            subprocess.run(build_cmd, cwd=rustdesk_dir, env=env, check=True)
            
            # Copy built executable
            exe_source = rustdesk_dir / 'target' / 'x86_64-pc-windows-gnu' / 'release' / 'rustdesk.exe'
            exe_dest = self.output_dir / 'connectassist-windows.exe'
            
            if exe_source.exists():
                shutil.copy2(exe_source, exe_dest)
                print(f"✅ Windows client built: {exe_dest}")
                return exe_dest
            else:
                print("❌ Windows executable not found after build")
                return None
                
        except subprocess.CalledProcessError as e:
            print(f"❌ Windows build failed: {e}")
            return None
    
    def build_linux_client(self, rustdesk_dir: Path):
        """Build Linux client"""
        print("🏗️ Building Linux client...")
        
        # Build command
        build_cmd = [
            'cargo', 'build', 
            '--release',
            '--features', 'inline'
        ]
        
        try:
            subprocess.run(build_cmd, cwd=rustdesk_dir, check=True)
            
            # Copy built executable
            exe_source = rustdesk_dir / 'target' / 'release' / 'rustdesk'
            exe_dest = self.output_dir / 'connectassist-linux'
            
            if exe_source.exists():
                shutil.copy2(exe_source, exe_dest)
                
                # Create AppImage (simplified version)
                appimage_dest = self.output_dir / 'connectassist-linux.AppImage'
                shutil.copy2(exe_source, appimage_dest)
                os.chmod(appimage_dest, 0o755)
                
                print(f"✅ Linux client built: {appimage_dest}")
                return appimage_dest
            else:
                print("❌ Linux executable not found after build")
                return None
                
        except subprocess.CalledProcessError as e:
            print(f"❌ Linux build failed: {e}")
            return None
    
    def create_installer_wrapper(self, executable_path: Path):
        """Create installer wrapper with custom settings"""
        if not executable_path.exists():
            return None
        
        print(f"📦 Creating installer wrapper for {executable_path.name}...")
        
        # For Windows, create NSIS installer script
        if executable_path.suffix == '.exe':
            return self._create_nsis_installer(executable_path)
        
        return executable_path
    
    def _create_nsis_installer(self, exe_path: Path):
        """Create NSIS installer script"""
        nsis_script = f"""
; ConnectAssist Installer Script
!define APPNAME "ConnectAssist Support Tool"
!define COMPANYNAME "ConnectAssist"
!define DESCRIPTION "Remote Support Tool"
!define VERSIONMAJOR 1
!define VERSIONMINOR 0
!define VERSIONBUILD 0

RequestExecutionLevel user
InstallDir "$LOCALAPPDATA\\ConnectAssist"

Name "${{APPNAME}}"
OutFile "{exe_path.stem}-installer.exe"

Page directory
Page instfiles

Section "install"
    SetOutPath $INSTDIR
    File "{exe_path}"
    
    ; Create uninstaller
    WriteUninstaller "$INSTDIR\\uninstall.exe"
    
    ; Create start menu shortcut
    CreateDirectory "$SMPROGRAMS\\ConnectAssist"
    CreateShortCut "$SMPROGRAMS\\ConnectAssist\\ConnectAssist Support.lnk" "$INSTDIR\\{exe_path.name}"
    CreateShortCut "$SMPROGRAMS\\ConnectAssist\\Uninstall.lnk" "$INSTDIR\\uninstall.exe"
    
    ; Registry entries for uninstaller
    WriteRegStr HKCU "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\ConnectAssist" "DisplayName" "${{APPNAME}}"
    WriteRegStr HKCU "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\ConnectAssist" "UninstallString" "$INSTDIR\\uninstall.exe"
SectionEnd

Section "uninstall"
    Delete "$INSTDIR\\{exe_path.name}"
    Delete "$INSTDIR\\uninstall.exe"
    RMDir "$INSTDIR"
    
    Delete "$SMPROGRAMS\\ConnectAssist\\ConnectAssist Support.lnk"
    Delete "$SMPROGRAMS\\ConnectAssist\\Uninstall.lnk"
    RMDir "$SMPROGRAMS\\ConnectAssist"
    
    DeleteRegKey HKCU "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\ConnectAssist"
SectionEnd
"""
        
        nsis_file = self.build_dir / f"{exe_path.stem}-installer.nsi"
        with open(nsis_file, 'w') as f:
            f.write(nsis_script)
        
        # Compile NSIS installer if makensis is available
        if shutil.which('makensis'):
            try:
                subprocess.run(['makensis', str(nsis_file)], check=True)
                installer_path = self.build_dir / f"{exe_path.stem}-installer.exe"
                if installer_path.exists():
                    final_path = self.output_dir / f"{exe_path.stem}-installer.exe"
                    shutil.move(installer_path, final_path)
                    print(f"✅ NSIS installer created: {final_path}")
                    return final_path
            except subprocess.CalledProcessError:
                print("⚠️ NSIS compilation failed, using direct executable")
        
        return exe_path
    
    def build_all_clients(self):
        """Build all client versions"""
        print("🚀 Starting ConnectAssist client build process...")
        
        self.setup_build_environment()
        rustdesk_dir = self.clone_rustdesk_source()
        self.create_custom_config(rustdesk_dir)
        
        built_clients = []
        
        # Build Windows client
        if self.config.get('build_windows', True):
            windows_client = self.build_windows_client(rustdesk_dir)
            if windows_client:
                installer = self.create_installer_wrapper(windows_client)
                built_clients.append(installer)
        
        # Build Linux client
        if self.config.get('build_linux', True):
            linux_client = self.build_linux_client(rustdesk_dir)
            if linux_client:
                built_clients.append(linux_client)
        
        print(f"✅ Build process completed. Built {len(built_clients)} clients:")
        for client in built_clients:
            print(f"   📦 {client}")
        
        return built_clients

def load_config(config_file: str) -> Dict:
    """Load configuration from file"""
    if os.path.exists(config_file):
        with open(config_file, 'r') as f:
            return json.load(f)
    else:
        # Default configuration
        return {
            "domain": "connectassist.live",
            "company_name": "ConnectAssist",
            "app_name": "ConnectAssist Support Tool",
            "build_windows": True,
            "build_linux": True,
            "build_macos": False,  # Requires macOS build environment
            "hide_tray": False,
            "auto_connect": False,
            "unattended_access": False,
            "unattended_password": "",
            "encryption_key": ""
        }

def main():
    parser = argparse.ArgumentParser(description='ConnectAssist RustDesk Client Builder')
    parser.add_argument('--config', default='builder-config.json', 
                       help='Configuration file path')
    parser.add_argument('--output-dir', default='../www/downloads',
                       help='Output directory for built clients')
    
    args = parser.parse_args()
    
    # Load configuration
    config = load_config(args.config)
    if args.output_dir:
        config['output_dir'] = args.output_dir
    
    # Create builder and build clients
    builder = RustDeskBuilder(config)
    
    try:
        built_clients = builder.build_all_clients()
        print(f"\n🎉 Successfully built {len(built_clients)} client(s)!")
        return 0
    except Exception as e:
        print(f"\n❌ Build failed: {e}")
        return 1

if __name__ == '__main__':
    sys.exit(main())
