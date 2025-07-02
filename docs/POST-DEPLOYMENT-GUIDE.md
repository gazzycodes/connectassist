# ConnectAssist Post-Deployment Configuration Guide

This guide covers all manual configuration steps required after the initial ConnectAssist deployment to make the platform production-ready for customer support operations.

## Table of Contents

1. [Prerequisites Verification](#prerequisites-verification)
2. [RustDesk Server Configuration](#rustdesk-server-configuration)
3. [Security Configuration](#security-configuration)
4. [Client Configuration](#client-configuration)
5. [Monitoring Setup](#monitoring-setup)
6. [Backup Configuration](#backup-configuration)
7. [Production Checklist](#production-checklist)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites Verification

### 1. Verify Deployment Status

First, ensure all services are running correctly:

```bash
# Check system health
cd /opt/connectassist
./scripts/health-check.sh --report

# Verify Docker containers
cd docker && docker-compose ps

# Check NGINX status
systemctl status nginx

# Verify SSL certificate
openssl x509 -in /etc/letsencrypt/live/connectassist.live/cert.pem -noout -dates
```

### 2. Verify Network Access

```bash
# Test external connectivity
curl -I https://connectassist.live
curl -I https://connectassist.live/downloads/connectassist-windows.exe

# Check RustDesk ports
netstat -tuln | grep -E ':(21115|21116|21117|21118|21119)'
```

---

## RustDesk Server Configuration

### 1. Generate Encryption Keys

RustDesk requires encryption keys for secure communication:

```bash
# Navigate to RustDesk data directory
cd /opt/connectassist/data

# Generate private key (if not exists)
if [ ! -f "id_ed25519" ]; then
    openssl genpkey -algorithm ed25519 -out id_ed25519
    chmod 600 id_ed25519
fi

# Generate public key
if [ ! -f "id_ed25519.pub" ]; then
    openssl pkey -in id_ed25519 -pubout -out id_ed25519.pub
fi

# Set proper ownership
chown root:root id_ed25519*
```

### 2. Configure Server Settings

Create or update the RustDesk server configuration:

```bash
# Create server configuration
cat > /opt/connectassist/data/rustdesk-server.toml << 'TOML'
[network]
# Server listening address
addr = "0.0.0.0:21115"

# Relay server address
relay-addr = "0.0.0.0:21116"

# NAT type detection servers
nat-type-test-servers = [
    "stun.l.google.com:19302",
    "stun1.l.google.com:19302"
]

[security]
# Enable encryption
encrypt = true

# Key file path
key = "/data/id_ed25519"

# Allow unencrypted connections (set to false for production)
allow-unencrypted = false

[logging]
# Log level: error, warn, info, debug, trace
level = "info"

# Log file path
file = "/data/rustdesk-server.log"

[limits]
# Maximum concurrent connections
max-connections = 1000

# Connection timeout in seconds
connection-timeout = 30

# Maximum bandwidth per connection (bytes/sec)
max-bandwidth = 10485760  # 10MB/s
TOML

# Set proper ownership
chown root:root /opt/connectassist/data/rustdesk-server.toml
```

### 3. Restart RustDesk Services

```bash
cd /opt/connectassist/docker
docker-compose down
docker-compose up -d

# Verify services are running
docker-compose ps
```

### 4. Extract Server Configuration for Clients

```bash
# Get the public key for client configuration
cd /opt/connectassist/data
PUBLIC_KEY=$(cat id_ed25519.pub | grep -v "BEGIN\|END" | tr -d '\n')
echo "Public Key for clients: $PUBLIC_KEY"

# Get server configuration string
echo "Server Configuration:"
echo "Host: connectassist.live"
echo "Port: 21116"
echo "Key: $PUBLIC_KEY"
```

---

## Security Configuration

### 1. Configure Firewall Rules

```bash
# Ensure UFW is configured correctly
ufw status verbose

# Add specific rules if needed
ufw allow from 192.168.0.0/16 to any port 22  # Restrict SSH to local networks
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 21115:21119/tcp
ufw allow 21115:21119/udp

# Enable firewall
ufw --force enable
```

### 2. Secure SSH Access

```bash
# Create SSH key for secure access (recommended)
ssh-keygen -t ed25519 -f ~/.ssh/connectassist_key -C "connectassist-admin"

# Configure SSH for key-only authentication
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Restart SSH service
systemctl restart sshd
```

### 3. Configure Log Rotation

```bash
# Create log rotation configuration
cat > /etc/logrotate.d/connectassist << 'LOGROTATE'
/var/log/connectassist-health.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
}

/opt/connectassist/data/rustdesk-server.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
    postrotate
        cd /opt/connectassist/docker && docker-compose restart
    endscript
}
LOGROTATE
```

---

## Client Configuration

### 1. Update Client Configuration Files

Create configuration files for different client types:

```bash
# Create Windows client configuration
mkdir -p /var/www/connectassist.live/config

cat > /var/www/connectassist.live/config/windows-config.json << 'JSON'
{
    "host": "connectassist.live",
    "port": 21116,
    "key": "REPLACE_WITH_PUBLIC_KEY",
    "auto_connect": true,
    "unattended_access": true,
    "hide_tray_icon": false,
    "start_minimized": true,
    "allow_remote_config": true
}
JSON

# Create macOS client configuration
cat > /var/www/connectassist.live/config/macos-config.json << 'JSON'
{
    "host": "connectassist.live",
    "port": 21116,
    "key": "REPLACE_WITH_PUBLIC_KEY",
    "auto_connect": true,
    "unattended_access": true,
    "hide_dock_icon": false,
    "start_minimized": true,
    "allow_remote_config": true
}
JSON

# Create Linux client configuration
cat > /var/www/connectassist.live/config/linux-config.json << 'JSON'
{
    "host": "connectassist.live",
    "port": 21116,
    "key": "REPLACE_WITH_PUBLIC_KEY",
    "auto_connect": true,
    "unattended_access": true,
    "start_minimized": true,
    "allow_remote_config": true
}
JSON

# Set proper ownership
chown -R www-data:www-data /var/www/connectassist.live/config
```

### 2. Update Configuration with Actual Key

```bash
# Get the public key
cd /opt/connectassist/data
PUBLIC_KEY=$(cat id_ed25519.pub | grep -v "BEGIN\|END" | tr -d '\n')

# Update configuration files
sed -i "s/REPLACE_WITH_PUBLIC_KEY/$PUBLIC_KEY/g" /var/www/connectassist.live/config/*.json

echo "Client configuration files updated with public key"
```

---

## Monitoring Setup

### 1. Configure Automated Health Checks

```bash
# Add health check to crontab
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/connectassist/scripts/health-check.sh") | crontab -

# Create systemd service for health monitoring
cat > /etc/systemd/system/connectassist-monitor.service << 'SERVICE'
[Unit]
Description=ConnectAssist Health Monitor
After=network.target docker.service

[Service]
Type=oneshot
ExecStart=/opt/connectassist/scripts/health-check.sh
User=root
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICE

# Create timer for the service
cat > /etc/systemd/system/connectassist-monitor.timer << 'TIMER'
[Unit]
Description=Run ConnectAssist Health Monitor every 5 minutes
Requires=connectassist-monitor.service

[Timer]
OnCalendar=*:0/5
Persistent=true

[Install]
WantedBy=timers.target
TIMER

# Enable and start the timer
systemctl daemon-reload
systemctl enable connectassist-monitor.timer
systemctl start connectassist-monitor.timer
```

### 2. Configure Email Alerts (Optional)

```bash
# Install mail utilities
apt update && apt install -y mailutils postfix

# Configure postfix for sending emails
dpkg-reconfigure postfix

# Test email functionality
echo "ConnectAssist monitoring test" | mail -s "Test Alert" admin@connectassist.live
```

---

## Backup Configuration

### 1. Create Backup Script

```bash
cat > /opt/connectassist/scripts/backup.sh << 'BACKUP'
#!/bin/bash

# ConnectAssist Backup Script
BACKUP_DIR="/opt/backups/connectassist"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="connectassist_backup_$DATE.tar.gz"

# Create backup directory
mkdir -p $BACKUP_DIR

# Create backup
tar -czf "$BACKUP_DIR/$BACKUP_FILE" \
    --exclude='/opt/connectassist/.git' \
    --exclude='/opt/connectassist/data/*.log' \
    /opt/connectassist \
    /etc/nginx/sites-available/connectassist.live \
    /etc/letsencrypt/live/connectassist.live \
    /var/www/connectassist.live

# Keep only last 7 backups
find $BACKUP_DIR -name "connectassist_backup_*.tar.gz" -mtime +7 -delete

echo "Backup completed: $BACKUP_DIR/$BACKUP_FILE"
BACKUP

chmod +x /opt/connectassist/scripts/backup.sh

# Add to crontab for daily backups
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/connectassist/scripts/backup.sh") | crontab -
```

---

## Production Checklist

### Pre-Production Verification

- [ ] All services running (Docker, NGINX, RustDesk)
- [ ] SSL certificate valid and auto-renewal configured
- [ ] Health check script running without errors
- [ ] Firewall configured and active
- [ ] SSH access secured with key authentication
- [ ] RustDesk encryption keys generated and configured
- [ ] Client configuration files created and accessible
- [ ] Monitoring and alerting configured
- [ ] Backup system configured and tested
- [ ] Log rotation configured

### Security Checklist

- [ ] Default passwords changed
- [ ] SSH password authentication disabled
- [ ] Firewall rules properly configured
- [ ] SSL/TLS encryption enabled
- [ ] RustDesk encryption enabled
- [ ] Regular security updates scheduled
- [ ] Access logs monitored

### Performance Checklist

- [ ] System resources monitored (CPU, RAM, disk)
- [ ] Network connectivity tested
- [ ] Client download speeds acceptable
- [ ] RustDesk connection latency acceptable
- [ ] Concurrent connection limits tested

---

## Troubleshooting

### Common Issues

#### 1. RustDesk Connection Failed

```bash
# Check if services are running
cd /opt/connectassist/docker && docker-compose ps

# Check logs
docker-compose logs hbbs
docker-compose logs hbbr

# Verify ports are open
netstat -tuln | grep -E ':(21115|21116|21117|21118|21119)'

# Test connectivity
telnet connectassist.live 21116
```

#### 2. SSL Certificate Issues

```bash
# Check certificate status
certbot certificates

# Renew certificate manually
certbot renew --dry-run

# Check NGINX configuration
nginx -t
```

#### 3. Website Not Accessible

```bash
# Check NGINX status
systemctl status nginx

# Check NGINX logs
tail -f /var/log/nginx/error.log

# Verify DNS resolution
nslookup connectassist.live
```

#### 4. Health Check Failures

```bash
# Run health check manually
cd /opt/connectassist
./scripts/health-check.sh --report

# Check specific service
systemctl status docker
systemctl status nginx
```

### Log Locations

- **Health Check Logs**: `/var/log/connectassist-health.log`
- **RustDesk Server Logs**: `/opt/connectassist/data/rustdesk-server.log`
- **NGINX Logs**: `/var/log/nginx/access.log` and `/var/log/nginx/error.log`
- **Docker Logs**: `docker-compose logs` in `/opt/connectassist/docker/`
- **System Logs**: `journalctl -u connectassist-monitor`

### Emergency Procedures

#### Service Recovery

```bash
# Restart all services
cd /opt/connectassist/docker
docker-compose down
docker-compose up -d
systemctl restart nginx

# Full system recovery
./scripts/health-check.sh
```

#### Backup Restoration

```bash
# Stop services
cd /opt/connectassist/docker && docker-compose down
systemctl stop nginx

# Restore from backup
cd /opt/backups/connectassist
tar -xzf connectassist_backup_YYYYMMDD_HHMMSS.tar.gz -C /

# Restart services
systemctl start nginx
cd /opt/connectassist/docker && docker-compose up -d
```

---

## Next Steps

After completing this configuration:

1. **Test Client Connections**: Download and test client applications
2. **Document Credentials**: Securely store all passwords and keys
3. **Train Support Staff**: Provide access and training materials
4. **Monitor Performance**: Watch system metrics for the first week
5. **Schedule Maintenance**: Plan regular updates and maintenance windows

For additional support and advanced configuration options, refer to:
- [Customer Support Workflow Guide](CUSTOMER-WORKFLOW.md)
- [Technician Operations Guide](TECHNICIAN-WORKFLOW.md)
- [Operational Requirements](OPERATIONAL-REQUIREMENTS.md)
