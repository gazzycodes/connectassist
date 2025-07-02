# ConnectAssist — Self-Hosted Remote Support Platform

🧠 **ConnectAssist** is a white-labeled, self-hosted remote support solution designed to replace commercial tools like ScreenConnect (ConnectWise), AnyDesk, or TeamViewer. It uses RustDesk's open-source backend hosted on your own VPS with full domain branding, end-to-end encryption, and complete control.

## 🔷 Overview

ConnectAssist provides a production-ready platform where:
- ✅ Tech support teams can create/manage remote sessions from any device
- ✅ Customers visit your custom domain to download branded client
- ✅ Full remote desktop control with file transfer, screen blackout, and unattended access
- ✅ Self-hosted under your own domain with no per-user fees

## 🏗️ Architecture

```
Client Device ↔ connectassist.live (VPS)
                ├─ hbbs (Relay) [port 21115]
                ├─ hbbr (Rendezvous) [port 21116]
                ├─ nginx (HTTPS: 443, HTTP: 80)
                ├─ certbot (auto-renew SSL)
                └─ /var/www/connectassist.live (download portal)
```

## 📦 Repository Structure

```
connectassist/
├── docker/                    # Docker configurations
│   └── docker-compose.yml     # RustDesk server setup
├── nginx/                     # NGINX configurations
│   └── sites-available/       # Site configs
├── www/                       # Web portal files
│   ├── index.html            # Download landing page
│   ├── assets/               # CSS, JS, images
│   └── downloads/            # Client executables
├── builder/                   # Client builder tools
│   ├── rustdesk-builder.py   # Custom EXE builder
│   └── templates/            # Build templates
├── scripts/                   # Maintenance scripts
│   ├── init-server.sh        # Server initialization
│   ├── update-certs.sh       # SSL renewal
│   └── health-check.sh       # System monitoring
├── certbot/                   # SSL certificate management
└── docs/                     # Documentation
```

## 🚀 Quick Start

### Prerequisites
- Ubuntu 22.04 VPS with Docker installed
- Domain pointed to your VPS IP
- Ports 21115, 21116, 80, 443 open

### Deployment
1. Clone this repository
2. Configure your domain in `docker/docker-compose.yml`
3. Run `./scripts/init-server.sh`
4. Access your portal at `https://yourdomain.com`

## 📋 Features Status

| Feature Category | Feature | Status |
|-----------------|---------|--------|
| 🖥️ Client Onboarding | Branded download page | ✅ Done |
| | Preconfigured RustDesk EXE | 🔜 In Progress |
| | Unattended access option | 🔜 Planned |
| 🔁 Session Management | Multi-device tech access | ✅ Native |
| | Session via ID/code | ✅ Native |
| | Input disable/screen blackout | ✅ With permissions |
| 📱 Cross-Platform | Desktop technician app | ✅ Native |
| | Mobile technician app | ✅ Native |
| | Cloud-style dashboard | 🔜 Planned |
| 🌐 Server Hosting | Self-hosted relay servers | ✅ Done |
| | SSL with auto-renewal | ✅ Done |
| | Subdomain support | ✅ Ready |

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
