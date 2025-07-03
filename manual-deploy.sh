#!/bin/bash

# ConnectAssist Customer Portal Integration - Manual Deployment Script
# Run this script on the VPS to deploy the customer portal integration

echo "🚀 ConnectAssist Customer Portal Integration Deployment"
echo "========================================================"

# Set project directory
PROJECT_DIR="/opt/connectassist"

# Check if project directory exists
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ Project directory $PROJECT_DIR not found!"
    echo "Please ensure ConnectAssist is properly installed."
    exit 1
fi

echo "📁 Project directory: $PROJECT_DIR"
cd "$PROJECT_DIR"

# Pull latest changes from GitHub
echo "📡 Pulling latest changes from GitHub..."
git pull origin main

if [ $? -ne 0 ]; then
    echo "❌ Git pull failed!"
    echo "Please check your internet connection and GitHub repository access."
    exit 1
fi

echo "✅ Successfully pulled latest changes"

# Make scripts executable
echo "🔧 Making scripts executable..."
chmod +x scripts/*.sh
chmod +x *.sh

# Check if admin API directory exists
if [ ! -d "api" ]; then
    echo "📁 Creating API directory..."
    mkdir -p api
fi

# Install Python dependencies for admin API
echo "📦 Installing Python dependencies..."
if command -v python3 &> /dev/null; then
    python3 -m pip install flask flask-cors requests sqlite3 pathlib zipfile
else
    echo "⚠️ Python3 not found. Installing..."
    apt update
    apt install -y python3 python3-pip
    python3 -m pip install flask flask-cors requests sqlite3 pathlib zipfile
fi

# Create downloads directory for client packages
echo "📁 Creating downloads directory..."
mkdir -p www/downloads
chmod 755 www/downloads

# Update NGINX configuration to serve admin panel and API
echo "🌐 Updating NGINX configuration..."

# Create admin panel location block
cat > /tmp/admin_location.conf << 'EOF'
    # Admin Dashboard
    location /admin/ {
        alias /opt/connectassist/www/admin/;
        index index.html;
        try_files $uri $uri/ =404;
    }

    # API endpoints
    location /api/ {
        proxy_pass http://127.0.0.1:5001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Downloads directory for client packages
    location /downloads/ {
        alias /opt/connectassist/www/downloads/;
        add_header Content-Disposition 'attachment';
    }
EOF

# Check if admin configuration already exists in NGINX
if ! grep -q "location /admin/" /etc/nginx/sites-available/connectassist.live; then
    echo "📝 Adding admin panel configuration to NGINX..."
    
    # Insert admin configuration before the main location block
    sed -i '/location \/ {/i\
    # Admin Dashboard\
    location /admin/ {\
        alias /opt/connectassist/www/admin/;\
        index index.html;\
        try_files $uri $uri/ =404;\
    }\
\
    # API endpoints\
    location /api/ {\
        proxy_pass http://127.0.0.1:5001;\
        proxy_set_header Host $host;\
        proxy_set_header X-Real-IP $remote_addr;\
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\
        proxy_set_header X-Forwarded-Proto $scheme;\
    }\
\
    # Downloads directory for client packages\
    location /downloads/ {\
        alias /opt/connectassist/www/downloads/;\
        add_header Content-Disposition '"'"'attachment'"'"';\
    }\
' /etc/nginx/sites-available/connectassist.live
fi

# Test NGINX configuration
echo "🧪 Testing NGINX configuration..."
nginx -t

if [ $? -ne 0 ]; then
    echo "❌ NGINX configuration test failed!"
    echo "Please check the configuration manually."
    exit 1
fi

# Reload NGINX
echo "🔄 Reloading NGINX..."
systemctl reload nginx

# Start admin API server
echo "🚀 Starting Admin API server..."

# Kill any existing admin API process
pkill -f "admin_api.py" 2>/dev/null

# Start admin API server in background
cd "$PROJECT_DIR"
nohup python3 api/admin_api.py > /var/log/connectassist-api.log 2>&1 &

# Wait a moment for the API to start
sleep 3

# Check if API is running
if pgrep -f "admin_api.py" > /dev/null; then
    echo "✅ Admin API server started successfully"
else
    echo "❌ Failed to start Admin API server"
    echo "Check logs: tail -f /var/log/connectassist-api.log"
fi

# Test endpoints
echo "🧪 Testing deployed endpoints..."

# Test main site
echo "Testing main site..."
curl -s -o /dev/null -w "%{http_code}" https://connectassist.live/ | grep -q "200" && echo "✅ Main site: OK" || echo "❌ Main site: Failed"

# Test admin panel
echo "Testing admin panel..."
curl -s -o /dev/null -w "%{http_code}" https://connectassist.live/admin/ | grep -q "200" && echo "✅ Admin panel: OK" || echo "❌ Admin panel: Failed"

# Test API status
echo "Testing API status..."
sleep 2
curl -s -o /dev/null -w "%{http_code}" https://connectassist.live/api/status | grep -q "200" && echo "✅ API status: OK" || echo "❌ API status: Failed"

echo ""
echo "🎉 Deployment Complete!"
echo "======================="
echo ""
echo "📋 Deployment Summary:"
echo "✅ Latest code pulled from GitHub"
echo "✅ NGINX configuration updated"
echo "✅ Admin API server started"
echo "✅ All endpoints configured"
echo ""
echo "🔗 Access Points:"
echo "- Customer Portal: https://connectassist.live/"
echo "- Admin Dashboard: https://connectassist.live/admin/"
echo "- API Status: https://connectassist.live/api/status"
echo ""
echo "📝 Next Steps:"
echo "1. Test the admin dashboard at https://connectassist.live/admin/"
echo "2. Generate a support code in the admin dashboard"
echo "3. Test the customer portal workflow"
echo "4. Verify installer generation and download"
echo ""
echo "📊 Monitoring:"
echo "- API Logs: tail -f /var/log/connectassist-api.log"
echo "- NGINX Logs: tail -f /var/log/nginx/access.log"
echo "- System Status: systemctl status nginx"
echo ""
echo "🔧 Troubleshooting:"
echo "If any issues occur, run: ./scripts/health-check.sh"
