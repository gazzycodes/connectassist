# ConnectAssist Quick Deploy Reference

**Your VPS Details:**
- IP: `103.195.103.198`
- User: `root`
- Password: `IBHTfYtj7tWFi_Shw234k4u`
- Domain: `connectassist.live`

## 🚀 Quick Deploy Commands

### Method 1: GitHub (Recommended)

```bash
# 1. Connect to VPS
ssh root@103.195.103.198

# 2. Install Git and clone
apt update && apt install -y git
cd /opt
git clone https://github.com/YOUR-USERNAME/connectassist.git
cd connectassist

# 3. Configure environment
cp docker/.env.example docker/.env
nano docker/.env  # Update RUSTDESK_DOMAIN=connectassist.live

# 4. Make executable and deploy
chmod +x scripts/*.sh
./scripts/init-server.sh

# 5. Verify
curl -I https://connectassist.live
docker-compose -f docker/docker-compose.yml ps
```

### Method 2: Direct Transfer (SCP)

```bash
# 1. On local machine - create archive
tar -czf connectassist.tar.gz *

# 2. Transfer to VPS
scp connectassist.tar.gz root@103.195.103.198:/opt/

# 3. Connect and extract
ssh root@103.195.103.198
cd /opt && tar -xzf connectassist.tar.gz
mkdir connectassist && mv * connectassist/ 2>/dev/null
cd connectassist

# 4. Continue with steps 3-5 from Method 1
```

## ✅ Quick Verification

```bash
# Check all services
systemctl status nginx docker
docker-compose -f /opt/connectassist/docker/docker-compose.yml ps
curl -I https://connectassist.live
netstat -tuln | grep -E ':(21115|21116|21117)'
```

## 🔧 Quick Fixes

```bash
# Restart services
systemctl restart nginx docker
cd /opt/connectassist && docker-compose restart

# Check logs
docker-compose -f /opt/connectassist/docker/docker-compose.yml logs
tail -f /var/log/nginx/error.log

# Reset firewall
ufw --force reset && /opt/connectassist/scripts/init-server.sh
```

## 📞 Emergency Commands

```bash
# Stop everything
docker-compose -f /opt/connectassist/docker/docker-compose.yml down
systemctl stop nginx

# Start everything
systemctl start nginx docker
cd /opt/connectassist && docker-compose up -d

# Health check
/opt/connectassist/scripts/health-check.sh --report
```

---
**📖 Full Guide:** See `docs/BEGINNER-DEPLOYMENT-GUIDE.md` for detailed instructions.
