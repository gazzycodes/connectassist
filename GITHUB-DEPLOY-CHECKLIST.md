# ConnectAssist GitHub Deployment Checklist

Quick reference checklist for GitHub-based deployment of ConnectAssist.

## 📋 Pre-Deployment Checklist

### Local Preparation
- [ ] GitHub account ready and logged in
- [ ] All ConnectAssist project files organized locally
- [ ] Project structure verified (docker/, nginx/, www/, scripts/, etc.)
- [ ] VPS credentials confirmed (IP: 103.195.103.198, user: root)

### GitHub Repository Setup
- [ ] New repository created: `connectassist`
- [ ] Repository set to Public
- [ ] Description added: "ConnectAssist - Self-hosted remote support platform using RustDesk"
- [ ] Website field set to: `https://connectassist.live`
- [ ] Topics added: remote-support, rustdesk, self-hosted, docker

## 🚀 Deployment Steps Checklist

### Phase 1: Repository Configuration
- [ ] All project files uploaded to GitHub
- [ ] File structure maintained correctly
- [ ] README.md updated with project details
- [ ] .gitignore file included
- [ ] Initial release (v1.0.0) created

### Phase 2: VPS Preparation
- [ ] SSH connection to VPS successful: `ssh root@103.195.103.198`
- [ ] System updated: `apt update && apt upgrade -y`
- [ ] Git installed: `apt install -y git`
- [ ] Git version verified: `git --version`
- [ ] Project directory created: `mkdir -p /opt`

### Phase 3: Repository Cloning
- [ ] Repository cloned: `git clone https://github.com/YOUR-USERNAME/connectassist.git /opt/connectassist`
- [ ] Directory navigation: `cd /opt/connectassist`
- [ ] All files present: `ls -la` shows complete structure
- [ ] Scripts made executable: `chmod +x scripts/*.sh`

### Phase 4: Environment Configuration
- [ ] Environment file copied: `cp docker/.env.example docker/.env`
- [ ] Environment variables updated:
  - [ ] `RUSTDESK_DOMAIN=connectassist.live`
  - [ ] `SSL_EMAIL=admin@connectassist.live`
  - [ ] `SERVER_IP=103.195.103.198`

### Phase 5: Deployment Execution
- [ ] Deployment script executed: `./scripts/init-server.sh`
- [ ] Script completed without critical errors
- [ ] "Installation completed!" message displayed
- [ ] All services reported as active

## ✅ Verification Checklist

### Service Status Verification
- [ ] NGINX status: `systemctl status nginx` → active (running)
- [ ] Docker status: `systemctl status docker` → active (running)
- [ ] Container status: `docker-compose ps` → both containers "Up"
- [ ] Port listening: `netstat -tuln | grep -E ':(21115|21116|21117)'` → ports active

### Website Verification
- [ ] HTTPS access: `curl -I https://connectassist.live` → HTTP/2 200
- [ ] Browser test: Website loads without SSL warnings
- [ ] Download page: Professional interface visible
- [ ] Device detection: Platform-specific download buttons work

### Security Verification
- [ ] SSL certificate: Valid and trusted
- [ ] Firewall status: `ufw status` → active with correct rules
- [ ] Port security: Only required ports open (21115-21119, 80, 443, 22)

### Health Check Verification
- [ ] Health script: `./scripts/health-check.sh --report` → all checks pass
- [ ] Log files: No critical errors in `/var/log/nginx/` or Docker logs
- [ ] Auto-renewal: SSL auto-renewal configured

## 🔧 Quick Troubleshooting

### Common Issues and Quick Fixes

#### Repository Issues
**Problem**: "Repository not found" during git clone
```bash
# Fix: Check repository URL and make sure it's public
git clone https://github.com/YOUR-ACTUAL-USERNAME/connectassist.git
```

