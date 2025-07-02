# ConnectAssist GitHub Deployment Workflow

Complete step-by-step guide for deploying ConnectAssist using GitHub method.

## 🎯 Phase 1: Repository Setup

### Step 1.1: Create New Repository

1. **Navigate to GitHub**
   - Go to [github.com](https://github.com)
   - Sign in to your account
   - Click the **"+"** icon in the top-right corner
   - Select **"New repository"**

2. **Repository Configuration**
   ```
   Repository name: connectassist
   Description: ConnectAssist - Self-hosted remote support platform using RustDesk
   Visibility: ✅ Public (recommended for easier deployment)
   
   Initialize repository:
   ✅ Add a README file
   ❌ Add .gitignore (we'll use our custom one)
   ❌ Choose a license (add later if needed)
   ```

3. **Click "Create repository"**

**✅ Success Check**: You should see a new repository at `https://github.com/YOUR-USERNAME/connectassist`

### Step 1.2: Repository Settings Configuration

1. **Navigate to Settings**
   - In your new repository, click the **"Settings"** tab
   - This is located in the top menu bar of your repository

2. **General Settings** (scroll down to find these sections):
   ```
   Repository name: connectassist (confirm it's correct)
   Description: ConnectAssist - Self-hosted remote support platform using RustDesk
   Website: https://connectassist.live (add your domain)
   Topics: Add tags like: remote-support, rustdesk, self-hosted, docker
   ```

3. **Features Section**:
   ```
   ✅ Wikis (for documentation)
   ✅ Issues (for bug tracking)
   ✅ Sponsorships (optional)
   ✅ Preserve this repository (recommended)
   ✅ Projects (for project management)
   ```

4. **Pull Requests Section**:
   ```
   ✅ Allow merge commits
   ✅ Allow squash merging
   ✅ Allow rebase merging
   ✅ Always suggest updating pull request branches
   ✅ Allow auto-merge
   ❌ Automatically delete head branches (keep for now)
   ```

## 🚀 Phase 2: File Upload Process

### Step 2.1: Prepare Local Files

Before uploading, ensure your ConnectAssist project structure is complete:

```
connectassist/
├── README.md
├── setup.sh
├── dev.sh
├── check-local.sh
├── .gitignore
├── docker/
├── nginx/
├── www/
├── builder/
├── scripts/
└── docs/
```

### Step 2.2: Upload Files to Repository

**Method A: Web Interface (Recommended for Initial Upload)**

1. **Navigate to your repository main page**
2. **Click "uploading an existing file"** (blue link in the middle of the page)
3. **Upload process**:
   - **Drag and drop** your entire ConnectAssist folder contents
   - OR click **"choose your files"** and select all files/folders
   - **Important**: Select ALL files and folders at once to maintain structure

4. **Commit the upload**:
   ```
   Commit message: Initial ConnectAssist project setup
   Extended description: 
   Complete ConnectAssist remote support platform including:
   - Docker configuration for RustDesk servers
   - NGINX web server setup with SSL
   - Professional download portal
   - Client builder tools
   - Automated deployment scripts
   - Comprehensive documentation
   ```

5. **Click "Commit changes"**

**Method B: Git Command Line (Alternative)**

If you prefer command line:
```bash
# On your local machine
cd /path/to/your/connectassist/folder
git init
git add .
git commit -m "Initial ConnectAssist project setup"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/connectassist.git
git push -u origin main
```

### Step 2.3: Verify Upload

**✅ Success Checks**:
1. All folders should be visible in your repository
2. File count should match your local project
3. README.md should display properly on the main page
4. No error messages during upload

**Expected Repository Structure**:
```
📁 connectassist/
├── 📄 README.md
├── 📄 setup.sh
├── 📄 dev.sh
├── 📄 check-local.sh
├── 📄 .gitignore
├── 📁 docker/
│   ├── 📄 docker-compose.yml
│   ├── 📄 .env
│   └── 📄 .env.example
├── 📁 nginx/
├── 📁 www/
├── 📁 builder/
├── 📁 scripts/
└── 📁 docs/
```

## ⚙️ Phase 3: Repository Configuration

### Step 3.1: Update Repository README

1. **Click on README.md** in your repository
2. **Click the pencil icon** (Edit this file)
3. **Update the README** with your specific information:

```markdown
# ConnectAssist - Remote Support Platform

🔗 **Live Instance**: https://connectassist.live

ConnectAssist is a self-hosted remote support platform using RustDesk backend with custom branding.

## 🚀 Quick Deploy

```bash
# Clone and deploy to VPS
git clone https://github.com/YOUR-USERNAME/connectassist.git /opt/connectassist
cd /opt/connectassist
sudo ./scripts/init-server.sh
```

## 📚 Documentation

- [Complete Deployment Guide](docs/BEGINNER-DEPLOYMENT-GUIDE.md)
- [Client Building Guide](docs/CLIENT-BUILDING.md)
- [Quick Deploy Reference](QUICK-DEPLOY.md)

## 🏗️ Architecture

- **Backend**: RustDesk relay and rendezvous servers
- **Frontend**: Professional web portal with device detection
- **Deployment**: Docker + NGINX + SSL automation
- **Domain**: connectassist.live

## 📊 Status

- ✅ Infrastructure deployed on Evolution Host VPS
- ✅ SSL certificates configured
- ✅ Professional download portal
- 🔄 Custom client building (in progress)

---
*Self-hosted alternative to ScreenConnect, TeamViewer, and AnyDesk*
```

4. **Commit changes** with message: "Update README with project details"

### Step 3.2: Create Release Tags (Best Practice)

1. **Go to "Releases"** (right sidebar of main repository page)
2. **Click "Create a new release"**
3. **Configure release**:
   ```
   Tag version: v1.0.0
   Release title: ConnectAssist v1.0.0 - Initial Release
   Description:
   🎉 Initial release of ConnectAssist remote support platform
   
   Features:
   - Complete RustDesk server setup with Docker
   - Professional web portal with SSL
   - Automated deployment scripts
   - Client builder framework
   - Comprehensive documentation
   
   Ready for production deployment!
   ```
4. **Click "Publish release"**

### Step 3.3: Configure Branch Protection (Optional but Recommended)

1. **Go to Settings → Branches**
2. **Click "Add rule"**
3. **Configure protection**:
   ```
   Branch name pattern: main
   ✅ Require pull request reviews before merging
   ✅ Require status checks to pass before merging
   ✅ Require branches to be up to date before merging
   ✅ Include administrators
   ```

## 🖥️ Phase 4: VPS Deployment Preparation

### Step 4.1: Connect to Your VPS

```bash
ssh root@103.195.103.198
```
Enter password: `IBHTfYtj7tWFi_Shw234k4u`

### Step 4.2: Prepare VPS Environment

```bash
# Update system
apt update && apt upgrade -y

# Install Git
apt install -y git curl wget

# Verify Git installation
git --version
```

**Expected Output**: `git version 2.34.1` (or similar)

### Step 4.3: Configure Git (Optional but Recommended)

```bash
# Set global Git configuration
git config --global user.name "ConnectAssist Server"
git config --global user.email "admin@connectassist.live"

# Verify configuration
git config --list
```

### Step 4.4: Create Project Directory

```bash
# Create and navigate to project directory
mkdir -p /opt
cd /opt

# Verify we're in the right location
pwd
```

**Expected Output**: `/opt`

## 🚀 Phase 5: Complete Deployment Workflow

### Step 5.1: Clone Repository

Replace `YOUR-USERNAME` with your actual GitHub username:

```bash
# Clone your ConnectAssist repository
git clone https://github.com/YOUR-USERNAME/connectassist.git

# Navigate to project directory
cd connectassist

# Verify all files are present
ls -la
```

**Expected Output**: You should see all your ConnectAssist files and folders

**✅ Success Check**: 
```bash
# Check specific important files
ls -la scripts/init-server.sh
ls -la docker/docker-compose.yml
ls -la www/index.html
```

All files should exist without "No such file or directory" errors.

### Step 5.2: Configure Environment

```bash
# Copy environment template
cp docker/.env.example docker/.env

# Edit environment file
nano docker/.env
```

**In nano editor, update these values**:
```bash
RUSTDESK_DOMAIN=connectassist.live
SSL_EMAIL=admin@connectassist.live
SERVER_IP=103.195.103.198
```

**Save and exit**: `Ctrl+X`, then `Y`, then `Enter`

### Step 5.3: Make Scripts Executable

```bash
# Make all scripts executable
chmod +x scripts/*.sh
chmod +x *.sh
chmod +x builder/*.py

# Verify permissions
ls -la scripts/
```

**Expected Output**: All `.sh` files should show `rwxr-xr-x` permissions

### Step 5.4: Run Deployment Script

```bash
# Execute the main deployment script
./scripts/init-server.sh
```

**This will take 5-10 minutes and will**:
- Install Docker, NGINX, Certbot
- Configure firewall (UFW)
- Set up SSL certificates
- Deploy RustDesk containers
- Configure web server

**Expected Final Output**:
```
✅ Installation completed!

📊 Service Status:
NGINX: active
Docker: active
ConnectAssist: active

🌐 Access Information:
Web Portal: https://connectassist.live
RustDesk Server: connectassist.live:21115

🎉 ConnectAssist is now ready!
```

### Step 5.5: Verify Deployment

```bash
# Check all services
systemctl status nginx docker

# Check Docker containers
docker-compose ps

# Check website
curl -I https://connectassist.live

# Run health check
./scripts/health-check.sh --report
```

**Expected Results**:
- NGINX: `active (running)`
- Docker: `active (running)`
- Containers: Both `hbbs` and `hbbr` showing `Up`
- Website: `HTTP/2 200`
- Health check: `All health checks passed`

## 🔄 Phase 6: Future Updates Workflow

### Step 6.1: Update Local Files

When you make changes to your ConnectAssist project:

1. **Update files locally**
2. **Commit to GitHub**:
   ```bash
   git add .
   git commit -m "Description of changes"
   git push origin main
   ```

### Step 6.2: Deploy Updates to VPS

```bash
# On your VPS
cd /opt/connectassist

# Pull latest changes
git pull origin main

# Restart services if needed
docker-compose restart
systemctl reload nginx

# Run health check
./scripts/health-check.sh
```

## 🎉 Success Verification

### Final Checklist

- [ ] Repository created and configured on GitHub
- [ ] All files uploaded with correct structure
- [ ] VPS successfully cloned the repository
- [ ] Deployment script completed without errors
- [ ] Website accessible at https://connectassist.live
- [ ] SSL certificate valid (no browser warnings)
- [ ] Docker containers running
- [ ] Health check passes

### Test Your Deployment

1. **Open browser** → `https://connectassist.live`
2. **Verify**: Professional download page loads
3. **Check**: No SSL certificate warnings
4. **Confirm**: Download buttons are visible

**🎊 Congratulations!** Your ConnectAssist platform is now live and ready for use!

## 📞 Next Steps

1. **Build custom clients** using the builder tools
2. **Customize branding** in the web portal
3. **Set up monitoring** and alerts
4. **Configure backups** for your deployment
5. **Scale for multiple clients** if needed

Your professional remote support platform is now operational! 🚀
