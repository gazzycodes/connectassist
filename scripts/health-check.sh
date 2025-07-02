#!/bin/bash

# ConnectAssist Health Check and Monitoring Script
# This script monitors all ConnectAssist services and sends alerts if needed

set -e

# Configuration
DOMAIN="connectassist.live"
PROJECT_DIR="/opt/connectassist"
LOG_FILE="/var/log/connectassist-health.log"
ALERT_EMAIL="admin@connectassist.live"
WEBHOOK_URL=""  # Optional: Slack/Discord webhook for alerts

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

# Alert function
send_alert() {
    local subject=$1
    local message=$2
    
    # Log the alert
    log_message "ALERT" "$subject: $message"
    
    # Send email if mail is configured
    if command -v mail &> /dev/null; then
        echo "$message" | mail -s "ConnectAssist Alert: $subject" $ALERT_EMAIL 2>/dev/null || true
    fi
    
    # Send webhook notification if configured
    if [ ! -z "$WEBHOOK_URL" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"🚨 ConnectAssist Alert: $subject\\n$message\"}" \
            "$WEBHOOK_URL" 2>/dev/null || true
    fi
}

# Check Docker containers
check_docker() {
    log_message "INFO" "Checking Docker containers..."
    
    if ! command -v docker &> /dev/null; then
        send_alert "Docker Not Found" "Docker is not installed or not in PATH"
        return 1
    fi
    
    if ! systemctl is-active --quiet docker; then
        send_alert "Docker Service Down" "Docker service is not running"
        systemctl restart docker
        sleep 5
    fi
    
    cd $PROJECT_DIR/docker
    
    # Check if containers are running
    local containers_status=$(docker-compose ps -q | wc -l)
    local running_containers=$(docker-compose ps | grep -c "Up" || echo "0")
    
    if [ $running_containers -eq 0 ]; then
        send_alert "RustDesk Containers Down" "No RustDesk containers are running"
        log_message "INFO" "Attempting to restart RustDesk containers..."
        docker-compose down
        sleep 2
        docker-compose up -d
        sleep 10
        
        # Check again
        running_containers=$(docker-compose ps | grep -c "Up" || echo "0")
        if [ $running_containers -eq 0 ]; then
            send_alert "RustDesk Restart Failed" "Failed to restart RustDesk containers"
            return 1
        else
            log_message "INFO" "RustDesk containers restarted successfully"
        fi
    else
        log_message "INFO" "RustDesk containers are running ($running_containers active)"
    fi
    
    # Check container health
    local unhealthy=$(cd $PROJECT_DIR/docker && docker-compose ps 2>/dev/null | grep -c "unhealthy" || echo "0")
    if [ "$unhealthy" -gt 0 ]; then
        send_alert "Unhealthy Containers" "$unhealthy containers are in unhealthy state"
    fi
}

# Check NGINX
check_nginx() {
    log_message "INFO" "Checking NGINX..."
    
    if ! systemctl is-active --quiet nginx; then
        send_alert "NGINX Down" "NGINX service is not running"
        systemctl restart nginx
        sleep 3
        
        if ! systemctl is-active --quiet nginx; then
            send_alert "NGINX Restart Failed" "Failed to restart NGINX service"
            return 1
        else
            log_message "INFO" "NGINX restarted successfully"
        fi
    else
        log_message "INFO" "NGINX is running"
    fi
    
    # Test NGINX configuration
    if ! nginx -t &>/dev/null; then
        send_alert "NGINX Config Error" "NGINX configuration test failed"
        return 1
    fi
}

# Check SSL certificate
check_ssl() {
    log_message "INFO" "Checking SSL certificate..."
    
    local cert_file="/etc/letsencrypt/live/$DOMAIN/cert.pem"
    
    if [ ! -f "$cert_file" ]; then
        send_alert "SSL Certificate Missing" "SSL certificate file not found: $cert_file"
        return 1
    fi
    
    # Check certificate expiry
    local cert_end_date=$(openssl x509 -in "$cert_file" -noout -enddate | cut -d= -f2)
    local cert_end_epoch=$(date -d "$cert_end_date" +%s)
    local current_epoch=$(date +%s)
    local days_left=$(( (cert_end_epoch - current_epoch) / 86400 ))
    
    log_message "INFO" "SSL certificate expires in $days_left days"
    
    if [ $days_left -lt 7 ]; then
        send_alert "SSL Certificate Expiring" "SSL certificate expires in $days_left days"
    elif [ $days_left -lt 30 ]; then
        log_message "WARN" "SSL certificate expires in $days_left days"
    fi
}

# Check website accessibility
check_website() {
    log_message "INFO" "Checking website accessibility..."
    
    local response_code=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN" --max-time 10)
    
    if [ "$response_code" != "200" ]; then
        send_alert "Website Inaccessible" "Website returned HTTP $response_code"
        return 1
    else
        log_message "INFO" "Website is accessible (HTTP $response_code)"
    fi
    
    # Check if download files exist
    local download_files=("connectassist-windows.exe" "connectassist-macos.dmg" "connectassist-linux.AppImage")
    for file in "${download_files[@]}"; do
        if [ ! -f "/var/www/$DOMAIN/downloads/$file" ]; then
            log_message "WARN" "Download file missing: $file"
        fi
    done
}

# Check RustDesk ports
check_ports() {
    log_message "INFO" "Checking RustDesk ports..."
    
    local ports=(21115 21116 21117 21118 21119)
    for port in "${ports[@]}"; do
        if ! netstat -tuln | grep -q ":$port "; then
            send_alert "Port Not Listening" "RustDesk port $port is not listening"
        else
            log_message "INFO" "Port $port is listening"
        fi
    done
}

# Check disk space
check_disk_space() {
    log_message "INFO" "Checking disk space..."
    
    local disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [ $disk_usage -gt 90 ]; then
        send_alert "Disk Space Critical" "Disk usage is at ${disk_usage}%"
    elif [ $disk_usage -gt 80 ]; then
        log_message "WARN" "Disk usage is at ${disk_usage}%"
    else
        log_message "INFO" "Disk usage is at ${disk_usage}%"
    fi
}

# Check memory usage
check_memory() {
    log_message "INFO" "Checking memory usage..."
    
    local mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    
    if [ $mem_usage -gt 90 ]; then
        send_alert "Memory Usage Critical" "Memory usage is at ${mem_usage}%"
    elif [ $mem_usage -gt 80 ]; then
        log_message "WARN" "Memory usage is at ${mem_usage}%"
    else
        log_message "INFO" "Memory usage is at ${mem_usage}%"
    fi
}

# Generate status report
generate_report() {
    local report_file="/tmp/connectassist-status-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "ConnectAssist Status Report"
        echo "=========================="
        echo "Generated: $(date)"
        echo ""
        
        echo "Services:"
        echo "- Docker: $(systemctl is-active docker)"
        echo "- NGINX: $(systemctl is-active nginx)"
        echo "- ConnectAssist: $(systemctl is-active connectassist 2>/dev/null || echo 'not configured')"
        echo ""
        
        echo "RustDesk Containers:"
        cd $PROJECT_DIR/docker && docker-compose ps 2>/dev/null || echo "Unable to get container status"
        echo ""
        
        echo "System Resources:"
        echo "- Disk Usage: $(df / | awk 'NR==2 {print $5}')"
        echo "- Memory Usage: $(free | awk 'NR==2{printf "%.1f%%", $3*100/$2}')"
        echo "- Load Average: $(uptime | awk -F'load average:' '{print $2}')"
        echo ""
        
        echo "Network Ports:"
        netstat -tuln | grep -E ':(21115|21116|21117|21118|21119|80|443) '
        echo ""
        
        echo "Recent Logs (last 10 lines):"
        tail -10 $LOG_FILE
        
    } > $report_file
    
    echo $report_file
}

# Main execution
main() {
    log_message "INFO" "Starting ConnectAssist health check..."
    
    local exit_code=0
    
    # Run all checks
    check_docker || exit_code=1
    check_nginx || exit_code=1
    check_ssl || exit_code=1
    check_website || exit_code=1
    check_ports || exit_code=1
    check_disk_space || exit_code=1
    check_memory || exit_code=1
    
    if [ $exit_code -eq 0 ]; then
        log_message "INFO" "All health checks passed"
    else
        log_message "ERROR" "Some health checks failed"
    fi
    
    # Generate report if requested
    if [ "$1" = "--report" ]; then
        local report_file=$(generate_report)
        echo -e "${BLUE}Status report generated: $report_file${NC}"
    fi
    
    log_message "INFO" "Health check completed"
    exit $exit_code
}

# Run main function
main "$@"
