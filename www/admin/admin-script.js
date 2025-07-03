// ConnectAssist Admin Dashboard JavaScript

class AdminDashboard {
    constructor() {
        this.apiBase = '/api';
        this.currentDevices = [];
        this.currentSupportCode = null;
        this.refreshInterval = null;
        
        this.init();
    }
    
    init() {
        this.setupEventListeners();
        this.loadDashboardData();
        this.startAutoRefresh();
    }
    
    setupEventListeners() {
        // Support code form
        document.getElementById('generateCodeForm').addEventListener('submit', (e) => {
            e.preventDefault();
            this.generateSupportCode();
        });
        
        // Device search and filter
        document.getElementById('deviceSearch').addEventListener('input', (e) => {
            this.filterDevices(e.target.value);
        });
        
        document.getElementById('deviceFilter').addEventListener('change', (e) => {
            this.filterDevicesByStatus(e.target.value);
        });
        
        // Modal close events
        window.addEventListener('click', (e) => {
            if (e.target.classList.contains('modal')) {
                this.closeModal(e.target.id);
            }
        });
    }
    
    async loadDashboardData() {
        try {
            await Promise.all([
                this.loadStats(),
                this.loadDevices(),
                this.loadRecentActivity()
            ]);
        } catch (error) {
            console.error('Error loading dashboard data:', error);
            this.showNotification('Error loading dashboard data', 'error');
        }
    }
    
    async loadStats() {
        try {
            const response = await fetch(`${this.apiBase}/stats`);
            const stats = await response.json();
            
            document.getElementById('onlineDevices').textContent = stats.online_devices || 0;
            document.getElementById('totalCustomers').textContent = stats.total_customers || 0;
            document.getElementById('activeCodes').textContent = stats.active_codes || 0;
            document.getElementById('activeSessions').textContent = stats.active_sessions || 0;
        } catch (error) {
            console.error('Error loading stats:', error);
        }
    }
    
    async loadDevices() {
        try {
            const response = await fetch(`${this.apiBase}/devices`);
            const devices = await response.json();
            
            this.currentDevices = devices;
            this.renderDevices(devices);
        } catch (error) {
            console.error('Error loading devices:', error);
            this.renderDevicesError();
        }
    }
    
    renderDevices(devices) {
        const grid = document.getElementById('devicesGrid');
        
        if (!devices || devices.length === 0) {
            grid.innerHTML = `
                <div class="device-card">
                    <div class="device-info">
                        <h4>No devices registered</h4>
                        <p>Generate support codes to start registering customer devices</p>
                    </div>
                </div>
            `;
            return;
        }
        
        grid.innerHTML = devices.map(device => `
            <div class="device-card" data-device-id="${device.id}">
                <div class="device-header">
                    <div class="device-info">
                        <h4>${device.customer_name || 'Unknown Customer'}</h4>
                        <p>${device.device_name || device.id}</p>
                        <p class="device-details">
                            ${device.os || 'Unknown OS'} • 
                            Last seen: ${this.formatDate(device.last_seen)}
                        </p>
                    </div>
                    <div class="device-status ${device.status}">
                        <i class="fas fa-circle"></i>
                        ${device.status}
                    </div>
                </div>
                <div class="device-actions">
                    <button class="btn btn-primary btn-small" 
                            onclick="adminDashboard.connectToDevice('${device.id}')"
                            ${device.status !== 'online' ? 'disabled' : ''}>
                        <i class="fas fa-desktop"></i> Connect
                    </button>
                    <button class="btn btn-secondary btn-small" 
                            onclick="adminDashboard.viewDeviceDetails('${device.id}')">
                        <i class="fas fa-info-circle"></i> Details
                    </button>
                    <button class="btn btn-outline btn-small" 
                            onclick="adminDashboard.removeDevice('${device.id}')">
                        <i class="fas fa-trash"></i> Remove
                    </button>
                </div>
            </div>
        `).join('');
    }
    
    renderDevicesError() {
        const grid = document.getElementById('devicesGrid');
        grid.innerHTML = `
            <div class="device-card">
                <div class="device-info">
                    <h4>Error loading devices</h4>
                    <p>Please check your connection and try again</p>
                </div>
                <div class="device-actions">
                    <button class="btn btn-primary btn-small" onclick="adminDashboard.loadDevices()">
                        <i class="fas fa-sync-alt"></i> Retry
                    </button>
                </div>
            </div>
        `;
    }
    
