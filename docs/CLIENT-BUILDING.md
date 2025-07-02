# ConnectAssist Client Building Guide

This guide explains how to build custom RustDesk clients preconfigured for your ConnectAssist server.

## Overview

The ConnectAssist client builder creates customized RustDesk clients that:
- Automatically connect to your server
- Include your branding and company information
- Can be configured for unattended access
- Support various deployment options

## Prerequisites

### System Requirements

- Linux build environment (Ubuntu 22.04 recommended)
- At least 4GB RAM and 20GB free disk space
- Internet connection for downloading dependencies

### Required Tools

```bash
# Install Rust toolchain
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# Install build dependencies
sudo apt update
sudo apt install -y \
    build-essential \
    pkg-config \
    libssl-dev \
    libgtk-3-dev \
    libxdo-dev \
    libxfixes-dev \
    libxrandr-dev \
    libasound2-dev \
    libpulse-dev \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    git \
    cmake \
    python3 \
    python3-pip

# For Windows cross-compilation
sudo apt install -y mingw-w64
rustup target add x86_64-pc-windows-gnu

# For creating installers (optional)
sudo apt install -y nsis
```

## Configuration

### Builder Configuration File

Edit `builder/builder-config.json` to customize your clients:

```json
{
  "domain": "connectassist.live",
  "company_name": "Your Company",
  "app_name": "Your Support Tool",
  "build_windows": true,
  "build_linux": true,
  "build_macos": false,
  "unattended_access": true,
  "unattended_password": "your-secure-password"
}
```

### Key Configuration Options

#### Basic Settings
- `domain`: Your ConnectAssist server domain
- `company_name`: Your company name for branding
- `app_name`: Application display name
- `build_windows/linux/macos`: Which platforms to build

#### Security Settings
- `unattended_access`: Enable permanent installation
- `unattended_password`: Password for unattended access
- `encryption_key`: Custom encryption key (optional)

#### UI Customization
- `hide_tray`: Hide system tray icon
- `auto_connect`: Automatically connect on startup
- `custom_title`: Custom window title
- `custom_welcome_message`: Welcome message for users

#### Features
- `file_transfer`: Enable file transfer capability
- `audio`: Enable audio transmission
- `clipboard`: Enable clipboard sharing
- `remote_restart`: Allow remote restart
- `chat`: Enable chat functionality

## Building Clients

### Quick Build

```bash
cd /opt/connectassist/builder

# Build all configured clients
python3 rustdesk-builder.py

# Built clients will be in ../www/downloads/
```

### Advanced Build Options

```bash
# Build with custom config file
python3 rustdesk-builder.py --config my-config.json

# Build to specific output directory
python3 rustdesk-builder.py --output-dir /path/to/output

# Build only Windows client
python3 rustdesk-builder.py --windows-only

# Build with debug information
python3 rustdesk-builder.py --debug
```

### Build Process Steps

1. **Environment Setup**: Validates build tools and dependencies
2. **Source Download**: Clones latest RustDesk source code
3. **Configuration**: Applies custom settings and branding
4. **Compilation**: Builds clients for specified platforms
5. **Packaging**: Creates installers and packages
6. **Output**: Places files in download directory

## Platform-Specific Building

### Windows Client

```bash
# Ensure Windows target is installed
rustup target add x86_64-pc-windows-gnu

# Build Windows client
python3 rustdesk-builder.py --config builder-config.json
```

**Output Files:**
- `connectassist-windows.exe`: Portable executable
- `connectassist-windows-installer.exe`: NSIS installer (if available)

### Linux Client

```bash
# Build Linux client
python3 rustdesk-builder.py --config builder-config.json
```

**Output Files:**
- `connectassist-linux`: Native Linux binary
- `connectassist-linux.AppImage`: Portable AppImage

### macOS Client (Requires macOS)

Building macOS clients requires a macOS build environment:

```bash
# On macOS system
brew install rust
rustup target add x86_64-apple-darwin
rustup target add aarch64-apple-darwin

# Build macOS client
python3 rustdesk-builder.py --config builder-config.json
```

## Customization Options

### Branding

