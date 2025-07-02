#!/bin/bash

# ConnectAssist Server Initialization Script
# This script sets up the complete ConnectAssist environment

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="connectassist.live"
EMAIL="admin@connectassist.live"
PROJECT_DIR="/opt/connectassist"
WEB_DIR="/var/www/connectassist.live"

echo -e "${BLUE}🚀 ConnectAssist Server Initialization${NC}"
echo "=================================="

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ This script must be run as root${NC}"
   exit 1
fi

# Update system
echo -e "${YELLOW}📦 Updating system packages...${NC}"
apt update && apt upgrade -y

# Install required packages
echo -e "${YELLOW}📦 Installing required packages...${NC}"
apt install -y curl wget git nginx certbot python3-certbot-nginx ufw docker.io docker-compose

# Configure firewall
echo -e "${YELLOW}🔥 Configuring firewall...${NC}"
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 21115/tcp
ufw allow 21116/tcp
ufw allow 21116/udp
ufw allow 21117/tcp
ufw allow 21118/tcp
ufw allow 21119/tcp
ufw --force enable

# Create project directory
echo -e "${YELLOW}📁 Setting up project directories...${NC}"
mkdir -p $PROJECT_DIR
mkdir -p $WEB_DIR
mkdir -p $WEB_DIR/downloads
mkdir -p $WEB_DIR/assets

# Copy web files
if [ -d "./www" ]; then
    echo -e "${YELLOW}📋 Copying web files...${NC}"
    cp -r ./www/* $WEB_DIR/
    chown -R www-data:www-data $WEB_DIR
    chmod -R 755 $WEB_DIR
fi

# Setup NGINX
echo -e "${YELLOW}🌐 Configuring NGINX...${NC}"
if [ -f "./nginx/sites-available/connectassist.live" ]; then
    cp ./nginx/sites-available/connectassist.live /etc/nginx/sites-available/
    ln -sf /etc/nginx/sites-available/connectassist.live /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
fi

# Test NGINX configuration
nginx -t
systemctl restart nginx
systemctl enable nginx

# Setup SSL with Let's Encrypt
echo -e "${YELLOW}🔒 Setting up SSL certificate...${NC}"
certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email $EMAIL --redirect

# Setup Docker for RustDesk
echo -e "${YELLOW}🐳 Setting up RustDesk Docker containers...${NC}"
cd $PROJECT_DIR

# Copy Docker configuration
if [ -f "../docker/docker-compose.yml" ]; then
    cp ../docker/docker-compose.yml .
    cp ../docker/.env .
fi

# Create data directory for RustDesk
mkdir -p ./data

# Start RustDesk services
docker-compose up -d

# Wait for services to start
echo -e "${YELLOW}⏳ Waiting for services to start...${NC}"
sleep 10

# Check service status
echo -e "${YELLOW}🔍 Checking service status...${NC}"
docker-compose ps

# Setup systemd service for auto-start
echo -e "${YELLOW}⚙️ Setting up systemd service...${NC}"
cat > /etc/systemd/system/connectassist.service << EOF
[Unit]
Description=ConnectAssist RustDesk Services
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$PROJECT_DIR
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable connectassist.service

# Setup log rotation
echo -e "${YELLOW}📝 Setting up log rotation...${NC}"
cat > /etc/logrotate.d/connectassist << EOF
/var/log/nginx/connectassist.live.*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 www-data www-data
    postrotate
        systemctl reload nginx
    endscript
}
EOF

# Setup health check cron
echo -e "${YELLOW}🏥 Setting up health monitoring...${NC}"
cat > /usr/local/bin/connectassist-health.sh << 'EOF'
#!/bin/bash
# ConnectAssist Health Check Script

LOG_FILE="/var/log/connectassist-health.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Check if Docker containers are running
if ! docker-compose -f /opt/connectassist/docker-compose.yml ps | grep -q "Up"; then
    echo "[$DATE] ERROR: RustDesk containers not running, restarting..." >> $LOG_FILE
    cd /opt/connectassist && docker-compose restart
fi

# Check if NGINX is running
if ! systemctl is-active --quiet nginx; then
    echo "[$DATE] ERROR: NGINX not running, restarting..." >> $LOG_FILE
    systemctl restart nginx
fi

# Check SSL certificate expiry (warn if less than 30 days)
CERT_DAYS=$(openssl x509 -in /etc/letsencrypt/live/connectassist.live/cert.pem -noout -dates | grep notAfter | cut -d= -f2 | xargs -I {} date -d "{}" +%s)
CURRENT_DAYS=$(date +%s)
DAYS_LEFT=$(( (CERT_DAYS - CURRENT_DAYS) / 86400 ))

if [ $DAYS_LEFT -lt 30 ]; then
    echo "[$DATE] WARNING: SSL certificate expires in $DAYS_LEFT days" >> $LOG_FILE
fi

echo "[$DATE] Health check completed" >> $LOG_FILE
EOF

chmod +x /usr/local/bin/connectassist-health.sh

# Add to crontab
(crontab -l 2>/dev/null; echo "*/15 * * * * /usr/local/bin/connectassist-health.sh") | crontab -

# Final status check
echo -e "${GREEN}✅ Installation completed!${NC}"
echo ""
echo -e "${BLUE}📊 Service Status:${NC}"
echo "NGINX: $(systemctl is-active nginx)"
echo "Docker: $(systemctl is-active docker)"
echo "ConnectAssist: $(systemctl is-active connectassist)"
echo ""
echo -e "${BLUE}🌐 Access Information:${NC}"
echo "Web Portal: https://$DOMAIN"
echo "RustDesk Server: $DOMAIN:21115"
echo ""
echo -e "${BLUE}📁 Important Paths:${NC}"
echo "Project Directory: $PROJECT_DIR"
echo "Web Directory: $WEB_DIR"
echo "Logs: /var/log/nginx/connectassist.live.*.log"
echo ""
echo -e "${GREEN}🎉 ConnectAssist is now ready!${NC}"
echo "Visit https://$DOMAIN to test the download portal."