    async loadRecentActivity() {
        try {
            const response = await fetch(`${this.apiBase}/activity`);
            const activities = await response.json();
            
            this.renderActivity(activities);
        } catch (error) {
            console.error('Error loading activity:', error);
        }
    }
    
    renderActivity(activities) {
        const feed = document.getElementById('activityFeed');
        
        if (!activities || activities.length === 0) {
            feed.innerHTML = `
                <div class="activity-item">
                    <div class="activity-icon">
                        <i class="fas fa-info-circle"></i>
                    </div>
                    <div class="activity-content">
                        <h5>No recent activity</h5>
                        <p>Activity will appear here as customers connect and technicians provide support</p>
                    </div>
                </div>
            `;
            return;
        }
        
        feed.innerHTML = activities.map(activity => `
            <div class="activity-item">
                <div class="activity-icon">
                    <i class="fas ${this.getActivityIcon(activity.type)}"></i>
                </div>
                <div class="activity-content">
                    <h5>${activity.title}</h5>
                    <p>${activity.description}</p>
                </div>
                <div class="activity-time">
                    ${this.formatDate(activity.timestamp)}
                </div>
            </div>
        `).join('');
    }
    
    async generateSupportCode() {
        const form = document.getElementById('generateCodeForm');
        const formData = new FormData(form);
        
        const customerData = {
            customer_name: formData.get('customerName'),
            customer_email: formData.get('customerEmail'),
            customer_phone: formData.get('customerPhone'),
            session_notes: formData.get('sessionNotes')
        };
        
        try {
            const response = await fetch(`${this.apiBase}/support-codes`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(customerData)
            });
            
            const result = await response.json();
            
            if (result.success) {
                this.currentSupportCode = result.support_code;
                this.displayGeneratedCode(result.support_code, customerData);
                this.showNotification('Support code generated successfully!', 'success');
                
                // Reset form
                form.reset();
                
                // Refresh stats
                this.loadStats();
            } else {
                throw new Error(result.error || 'Failed to generate support code');
            }
        } catch (error) {
            console.error('Error generating support code:', error);
            this.showNotification('Error generating support code: ' + error.message, 'error');
        }
    }
    
    displayGeneratedCode(code, customerData) {
        const display = document.getElementById('generatedCodeDisplay');
        const codeValue = document.getElementById('supportCodeValue');
        const codeInstructions = document.getElementById('codeInstructions');
        
        codeValue.textContent = code;
        codeInstructions.textContent = code;
        
        display.style.display = 'block';
        display.scrollIntoView({ behavior: 'smooth' });
    }
    
    copyCodeToClipboard() {
        if (this.currentSupportCode) {
            navigator.clipboard.writeText(this.currentSupportCode).then(() => {
                this.showNotification('Support code copied to clipboard!', 'success');
            }).catch(() => {
                this.showNotification('Failed to copy code to clipboard', 'error');
            });
        }
    }
    
    async sendCodeToCustomer() {
        if (!this.currentSupportCode) return;
        
        // This would integrate with email service
        this.showNotification('Email integration not yet configured', 'warning');
    }
    
    connectToDevice(deviceId) {
        const device = this.currentDevices.find(d => d.id === deviceId);
        if (!device) return;
        
        if (device.status !== 'online') {
            this.showNotification('Device is not online', 'warning');
            return;
        }
        
        // Show connection modal
        this.showModal('connectModal');
        
        // Store current device for connection
        this.currentConnectionDevice = device;
    }
    
    async initiateConnection(type) {
        if (!this.currentConnectionDevice) return;
        
        try {
            const response = await fetch(`${this.apiBase}/connect`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    device_id: this.currentConnectionDevice.id,
                    connection_type: type
                })
            });
            
            const result = await response.json();
            
            if (result.success) {
                // Launch RustDesk client with connection details
                this.launchRustDeskClient(result.connection_info);
                this.closeModal('connectModal');
                this.showNotification('Connection initiated successfully!', 'success');
            } else {
                throw new Error(result.error || 'Failed to initiate connection');
            }
        } catch (error) {
            console.error('Error initiating connection:', error);
            this.showNotification('Error initiating connection: ' + error.message, 'error');
        }
    }
    
    launchRustDeskClient(connectionInfo) {
        // Create a temporary link to launch RustDesk
        const rustdeskUrl = `rustdesk://${connectionInfo.device_id}?password=${connectionInfo.password}`;
        
        // Try to launch RustDesk client
        const link = document.createElement('a');
        link.href = rustdeskUrl;
        link.click();
        
        // Fallback: show connection details
        setTimeout(() => {
            this.showConnectionDetails(connectionInfo);
        }, 1000);
    }
    
    showConnectionDetails(connectionInfo) {
        const details = `
            Device ID: ${connectionInfo.device_id}
            Password: ${connectionInfo.password}
            Server: ${connectionInfo.server}
        `;
        
        if (confirm('RustDesk client not detected. Copy connection details to clipboard?')) {
            navigator.clipboard.writeText(details);
        }
    }
    
    // Utility functions
    formatDate(dateString) {
        if (!dateString) return 'Never';
        
        const date = new Date(dateString);
        const now = new Date();
        const diff = now - date;
        
        if (diff < 60000) return 'Just now';
        if (diff < 3600000) return `${Math.floor(diff / 60000)} minutes ago`;
        if (diff < 86400000) return `${Math.floor(diff / 3600000)} hours ago`;
        
        return date.toLocaleDateString();
    }
    
    getActivityIcon(type) {
        const icons = {
            'connection': 'fa-plug',
            'code_generated': 'fa-key',
            'device_registered': 'fa-desktop',
            'session_started': 'fa-play',
            'session_ended': 'fa-stop',
            'error': 'fa-exclamation-triangle'
        };
        
        return icons[type] || 'fa-info-circle';
    }
    
    showModal(modalId) {
        document.getElementById(modalId).style.display = 'block';
    }
    
    closeModal(modalId) {
        document.getElementById(modalId).style.display = 'none';
    }
    
    showNotification(message, type = 'info') {
        // Create notification element
        const notification = document.createElement('div');
        notification.className = `notification notification-${type}`;
        notification.innerHTML = `
            <i class="fas ${type === 'success' ? 'fa-check-circle' : type === 'error' ? 'fa-exclamation-circle' : 'fa-info-circle'}"></i>
            <span>${message}</span>
            <button onclick="this.parentElement.remove()">×</button>
        `;
        
        // Add to page
        document.body.appendChild(notification);
        
        // Auto remove after 5 seconds
        setTimeout(() => {
            if (notification.parentElement) {
                notification.remove();
            }
        }, 5000);
    }
    
    filterDevices(searchTerm) {
        const cards = document.querySelectorAll('.device-card');
        
        cards.forEach(card => {
            const text = card.textContent.toLowerCase();
            const matches = text.includes(searchTerm.toLowerCase());
            card.style.display = matches ? 'block' : 'none';
        });
    }
    
    filterDevicesByStatus(status) {
        const cards = document.querySelectorAll('.device-card');
        
        cards.forEach(card => {
            if (status === 'all') {
                card.style.display = 'block';
            } else {
                const statusElement = card.querySelector('.device-status');
                const matches = statusElement && statusElement.classList.contains(status);
                card.style.display = matches ? 'block' : 'none';
            }
        });
    }
    
    startAutoRefresh() {
        this.refreshInterval = setInterval(() => {
            this.loadStats();
            this.loadDevices();
        }, 30000); // Refresh every 30 seconds
    }
    
    refreshDashboard() {
        this.loadDashboardData();
        this.showNotification('Dashboard refreshed', 'success');
    }
}

// Global functions for HTML onclick handlers
function refreshDashboard() {
    adminDashboard.refreshDashboard();
}

function copyCodeToClipboard() {
    adminDashboard.copyCodeToClipboard();
}

function sendCodeToCustomer() {
    adminDashboard.sendCodeToCustomer();
}

function closeModal(modalId) {
    adminDashboard.closeModal(modalId);
}

function initiateConnection(type) {
    adminDashboard.initiateConnection(type);
}

// Quick action functions
function viewAllDevices() {
    document.querySelector('.device-section').scrollIntoView({ behavior: 'smooth' });
}

function viewActiveSessions() {
    adminDashboard.showNotification('Active sessions view coming soon', 'info');
}

function generateBulkCodes() {
    adminDashboard.showNotification('Bulk code generation coming soon', 'info');
}

function exportCustomerData() {
    adminDashboard.showNotification('Export functionality coming soon', 'info');
}

function systemSettings() {
    adminDashboard.showNotification('System settings coming soon', 'info');
}

function viewLogs() {
    adminDashboard.showNotification('Log viewer coming soon', 'info');
}

// Initialize dashboard when page loads
let adminDashboard;
document.addEventListener('DOMContentLoaded', () => {
    adminDashboard = new AdminDashboard();
});