1. **Icons and Images**
```bash
# Place custom icons in builder/assets/
cp your-icon.ico builder/assets/icon.ico
cp your-logo.png builder/assets/logo.png
```

2. **Application Information**
```json
{
  "branding": {
    "company_url": "https://yourcompany.com",
    "support_email": "support@yourcompany.com",
    "version": "1.0.0",
    "description": "Custom remote support tool"
  }
}
```

### Server Configuration

```json
{
  "server_config": {
    "relay_server": "your-domain.com:21117",
    "signal_server": "your-domain.com:21115",
    "api_server": "https://your-domain.com",
    "direct_server": "your-domain.com:21116"
  }
}
```

### Security Options

```json
{
  "security": {
    "require_password": true,
    "session_timeout": 3600,
    "max_sessions": 5,
    "whitelist_enabled": true,
    "whitelist_ips": ["192.168.1.0/24"]
  }
}
```

## Deployment Options

### Portable Executable

- No installation required
- Runs directly when executed
- Ideal for one-time support sessions

### Installer Package

- Professional installation experience
- Creates shortcuts and registry entries
- Supports unattended installation
- Better for permanent installations

### Service Installation

```json
{
  "deployment": {
    "install_service": true,
    "service_name": "ConnectAssistService",
    "auto_start": true,
    "run_as_system": false
  }
}
```

## Testing Built Clients

### Basic Functionality Test

1. **Download Test**
```bash
# Test download from your server
curl -I https://yourdomain.com/downloads/connectassist-windows.exe
```

2. **Connection Test**
```bash
# Run client and verify connection
./connectassist-linux
# Check if it connects to your server
```

3. **Feature Test**
- Test remote desktop functionality
- Verify file transfer works
- Check audio/clipboard if enabled

### Automated Testing

```bash
# Create test script
cat > test-client.sh << 'EOF'
#!/bin/bash
# Download and test client
wget https://yourdomain.com/downloads/connectassist-linux.AppImage
chmod +x connectassist-linux.AppImage
./connectassist-linux.AppImage --test-connection
EOF

chmod +x test-client.sh
./test-client.sh
```

## Troubleshooting

### Common Build Issues

1. **Missing Dependencies**
```bash
# Install missing Rust components
rustup component add rustfmt
rustup component add clippy
```

2. **Cross-compilation Errors**
```bash
# Reinstall Windows target
rustup target remove x86_64-pc-windows-gnu
rustup target add x86_64-pc-windows-gnu
```

3. **Build Failures**
```bash
# Clean build directory
rm -rf builder/build/
# Retry build
python3 rustdesk-builder.py --clean
```

### Runtime Issues

1. **Connection Problems**
- Verify server domain is correct
- Check firewall settings
- Confirm ports are open

2. **Permission Issues**
- Run as administrator on Windows
- Check file permissions on Linux
- Verify security settings

### Debug Mode

```bash
# Build with debug information
python3 rustdesk-builder.py --debug

# Run client with verbose logging
./connectassist-linux --verbose
```

## Advanced Configuration

### Custom Build Scripts

Create custom build scripts for specific requirements:

```python
# custom-builder.py
from rustdesk_builder import RustDeskBuilder

config = {
    "domain": "client1.connectassist.live",
    "company_name": "Client Company",
    "custom_features": ["screen_recording", "session_logging"]
}

builder = RustDeskBuilder(config)
builder.build_all_clients()
```

### Multi-Client Builds

```bash
# Build for multiple clients
for client in client1 client2 client3; do
    python3 rustdesk-builder.py --config configs/${client}-config.json
done
```

### Automated Builds

```bash
# Setup automated builds with cron
0 2 * * 0 cd /opt/connectassist/builder && python3 rustdesk-builder.py --auto
```

## Best Practices

1. **Version Control**
   - Keep configuration files in version control
   - Tag releases for tracking
   - Maintain build logs

2. **Security**
   - Use strong passwords for unattended access
   - Regularly update encryption keys
   - Monitor client usage

3. **Testing**
   - Test all built clients before deployment
   - Verify on target operating systems
   - Check compatibility with antivirus software

4. **Documentation**
   - Document custom configurations
   - Maintain deployment procedures
   - Keep troubleshooting guides updated
