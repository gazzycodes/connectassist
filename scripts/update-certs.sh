#!/bin/bash

# ConnectAssist SSL Certificate Management Script
# Handles SSL certificate renewal and management

set -e

# Configuration
DOMAIN="connectassist.live"
EMAIL="admin@connectassist.live"
LOG_FILE="/var/log/connectassist-ssl.log"
BACKUP_DIR="/opt/connectassist/ssl-backups"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging function
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a $LOG_FILE
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}❌ This script must be run as root${NC}"
        exit 1
    fi
}

# Backup existing certificates
backup_certificates() {
    log_message "INFO" "Backing up existing certificates..."
    
    mkdir -p $BACKUP_DIR
    local backup_name="ssl-backup-$(date +%Y%m%d-%H%M%S)"
    
    if [ -d "/etc/letsencrypt/live/$DOMAIN" ]; then
        cp -r /etc/letsencrypt/live/$DOMAIN $BACKUP_DIR/$backup_name
        log_message "INFO" "Certificates backed up to $BACKUP_DIR/$backup_name"
    else
        log_message "WARN" "No existing certificates found to backup"
    fi
}

# Check certificate status
check_certificate_status() {
    log_message "INFO" "Checking current certificate status..."
    
    local cert_file="/etc/letsencrypt/live/$DOMAIN/cert.pem"
    
    if [ ! -f "$cert_file" ]; then
        log_message "WARN" "No certificate found for $DOMAIN"
        return 1
    fi
    
    # Get certificate information
    local cert_subject=$(openssl x509 -in "$cert_file" -noout -subject | sed 's/subject=//')
    local cert_issuer=$(openssl x509 -in "$cert_file" -noout -issuer | sed 's/issuer=//')
    local cert_start=$(openssl x509 -in "$cert_file" -noout -startdate | cut -d= -f2)
    local cert_end=$(openssl x509 -in "$cert_file" -noout -enddate | cut -d= -f2)
    
    # Calculate days until expiry
    local cert_end_epoch=$(date -d "$cert_end" +%s)
    local current_epoch=$(date +%s)
    local days_left=$(( (cert_end_epoch - current_epoch) / 86400 ))
    
    log_message "INFO" "Certificate Subject: $cert_subject"
    log_message "INFO" "Certificate Issuer: $cert_issuer"
    log_message "INFO" "Valid From: $cert_start"
    log_message "INFO" "Valid Until: $cert_end"
    log_message "INFO" "Days Until Expiry: $days_left"
    
    if [ $days_left -lt 0 ]; then
        log_message "ERROR" "Certificate has expired!"
        return 2
    elif [ $days_left -lt 30 ]; then
        log_message "WARN" "Certificate expires in $days_left days"
        return 1
    else
        log_message "INFO" "Certificate is valid for $days_left more days"
        return 0
    fi
}

# Renew certificate
renew_certificate() {
    log_message "INFO" "Attempting to renew SSL certificate..."
    
    # Test NGINX configuration first
    if ! nginx -t; then
        log_message "ERROR" "NGINX configuration test failed"
        return 1
    fi
    
    # Stop NGINX temporarily for standalone renewal if needed
    local nginx_was_running=false
    if systemctl is-active --quiet nginx; then
        nginx_was_running=true
    fi
    
    # Try renewal with NGINX plugin first
    if certbot renew --nginx --non-interactive --agree-tos; then
        log_message "INFO" "Certificate renewed successfully using NGINX plugin"
    else
        log_message "WARN" "NGINX plugin renewal failed, trying standalone method..."
        
        # Stop NGINX for standalone renewal
        if $nginx_was_running; then
            systemctl stop nginx
        fi
        
        # Try standalone renewal
        if certbot renew --standalone --non-interactive --agree-tos; then
            log_message "INFO" "Certificate renewed successfully using standalone method"
        else
            log_message "ERROR" "Certificate renewal failed with both methods"
            
            # Restart NGINX if it was running
            if $nginx_was_running; then
                systemctl start nginx
            fi
            return 1
        fi
        
        # Restart NGINX
        if $nginx_was_running; then
            systemctl start nginx
        fi
    fi
    
    # Reload NGINX to use new certificate
    if systemctl is-active --quiet nginx; then
        systemctl reload nginx
        log_message "INFO" "NGINX reloaded with new certificate"
    fi
    
    return 0
}

# Force new certificate (for initial setup or major issues)
force_new_certificate() {
    log_message "INFO" "Forcing new certificate creation..."
    
    # Backup existing certificates
    backup_certificates
    
    # Stop NGINX
    local nginx_was_running=false
    if systemctl is-active --quiet nginx; then
        nginx_was_running=true
        systemctl stop nginx
    fi
    
    # Remove existing certificate
    if [ -d "/etc/letsencrypt/live/$DOMAIN" ]; then
        rm -rf /etc/letsencrypt/live/$DOMAIN
        rm -rf /etc/letsencrypt/archive/$DOMAIN
        rm -f /etc/letsencrypt/renewal/$DOMAIN.conf
    fi
    
    # Create new certificate
    if certbot certonly --standalone -d $DOMAIN --non-interactive --agree-tos --email $EMAIL; then
        log_message "INFO" "New certificate created successfully"
        
        # Start NGINX and configure it
        if $nginx_was_running; then
            systemctl start nginx
            
            # Run certbot with NGINX plugin to configure
            certbot --nginx -d $DOMAIN --non-interactive --agree-tos --redirect
        fi
    else
        log_message "ERROR" "Failed to create new certificate"
        
        # Start NGINX if it was running
        if $nginx_was_running; then
            systemctl start nginx
        fi
        return 1
    fi
}

