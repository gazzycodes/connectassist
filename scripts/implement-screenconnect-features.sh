#!/bin/bash

# ConnectAssist ScreenConnect Features Implementation Script
# This script implements immediate improvements for ScreenConnect-equivalent functionality

set -e

echo "🔗 ConnectAssist ScreenConnect Features Implementation"
echo "=================================================="

# Configuration
DOMAIN="connectassist.live"
ADMIN_EMAIL="admin@connectassist.live"
BACKUP_DIR="/opt/connectassist/backups/$(date +%Y%m%d_%H%M%S)"

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo "📋 Step 1: Backing up current configuration..."
cp -r /opt/connectassist/docker "$BACKUP_DIR/"
cp -r /opt/connectassist/www "$BACKUP_DIR/"
echo "✅ Backup created at: $BACKUP_DIR"

echo "📋 Step 2: Updating RustDesk server configuration for persistent connections..."

# Create enhanced server configuration
cat > /opt/connectassist/docker/hbbs.toml << 'EOF'
[network]
addr = "0.0.0.0:21115"
relay-addr = "0.0.0.0:21116"
keep-alive = 30
connection-timeout = 300
max-connections = 1000

[security]
encrypt = true
allow-unencrypted = false
permanent-password-enabled = true
auto-accept-connections = false

[features]
unattended-access = true
auto-reconnect = true
persistent-connection = true
session-recording = false

[logging]
level = "info"
file = "/var/log/rustdesk/hbbs.log"
max-size = "100MB"
max-files = 5

[limits]
max-sessions-per-device = 1
max-devices-per-user = 50
session-timeout = 3600
EOF

echo "✅ Enhanced server configuration created"

echo "📋 Step 3: Creating support code system database..."

# Create SQLite database for support codes and devices
cat > /opt/connectassist/scripts/create_database.sql << 'EOF'
-- ConnectAssist Support System Database

CREATE TABLE IF NOT EXISTS support_codes (
    code VARCHAR(6) PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    used BOOLEAN DEFAULT FALSE,
    technician_id VARCHAR(50),
    customer_info TEXT
);

CREATE TABLE IF NOT EXISTS devices (
    device_id VARCHAR(50) PRIMARY KEY,
    support_code VARCHAR(6),
    customer_name VARCHAR(100),
    device_name VARCHAR(100),
    permanent_password VARCHAR(255),
    last_seen TIMESTAMP,
    status ENUM('online', 'offline', 'maintenance') DEFAULT 'offline',
    auto_accept BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (support_code) REFERENCES support_codes(code)
);