**Problem**: "Permission denied" during git operations
```bash
# Fix: Ensure you're using the correct repository URL
# For public repos, HTTPS should work without authentication
```

#### File Permission Issues
**Problem**: "Permission denied" when running scripts
```bash
# Fix: Make scripts executable
chmod +x scripts/*.sh
chmod +x *.sh
```

#### Service Startup Issues
**Problem**: Docker containers not starting
```bash
# Check Docker service
systemctl status docker
systemctl start docker

# Check container logs
cd /opt/connectassist
docker-compose logs
```

**Problem**: NGINX not starting
```bash
# Check NGINX configuration
nginx -t

# Check for port conflicts
netstat -tuln | grep :80
netstat -tuln | grep :443

# Restart NGINX
systemctl restart nginx
```

#### SSL Certificate Issues
**Problem**: SSL certificate creation fails
```bash
# Check domain DNS
nslookup connectassist.live

# Verify domain points to your VPS IP
dig connectassist.live

# Try manual certificate creation
certbot certonly --standalone -d connectassist.live --email admin@connectassist.live
```

#### Website Access Issues
**Problem**: Website shows default NGINX page
```bash
# Check site configuration
ls -la /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx
```

**Problem**: "Connection refused" or timeout
```bash
# Check firewall
ufw status

# Reset firewall if needed
ufw --force reset
./scripts/init-server.sh  # This will reconfigure firewall
```

## 🔄 Update Workflow Checklist

### When Making Changes
- [ ] Update files locally
- [ ] Test changes locally (if possible)
- [ ] Commit to GitHub: `git add . && git commit -m "Description"`
- [ ] Push to GitHub: `git push origin main`

### Deploying Updates to VPS
- [ ] SSH to VPS: `ssh root@103.195.103.198`
- [ ] Navigate to project: `cd /opt/connectassist`
- [ ] Pull updates: `git pull origin main`
- [ ] Restart services if needed: `docker-compose restart`
- [ ] Verify deployment: `./scripts/health-check.sh`

## 📞 Emergency Procedures

### Complete Service Restart
```bash
# Stop all services
docker-compose down
systemctl stop nginx

# Start all services
systemctl start nginx
docker-compose up -d

# Verify everything is working
./scripts/health-check.sh --report
```

### Rollback to Previous Version
```bash
# Check commit history
git log --oneline

# Rollback to previous commit
git reset --hard HEAD~1

# Restart services
docker-compose restart
systemctl reload nginx
```

### Complete Redeployment
```bash
# Backup current installation
cp -r /opt/connectassist /opt/connectassist-backup-$(date +%Y%m%d)

# Fresh clone
rm -rf /opt/connectassist
git clone https://github.com/YOUR-USERNAME/connectassist.git /opt/connectassist
cd /opt/connectassist

# Reconfigure and redeploy
cp docker/.env.example docker/.env
nano docker/.env  # Update settings
chmod +x scripts/*.sh
./scripts/init-server.sh
```

## 📊 Success Metrics

Your deployment is successful when:
- [ ] Website loads at https://connectassist.live
- [ ] SSL certificate is valid (green lock in browser)
- [ ] Download buttons are functional
- [ ] Health check reports "All health checks passed"
- [ ] Docker containers show "Up" status
- [ ] NGINX and Docker services are "active (running)"

## 🎯 Next Steps After Successful Deployment

1. **Build Custom Clients**
   - Configure `builder/builder-config.json`
   - Run `python3 builder/rustdesk-builder.py`

2. **Customize Branding**
   - Edit `www/index.html` and `www/assets/style.css`
   - Update company information and colors

3. **Set Up Monitoring**
   - Configure email alerts in health check script
   - Set up log monitoring

4. **Plan for Scale**
   - Consider subdomain setup for multiple clients
   - Plan backup and disaster recovery procedures

---
**📖 Full Documentation**: See `docs/GITHUB-DEPLOYMENT-WORKFLOW.md` for complete details.
