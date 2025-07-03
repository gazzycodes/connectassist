#!/usr/bin/env python3
"""
ConnectAssist Admin API
Handles admin dashboard operations, support code generation, and client creation
"""

import os
import sys
import json
import sqlite3
import secrets
import string
import subprocess
import tempfile
import zipfile
from datetime import datetime, timedelta
from pathlib import Path
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS

# Add builder directory to path for client generation
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'builder'))

app = Flask(__name__)
CORS(app)

# Configuration
DATABASE_PATH = '/opt/connectassist/data/connectassist.db'
BUILDER_PATH = '/opt/connectassist/builder'
DOWNLOADS_PATH = '/opt/connectassist/www/downloads'

class AdminAPI:
    def __init__(self):
        self.init_database()
    
    def init_database(self):
        """Initialize the database with admin-specific tables"""
        conn = sqlite3.connect(DATABASE_PATH)
        cursor = conn.cursor()
        
        # Create admin tables
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS admin_sessions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                session_token TEXT UNIQUE NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                expires_at TIMESTAMP NOT NULL,
                technician_name TEXT,
                ip_address TEXT
            )
        ''')
        
        # Create client packages table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS client_packages (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                support_code TEXT NOT NULL,
                package_path TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                downloaded_at TIMESTAMP,
                customer_name TEXT,
                customer_email TEXT,
                customer_phone TEXT,
                session_notes TEXT
            )
        ''')
        
        # Create connection logs table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS connection_logs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                device_id TEXT NOT NULL,
                technician_id TEXT,
                connection_type TEXT,
                started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                ended_at TIMESTAMP,
                duration INTEGER,
                status TEXT DEFAULT 'active'
            )
        ''')
        
        conn.commit()
        conn.close()
    
    def generate_support_code(self):
        """Generate a unique 6-digit support code"""
        while True:
            code = ''.join(secrets.choice(string.digits) for _ in range(6))
            
            # Check if code already exists and is still valid
            conn = sqlite3.connect(DATABASE_PATH)
            cursor = conn.cursor()
            cursor.execute('''
                SELECT id FROM support_codes 
                WHERE code = ? AND expires_at > datetime('now')
            ''', (code,))
            
            if not cursor.fetchone():
                conn.close()
                return code
            
            conn.close()
    
    def create_support_code(self, customer_data):
        """Create a new support code with customer information"""
        code = self.generate_support_code()
        expires_at = datetime.now() + timedelta(hours=24)
        
        conn = sqlite3.connect(DATABASE_PATH)
        cursor = conn.cursor()
        
        cursor.execute('''
            INSERT INTO support_codes (code, expires_at, customer_name, customer_email, 
                                     customer_phone, session_notes, status)
            VALUES (?, ?, ?, ?, ?, ?, 'active')
        ''', (
            code,
            expires_at.isoformat(),
            customer_data.get('customer_name'),
            customer_data.get('customer_email'),
            customer_data.get('customer_phone'),
            customer_data.get('session_notes')
        ))
        
        conn.commit()
        conn.close()
        
        return {
            'success': True,
            'support_code': code,
            'expires_at': expires_at.isoformat(),
            'customer_data': customer_data
        }
    
    def create_client_package(self, support_code, customer_data):
        """Create a custom client package for the support code"""
        try:
            # Create temporary directory for package creation
            with tempfile.TemporaryDirectory() as temp_dir:
                temp_path = Path(temp_dir)
                
                # Copy RustDesk binary
                rustdesk_binary = Path(BUILDER_PATH) / 'downloads' / 'rustdesk-windows.exe'
                if not rustdesk_binary.exists():
                    # Download RustDesk binary if not exists
                    self.download_rustdesk_binary()
                
                client_exe = temp_path / 'connectassist-windows.exe'
                if rustdesk_binary.exists():
                    import shutil
                    shutil.copy2(rustdesk_binary, client_exe)
                else:
                    raise Exception("RustDesk binary not available")
                
                # Copy installation scripts
                scripts = ['install-service.ps1', 'install-connectassist.bat']
                for script in scripts:
                    script_path = Path(BUILDER_PATH) / script
                    if script_path.exists():
                        import shutil
                        shutil.copy2(script_path, temp_path / script)
                
                # Create client configuration
                config = {
                    "server": "connectassist.live",
                    "relay_server": "connectassist.live:21117",
                    "signal_server": "connectassist.live:21115",
                    "api_server": "https://connectassist.live",
                    "permanent_password": f"CA{support_code}!",
                    "auto_connect": True,
                    "unattended_access": True,
                    "install_service": True,
                    "auto_start": True,
                    "start_minimized": True,
                    "service_name": "ConnectAssist Remote Support",
                    "support_code": support_code,
                    "customer_info": customer_data
                }
                
                config_file = temp_path / 'connectassist-config.json'
                with open(config_file, 'w') as f:
                    json.dump(config, f, indent=2)
                
                # Create installation instructions
                instructions = self.create_installation_instructions(support_code, customer_data)
                instructions_file = temp_path / 'INSTALLATION-INSTRUCTIONS.txt'
                with open(instructions_file, 'w', encoding='utf-8') as f:
                    f.write(instructions)
                
                # Create setup launcher
                setup_script = self.create_setup_script(support_code)
                setup_file = temp_path / 'setup-connectassist.bat'
                with open(setup_file, 'w', encoding='utf-8') as f:
                    f.write(setup_script)
                
                # Create ZIP package
                package_name = f"ConnectAssist-{support_code}-{customer_data.get('customer_name', 'Customer').replace(' ', '')}.zip"
                package_path = Path(DOWNLOADS_PATH) / package_name
                
                # Ensure downloads directory exists
                package_path.parent.mkdir(parents=True, exist_ok=True)
                
                with zipfile.ZipFile(package_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
                    for file_path in temp_path.rglob('*'):
                        if file_path.is_file():
                            arcname = file_path.relative_to(temp_path)
                            zipf.write(file_path, arcname)
                
                # Record package in database
                conn = sqlite3.connect(DATABASE_PATH)
                cursor = conn.cursor()
                cursor.execute('''
                    INSERT INTO client_packages (support_code, package_path, customer_name, 
                                               customer_email, customer_phone, session_notes)
                    VALUES (?, ?, ?, ?, ?, ?)
                ''', (
                    support_code,
                    str(package_path),
                    customer_data.get('customer_name'),
                    customer_data.get('customer_email'),
                    customer_data.get('customer_phone'),
                    customer_data.get('session_notes')
                ))
                conn.commit()
                conn.close()
                
                return {
                    'success': True,
                    'package_path': str(package_path),
                    'package_name': package_name,
                    'download_url': f'/downloads/{package_name}'
                }
                
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def download_rustdesk_binary(self):
        """Download RustDesk binary if not exists"""
        import urllib.request
        
        download_url = "https://github.com/rustdesk/rustdesk/releases/download/1.2.3/rustdesk-1.2.3-x86_64.exe"
        binary_path = Path(BUILDER_PATH) / 'downloads' / 'rustdesk-windows.exe'
        
        # Create downloads directory
        binary_path.parent.mkdir(parents=True, exist_ok=True)
        
        try:
            urllib.request.urlretrieve(download_url, binary_path)
            return True
        except Exception as e:
            print(f"Failed to download RustDesk binary: {e}")
            return False
    
    def create_installation_instructions(self, support_code, customer_data):
        """Create installation instructions for the customer"""
        customer_name = customer_data.get('customer_name', 'Customer')
        
        return f"""# ConnectAssist Remote Support Installation

Hello {customer_name},

This package contains ConnectAssist remote support software that will allow your technician to provide assistance when needed.

## IMPORTANT: One-Time Setup Required

### What this does:
- Installs ConnectAssist as a background service on your computer
- Starts automatically when your computer boots up
- Runs quietly without interfering with your normal computer use
- Allows your technician to connect for support when you need help

### Installation Steps:
1. **Extract this ZIP file** to your Desktop or Downloads folder
2. **Right-click** on 'setup-connectassist.bat'
3. **Select** "Run as administrator"
4. **Click "Yes"** when Windows asks for permission
5. **Follow** the on-screen instructions
6. **Wait** for "Installation completed successfully!" message

### After Installation:
- ConnectAssist runs automatically in the background
- Your technician can connect when you need support
- No further action needed from you
- The service starts automatically when you restart your computer

### Security & Privacy:
- Only authorized technicians with correct credentials can connect
- All connections are encrypted and secure
- No personal data is accessed without your permission
- You can uninstall anytime if needed

### Support Information:
- Support Code: {support_code}
- Customer: {customer_name}
- Server: connectassist.live

### Need Help with Installation?
Contact your technician for step-by-step assistance.

### To Uninstall (if needed):
1. Press Windows + R keys together
2. Type: cmd
3. Right-click "Command Prompt" and select "Run as administrator"
4. Type: sc delete ConnectAssistService
5. Press Enter

---
ConnectAssist Remote Support - Secure, Professional, Reliable
Your technician can now provide seamless support whenever you need it.
"""
    
    def create_setup_script(self, support_code):
        """Create the setup script with embedded configuration"""
        return f"""@echo off
REM ConnectAssist Configuration and Service Launcher
REM Support Code: {support_code}

title ConnectAssist Setup

echo.
echo  ====================================================
echo   ConnectAssist Remote Support Setup
echo  ====================================================
echo.

REM Configure RustDesk with ConnectAssist settings
echo  [INFO] Configuring ConnectAssist settings...

REM Set server configuration
reg add "HKCU\\Software\\RustDesk\\config" /v "custom-rendezvous-server" /t REG_SZ /d "connectassist.live" /f >nul 2>&1
reg add "HKCU\\Software\\RustDesk\\config" /v "relay-server" /t REG_SZ /d "connectassist.live:21117" /f >nul 2>&1
reg add "HKCU\\Software\\RustDesk\\config" /v "api-server" /t REG_SZ /d "https://connectassist.live" /f >nul 2>&1

REM Set permanent password
reg add "HKCU\\Software\\RustDesk\\config" /v "permanent_password" /t REG_SZ /d "CA{support_code}!" /f >nul 2>&1

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

# Initialize API
admin_api = AdminAPI()

# API Routes
@app.route('/api/stats', methods=['GET'])
def get_stats():
    """Get dashboard statistics"""
    try:
        conn = sqlite3.connect(DATABASE_PATH)
        cursor = conn.cursor()
        
        # Get online devices count
        cursor.execute('''
            SELECT COUNT(*) FROM devices 
            WHERE last_seen > datetime('now', '-5 minutes')
        ''')
        online_devices = cursor.fetchone()[0]
        
        # Get total customers
        cursor.execute('SELECT COUNT(DISTINCT customer_name) FROM devices WHERE customer_name IS NOT NULL')
        total_customers = cursor.fetchone()[0]
        
        # Get active support codes
        cursor.execute('''
            SELECT COUNT(*) FROM support_codes 
            WHERE expires_at > datetime('now') AND status = 'active'
        ''')
        active_codes = cursor.fetchone()[0]
        
        # Get active sessions
        cursor.execute('''
            SELECT COUNT(*) FROM connection_logs 
            WHERE status = 'active'
        ''')
        active_sessions = cursor.fetchone()[0]
        
        conn.close()
        
        return jsonify({
            'online_devices': online_devices,
            'total_customers': total_customers,
            'active_codes': active_codes,
            'active_sessions': active_sessions
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/support-codes', methods=['POST'])
def create_support_code():
    """Generate a new support code"""
    try:
        customer_data = request.get_json()
        
        # Validate required fields
        if not customer_data.get('customer_name'):
            return jsonify({'error': 'Customer name is required'}), 400
        
        # Create support code
        result = admin_api.create_support_code(customer_data)
        
        # Create client package
        if result['success']:
            package_result = admin_api.create_client_package(
                result['support_code'], 
                customer_data
            )
            result.update(package_result)
        
        return jsonify(result)
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/devices', methods=['GET'])
def get_devices():
    """Get all registered devices"""
    try:
        conn = sqlite3.connect(DATABASE_PATH)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT id, customer_name, device_name, os, last_seen, created_at,
                   CASE 
                       WHEN last_seen > datetime('now', '-5 minutes') THEN 'online'
                       WHEN last_seen > datetime('now', '-1 hour') THEN 'recent'
                       ELSE 'offline'
                   END as status
            FROM devices
            ORDER BY last_seen DESC
        ''')
        
        devices = []
        for row in cursor.fetchall():
            devices.append({
                'id': row[0],
                'customer_name': row[1],
                'device_name': row[2],
                'os': row[3],
                'last_seen': row[4],
                'created_at': row[5],
                'status': row[6]
            })
        
        conn.close()
        return jsonify(devices)
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/activity', methods=['GET'])
def get_activity():
    """Get recent activity"""
    try:
        conn = sqlite3.connect(DATABASE_PATH)
        cursor = conn.cursor()
        
        # Get recent activities from multiple sources
        activities = []
        
        # Recent support codes
        cursor.execute('''
            SELECT 'code_generated' as type, customer_name, created_at
            FROM support_codes
            WHERE created_at > datetime('now', '-24 hours')
            ORDER BY created_at DESC
            LIMIT 5
        ''')
        
        for row in cursor.fetchall():
            activities.append({
                'type': row[0],
                'title': f'Support code generated for {row[1]}',
                'description': 'New support code created for customer assistance',
                'timestamp': row[2]
            })
        
        # Recent device registrations
        cursor.execute('''
            SELECT 'device_registered' as type, customer_name, device_name, created_at
            FROM devices
            WHERE created_at > datetime('now', '-24 hours')
            ORDER BY created_at DESC
            LIMIT 5
        ''')
        
        for row in cursor.fetchall():
            activities.append({
                'type': row[0],
                'title': f'Device registered: {row[2]}',
                'description': f'Customer {row[1]} installed ConnectAssist',
                'timestamp': row[3]
            })
        
        # Sort by timestamp
        activities.sort(key=lambda x: x['timestamp'], reverse=True)
        
        conn.close()
        return jsonify(activities[:10])  # Return top 10
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/connect', methods=['POST'])
def initiate_connection():
    """Initiate connection to a device"""
    try:
        data = request.get_json()
        device_id = data.get('device_id')
        connection_type = data.get('connection_type', 'desktop')

        if not device_id:
            return jsonify({'error': 'Device ID is required'}), 400

        # Get device information
        conn = sqlite3.connect(DATABASE_PATH)
        cursor = conn.cursor()

        cursor.execute('''
            SELECT customer_name, device_name, last_seen
            FROM devices
            WHERE id = ?
        ''', (device_id,))

        device = cursor.fetchone()
        if not device:
            return jsonify({'error': 'Device not found'}), 404

        # Check if device is online
        cursor.execute('''
            SELECT last_seen > datetime('now', '-5 minutes') as is_online
            FROM devices
            WHERE id = ?
        ''', (device_id,))

        is_online = cursor.fetchone()[0]
        if not is_online:
            return jsonify({'error': 'Device is not online'}), 400

        # Get permanent password for device
        cursor.execute('''
            SELECT code FROM support_codes sc
            JOIN devices d ON d.support_code = sc.code
            WHERE d.id = ?
        ''', (device_id,))

        support_code_row = cursor.fetchone()
        permanent_password = f"CA{support_code_row[0]}!" if support_code_row else "ConnectAssist2024!"

        # Log connection attempt
        cursor.execute('''
            INSERT INTO connection_logs (device_id, connection_type, status)
            VALUES (?, ?, 'active')
        ''', (device_id, connection_type))

        conn.commit()
        conn.close()

        return jsonify({
            'success': True,
            'connection_info': {
                'device_id': device_id,
                'password': permanent_password,
                'server': 'connectassist.live',
                'connection_type': connection_type
            }
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Customer API Endpoints
@app.route('/api/customer/installer', methods=['POST'])
def generate_customer_installer():
    """Validate support code and generate custom installer for customer"""
    try:
        data = request.get_json()
        support_code = data.get('support_code')

        if not support_code:
            return jsonify({'error': 'Support code is required'}), 400

        if len(support_code) != 6 or not support_code.isdigit():
            return jsonify({'error': 'Support code must be exactly 6 digits'}), 400

        # Validate support code
        conn = sqlite3.connect(DATABASE_PATH)
        cursor = conn.cursor()

        cursor.execute('''
            SELECT id, customer_name, customer_email, customer_phone, session_notes, expires_at
            FROM support_codes
            WHERE code = ? AND expires_at > datetime('now') AND status = 'active'
        ''', (support_code,))

        code_data = cursor.fetchone()
        if not code_data:
            conn.close()
            return jsonify({'error': 'Invalid or expired support code'}), 400

        # Extract customer data
        customer_data = {
            'customer_name': code_data[1],
            'customer_email': code_data[2],
            'customer_phone': code_data[3],
            'session_notes': code_data[4]
        }

        # Check if installer already exists
        cursor.execute('''
            SELECT package_path, package_name FROM client_packages
            WHERE support_code = ?
            ORDER BY created_at DESC
            LIMIT 1
        ''', (support_code,))

        existing_package = cursor.fetchone()

        if existing_package and Path(existing_package[0]).exists():
            # Return existing package
            package_name = Path(existing_package[0]).name
            download_url = f'/downloads/{package_name}'

            # Update download tracking
            cursor.execute('''
                UPDATE client_packages
                SET downloaded_at = datetime('now')
                WHERE support_code = ? AND package_path = ?
            ''', (support_code, existing_package[0]))
            conn.commit()
            conn.close()

            return jsonify({
                'success': True,
                'download_url': download_url,
                'customer_data': customer_data,
                'support_code': support_code
            })

        conn.close()

        # Generate new installer package
        package_result = create_client_package(support_code, customer_data)

        if package_result['success']:
            return jsonify({
                'success': True,
                'download_url': package_result['download_url'],
                'customer_data': customer_data,
                'support_code': support_code
            })
        else:
            return jsonify({'error': package_result['error']}), 500

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/track-download', methods=['POST'])
def track_download():
    """Track installer downloads for analytics"""
    try:
        data = request.get_json()
        support_code = data.get('support_code')
        timestamp = data.get('timestamp')

        if support_code:
            conn = sqlite3.connect(DATABASE_PATH)
            cursor = conn.cursor()

            cursor.execute('''
                UPDATE client_packages
                SET downloaded_at = ?
                WHERE support_code = ?
            ''', (timestamp, support_code))

            conn.commit()
            conn.close()

        return jsonify({'success': True})

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/status', methods=['GET'])
def get_system_status():
    """Get system status for customer portal"""
    try:
        # Simple status check - could be enhanced with actual service monitoring
        return jsonify({
            'online': True,
            'server': 'connectassist.live',
            'timestamp': datetime.now().isoformat()
        })

    except Exception as e:
        return jsonify({
            'online': False,
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }), 500

@app.route('/api/deploy', methods=['POST'])
def deploy_updates():
    """Deploy updates from GitHub repository"""
    try:
        # Simple deployment endpoint for updating from GitHub
        import subprocess
        import os

        # Verify deployment key (simple security)
        data = request.get_json() or {}
        deploy_key = data.get('deploy_key')

        if deploy_key != 'ConnectAssist2024Deploy':
            return jsonify({'success': False, 'error': 'Invalid deployment key'}), 403

        # Change to the project directory
        project_dir = '/opt/connectassist'
        if not os.path.exists(project_dir):
            return jsonify({'success': False, 'error': 'Project directory not found'})

        # Pull latest changes from GitHub
        result = subprocess.run(['git', 'pull', 'origin', 'main'],
                              cwd=project_dir,
                              capture_output=True,
                              text=True)

        if result.returncode == 0:
            # Restart API service if needed
            try:
                subprocess.run(['pkill', '-f', 'admin_api.py'], capture_output=True)
            except:
                pass

            return jsonify({
                'success': True,
                'message': 'Deployment successful - API will restart',
                'git_output': result.stdout
            })
        else:
            return jsonify({
                'success': False,
                'error': 'Git pull failed',
                'git_error': result.stderr
            })

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)
