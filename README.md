# ConnectAssist — Self-Hosted Remote Support Platform

🧠 **ConnectAssist** is a white-labeled, self-hosted remote support solution designed to replace commercial tools like ScreenConnect (ConnectWise), AnyDesk, or TeamViewer. It uses RustDesk's open-source backend hosted on your own VPS with full domain branding, end-to-end encryption, and complete control.

## 🔷 Overview

ConnectAssist provides a production-ready platform where:
- ✅ **Professional Admin Dashboard** - Web-based technician interface at `/admin`
- ✅ **Support Code System** - 6-digit codes for zero-technical-knowledge customer workflow
- ✅ **On-Demand Client Generation** - Automatic installer creation when customers enter support codes
- ✅ **Persistent Client Installation** - Clients install as Windows services surviving reboots
- ✅ **Password-Free Technician Access** - Direct connection using customer IDs without passwords
- ✅ **Real-Time Device Management** - Monitor online/offline status and initiate connections
- ✅ **Self-hosted under your own domain** with no per-user fees or licensing restrictions

## 🏗️ Architecture

```
Customer Portal ↔ Admin Dashboard ↔ connectassist.live (VPS)
                                   ├─ Flask API Server [port 5001]
                                   ├─ hbbs (Relay) [port 21115]
                                   ├─ hbbr (Rendezvous) [port 21116]
                                   ├─ nginx (HTTPS: 443, HTTP: 80)
                                   ├─ certbot (auto-renew SSL)
                                   ├─ SQLite Database (device/code management)
                                   └─ On-Demand Client Generation
```

## 🔄 Current Workflow (ScreenConnect-Equivalent)

### **For Technicians:**
1. **Visit:** https://connectassist.live/admin
2. **Generate** 6-digit support code for customer
3. **Provide code** to customer via phone/email
4. **Monitor** customer device status in dashboard
5. **Connect** to customer device when online

### **For Customers:**
1. **Visit:** https://connectassist.live
2. **Enter** 6-digit support code provided by technician
3. **Download** custom installer automatically generated
4. **Run installer** - installs as persistent Windows service
5. **Technician connects** automatically when needed

## 📦 Repository Structure

```
connectassist/
├── api/                       # Backend API server
│   └── admin_api.py          # Flask API with all endpoints
├── docker/                    # Docker configurations
│   └── docker-compose.yml     # RustDesk server setup
├── nginx/                     # NGINX configurations
│   └── sites-available/       # Site configs
├── www/                       # Web portal files
│   ├── index.html            # Customer portal (support code entry)
│   ├── admin/                # Admin dashboard
│   │   ├── index.html        # Technician interface
│   │   ├── admin-script.js   # Dashboard functionality
│   │   └── admin-style.css   # Dashboard styling
│   ├── assets/               # CSS, JS, images
│   │   ├── customer-portal.js # Customer portal logic
│   │   └── style.css         # Main styling
│   └── downloads/            # Generated client packages
├── builder/                   # Client builder tools
│   ├── rustdesk-builder.py   # Custom EXE builder
│   ├── persistent-client-creator.py # Service installer creator
│   └── templates/            # Build templates
├── scripts/                   # Maintenance scripts
│   ├── init-server.sh        # Server initialization
│   ├── update-certs.sh       # SSL renewal
│   ├── health-check.sh       # System monitoring
│   └── manage-support.sh     # Support code management
├── data/                      # Database and logs
│   └── connectassist.db      # SQLite database
├── certbot/                   # SSL certificate management
└── docs/                     # Documentation
```

## 🚀 Quick Start

### Prerequisites
- Ubuntu 22.04 VPS with Docker installed
- Domain pointed to your VPS IP
- Ports 21115, 21116, 80, 443, 5001 open
- Python 3.8+ with pip installed

### Deployment
1. Clone this repository to `/opt/connectassist`
2. Configure your domain in `docker/docker-compose.yml`
3. Run `./scripts/init-server.sh` to set up base infrastructure
4. Install Python dependencies: `pip3 install flask flask-cors requests`
5. Start the API server: `python3 api/admin_api.py`
6. Access your portals:
   - **Customer Portal:** `https://yourdomain.com`
   - **Admin Dashboard:** `https://yourdomain.com/admin`

## 📋 Features Status

| Feature Category | Feature | Status |
|-----------------|---------|--------|
| 🖥️ **Client Onboarding** | Support code-based customer portal | ✅ **DEPLOYED** |
| | On-demand client generation | ✅ **DEPLOYED** |
| | Persistent service installation | ✅ **DEPLOYED** |
| | Zero-technical-knowledge workflow | ✅ **DEPLOYED** |
| 🔧 **Admin Dashboard** | Web-based technician interface | ✅ **DEPLOYED** |
| | Support code generation | ✅ **DEPLOYED** |
| | Real-time device monitoring | ✅ **DEPLOYED** |
| | Direct connection initiation | ✅ **DEPLOYED** |
| 🔁 **Session Management** | Password-free technician access | ✅ **DEPLOYED** |
| | Persistent unattended access | ✅ **DEPLOYED** |
| | Multi-device tech access | ✅ Native |
| | Session logging and tracking | ✅ **DEPLOYED** |
| 📊 **API Integration** | RESTful API endpoints | ✅ **DEPLOYED** |
| | Customer installer API | ✅ **DEPLOYED** |
| | Admin management API | ✅ **DEPLOYED** |
| | Real-time status monitoring | ✅ **DEPLOYED** |
| 🌐 **Server Hosting** | Self-hosted relay servers | ✅ Done |
| | SSL with auto-renewal | ✅ Done |
| | Production-ready deployment | ✅ **DEPLOYED** |

## 💸 Cost Structure

| Item | Provider | Monthly Cost |
|------|----------|--------------|
| VPS | Evolution Host (2 vCPU, 2GB RAM) | €10 |
| Domain | Namecheap | ~$10/year |
| RustDesk License | Free (AGPL) | €0 |
| Cloudflare | Free tier | €0 |

## 🔧 Development

This project is designed for AI-assisted development with:
- Cursor IDE / AugmentCode compatibility
- Automated build pipelines
- Multi-tenant configuration support
- GitHub Actions deployment

## 📞 Support

For technical support or questions, contact the development team.

## 📄 License

This project uses RustDesk under AGPL license. See LICENSE file for details.
