# ConnectAssist API Documentation

This document provides comprehensive documentation for the ConnectAssist Flask API server that powers the admin dashboard and customer portal integration.

## Base URL
- **Production:** `https://connectassist.live/api`
- **Local Development:** `http://localhost:5001/api`

## Authentication
Most admin endpoints require authentication. Customer endpoints are publicly accessible but validate support codes.

## API Endpoints Overview

### System Status
- `GET /api/status` - Get system status and health information

### Customer Endpoints
- `POST /api/customer/installer` - Generate custom installer for support code
- `POST /api/track-download` - Track installer downloads

### Admin Dashboard Endpoints
- `GET /api/stats` - Get dashboard statistics
- `POST /api/support-codes` - Generate new support code
- `GET /api/support-codes` - List active support codes
- `DELETE /api/support-codes/<code>` - Deactivate support code
- `GET /api/devices` - List managed devices
- `POST /api/devices/<device_id>/connect` - Initiate connection to device
- `GET /api/logs` - Get system logs

### Deployment Endpoints
- `POST /api/deploy` - Deploy updates from GitHub (requires deploy key)

---

## Detailed Endpoint Documentation

### System Status

#### GET /api/status
Get current system status and health information.

**Response:**
```json
{
  "online": true,
  "server": "connectassist.live",
  "timestamp": "2025-07-03T11:11:52.530188",
  "version": "1.0.0",
  "services": {
    "database": "connected",
    "rustdesk_relay": "running",
    "client_builder": "available"
  }
}
```

---

### Customer Endpoints

#### POST /api/customer/installer
Validate support code and generate custom installer package for customer.

**Request Body:**
```json
{
  "support_code": "123456"
}
```

**Response (Success):**
```json
{
  "success": true,
  "download_url": "/downloads/ConnectAssist-SUPP-123456-1720012345.zip",
  "expires_at": "2025-07-04T12:00:00Z",
  "instructions": "Download and run the installer...",
  "customer_info": {
    "customer_name": "John Smith",
    "device_id": "SUPP-123456-1720012345"
  }
}
```

**Response (Error):**
```json
{
  "success": false,
  "error": "Invalid or expired support code"
}
```

#### POST /api/track-download
Track installer downloads for analytics and monitoring.

**Request Body:**
```json
{
  "support_code": "123456",
  "download_url": "/downloads/ConnectAssist-SUPP-123456-1720012345.zip",
  "user_agent": "Mozilla/5.0...",
  "ip_address": "192.168.1.100"
}
```

**Response:**
```json
{
  "success": true,
  "tracked": true
}
```

---

### Admin Dashboard Endpoints

#### GET /api/stats
Get dashboard statistics for admin interface.

**Response:**
```json
{
  "success": true,
  "stats": {
    "online_devices": 5,
    "total_customers": 12,
    "active_support_codes": 3,
    "total_sessions_today": 8,
    "system_uptime": "5 days, 12 hours"
  }
}
```

#### POST /api/support-codes
Generate a new 6-digit support code for customer.

**Request Body:**
```json
{
  "customer_name": "John Smith",
  "notes": "Printer setup assistance",
  "expires_hours": 24
}
```

**Response:**
```json
{
  "success": true,
  "support_code": "123456",
  "customer_name": "John Smith",
  "expires_at": "2025-07-04T12:00:00Z",
  "created_at": "2025-07-03T12:00:00Z",
  "client_package": {
    "created": true,
    "download_url": "/downloads/ConnectAssist-SUPP-123456-1720012345.zip"
  }
}
```

#### GET /api/support-codes
List all active support codes.

**Response:**
```json
{
  "success": true,
  "support_codes": [
    {
      "code": "123456",
      "customer_name": "John Smith",
      "created_at": "2025-07-03T12:00:00Z",
      "expires_at": "2025-07-04T12:00:00Z",
      "status": "active",
      "downloads": 1
    }
  ]
}
```

#### DELETE /api/support-codes/<code>
Deactivate a support code.

**Response:**
```json
{
  "success": true,
  "message": "Support code 123456 deactivated"
}
```

#### GET /api/devices
List all managed devices with their current status.

**Response:**
```json
{
  "success": true,
  "devices": [
    {
      "device_id": "SUPP-123456-1720012345",
      "customer_name": "John Smith",
      "status": "online",
      "last_seen": "2025-07-03T12:00:00Z",
      "ip_address": "192.168.1.100",
      "platform": "Windows 10",
      "permanent_password": "auto-generated-key",
      "support_code": "123456"
    }
  ]
}
```

#### POST /api/devices/<device_id>/connect
Initiate connection to a specific device.

**Request Body:**
```json
{
  "connection_type": "view_only",
  "technician_id": "TECH-001"
}
```

**Response:**
```json
{
  "success": true,
  "connection_info": {
    "device_id": "SUPP-123456-1720012345",
    "password": "auto-generated-key",
    "server": "connectassist.live",
    "connection_type": "view_only"
  }
}
```

#### GET /api/logs
Get recent system logs for monitoring.

**Response:**
```json
{
  "success": true,
  "logs": [
    {
      "timestamp": "2025-07-03T12:00:00Z",
      "level": "INFO",
      "message": "Support code 123456 generated for John Smith",
      "category": "support_code"
    }
  ]
}
```

---

### Deployment Endpoints

#### POST /api/deploy
Deploy updates from GitHub repository (requires authentication).

**Request Body:**
```json
{
  "deploy_key": "ConnectAssist2024Deploy"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Deployment completed successfully",
  "changes": "30 files changed, 7144 insertions(+), 49 deletions(-)"
}
```

---

## Error Handling

All API endpoints return consistent error responses:

```json
{
  "success": false,
  "error": "Error description",
  "error_code": "INVALID_SUPPORT_CODE",
  "timestamp": "2025-07-03T12:00:00Z"
}
```

## Rate Limiting

- Customer endpoints: 10 requests per minute per IP
- Admin endpoints: 100 requests per minute per session
- Deployment endpoints: 1 request per minute

## Database Schema

The API uses SQLite database with the following main tables:
- `support_codes` - Active support codes and expiration
- `devices` - Registered customer devices
- `sessions` - Connection session logs
- `admin_sessions` - Admin authentication sessions
- `client_packages` - Generated installer packages
- `connection_logs` - Connection attempt logs

## Security Considerations

- All admin endpoints require proper authentication
- Support codes expire after 24 hours by default
- Client packages are generated with unique device IDs
- All connections use encrypted permanent passwords
- API server runs on internal port 5001 behind NGINX proxy