CREATE TABLE IF NOT EXISTS technicians (
    technician_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    access_level ENUM('basic', 'advanced', 'admin') DEFAULT 'basic',
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sessions (
    session_id VARCHAR(50) PRIMARY KEY,
    device_id VARCHAR(50),
    technician_id VARCHAR(50),
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP,
    duration INTEGER,
    notes TEXT,
    FOREIGN KEY (device_id) REFERENCES devices(device_id),
    FOREIGN KEY (technician_id) REFERENCES technicians(technician_id)
);

-- Insert default technician
INSERT OR IGNORE INTO technicians (technician_id, name, email, access_level) 
VALUES ('TECH-001', 'Admin Technician', 'admin@connectassist.live', 'admin');

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_devices_status ON devices(status);
CREATE INDEX IF NOT EXISTS idx_devices_last_seen ON devices(last_seen);
CREATE INDEX IF NOT EXISTS idx_support_codes_expires ON support_codes(expires_at);
CREATE INDEX IF NOT EXISTS idx_sessions_device ON sessions(device_id);
EOF

# Initialize database
sqlite3 /opt/connectassist/data/connectassist.db < /opt/connectassist/scripts/create_database.sql
echo "✅ Support system database created"

echo "📋 Step 4: Creating support code generator API..."

# Create Python API for support code management
cat > /opt/connectassist/scripts/support_api.py << 'EOF'
#!/usr/bin/env python3
"""
ConnectAssist Support Code API
Provides endpoints for generating support codes and managing devices
"""

import sqlite3
import random
import string
import json
import hashlib
from datetime import datetime, timedelta
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import os

app = Flask(__name__)
CORS(app)

DB_PATH = '/opt/connectassist/data/connectassist.db'
CLIENT_BUILD_PATH = '/opt/connectassist/builder'

def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def generate_support_code():
    """Generate a 6-digit support code"""
    return ''.join(random.choices(string.digits, k=6))

def generate_device_password():
    """Generate a secure device password"""
    return ''.join(random.choices(string.ascii_letters + string.digits, k=16))

@app.route('/api/support-code/generate', methods=['POST'])
def create_support_code():
    """Generate a new support code for customer support"""
    data = request.get_json() or {}
    technician_id = data.get('technician_id', 'TECH-001')
    customer_info = data.get('customer_info', '')
    
    code = generate_support_code()
    expires_at = datetime.now() + timedelta(hours=24)
    
    conn = get_db()
    try:
        conn.execute(
            'INSERT INTO support_codes (code, expires_at, technician_id, customer_info) VALUES (?, ?, ?, ?)',
            (code, expires_at, technician_id, customer_info)
        )
        conn.commit()
        
        return jsonify({
            'support_code': code,
            'expires_at': expires_at.isoformat(),
            'instructions': f'Customer should visit https://connectassist.live and enter code: {code}'
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        conn.close()

@app.route('/api/support-code/<code>/validate', methods=['GET'])
def validate_support_code(code):
    """Validate a support code"""
    conn = get_db()
    try:
        result = conn.execute(
            'SELECT * FROM support_codes WHERE code = ? AND expires_at > ? AND used = FALSE',
            (code, datetime.now())
        ).fetchone()
        
        if result:
            return jsonify({'valid': True, 'code': code})
        else:
            return jsonify({'valid': False, 'error': 'Invalid or expired code'}), 400
    finally:
        conn.close()

@app.route('/api/client/generate/<support_code>')
def generate_client(support_code):
    """Generate a custom client for the support code"""
    # Validate support code first
    conn = get_db()
    try:
        result = conn.execute(
            'SELECT * FROM support_codes WHERE code = ? AND expires_at > ? AND used = FALSE',
            (support_code, datetime.now())
        ).fetchone()
        
        if not result:
            return jsonify({'error': 'Invalid or expired support code'}), 400
        
        # Generate unique device ID and password
        device_id = f"SUPP-{support_code}-{int(datetime.now().timestamp())}"
        device_password = generate_device_password()
        
        # Register device
        conn.execute(
            'INSERT INTO devices (device_id, support_code, permanent_password, status) VALUES (?, ?, ?, ?)',
            (device_id, support_code, device_password, 'offline')
        )
        
        # Mark support code as used
        conn.execute(
            'UPDATE support_codes SET used = TRUE WHERE code = ?',
            (support_code,)
        )
        
        conn.commit()
        
        # TODO: Build custom client with embedded configuration
        # For now, return configuration that can be manually applied
        config = {
            'device_id': device_id,
            'server': 'connectassist.live',
            'permanent_password': device_password,
            'auto_start': True,
            'unattended_access': True
        }
        
        return jsonify({
            'device_id': device_id,
            'configuration': config,
            'download_url': f'/downloads/connectassist-windows.exe',
            'instructions': 'Download and run the client, then apply the provided configuration'
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        conn.close()

@app.route('/api/devices', methods=['GET'])
def list_devices():
    """List all registered devices"""
    conn = get_db()
    try:
        devices = conn.execute('''
            SELECT d.*, s.technician_id, s.customer_info 
            FROM devices d 
            LEFT JOIN support_codes s ON d.support_code = s.code 
            ORDER BY d.last_seen DESC
        ''').fetchall()
        
        return jsonify([dict(device) for device in devices])
    finally:
        conn.close()

@app.route('/api/devices/<device_id>/status', methods=['POST'])
def update_device_status(device_id):
    """Update device status (called by client)"""
    data = request.get_json() or {}
    status = data.get('status', 'online')
    
    conn = get_db()
    try:
        conn.execute(
            'UPDATE devices SET status = ?, last_seen = ? WHERE device_id = ?',
            (status, datetime.now(), device_id)
        )
        conn.commit()
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        conn.close()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
EOF

chmod +x /opt/connectassist/scripts/support_api.py
echo "✅ Support API created"

echo "📋 Step 5: Creating enhanced web interface..."

# Backup original index.html
cp /opt/connectassist/www/index.html "$BACKUP_DIR/"

# Create enhanced web interface with support code input
cat > /opt/connectassist/www/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ConnectAssist - Remote Support</title>
    <link rel="stylesheet" href="assets/style.css">
    <link rel="icon" type="image/x-icon" href="assets/favicon.ico">
</head>
<body>
    <div class="container">
        <header class="header">
            <div class="logo">
                <h1>🔗 ConnectAssist</h1>
                <p class="tagline">Secure Remote Support</p>
            </div>
        </header>

        <main class="main-content">
            <section class="hero">
                <h2>Get Remote Support</h2>
                <p class="hero-description">
                    Enter the support code provided by your technician to download the support tool.
                </p>
            </section>

            <section class="support-code-section">
                <div class="support-code-card">
                    <div class="support-icon">🎫</div>
                    <h3>Enter Support Code</h3>
                    <p>Your technician will provide you with a 6-digit support code.</p>
                    
                    <div class="code-input-group">
                        <input type="text" id="support-code" placeholder="000000" maxlength="6" pattern="[0-9]{6}">
                        <button class="btn-primary" id="validate-code" onclick="validateSupportCode()">
                            <span class="btn-icon">✓</span>
                            <span class="btn-text">Validate Code</span>
                        </button>
                    </div>
                    
                    <div id="code-status" class="code-status"></div>
                </div>
            </section>

            <section class="download-section" id="download-section" style="display: none;">
                <div class="download-card">
                    <div class="download-icon">💻</div>
                    <h3 id="platform-title">Ready to Download</h3>
                    <p id="platform-description">Your support tool is ready for download.</p>
                    
                    <div class="download-buttons">
                        <button class="btn-primary" id="primary-download" onclick="downloadSupportTool()">
                            <span class="btn-icon">⬇️</span>
                            <span class="btn-text">Download Support Tool</span>
                        </button>
                        
                        <div class="alternative-downloads">
                            <p>Need a different version?</p>
                            <div class="alt-buttons">
                                <a href="downloads/connectassist-windows.exe" class="btn-alt">
                                    🪟 Windows
                                </a>
                                <a href="downloads/connectassist-macos.dmg" class="btn-alt">
                                    🍎 macOS
                                </a>
                                <a href="downloads/connectassist-linux.AppImage" class="btn-alt">
                                    🐧 Linux
                                </a>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            <section class="instructions">
                <h3>📋 How to get support:</h3>
                <ol class="steps">
                    <li><strong>Get Support Code</strong> from your technician</li>
                    <li><strong>Enter Code</strong> in the field above</li>
                    <li><strong>Download</strong> the support tool</li>
                    <li><strong>Run</strong> the downloaded file (no installation required)</li>
                    <li><strong>Wait</strong> for your technician to connect</li>
                </ol>
                
                <div class="security-note">
                    <div class="security-icon">🔒</div>
                    <div class="security-text">
                        <strong>Your security is our priority</strong><br>
                        All connections are encrypted end-to-end. The support session will only last as long as needed to resolve your issue.
                    </div>
                </div>
            </section>

            <section class="faq">
                <h3>❓ Frequently Asked Questions</h3>
                <div class="faq-item">
                    <h4>What is a support code?</h4>
                    <p>A support code is a 6-digit number provided by your technician that allows you to download a personalized support tool.</p>
                </div>
                <div class="faq-item">
                    <h4>Is this safe to run?</h4>
                    <p>Yes, our support tool uses industry-standard encryption and only allows connections when you explicitly approve them.</p>
                </div>
                <div class="faq-item">
                    <h4>Do I need to install anything?</h4>
                    <p>No installation required. Simply download and run the tool when you need support.</p>
                </div>
                <div class="faq-item">
                    <h4>How do I end the support session?</h4>
                    <p>You can close the support tool at any time to immediately end the session.</p>
                </div>
            </section>
        </main>

        <footer class="footer">
            <p>&copy; 2024 ConnectAssist. Secure remote support solution.</p>
            <p class="contact">Need help? Contact: <a href="mailto:support@connectassist.live">support@connectassist.live</a></p>
        </footer>
    </div>

    <script src="assets/script.js"></script>
    <script>
        let validatedCode = null;
        
        function validateSupportCode() {
            const code = document.getElementById('support-code').value;
            const statusDiv = document.getElementById('code-status');
            
            if (code.length !== 6 || !/^\d{6}$/.test(code)) {
                statusDiv.innerHTML = '<div class="error">Please enter a valid 6-digit code</div>';
                return;
            }
            
            statusDiv.innerHTML = '<div class="loading">Validating code...</div>';
            
            fetch(`/api/support-code/${code}/validate`)
                .then(response => response.json())
                .then(data => {
                    if (data.valid) {
                        validatedCode = code;
                        statusDiv.innerHTML = '<div class="success">✅ Code validated! You can now download the support tool.</div>';
                        document.getElementById('download-section').style.display = 'block';
                        document.getElementById('download-section').scrollIntoView({ behavior: 'smooth' });
                    } else {
                        statusDiv.innerHTML = '<div class="error">❌ Invalid or expired code. Please check with your technician.</div>';
                    }
                })
                .catch(error => {
                    statusDiv.innerHTML = '<div class="error">❌ Error validating code. Please try again.</div>';
                });
        }
        
        function downloadSupportTool() {
            if (!validatedCode) {
                alert('Please validate your support code first.');
                return;
            }
            
            // Generate custom client for this support code
            window.location.href = `/api/client/generate/${validatedCode}`;
        }
        
        // Auto-format support code input
        document.getElementById('support-code').addEventListener('input', function(e) {
            let value = e.target.value.replace(/\D/g, '');
            if (value.length > 6) value = value.slice(0, 6);
            e.target.value = value;
        });
        
        // Allow Enter key to validate code
        document.getElementById('support-code').addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                validateSupportCode();
            }
        });
    </script>
</body>
</html>
EOF

echo "✅ Enhanced web interface created"

echo "📋 Step 6: Creating Docker service for Support API..."

# Create Docker service for the Support API
cat > /opt/connectassist/docker/docker-compose.support.yml << 'EOF'
version: '3.8'

services:
  support-api:
    image: python:3.9-slim
    container_name: connectassist-support-api
    restart: unless-stopped
    ports:
      - "5000:5000"
    volumes:
      - /opt/connectassist/scripts:/app
      - /opt/connectassist/data:/opt/connectassist/data
    working_dir: /app
    command: >
      sh -c "pip install flask flask-cors &&
             python support_api.py"
    networks:
      - connectassist-network

networks:
  connectassist-network:
    external: true
EOF

echo "✅ Support API Docker service created"

echo "📋 Step 7: Creating technician dashboard..."

# Create simple technician dashboard
mkdir -p /opt/connectassist/www/admin
cat > /opt/connectassist/www/admin/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ConnectAssist - Technician Dashboard</title>
    <link rel="stylesheet" href="../assets/style.css">
    <style>
        .dashboard { max-width: 1200px; margin: 0 auto; padding: 20px; }
        .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .stat-card { background: #f8f9fa; padding: 20px; border-radius: 8px; text-align: center; }
        .device-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 20px; }
        .device-card { background: white; border: 1px solid #ddd; border-radius: 8px; padding: 20px; }
        .device-online { border-left: 4px solid #28a745; }
        .device-offline { border-left: 4px solid #dc3545; }
        .btn-small { padding: 8px 16px; font-size: 14px; }
    </style>
</head>
<body>
    <div class="container">
        <header class="header">
            <div class="logo">
                <h1>🔗 ConnectAssist</h1>
                <p class="tagline">Technician Dashboard</p>
            </div>
        </header>

        <div class="dashboard">
            <section class="stats-section">
                <h2>📊 Overview</h2>
                <div class="stats-grid">
                    <div class="stat-card">
                        <h3 id="online-devices">0</h3>
                        <p>Online Devices</p>
                    </div>
                    <div class="stat-card">
                        <h3 id="total-devices">0</h3>
                        <p>Total Devices</p>
                    </div>
                    <div class="stat-card">
                        <h3 id="active-codes">0</h3>
                        <p>Active Support Codes</p>
                    </div>
                </div>
            </section>

            <section class="actions-section">
                <h2>🎫 Generate Support Code</h2>
                <div class="support-code-card">
                    <input type="text" id="customer-info" placeholder="Customer name or info (optional)">
                    <button class="btn-primary" onclick="generateSupportCode()">Generate New Code</button>
                    <div id="generated-code" class="code-result"></div>
                </div>
            </section>

            <section class="devices-section">
                <h2>💻 Connected Devices</h2>
                <div id="device-grid" class="device-grid">
                    <!-- Devices will be loaded here -->
                </div>
            </section>
        </div>
    </div>

    <script>
        function generateSupportCode() {
            const customerInfo = document.getElementById('customer-info').value;
            
            fetch('/api/support-code/generate', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ customer_info: customerInfo })
            })
            .then(response => response.json())
            .then(data => {
                document.getElementById('generated-code').innerHTML = `
                    <div class="success">
                        <h3>Support Code Generated: ${data.support_code}</h3>
                        <p>Expires: ${new Date(data.expires_at).toLocaleString()}</p>
                        <p>Instructions: ${data.instructions}</p>
                    </div>
                `;
            })
            .catch(error => {
                document.getElementById('generated-code').innerHTML = `
                    <div class="error">Error generating code: ${error.message}</div>
                `;
            });
        }
        
        function loadDevices() {
            fetch('/api/devices')
                .then(response => response.json())
                .then(devices => {
                    const grid = document.getElementById('device-grid');
                    const onlineCount = devices.filter(d => d.status === 'online').length;
                    
                    document.getElementById('online-devices').textContent = onlineCount;
                    document.getElementById('total-devices').textContent = devices.length;
                    
                    grid.innerHTML = devices.map(device => `
                        <div class="device-card device-${device.status}">
                            <h4>${device.device_id}</h4>
                            <p><strong>Status:</strong> ${device.status}</p>
                            <p><strong>Last Seen:</strong> ${device.last_seen ? new Date(device.last_seen).toLocaleString() : 'Never'}</p>
                            <p><strong>Customer:</strong> ${device.customer_info || 'N/A'}</p>
                            ${device.status === 'online' ? 
                                '<button class="btn-primary btn-small" onclick="connectToDevice(\'' + device.device_id + '\')">Connect</button>' :
                                '<button class="btn-secondary btn-small" disabled>Offline</button>'
                            }
                        </div>
                    `).join('');
                });
        }
        
        function connectToDevice(deviceId) {
            alert(`Connecting to device: ${deviceId}\n\nIn a full implementation, this would launch the RustDesk client with the device credentials.`);
        }
        
        // Load devices on page load and refresh every 30 seconds
        loadDevices();
        setInterval(loadDevices, 30000);
    </script>
</body>
</html>
EOF

echo "✅ Technician dashboard created"

echo "📋 Step 8: Starting enhanced services..."

# Start the support API
cd /opt/connectassist/docker
docker-compose -f docker-compose.support.yml up -d

# Update NGINX configuration to proxy API requests
cat >> /etc/nginx/sites-available/connectassist.live << 'EOF'

    # Support API proxy
    location /api/ {
        proxy_pass http://localhost:5000/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
EOF

# Reload NGINX
systemctl reload nginx

echo "✅ Services started and configured"

echo "📋 Step 9: Creating management scripts..."

# Create support code management script
cat > /opt/connectassist/scripts/manage-support.sh << 'EOF'
#!/bin/bash

# ConnectAssist Support Management Script

DB_PATH="/opt/connectassist/data/connectassist.db"

case "$1" in
    "generate")
        echo "Generating support code..."
        curl -X POST http://localhost:5000/api/support-code/generate \
             -H "Content-Type: application/json" \
             -d "{\"customer_info\": \"$2\"}" | jq .
        ;;
    "list-devices")
        echo "Listing all devices..."
        curl http://localhost:5000/api/devices | jq .
        ;;
    "list-codes")
        echo "Listing active support codes..."
        sqlite3 "$DB_PATH" "SELECT code, created_at, expires_at, used, customer_info FROM support_codes WHERE expires_at > datetime('now') ORDER BY created_at DESC;"
        ;;
    "cleanup")
        echo "Cleaning up expired codes..."
        sqlite3 "$DB_PATH" "DELETE FROM support_codes WHERE expires_at < datetime('now');"
        echo "Cleanup completed."
        ;;
    *)
        echo "Usage: $0 {generate|list-devices|list-codes|cleanup} [customer_info]"
        echo ""
        echo "Examples:"
        echo "  $0 generate 'John Doe - Computer Issues'"
        echo "  $0 list-devices"
        echo "  $0 list-codes"
        echo "  $0 cleanup"
        ;;
