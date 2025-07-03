# ConnectAssist Web Admin Dashboard Guide

This guide provides comprehensive instructions for using the ConnectAssist Web Admin Dashboard, designed to replace command-line tools with a professional web-based interface.

## Quick Access

- **Admin Dashboard URL:** `https://connectassist.live/admin`
- **Customer Portal URL:** `https://connectassist.live`
- **API Documentation:** See `docs/API-DOCUMENTATION.md`

---

## Dashboard Overview

### Main Interface Components

The admin dashboard consists of four main panels:

#### 1. **System Status Panel** (Top Left)
- **System Health Indicator** - Green "Online" means all systems operational
- **Online Devices Count** - Number of customer devices currently connected
- **Active Support Codes** - Number of valid, unexpired support codes
- **Total Customers** - Total number of customers with installed clients

#### 2. **Support Code Generation Panel** (Top Right)
- **Customer Name Field** - Enter customer's name for code generation
- **Generate Button** - Creates new 6-digit support code
- **Recent Codes List** - Shows last 5 generated codes with status

#### 3. **Device Management Panel** (Bottom Left)
- **Connected Devices List** - All customer devices with real-time status
- **Device Information** - Customer name, device ID, last seen, platform
- **Connection Buttons** - Direct connect to online devices
- **Status Indicators** - Green (online), Red (offline), Yellow (connecting)

#### 4. **Recent Activity Panel** (Bottom Right)
- **Connection Logs** - Recent technician connections to devices
- **Support Sessions** - Active and completed support sessions
- **System Events** - Important system notifications and alerts

---

## Step-by-Step Workflows

### Workflow 1: New Customer Support Request

**Scenario:** Customer calls with computer problem, needs first-time setup.

1. **Access Dashboard**
   ```
   Navigate to: https://connectassist.live/admin
   Verify: System status shows "Online" (green indicator)
   ```

2. **Generate Support Code**
   ```
   In "Generate Support Code" panel:
   - Enter customer name (e.g., "John Smith")
   - Click "Generate Support Code" button
   - Note the 6-digit code (e.g., 123456)
   ```

3. **Provide Code to Customer**
   ```
   Tell customer over phone:
   "Please visit connectassist.live and enter code 123456"
   "The code expires in 24 hours"
   "Follow the download and installation instructions"
   ```

4. **Monitor Installation Progress**
   ```
   In dashboard, watch for:
   - Support code status changes to "Downloaded"
   - New device appears in "Connected Devices" panel
   - Device status shows "Online" when ready
   ```

5. **Connect to Customer Device**
   ```
   When device shows "Online":
   - Click "Connect" button next to customer's device
   - RustDesk client opens automatically
   - Begin remote support session
   ```

### Workflow 2: Returning Customer Support

**Scenario:** Customer with previously installed ConnectAssist needs help.

1. **Locate Customer Device**
   ```
   In "Connected Devices" panel:
   - Find customer by name or device ID
   - Check device status (should be "Online")
   ```

2. **Direct Connection**
   ```
   If device is online:
   - Click "Connect" button immediately
   - No support code generation needed
   - RustDesk opens with automatic connection
   ```

3. **If Device is Offline**
   ```
   Options:
   - Wait for device to come online (customer turns on computer)
   - Call customer to ensure computer is on and connected
   - Generate new support code if client needs reinstallation
   ```

### Workflow 3: Managing Multiple Support Sessions

**Scenario:** Multiple customers need support simultaneously.

1. **Dashboard Monitoring**
   ```
   Use dashboard to:
   - Monitor all online devices in real-time
   - Track active support codes and their expiration
   - See which technicians are connected to which devices
   ```

2. **Priority Management**
   ```
   Prioritize based on:
   - Device online status (connect to online devices first)
   - Support code expiration times
   - Customer urgency level
   ```

3. **Session Tracking**
   ```
   Dashboard automatically tracks:
   - Connection start/end times
   - Which technician connected to which device
   - Session duration and activities
   ```

