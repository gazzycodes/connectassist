# ConnectAssist Deployment Guide

This guide covers the complete deployment process for ConnectAssist with **Web Admin Dashboard** and **Customer Portal Integration** on your VPS.

## Prerequisites

- Ubuntu 22.04 VPS with root access
- Domain name pointed to your VPS IP
- Ports 21115, 21116, 80, 443, 5001 open
- At least 2GB RAM and 2 vCPU recommended
- Python 3.8+ with pip installed
- Git installed

## Complete Deployment Process

### 1. Initial Server Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y docker.io docker-compose nginx certbot python3-certbot-nginx git python3-pip

# Clone the repository
git clone https://github.com/yourusername/connectassist.live.git /opt/connectassist
cd /opt/connectassist

# Make scripts executable
chmod +x scripts/*.sh

# Run the initialization script
sudo ./scripts/init-server.sh
```

### 2. Configure Environment

Edit the environment file:
```bash
sudo nano docker/.env
```

Update the following variables:
- `RUSTDESK_DOMAIN`: Your domain name (e.g., connectassist.live)
- `SSL_EMAIL`: Your email for SSL certificates
- `SERVER_IP`: Your VPS IP address

### 3. Deploy RustDesk Services

```bash
# Start RustDesk services
cd /opt/connectassist/docker
sudo docker-compose up -d

# Check service status
sudo docker-compose ps
```

### 4. Install Python Dependencies

```bash
# Install Flask API dependencies
sudo pip3 install flask flask-cors requests

# Verify installation
python3 -c "import flask, flask_cors, requests; print('Dependencies installed successfully')"
```

### 5. Configure NGINX

```bash
# Copy NGINX configuration
sudo cp nginx/sites-available/connectassist.live /etc/nginx/sites-available/
sudo ln -sf /etc/nginx/sites-available/connectassist.live /etc/nginx/sites-enabled/

# Test NGINX configuration
sudo nginx -t

# Reload NGINX
sudo systemctl reload nginx
```

### 6. Setup SSL Certificates

```bash
# Generate SSL certificates
sudo certbot --nginx -d yourdomain.com

# Verify auto-renewal
sudo certbot renew --dry-run
```

### 7. Deploy Flask API Server

```bash
# Start API server in background
cd /opt/connectassist
nohup python3 api/admin_api.py > logs/api.log 2>&1 &

# Verify API is running
curl -s https://yourdomain.com/api/status | python3 -m json.tool
```

### 8. Verify Complete Deployment

```bash
# Check all services
sudo systemctl status nginx
sudo docker-compose -f docker/docker-compose.yml ps
ps aux | grep admin_api.py

# Test web interfaces
curl -I https://yourdomain.com
curl -I https://yourdomain.com/admin
curl -s https://yourdomain.com/api/status
```

### 4. Configure SSL

```bash
# Setup SSL certificates
sudo ./scripts/update-certs.sh setup-auto

# Test SSL configuration
sudo ./scripts/update-certs.sh test
```

### 5. Verify Deployment

```bash
# Run health check
sudo ./scripts/health-check.sh --report

# Test website access
curl -I https://yourdomain.com
```

## Manual Deployment Steps

### Docker Setup

1. **Install Docker and Docker Compose**
```bash
sudo apt update
sudo apt install -y docker.io docker-compose
sudo systemctl enable docker
sudo systemctl start docker
```

2. **Configure RustDesk Services**
```bash
cd /opt/connectassist
sudo docker-compose up -d
```

### NGINX Configuration

1. **Install NGINX**
```bash
sudo apt install -y nginx
```

2. **Configure Site**
```bash
sudo cp nginx/sites-available/connectassist.live /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/connectassist.live /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
```

### SSL Certificate Setup

1. **Install Certbot**
```bash
sudo apt install -y certbot python3-certbot-nginx
```

2. **Obtain Certificate**
```bash
sudo certbot --nginx -d yourdomain.com --email your@email.com --agree-tos --non-interactive
```

### Firewall Configuration

```bash
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 21115:21119/tcp
sudo ufw allow 21116/udp
sudo ufw --force enable
```

## Building Custom Clients

### Prerequisites for Building

```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# Install build dependencies
sudo apt install -y build-essential pkg-config libssl-dev libgtk-3-dev libxdo-dev libxfixes-dev libxrandr-dev

# For Windows cross-compilation
sudo apt install -y mingw-w64
rustup target add x86_64-pc-windows-gnu
```

### Build Clients

```bash
cd /opt/connectassist/builder

# Configure build settings
nano builder-config.json

# Build all clients
python3 rustdesk-builder.py

# Built clients will be available in ../www/downloads/
```

## Post-Deployment Configuration

### 1. Test RustDesk Connection

1. Download a client from your domain
2. Run the client
3. Note the connection ID
4. Test connection from another RustDesk client

### 2. Configure Unattended Access

```bash
# Generate encryption key
openssl rand -hex 32

# Update builder-config.json with the key
# Rebuild clients with unattended access enabled
```

### 3. Setup Monitoring

```bash
# Setup health monitoring cron job
sudo crontab -e

# Add this line:
# */15 * * * * /opt/connectassist/scripts/health-check.sh
```

### 4. Configure Backups

```bash
# Create backup script
sudo nano /usr/local/bin/connectassist-backup.sh

