// ConnectAssist Customer Portal JavaScript

document.addEventListener('DOMContentLoaded', function() {
    // Initialize the portal
    initializePortal();
});

function initializePortal() {
    // Set up event listeners
    const supportForm = document.getElementById('supportForm');
    if (supportForm) {
        supportForm.addEventListener('submit', handleSupportRequest);
    }
    
    // Update connection status
    updateConnectionStatus();
    
    // Start periodic status updates
    setInterval(updateConnectionStatus, 30000);
}

function handleSupportRequest(event) {
    event.preventDefault();
    
    const supportCode = document.getElementById('supportCode').value.trim();
    
    if (!supportCode) {
        showMessage('Please enter a support code', 'error');
        return;
    }
    
    if (supportCode.length !== 6 || !/^\d{6}$/.test(supportCode)) {
        showMessage('Support code must be exactly 6 digits', 'error');
        return;
    }
    
    // Show loading state
    showMessage('Validating support code and generating your installer...', 'info');
    
    // Validate and process support code
    validateAndGenerateInstaller(supportCode);
}

async function validateAndGenerateInstaller(code) {
    try {
        // Call the new unified API endpoint that validates code and generates installer
        const response = await fetch('/api/customer/installer', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ support_code: code })
        });
        
        const result = await response.json();
        
        if (result.success) {
            showMessage('Support code validated! Your installer is ready for download.', 'success');
            showDownloadInstructions(result.download_url, result.customer_data, code);
        } else {
            showMessage(result.error || 'Invalid support code or installer generation failed', 'error');
        }
    } catch (error) {
        console.error('Error processing support code:', error);
        showMessage('Connection error. Please try again.', 'error');
    }
}

function showDownloadInstructions(downloadUrl, customerData, supportCode) {
    const customerName = customerData?.customer_name || 'Customer';
    const instructionsHtml = `
        <div class="download-instructions">
            <div class="success-header">
                <i class="fas fa-check-circle success-icon"></i>
                <h3>Your ConnectAssist installer is ready!</h3>
            </div>
            
            <p class="customer-greeting">Hello <strong>${customerName}</strong>,</p>
            <p class="intro-text">Your technician has prepared a custom ConnectAssist installer just for you. This will enable secure remote support when you need assistance.</p>
            
            <div class="download-section">
                <a href="${downloadUrl}" class="download-button" onclick="trackDownload('${supportCode}')">
                    <i class="fas fa-download"></i>
                    Download Your ConnectAssist Installer
                </a>
                <p class="download-details">
                    <i class="fas fa-info-circle"></i>
                    File size: ~15MB | Compatible with Windows 10/11
                </p>
            </div>
            
            <div class="installation-guide">
                <h4><i class="fas fa-list-ol"></i> Simple Installation Steps:</h4>
                <div class="steps-container">
                    <div class="step">
                        <div class="step-number">1</div>
                        <div class="step-content">
                            <strong>Download</strong> the installer using the button above
                        </div>
                    </div>
                    <div class="step">
                        <div class="step-number">2</div>
                        <div class="step-content">
                            <strong>Extract</strong> the ZIP file to your Desktop or Downloads folder
                        </div>
                    </div>
                    <div class="step">
                        <div class="step-number">3</div>
                        <div class="step-content">
                            <strong>Right-click</strong> on "setup-connectassist.bat" and select <strong>"Run as administrator"</strong>
                        </div>
                    </div>
                    <div class="step">
                        <div class="step-number">4</div>
                        <div class="step-content">
                            <strong>Click "Yes"</strong> when Windows asks for permission
                        </div>
                    </div>
                    <div class="step">
                        <div class="step-number">5</div>
                        <div class="step-content">
                            <strong>Follow</strong> the on-screen instructions and wait for completion
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="important-info">
                <h4><i class="fas fa-exclamation-triangle"></i> Important Information:</h4>
                <div class="info-grid">
                    <div class="info-item">
                        <i class="fas fa-clock"></i>
                        <div>
                            <strong>One-Time Setup</strong>
                            <p>You only need to install this once - it will work automatically after that</p>
                        </div>
                    </div>
                    <div class="info-item">
                        <i class="fas fa-cog"></i>
                        <div>
                            <strong>Runs in Background</strong>
                            <p>ConnectAssist runs quietly and won't interfere with your normal computer use</p>
                        </div>
                    </div>
                    <div class="info-item">
                        <i class="fas fa-sync-alt"></i>
                        <div>
                            <strong>Auto-Start</strong>
                            <p>Starts automatically when you restart your computer - no action needed</p>
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="security-info">
                <h4><i class="fas fa-shield-alt"></i> Security & Privacy:</h4>
                <ul class="security-list">
                    <li><i class="fas fa-check"></i> Only your authorized technician can connect</li>
                    <li><i class="fas fa-check"></i> All connections are encrypted and secure</li>
                    <li><i class="fas fa-check"></i> No personal data is accessed without your permission</li>
                    <li><i class="fas fa-check"></i> You can uninstall anytime if needed</li>
                </ul>
            </div>
            
            <div class="support-section">
                <h4><i class="fas fa-question-circle"></i> Need Help with Installation?</h4>
                <p>If you have any trouble with the installation process, contact your technician for step-by-step assistance.</p>
                <div class="support-details">
                    <p><strong>Your Support Code:</strong> <code>${supportCode}</code></p>
                    <p><strong>Customer:</strong> ${customerName}</p>
                </div>
            </div>
            
            <div class="next-steps">
                <h4><i class="fas fa-arrow-right"></i> What Happens Next?</h4>
                <p>After installation, your technician will be able to connect to provide support whenever you need assistance. You don't need to do anything else - just use your computer normally!</p>
            </div>
        </div>
    `;
    
    // Replace form with instructions
    const formContainer = document.querySelector('.support-form');
    formContainer.innerHTML = instructionsHtml;
    
    // Scroll to top of instructions
    formContainer.scrollIntoView({ behavior: 'smooth' });
}