---

## Advanced Features

### Support Code Management

**Viewing All Active Codes:**
- All generated codes appear in the "Recent Support Codes" section
- Shows customer name, code, creation time, expiration time, and status

**Code Status Types:**
- **Active** - Code generated, waiting for customer to use
- **Downloaded** - Customer downloaded installer using the code
- **Connected** - Device is online and ready for connection
- **Expired** - Code has passed 24-hour expiration time

**Deactivating Codes:**
- Click the "×" button next to any support code
- Prevents customer from using the code
- Use when customer no longer needs support

### Device Information Details

**For each connected device, view:**
- **Customer Name** - Identifies the device owner
- **Device ID** - Unique identifier (format: SUPP-123456-timestamp)
- **Support Code** - Original code used for setup
- **Last Seen** - Timestamp of last connection
- **IP Address** - Current network location
- **Platform** - Operating system (Windows 10, macOS, etc.)
- **Connection Status** - Real-time online/offline status

### Real-Time Monitoring

**Automatic Updates:**
- Device status updates every 30 seconds
- Support code status updates in real-time
- Connection logs update immediately when sessions start/end

**Status Indicators:**
- 🟢 **Green Dot** - Device online and ready
- 🔴 **Red Dot** - Device offline or disconnected
- 🟡 **Yellow Dot** - Device connecting or in transition
- ⚪ **Gray Dot** - Device status unknown

---

## Troubleshooting Common Issues

### Dashboard Not Loading
```
1. Check internet connection
2. Verify URL: https://connectassist.live/admin
3. Clear browser cache and cookies
4. Try different browser (Chrome, Firefox, Safari)
5. Check if system status shows "Online"
```

### Support Code Not Working
```
1. Verify code was entered correctly (6 digits)
2. Check if code has expired (24-hour limit)
3. Ensure customer is using correct website: connectassist.live
4. Generate new code if needed
5. Check system status in dashboard
```

### Device Not Appearing Online
```
1. Confirm customer's computer is on and connected to internet
2. Verify customer completed installation process
3. Check if Windows firewall is blocking ConnectAssist
4. Have customer restart computer
5. Generate new support code for reinstallation if needed
```

### Cannot Connect to Device
```
1. Verify device shows "Online" status in dashboard
2. Check if RustDesk client is installed on technician computer
3. Ensure firewall allows RustDesk connections
4. Try refreshing dashboard and reconnecting
5. Check connection logs for error messages
```

---

## Security Best Practices

### Access Control
- Only authorized technicians should access the admin dashboard
- Use secure, private networks when possible
- Log out of dashboard when not in use

### Customer Privacy
- Only connect to devices when customer has requested support
- Explain all actions to customers during sessions
- Respect customer privacy and data

### Code Management
- Generate new codes for each support session
- Deactivate unused codes promptly
- Never share support codes with unauthorized persons

---

## Integration with RustDesk Client

### Automatic Connection Process
1. Dashboard generates connection parameters automatically
2. Clicking "Connect" launches RustDesk with pre-filled settings
3. No manual password entry required
4. Direct connection to customer device

### Connection Parameters
- **Server:** connectassist.live
- **Device ID:** Automatically provided
- **Password:** Automatically generated and embedded
- **Connection Type:** Full control (default) or view-only

### Session Management
- All connections logged automatically
- Session duration tracked
- Connection quality monitored
- Automatic reconnection if connection drops

---

## Support and Maintenance

### Regular Monitoring
- Check dashboard daily for system health
- Monitor device connection patterns
- Review connection logs for issues
- Update customer information as needed

### Maintenance Tasks
- Clean up expired support codes weekly
- Review and archive old connection logs
- Monitor system performance metrics
- Update customer contact information

### Getting Help
- Check system logs in dashboard
- Review API documentation for technical details
- Contact system administrator for server issues
- Refer to troubleshooting guides for common problems