# Add backup cron job
sudo crontab -e
# 0 2 * * * /usr/local/bin/connectassist-backup.sh
```

## Troubleshooting

### Common Issues

1. **Containers not starting**
```bash
sudo docker-compose logs
sudo docker-compose restart
```

2. **SSL certificate issues**
```bash
sudo ./scripts/update-certs.sh status
sudo ./scripts/update-certs.sh renew
```

3. **Connection issues**
```bash
# Check ports
sudo netstat -tuln | grep -E ':(21115|21116|21117)'

# Check firewall
sudo ufw status
```

4. **Website not accessible**
```bash
sudo nginx -t
sudo systemctl status nginx
sudo systemctl restart nginx
```

### Log Locations

- NGINX logs: `/var/log/nginx/connectassist.live.*.log`
- Docker logs: `sudo docker-compose logs`
- Health check logs: `/var/log/connectassist-health.log`
- SSL logs: `/var/log/connectassist-ssl.log`

## Scaling and Multi-Tenancy

### Option 1: Subdomains

```bash
# Add subdomain to DNS
# Update NGINX configuration for subdomain
# Deploy separate Docker stack for each client
```

### Option 2: Separate VPS

```bash
# Deploy complete stack on new VPS
# Use different domain or subdomain
# Maintain separate configurations
```

## Security Considerations

1. **Regular Updates**
```bash
sudo apt update && sudo apt upgrade
sudo docker-compose pull && sudo docker-compose up -d
```

2. **Firewall Rules**
- Only open required ports
- Consider IP whitelisting for admin access

3. **SSL Monitoring**
- Monitor certificate expiry
- Setup renewal alerts

4. **Access Logs**
- Monitor connection logs
- Setup log rotation
- Consider log analysis tools

## Performance Optimization

1. **Resource Monitoring**
```bash
# Monitor system resources
htop
df -h
free -h
```

2. **Docker Optimization**
```bash
# Limit container resources in docker-compose.yml
# Setup log rotation for containers
```

3. **NGINX Optimization**
- Enable gzip compression
- Configure caching headers
- Optimize worker processes

## Maintenance

### Regular Tasks

1. **Weekly**
   - Check system updates
   - Review logs for errors
   - Test backup procedures

2. **Monthly**
   - Update Docker images
   - Review SSL certificate status
   - Performance analysis

3. **Quarterly**
   - Security audit
   - Capacity planning
   - Disaster recovery testing
