<?php
/**
 * ConnectAssist Simple Deployment Script
 * Access via: https://connectassist.live/deploy.php?action=deploy&key=ConnectAssist2024Deploy
 */

// Simple security check
$deploy_key = $_GET['key'] ?? '';
$action = $_GET['action'] ?? '';

if ($deploy_key !== 'ConnectAssist2024Deploy') {
    http_response_code(403);
    die('Access denied');
}

header('Content-Type: text/plain');

function logMessage($message) {
    echo date('Y-m-d H:i:s') . " - " . $message . "\n";
    flush();
}

function executeCommand($command, $description) {
    logMessage("Executing: $description");
    logMessage("Command: $command");
    
    $output = [];
    $return_code = 0;
    exec($command . ' 2>&1', $output, $return_code);
    
    foreach ($output as $line) {
        logMessage("  " . $line);
    }
    
    if ($return_code === 0) {
        logMessage("✅ $description completed successfully");
    } else {
        logMessage("❌ $description failed with code $return_code");
    }
    
    return $return_code === 0;
}

if ($action === 'deploy') {
    logMessage("🚀 ConnectAssist Customer Portal Integration Deployment");
    logMessage("======================================================");
    
    // Change to project directory
    $project_dir = '/opt/connectassist';
    if (!is_dir($project_dir)) {
        logMessage("❌ Project directory $project_dir not found!");
        exit(1);
    }
    
    chdir($project_dir);
    logMessage("📁 Changed to project directory: $project_dir");
    
    // Pull latest changes from GitHub
    if (!executeCommand('git pull origin main', 'Pull latest changes from GitHub')) {
        logMessage("❌ Deployment failed at git pull stage");
        exit(1);
    }
    
    // Make scripts executable
    executeCommand('chmod +x scripts/*.sh', 'Make scripts executable');
    executeCommand('chmod +x *.sh', 'Make root scripts executable');
    
    // Create necessary directories
    executeCommand('mkdir -p www/downloads', 'Create downloads directory');
    executeCommand('chmod 755 www/downloads', 'Set downloads directory permissions');
    
    // Install Python dependencies
    logMessage("📦 Installing Python dependencies...");
    executeCommand('python3 -m pip install flask flask-cors requests pathlib', 'Install Python packages');
    
    // Update NGINX configuration if needed
    $nginx_config = '/etc/nginx/sites-available/connectassist.live';
    if (file_exists($nginx_config)) {
        $config_content = file_get_contents($nginx_config);
        
        if (strpos($config_content, 'location /admin/') === false) {
            logMessage("📝 Updating NGINX configuration...");
            
            // Create backup
            executeCommand("cp $nginx_config $nginx_config.backup", 'Backup NGINX config');
            
            // Add admin and API locations
            $admin_config = '
    # Admin Dashboard
    location /admin/ {
        alias /opt/connectassist/www/admin/;
        index index.html;
        try_files $uri $uri/ =404;
    }

    # API endpoints
    location /api/ {
        proxy_pass http://127.0.0.1:5001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Downloads directory for client packages
    location /downloads/ {
        alias /opt/connectassist/www/downloads/;
        add_header Content-Disposition "attachment";
    }
';
            
            // Insert before main location block
            $updated_config = str_replace('    location / {', $admin_config . '    location / {', $config_content);
            file_put_contents($nginx_config, $updated_config);
            
            // Test and reload NGINX
            if (executeCommand('nginx -t', 'Test NGINX configuration')) {
                executeCommand('systemctl reload nginx', 'Reload NGINX');
            } else {
                logMessage("❌ NGINX configuration test failed, restoring backup");
                executeCommand("cp $nginx_config.backup $nginx_config", 'Restore NGINX config backup');
            }
        } else {
            logMessage("✅ NGINX configuration already includes admin panel settings");
        }
    }
    
    // Start admin API server
    logMessage("🚀 Starting Admin API server...");
    
    // Kill any existing admin API process
    executeCommand('pkill -f "admin_api.py"', 'Stop existing admin API server');
    
    // Wait a moment
    sleep(2);
    
    // Start admin API server in background
    executeCommand('nohup python3 api/admin_api.py > /var/log/connectassist-api.log 2>&1 &', 'Start admin API server');
    
    // Wait for API to start
    sleep(3);
    
    // Check if API is running
    $api_running = executeCommand('pgrep -f "admin_api.py"', 'Check if admin API is running');
    
    if ($api_running) {
        logMessage("✅ Admin API server started successfully");
    } else {
        logMessage("❌ Failed to start Admin API server");
        logMessage("Check logs: tail -f /var/log/connectassist-api.log");
    }
    
    logMessage("");
    logMessage("🎉 Deployment Complete!");
    logMessage("======================");
    logMessage("");
    logMessage("🔗 Access Points:");
    logMessage("- Customer Portal: https://connectassist.live/");
    logMessage("- Admin Dashboard: https://connectassist.live/admin/");
    logMessage("- API Status: https://connectassist.live/api/status");
    logMessage("");
    logMessage("📝 Next Steps:");
    logMessage("1. Test the admin dashboard");
    logMessage("2. Generate a support code");
    logMessage("3. Test the customer portal workflow");
    logMessage("4. Verify installer generation");
    
} elseif ($action === 'test') {
    logMessage("🧪 Testing ConnectAssist Endpoints");
    logMessage("==================================");
    
    $endpoints = [
        'Main Site' => 'https://connectassist.live/',
        'Admin Dashboard' => 'https://connectassist.live/admin/',
        'API Status' => 'https://connectassist.live/api/status'
    ];
    
    foreach ($endpoints as $name => $url) {
        logMessage("Testing $name...");
        
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, 10);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        
        $response = curl_exec($ch);
        $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        if ($http_code === 200) {
            logMessage("✅ $name: OK ($http_code)");
        } else {
            logMessage("❌ $name: Failed ($http_code)");
        }
    }
    
} elseif ($action === 'status') {
    logMessage("📊 ConnectAssist System Status");
    logMessage("==============================");
    
    // Check services
    executeCommand('systemctl status nginx --no-pager -l', 'NGINX Status');
    executeCommand('systemctl status docker --no-pager -l', 'Docker Status');
    executeCommand('docker-compose ps', 'Container Status');
    executeCommand('pgrep -f "admin_api.py"', 'Admin API Process');
    
    // Check ports
    executeCommand('netstat -tuln | grep -E ":(21115|21116|21117|80|443|5001)"', 'Port Status');
    
} else {
    logMessage("ConnectAssist Deployment Interface");
    logMessage("==================================");
    logMessage("");
    logMessage("Available actions:");
    logMessage("- deploy: Deploy customer portal integration");
    logMessage("- test: Test all endpoints");
    logMessage("- status: Show system status");
    logMessage("");
    logMessage("Usage:");
    logMessage("https://connectassist.live/deploy.php?action=deploy&key=ConnectAssist2024Deploy");
    logMessage("https://connectassist.live/deploy.php?action=test&key=ConnectAssist2024Deploy");
    logMessage("https://connectassist.live/deploy.php?action=status&key=ConnectAssist2024Deploy");
}
?>
