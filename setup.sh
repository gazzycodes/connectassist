#!/bin/bash

# ConnectAssist Quick Setup Script
# This script prepares the local development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 ConnectAssist Local Setup${NC}"
echo "============================="

# Check if we're in the right directory
if [ ! -f "README.md" ] || [ ! -d "docker" ]; then
    echo -e "${RED}❌ Please run this script from the ConnectAssist root directory${NC}"
    exit 1
fi

# Make scripts executable
echo -e "${YELLOW}📝 Making scripts executable...${NC}"
chmod +x scripts/*.sh
chmod +x builder/*.py
chmod +x setup.sh

# Create necessary directories
echo -e "${YELLOW}📁 Creating directories...${NC}"
mkdir -p www/downloads
mkdir -p www/assets
mkdir -p builder/build
mkdir -p builder/assets
mkdir -p certbot
mkdir -p logs

# Create placeholder download files
echo -e "${YELLOW}📦 Creating placeholder download files...${NC}"
cat > www/downloads/README.md << 'EOF'
# Download Files

This directory contains the ConnectAssist client executables.

## Files

- `connectassist-windows.exe` - Windows client
- `connectassist-macos.dmg` - macOS client  
- `connectassist-linux.AppImage` - Linux client

## Building Clients

To build custom clients, use the builder script:

```bash
cd builder
python3 rustdesk-builder.py
```

See `docs/CLIENT-BUILDING.md` for detailed instructions.
EOF

# Create placeholder favicon
echo -e "${YELLOW}🎨 Creating placeholder assets...${NC}"
# Create a simple favicon placeholder
echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==" | base64 -d > www/assets/favicon.ico

# Create .gitignore
echo -e "${YELLOW}📋 Creating .gitignore...${NC}"
cat > .gitignore << 'EOF'
# Build directories
builder/build/
builder/rustdesk/

# Download files
www/downloads/*.exe
www/downloads/*.dmg
www/downloads/*.AppImage
www/downloads/*.deb
www/downloads/*.rpm

# Logs
logs/
*.log

# SSL certificates (keep structure, not actual certs)
certbot/live/
certbot/archive/
certbot/renewal/

# Docker data
docker/data/

# Environment files with secrets
.env.local
.env.production

# Temporary files
*.tmp
*.temp
.DS_Store
Thumbs.db

# IDE files
.vscode/
.idea/
*.swp
*.swo

# Python
__pycache__/
*.pyc
*.pyo
*.pyd
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Node.js (if used for future features)
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
EOF

# Create development docker-compose override
echo -e "${YELLOW}🐳 Creating development Docker override...${NC}"
cat > docker/docker-compose.dev.yml << 'EOF'
version: '3.8'

# Development override for docker-compose.yml
# Usage: docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

services:
  hbbs:
    ports:
      - "21115:21115"
      - "21116:21116"
      - "21116:21116/udp"
      - "21118:21118"
    environment:
      - RUST_LOG=debug
    volumes:
      - ./data:/root
      - ./logs:/var/log/rustdesk

  hbbr:
    ports:
      - "21117:21117"
      - "21119:21119"
    environment:
      - RUST_LOG=debug
    volumes:
      - ./data:/root
      - ./logs:/var/log/rustdesk

  # Optional: Add a simple web server for local testing
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ../www:/usr/share/nginx/html:ro
    depends_on:
      - hbbs
      - hbbr
EOF

# Create local development script
echo -e "${YELLOW}🔧 Creating development helper script...${NC}"
cat > dev.sh << 'EOF'
#!/bin/bash

# ConnectAssist Development Helper Script

case "$1" in
    "start")
        echo "🚀 Starting ConnectAssist development environment..."
        cd docker
        docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
        echo "✅ Services started. Web interface: http://localhost:8080"
        ;;
    "stop")
        echo "🛑 Stopping ConnectAssist services..."
        cd docker
        docker-compose down
        ;;
    "logs")
        echo "📋 Showing service logs..."
        cd docker
        docker-compose logs -f
        ;;
    "build")
        echo "🏗️ Building ConnectAssist clients..."
        cd builder
        python3 rustdesk-builder.py
        ;;
    "test")
        echo "🧪 Running tests..."
        # Add test commands here
        echo "Tests not implemented yet"
        ;;
    "clean")
        echo "🧹 Cleaning up..."
        cd docker
        docker-compose down -v
        docker system prune -f
        ;;
    *)
        echo "ConnectAssist Development Helper"
        echo "Usage: $0 {start|stop|logs|build|test|clean}"
        echo ""
        echo "Commands:"
        echo "  start  - Start development environment"
        echo "  stop   - Stop all services"
        echo "  logs   - Show service logs"
        echo "  build  - Build client applications"
        echo "  test   - Run tests"
        echo "  clean  - Clean up containers and volumes"
        ;;
esac
EOF

chmod +x dev.sh

# Create example environment file
echo -e "${YELLOW}⚙️ Creating example environment file...${NC}"
cat > docker/.env.example << 'EOF'
# ConnectAssist Environment Configuration
# Copy this file to .env and update the values

# Domain Configuration
RUSTDESK_DOMAIN=connectassist.live
RUSTDESK_RELAY_PORT=21117
RUSTDESK_SIGNAL_PORT=21115
RUSTDESK_WEB_PORT=21118

# SSL Configuration
SSL_EMAIL=admin@connectassist.live
CERTBOT_DOMAINS=connectassist.live

# Server Configuration
SERVER_IP=103.195.103.198
SSH_PORT=22

# Security (generate secure values)
ENCRYPTION_KEY=
ADMIN_PASSWORD=

# Optional: Multi-tenant support
# CLIENT_SUBDOMAINS=client1.connectassist.live,client2.connectassist.live

# Optional: Monitoring and Alerts
WEBHOOK_URL=
ALERT_EMAIL=admin@connectassist.live

# Development Settings
DEBUG=false
LOG_LEVEL=info
EOF

# Create a simple health check script for local development
echo -e "${YELLOW}🏥 Creating local health check...${NC}"
cat > check-local.sh << 'EOF'
#!/bin/bash

# Simple local health check for development

echo "🔍 ConnectAssist Local Health Check"
echo "=================================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running"
    exit 1
fi

# Check if services are running
cd docker
if docker-compose ps | grep -q "Up"; then
    echo "✅ RustDesk services are running"
else
    echo "❌ RustDesk services are not running"
    echo "💡 Run './dev.sh start' to start services"
fi

# Check if web interface is accessible
if curl -s http://localhost:8080 > /dev/null; then
    echo "✅ Web interface is accessible at http://localhost:8080"
else
    echo "⚠️ Web interface not accessible (this is normal if not using dev environment)"
fi

# Check if download directory has files
if ls ../www/downloads/*.exe > /dev/null 2>&1 || ls ../www/downloads/*.AppImage > /dev/null 2>&1; then
    echo "✅ Client files are available"
else
    echo "⚠️ No client files found"
    echo "💡 Run './dev.sh build' to build clients"
fi

echo ""
echo "🎯 Next steps:"
echo "  - Run './dev.sh start' to start development environment"
echo "  - Run './dev.sh build' to build client applications"
echo "  - See README.md for deployment instructions"
EOF

chmod +x check-local.sh

# Final summary
echo -e "${GREEN}✅ Local setup completed!${NC}"
echo ""
echo -e "${BLUE}📋 What's been set up:${NC}"
echo "  ✅ Scripts made executable"
echo "  ✅ Directory structure created"
echo "  ✅ Development helpers created"
echo "  ✅ Configuration templates created"
echo "  ✅ Git ignore file created"
echo ""
echo -e "${BLUE}🚀 Next steps:${NC}"
echo "  1. Review and update docker/.env with your settings"
echo "  2. Run './dev.sh start' for local development"
echo "  3. Run './check-local.sh' to verify setup"
echo "  4. See docs/DEPLOYMENT.md for production deployment"
echo ""
echo -e "${BLUE}🔧 Development commands:${NC}"
echo "  ./dev.sh start    - Start development environment"
echo "  ./dev.sh build    - Build client applications"
echo "  ./check-local.sh  - Check local setup"
echo ""
echo -e "${GREEN}🎉 ConnectAssist is ready for development!${NC}"