function trackDownload(supportCode) {
    // Track download for analytics
    console.log(`Download tracked for support code: ${supportCode}`);
    
    if (typeof gtag !== 'undefined') {
        gtag('event', 'download', {
            'event_category': 'installer',
            'event_label': 'connectassist_installer',
            'custom_parameter_1': supportCode
        });
    }
    
    // Also track via API for admin dashboard
    fetch('/api/track-download', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ 
            support_code: supportCode,
            timestamp: new Date().toISOString()
        })
    }).catch(error => {
        console.log('Download tracking failed:', error);
    });
}

async function updateConnectionStatus() {
    try {
        const response = await fetch('/api/status');
        const status = await response.json();
        
        const statusElement = document.getElementById('connectionStatus');
        if (statusElement) {
            if (status.online) {
                statusElement.innerHTML = '<i class="fas fa-check-circle"></i> ConnectAssist Online';
                statusElement.className = 'status online';
            } else {
                statusElement.innerHTML = '<i class="fas fa-exclamation-circle"></i> ConnectAssist Offline';
                statusElement.className = 'status offline';
            }
        }
    } catch (error) {
        console.error('Error checking status:', error);
        const statusElement = document.getElementById('connectionStatus');
        if (statusElement) {
            statusElement.innerHTML = '<i class="fas fa-question-circle"></i> Status Unknown';
            statusElement.className = 'status unknown';
        }
    }
}

function showMessage(message, type) {
    // Remove existing messages
    const existingMessages = document.querySelectorAll('.message');
    existingMessages.forEach(msg => msg.remove());
    
    // Create new message
    const messageDiv = document.createElement('div');
    messageDiv.className = `message ${type}`;
    messageDiv.innerHTML = `
        <i class="fas ${getMessageIcon(type)}"></i>
        <span>${message}</span>
    `;
    
    // Insert message
    const form = document.getElementById('supportForm');
    if (form) {
        form.parentNode.insertBefore(messageDiv, form);
    }
    
    // Auto-remove success/info messages after 5 seconds
    if (type === 'success' || type === 'info') {
        setTimeout(() => {
            if (messageDiv.parentNode) {
                messageDiv.remove();
            }
        }, 5000);
    }
}

function getMessageIcon(type) {
    const icons = {
        'success': 'fa-check-circle',
        'error': 'fa-exclamation-circle',
        'info': 'fa-info-circle',
        'warning': 'fa-exclamation-triangle'
    };
    return icons[type] || 'fa-info-circle';
}
