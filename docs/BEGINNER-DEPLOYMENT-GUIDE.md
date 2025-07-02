# ConnectAssist Complete Deployment Guide for Beginners

This guide will walk you through deploying ConnectAssist to your VPS server step by step, assuming you're new to server deployment.

## 📋 Prerequisites Check

### What You Need Before Starting

1. **Your VPS Details** (✅ You have these):
   - IP: 103.195.103.198
   - Username: root
   - Password: IBHTfYtj7tWFi_Shw234k4u
   - OS: Ubuntu 22.04
   - Domain: connectassist.live

2. **Local Machine Requirements**:
   - Windows, macOS, or Linux computer
   - Internet connection
   - Terminal/Command Prompt access

3. **Tools to Install Locally** (we'll cover this):
   - SSH client (built into most systems)
   - SCP/SFTP client (optional, for file transfer)
   - Git (recommended method)

### Step 1: Verify VPS Access

First, let's make sure you can connect to your VPS:

**On Windows:**
```cmd
ssh root@103.195.103.198
```

**On macOS/Linux:**
```bash
ssh root@103.195.103.198
```

When prompted, enter your password: `IBHTfYtj7tWFi_Shw234k4u`

**Expected Output:**
```
Welcome to Ubuntu 22.04.x LTS (GNU/Linux ...)
root@your-server:~#
```

**✅ Success Check**: You should see a command prompt starting with `root@`

**❌ Troubleshooting**:
- If "connection refused": Check if the IP is correct
- If "timeout": Check your internet connection
- If "permission denied": Double-check the password

Type `exit` to disconnect for now.

## 🚀 File Transfer Methods Comparison

### Method 1: GitHub (RECOMMENDED) ⭐

**Pros:**
- ✅ Version control and backup
- ✅ Easy updates and collaboration
- ✅ Professional workflow
- ✅ Free for public repositories

**Cons:**
- ❌ Requires GitHub account setup
- ❌ Slight learning curve

**Best for:** Long-term projects, team collaboration, professional deployment

### Method 2: SCP (Simple Copy Protocol)

**Pros:**
- ✅ Direct file transfer
- ✅ No third-party services
- ✅ Works immediately

**Cons:**
- ❌ No version control
- ❌ Manual process for updates
- ❌ No backup/history

**Best for:** Quick one-time deployments, small projects

### Method 3: SFTP (Secure File Transfer Protocol)

**Pros:**
- ✅ User-friendly GUI tools available
- ✅ Direct file transfer
- ✅ Good for beginners

**Cons:**
- ❌ No version control
- ❌ Requires additional software
- ❌ Manual update process

**Best for:** Users who prefer GUI tools

## 🎯 RECOMMENDED APPROACH: GitHub Method

We'll use GitHub because it's the most professional and maintainable approach.

### Step 2: Set Up GitHub Repository

#### 2.1 Create GitHub Account (if you don't have one)
1. Go to [github.com](https://github.com)
2. Click "Sign up"
3. Follow the registration process

#### 2.2 Create Repository
1. Click the "+" icon in top right
2. Select "New repository"
3. Repository name: `connectassist`
4. Description: `ConnectAssist - Self-hosted remote support platform`
5. Set to **Public** (free) or **Private** (if you have a paid plan)
6. ✅ Check "Add a README file"
7. Click "Create repository"

#### 2.3 Upload Project Files
1. In your new repository, click "uploading an existing file"
2. Drag and drop ALL the ConnectAssist files we created
3. Or click "choose your files" and select all files/folders
4. Scroll down, add commit message: "Initial ConnectAssist setup"
5. Click "Commit changes"

**✅ Success Check**: You should see all your files listed in the repository

### Step 3: Deploy to VPS Using GitHub

#### 3.1 Connect to Your VPS
```bash
ssh root@103.195.103.198
```
Enter password when prompted.

#### 3.2 Install Git on VPS
```bash
apt update
apt install -y git
```

**Expected Output:**
```
Reading package lists... Done
Building dependency tree... Done
...
git is already the newest version (1:2.34.1-1ubuntu1.x)
```

#### 3.3 Clone Your Repository
Replace `YOUR-USERNAME` with your GitHub username:

```bash
cd /opt
git clone https://github.com/YOUR-USERNAME/connectassist.git
cd connectassist
```

**Expected Output:**
```
Cloning into 'connectassist'...
remote: Enumerating objects: XX, done.
remote: Counting objects: 100% (XX/XX), done.
...
```

**✅ Success Check**: 
```bash
ls -la
```
You should see all your ConnectAssist files listed.

**❌ Troubleshooting**:
- If "repository not found": Check the URL and make sure repository is public
- If "permission denied": Make sure you're using the correct GitHub username

### Step 4: Configure Environment

#### 4.1 Set Up Environment Variables
```bash
cd /opt/connectassist
cp docker/.env.example docker/.env
nano docker/.env
```

**In the nano editor**, update these values:
```bash
RUSTDESK_DOMAIN=connectassist.live
SSL_EMAIL=admin@connectassist.live
SERVER_IP=103.195.103.198
```

**To save in nano:**
1. Press `Ctrl + X`
2. Press `Y` to confirm
3. Press `Enter` to save

#### 4.2 Make Scripts Executable
```bash
chmod +x scripts/*.sh
chmod +x setup.sh
chmod +x dev.sh
chmod +x check-local.sh
```

**✅ Success Check**: No error messages should appear.

### Step 5: Run Initial Server Setup

#### 5.1 Execute the Setup Script
```bash
./scripts/init-server.sh
```

**This script will:**
- Update system packages (2-3 minutes)
- Install Docker, NGINX, Certbot
- Configure firewall
- Set up SSL certificates
- Start RustDesk services

**Expected Duration:** 5-10 minutes

**Expected Output (key parts):**
```
🚀 ConnectAssist Server Initialization
==================================
📦 Updating system packages...
📦 Installing required packages...
🔥 Configuring firewall...
🌐 Configuring NGINX...
🔒 Setting up SSL certificate...
🐳 Setting up RustDesk Docker containers...
✅ Installation completed!
```

**✅ Success Check**: Look for "✅ Installation completed!" at the end.

#### 5.2 Verify Services Are Running
```bash
# Check Docker containers
docker-compose -f /opt/connectassist/docker/docker-compose.yml ps

# Check NGINX
systemctl status nginx

# Check SSL certificate
curl -I https://connectassist.live
```

**Expected Output:**
```bash
# Docker containers should show "Up"
NAME    COMMAND    SERVICE    STATUS    PORTS
hbbs    ...        hbbs       Up        0.0.0.0:21115->21115/tcp, ...
hbbr    ...        hbbr       Up        0.0.0.0:21117->21117/tcp, ...

# NGINX should show "active (running)"
● nginx.service - A high performance web server
   Active: active (running) since ...

# SSL check should show "HTTP/2 200"
HTTP/2 200
server: nginx/1.18.0
```

### Step 6: Test Your Deployment

#### 6.1 Test Website Access
Open your web browser and go to: `https://connectassist.live`

**✅ Success Check**: You should see the ConnectAssist download page with:
- Professional design
- Download buttons for different platforms
- FAQ section
- No SSL certificate warnings

#### 6.2 Test RustDesk Server Ports
```bash
# Check if RustDesk ports are listening
netstat -tuln | grep -E ':(21115|21116|21117|21118|21119)'
```

**Expected Output:**
```
tcp6    0    0 :::21115    :::*    LISTEN
tcp6    0    0 :::21116    :::*    LISTEN
tcp6    0    0 :::21117    :::*    LISTEN
...
```

#### 6.3 Run Health Check
```bash
/opt/connectassist/scripts/health-check.sh --report
```

**Expected Output:**
```
[TIMESTAMP] [INFO] Starting ConnectAssist health check...
[TIMESTAMP] [INFO] RustDesk containers are running (2 active)
[TIMESTAMP] [INFO] NGINX is running
[TIMESTAMP] [INFO] SSL certificate expires in XXX days
[TIMESTAMP] [INFO] Website is accessible (HTTP 200)
[TIMESTAMP] [INFO] All health checks passed
```

## 🔧 Post-Deployment Configuration

### Step 7: Set Up Monitoring

#### 7.1 Configure Auto-SSL Renewal
```bash
/opt/connectassist/scripts/update-certs.sh setup-auto
```

#### 7.2 Set Up Health Monitoring
```bash
# Add health check to cron
crontab -e
```

Add this line at the bottom:
```bash
*/15 * * * * /opt/connectassist/scripts/health-check.sh
```

Save and exit (Ctrl+X, Y, Enter).

### Step 8: Build Your First Client (Optional)

#### 8.1 Install Build Dependencies
```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# Install build tools
apt install -y build-essential pkg-config libssl-dev
```

#### 8.2 Configure Client Builder
```bash
cd /opt/connectassist/builder
nano builder-config.json
```

Update the domain and company information, then save.

#### 8.3 Build Clients
```bash
python3 rustdesk-builder.py
```

**Note**: This step takes 15-30 minutes and requires significant resources.

## ❌ Common Issues and Solutions

### Issue 1: "Permission Denied" Errors
**Solution:**
```bash
# Make sure you're running as root
sudo su -
# Or prefix commands with sudo
sudo ./scripts/init-server.sh
```

### Issue 2: Docker Containers Won't Start
**Solution:**
```bash
# Check Docker service
systemctl status docker
systemctl start docker

# Check container logs
cd /opt/connectassist
docker-compose logs
```

### Issue 3: SSL Certificate Fails
**Solution:**
```bash
# Make sure domain points to your server
nslookup connectassist.live

# Try manual certificate creation
certbot certonly --standalone -d connectassist.live
```

### Issue 4: Website Shows NGINX Default Page
**Solution:**
```bash
# Check NGINX configuration
nginx -t
# Restart NGINX
systemctl restart nginx
# Check site is enabled
ls -la /etc/nginx/sites-enabled/
```

### Issue 5: Firewall Blocking Connections
**Solution:**
```bash
# Check firewall status
ufw status
# Reset and reconfigure if needed
ufw --force reset
/opt/connectassist/scripts/init-server.sh
```

## ✅ Final Verification Checklist

After deployment, verify these items:

- [ ] Website loads at https://connectassist.live
- [ ] SSL certificate is valid (no browser warnings)
- [ ] Download buttons are visible on the website
- [ ] Docker containers are running (`docker-compose ps`)
- [ ] NGINX is active (`systemctl status nginx`)
- [ ] Firewall allows required ports (`ufw status`)
- [ ] Health check passes (`./scripts/health-check.sh`)
- [ ] Auto-renewal is configured (`crontab -l`)

## 🎉 Success! What's Next?

Your ConnectAssist platform is now live! Here's what you can do next:

1. **Build Custom Clients**: Follow the client building guide
2. **Customize Branding**: Edit the website design and colors
3. **Set Up Monitoring**: Configure email alerts for issues
4. **Scale for Clients**: Set up subdomains for different clients
5. **Backup Strategy**: Implement regular backups

## 📞 Getting Help

If you encounter issues:
1. Check the troubleshooting section above
2. Run the health check script for diagnostics
3. Check log files in `/var/log/nginx/` and Docker logs
4. Refer to the detailed documentation in `docs/`

Your ConnectAssist platform is now ready to provide professional remote support services!

---

## 🔄 Alternative Method: Direct File Transfer (SCP)

If you prefer not to use GitHub, here's how to transfer files directly:

### Prerequisites for SCP Method
- All ConnectAssist files on your local machine
- SSH access to your VPS (already verified above)

### Step-by-Step SCP Deployment

#### 1. Prepare Files Locally
```bash
# On your local machine, navigate to your ConnectAssist folder
cd /path/to/your/connectassist/folder

# Create a compressed archive
tar -czf connectassist.tar.gz *
```

#### 2. Transfer Files to VPS
```bash
# Transfer the archive to your VPS
scp connectassist.tar.gz root@103.195.103.198:/opt/

# Connect to VPS
ssh root@103.195.103.198
```

#### 3. Extract and Set Up on VPS
```bash
# On the VPS
cd /opt
tar -xzf connectassist.tar.gz
mkdir -p connectassist
mv * connectassist/ 2>/dev/null || true
cd connectassist

# Make scripts executable
chmod +x scripts/*.sh
chmod +x *.sh

# Continue with Step 4 from the main guide above
```

### Updating Files with SCP
When you make changes locally:
```bash
# Create new archive
tar -czf connectassist-update.tar.gz *

# Transfer to VPS
scp connectassist-update.tar.gz root@103.195.103.198:/opt/

# On VPS: backup current version and update
ssh root@103.195.103.198
cd /opt
cp -r connectassist connectassist-backup-$(date +%Y%m%d)
cd connectassist
tar -xzf ../connectassist-update.tar.gz
```

---

## 📱 GUI Method: Using FileZilla (SFTP)

For users who prefer graphical interfaces:

### 1. Install FileZilla
- Download from [filezilla-project.org](https://filezilla-project.org/)
- Install on your local machine

### 2. Connect to VPS
- Host: `103.195.103.198`
- Username: `root`
- Password: `IBHTfYtj7tWFi_Shw234k4u`
- Port: `22`
- Protocol: `SFTP`

### 3. Transfer Files
- Navigate to `/opt/` on the remote side
- Create folder `connectassist`
- Drag and drop all your local ConnectAssist files

### 4. Set Permissions via SSH
```bash
ssh root@103.195.103.198
cd /opt/connectassist
chmod +x scripts/*.sh
chmod +x *.sh
```

Then continue with the main deployment steps.