# Test certificate
test_certificate() {
    log_message "INFO" "Testing certificate configuration..."
    
    # Test HTTPS connection
    if curl -s -I "https://$DOMAIN" | grep -q "HTTP/2 200"; then
        log_message "INFO" "HTTPS connection test passed"
    else
        log_message "ERROR" "HTTPS connection test failed"
        return 1
    fi
    
    # Test SSL certificate with OpenSSL
    if echo | openssl s_client -servername $DOMAIN -connect $DOMAIN:443 2>/dev/null | openssl x509 -noout -dates; then
        log_message "INFO" "SSL certificate test passed"
    else
        log_message "ERROR" "SSL certificate test failed"
        return 1
    fi
    
    # Test SSL Labs rating (optional, requires internet)
    log_message "INFO" "For detailed SSL analysis, visit: https://www.ssllabs.com/ssltest/analyze.html?d=$DOMAIN"
}

# Setup auto-renewal
setup_auto_renewal() {
    log_message "INFO" "Setting up automatic certificate renewal..."
    
    # Create renewal script
    cat > /usr/local/bin/connectassist-ssl-renew.sh << 'EOF'
#!/bin/bash
# ConnectAssist SSL Auto-Renewal Script

LOG_FILE="/var/log/connectassist-ssl.log"
DOMAIN="connectassist.live"

log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> $LOG_FILE
}

log_message "INFO" "Starting automatic SSL renewal check..."

# Check if renewal is needed (30 days before expiry)
if certbot certificates | grep -A 10 "$DOMAIN" | grep -q "VALID: [0-2][0-9] days"; then
    log_message "INFO" "Certificate renewal needed, attempting renewal..."
    
    if /opt/connectassist/scripts/update-certs.sh --renew; then
        log_message "INFO" "Automatic renewal successful"
        
        # Send success notification
        if command -v mail &> /dev/null; then
            echo "SSL certificate for $DOMAIN has been automatically renewed." | \
                mail -s "ConnectAssist SSL Renewal Success" admin@connectassist.live 2>/dev/null || true
        fi
    else
        log_message "ERROR" "Automatic renewal failed"
        
        # Send failure notification
        if command -v mail &> /dev/null; then
            echo "SSL certificate renewal for $DOMAIN failed. Manual intervention required." | \
                mail -s "ConnectAssist SSL Renewal FAILED" admin@connectassist.live 2>/dev/null || true
        fi
    fi
else
    log_message "INFO" "Certificate renewal not needed at this time"
fi
EOF

    chmod +x /usr/local/bin/connectassist-ssl-renew.sh
    
    # Add to crontab (run twice daily)
    (crontab -l 2>/dev/null | grep -v connectassist-ssl-renew; echo "0 2,14 * * * /usr/local/bin/connectassist-ssl-renew.sh") | crontab -
    
    log_message "INFO" "Auto-renewal cron job configured (runs at 2 AM and 2 PM daily)"
}

# Show certificate information
show_certificate_info() {
    echo -e "${BLUE}🔒 SSL Certificate Information${NC}"
    echo "================================"
    
    if check_certificate_status; then
        echo -e "${GREEN}✅ Certificate is valid${NC}"
    else
        echo -e "${YELLOW}⚠️ Certificate needs attention${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}Certificate Files:${NC}"
    echo "Certificate: /etc/letsencrypt/live/$DOMAIN/cert.pem"
    echo "Private Key: /etc/letsencrypt/live/$DOMAIN/privkey.pem"
    echo "Full Chain: /etc/letsencrypt/live/$DOMAIN/fullchain.pem"
    echo "Chain: /etc/letsencrypt/live/$DOMAIN/chain.pem"
    
    echo ""
    echo -e "${BLUE}Renewal Information:${NC}"
    certbot certificates | grep -A 10 "$DOMAIN" || echo "No certificate information available"
}

# Main function
main() {
    check_root
    
    case "${1:-status}" in
        "status"|"info")
            show_certificate_info
            ;;
        "renew")
            backup_certificates
            if renew_certificate; then
                echo -e "${GREEN}✅ Certificate renewal completed${NC}"
                test_certificate
            else
                echo -e "${RED}❌ Certificate renewal failed${NC}"
                exit 1
            fi
            ;;
        "force"|"new")
            if force_new_certificate; then
                echo -e "${GREEN}✅ New certificate created${NC}"
                test_certificate
            else
                echo -e "${RED}❌ Certificate creation failed${NC}"
                exit 1
            fi
            ;;
        "test")
            test_certificate
            ;;
        "setup-auto")
            setup_auto_renewal
            echo -e "${GREEN}✅ Auto-renewal configured${NC}"
            ;;
        "backup")
            backup_certificates
            echo -e "${GREEN}✅ Certificates backed up${NC}"
            ;;
        *)
            echo "Usage: $0 {status|renew|force|test|setup-auto|backup}"
            echo ""
            echo "Commands:"
            echo "  status     - Show certificate status and information"
            echo "  renew      - Renew existing certificate"
            echo "  force      - Force creation of new certificate"
            echo "  test       - Test certificate configuration"
            echo "  setup-auto - Setup automatic renewal"
            echo "  backup     - Backup current certificates"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