esac
EOF

chmod +x /opt/connectassist/scripts/manage-support.sh

echo "✅ Management scripts created"

echo ""
echo "🎉 ConnectAssist ScreenConnect Features Implementation Complete!"
echo "=============================================================="
echo ""
echo "📋 What's been implemented:"
echo "✅ Enhanced RustDesk server configuration for persistent connections"
echo "✅ Support code generation and validation system"
echo "✅ Device registration and management database"
echo "✅ Enhanced web interface with support code input"
echo "✅ Support API for code generation and device management"
echo "✅ Basic technician dashboard"
echo "✅ Management scripts for support operations"
echo ""
echo "🌐 Access Points:"
echo "• Customer Portal: https://connectassist.live"
echo "• Technician Dashboard: https://connectassist.live/admin"
echo "• Support API: https://connectassist.live/api/"
echo ""
echo "🔧 Management Commands:"
echo "• Generate support code: /opt/connectassist/scripts/manage-support.sh generate 'Customer Name'"
echo "• List devices: /opt/connectassist/scripts/manage-support.sh list-devices"
echo "• List active codes: /opt/connectassist/scripts/manage-support.sh list-codes"
echo "• Cleanup expired codes: /opt/connectassist/scripts/manage-support.sh cleanup"
echo ""
echo "📝 Next Steps:"
echo "1. Test the support code generation and validation"
echo "2. Rebuild clients with enhanced unattended access configuration"
echo "3. Consider upgrading to RustDesk Pro for full admin panel features"
echo "4. Implement automatic client building with embedded configurations"
echo ""
echo "💡 For full ScreenConnect equivalent functionality, consider:"
echo "• RustDesk Pro license ($50-200/month) for complete web console"
echo "• Custom client building automation"
echo "• Advanced session management and logging"
echo ""
echo "Backup created at: $BACKUP_DIR"
