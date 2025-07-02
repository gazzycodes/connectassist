// ConnectAssist Client-Side Logic
document.addEventListener('DOMContentLoaded', function() {
    detectPlatform();
    setupDownloadTracking();
});

function detectPlatform() {
    const userAgent = navigator.userAgent.toLowerCase();
    const platform = navigator.platform.toLowerCase();
    
    let detectedOS = 'unknown';
    let downloadUrl = '';
    let platformTitle = '';
    let platformDescription = '';
    let platformIcon = '💻';

    // Detect operating system
    if (userAgent.includes('windows') || platform.includes('win')) {
        detectedOS = 'windows';
        downloadUrl = 'downloads/connectassist-windows.exe';
        platformTitle = '🪟 Windows Detected';
        platformDescription = 'Download the Windows support tool to get started.';
        platformIcon = '🪟';
    } else if (userAgent.includes('mac') || platform.includes('mac')) {
        detectedOS = 'macos';
        downloadUrl = 'downloads/connectassist-macos.dmg';
        platformTitle = '🍎 macOS Detected';
        platformDescription = 'Download the macOS support tool to get started.';
        platformIcon = '🍎';
    } else if (userAgent.includes('linux') || platform.includes('linux')) {
        detectedOS = 'linux';
        downloadUrl = 'downloads/connectassist-linux.AppImage';
        platformTitle = '🐧 Linux Detected';
        platformDescription = 'Download the Linux support tool to get started.';
        platformIcon = '🐧';
    } else {
        // Fallback to Windows for unknown platforms
        detectedOS = 'windows';
        downloadUrl = 'downloads/connectassist-windows.exe';
        platformTitle = '💻 Download Support Tool';
        platformDescription = 'We detected an unknown system. The Windows version should work on most computers.';
        platformIcon = '💻';
    }

    // Update the UI
    updatePlatformUI(detectedOS, downloadUrl, platformTitle, platformDescription, platformIcon);
    
    // Show download buttons
    setTimeout(() => {
        document.getElementById('download-buttons').style.display = 'block';
    }, 500);
}

function updatePlatformUI(os, downloadUrl, title, description, icon) {
    const downloadCard = document.getElementById('download-card');
    const platformTitle = document.getElementById('platform-title');
    const platformDescription = document.getElementById('platform-description');
    const primaryDownload = document.getElementById('primary-download');
    
    // Update icon
    downloadCard.querySelector('.download-icon').textContent = icon;
    
    // Update text
    platformTitle.textContent = title;
    platformDescription.textContent = description;
    
    // Update primary download button
    primaryDownload.onclick = () => downloadFile(downloadUrl, os);
    
    // Highlight the detected platform in alternative downloads
    const altButtons = document.querySelectorAll('.btn-alt');
    altButtons.forEach(btn => {
        if (btn.dataset.platform === os) {
            btn.style.background = '#e0f2fe';
            btn.style.borderColor = '#0ea5e9';
            btn.style.color = '#0c4a6e';
        }
    });
}

function downloadFile(url, platform) {
    // Track download
    trackDownload(platform);
    
    // Check if file exists before downloading
    fetch(url, { method: 'HEAD' })
        .then(response => {
            if (response.ok) {
                // File exists, proceed with download
                const link = document.createElement('a');
                link.href = url;
                link.download = url.split('/').pop();
                document.body.appendChild(link);
                link.click();
                document.body.removeChild(link);
                
                // Show success message
                showDownloadMessage('success', 'Download started! Run the file once it finishes downloading.');
            } else {
                // File doesn't exist
                showDownloadMessage('error', 'Download file not available. Please contact support.');
            }
        })
        .catch(error => {
            console.error('Download check failed:', error);
            showDownloadMessage('error', 'Unable to start download. Please try again or contact support.');
        });
}

function trackDownload(platform) {
    // Send download analytics (if analytics service is available)
    const downloadData = {
        platform: platform,
        timestamp: new Date().toISOString(),
        userAgent: navigator.userAgent,
        referrer: document.referrer
    };
    
    // Log to console for now (replace with actual analytics service)
    console.log('Download tracked:', downloadData);
    
    // Optional: Send to analytics endpoint
    // fetch('/api/analytics/download', {
    //     method: 'POST',
    //     headers: { 'Content-Type': 'application/json' },
    //     body: JSON.stringify(downloadData)
    // }).catch(err => console.log('Analytics failed:', err));
}

function showDownloadMessage(type, message) {
    // Remove existing messages
    const existingMessage = document.querySelector('.download-message');
    if (existingMessage) {
        existingMessage.remove();
    }
    
    // Create message element
    const messageDiv = document.createElement('div');
    messageDiv.className = `download-message ${type}`;
    messageDiv.innerHTML = `
        <div class="message-icon">${type === 'success' ? '✅' : '❌'}</div>
        <div class="message-text">${message}</div>
    `;
    
    // Add styles
    messageDiv.style.cssText = `
        display: flex;
        align-items: center;
        gap: 12px;
        padding: 16px;
        margin: 20px 0;
        border-radius: 8px;
        font-size: 0.9rem;
        ${type === 'success' 
            ? 'background: #f0fdf4; border: 1px solid #16a34a; color: #15803d;'
            : 'background: #fef2f2; border: 1px solid #dc2626; color: #dc2626;'
        }
    `;
    
    // Insert after download buttons
    const downloadButtons = document.getElementById('download-buttons');
    downloadButtons.parentNode.insertBefore(messageDiv, downloadButtons.nextSibling);
    
    // Auto-remove success messages after 5 seconds
    if (type === 'success') {
        setTimeout(() => {
            if (messageDiv.parentNode) {
                messageDiv.remove();
            }
        }, 5000);
    }
}

function setupDownloadTracking() {
    // Track clicks on alternative download buttons
    const altButtons = document.querySelectorAll('.btn-alt');
    altButtons.forEach(btn => {
        btn.addEventListener('click', function(e) {
            const platform = this.dataset.platform;
            trackDownload(platform);
        });
    });
}

// Utility function to get connection info (for future use)
function getConnectionInfo() {
    return {
        ip: '', // Will be populated by server-side script if needed
        userAgent: navigator.userAgent,
        screen: {
            width: screen.width,
            height: screen.height,
            colorDepth: screen.colorDepth
        },
        timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
        language: navigator.language
    };
}
