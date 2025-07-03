# ConnectAssist Technician Operations Guide

This guide provides comprehensive procedures for support technicians to efficiently initiate, manage, and complete remote support sessions using ConnectAssist's **Web-Based Admin Dashboard**.

## Table of Contents

1. [Overview](#overview)
2. [Admin Dashboard Access](#admin-dashboard-access)
3. [Support Code Generation](#support-code-generation)
4. [Device Management](#device-management)
5. [Session Initiation Process](#session-initiation-process)
6. [Session Management](#session-management)
7. [Common Support Scenarios](#common-support-scenarios)
8. [Troubleshooting Technical Issues](#troubleshooting-technical-issues)
9. [Session Documentation](#session-documentation)
10. [Best Practices](#best-practices)
11. [Security Guidelines](#security-guidelines)

---

## Overview

ConnectAssist now provides a **professional web-based admin dashboard** that eliminates the need for command-line tools. Technicians can manage all support operations through an intuitive web interface at `https://connectassist.live/admin`.

### Key Features
- ✅ **Web-Based Interface** - No command-line tools required
- ✅ **Support Code Generation** - Create 6-digit codes for customers
- ✅ **Real-Time Device Monitoring** - See online/offline status instantly
- ✅ **Direct Connection Initiation** - Connect to devices with one click
- ✅ **Session Tracking** - Automatic logging of all support activities
- ✅ **Customer Management** - Organized view of all customer devices

### Key Principles
- **Customer-First Approach**: Always explain what you're doing
- **Security-Conscious**: Follow all security protocols
- **Efficient Resolution**: Use the admin dashboard for quick problem solving
- **Documentation**: All actions are automatically logged
- **Professional Communication**: Maintain clear, patient communication

---

## Admin Dashboard Access

### 1. Accessing the Dashboard

**URL:** `https://connectassist.live/admin`

**Login Process:**
1. Open your web browser
2. Navigate to `https://connectassist.live/admin`
3. The dashboard loads automatically (no login required in current version)
4. Verify system status indicator shows "Online" (green)

### 2. Dashboard Overview

The admin dashboard provides four main sections:

#### **System Status Panel**
- Real-time system health indicator
- Online devices count
- Active support codes count
- Total customers count

#### **Support Code Generation Panel**
- Customer name input field
- Generate new 6-digit support codes
- View recently generated codes

#### **Device Management Panel**
- List of all customer devices
- Real-time online/offline status
- Direct connection buttons
- Device information display

#### **Recent Activity Panel**
- Recent support sessions
- Connection logs
- System events

---

## Support Code Generation

### 1. Creating Support Codes for Customers

**When a customer calls for support:**

1. **Access the Admin Dashboard**
   - Navigate to `https://connectassist.live/admin`
   - Verify the system status shows "Online"

2. **Generate Support Code**
   - In the "Generate Support Code" panel
   - Enter the customer's name in the "Customer Name" field
   - Click the **"Generate Support Code"** button
   - A 6-digit code will be generated (example: 123456)

3. **Provide Code to Customer**
   - Give the 6-digit code to the customer over the phone
   - Explain that the code expires in 24 hours
   - Guide them to visit `https://connectassist.live`
   - Instruct them to enter the code in the support code field

4. **Monitor Code Status**
   - The generated code appears in the "Recent Support Codes" section
   - Status shows as "Active" until customer downloads installer
   - Status changes to "Downloaded" when customer gets the installer

### 2. Support Code Management

**Viewing Active Codes:**
- All active support codes are displayed in the dashboard
- Shows customer name, code, creation time, and expiration
- Real-time status updates (Active → Downloaded → Connected)

**Deactivating Codes:**
- Click the "X" button next to any support code to deactivate it
- Deactivated codes cannot be used by customers
- Use this if a customer no longer needs support

---

## Device Management

### 1. Monitoring Customer Devices

**Device Status Dashboard:**
- All customer devices appear in the "Connected Devices" panel
- Real-time online/offline status indicators
- Device information includes:
  - Customer name
  - Device ID
  - Last seen timestamp
  - Connection status
  - Platform (Windows/Mac/Linux)

**Status Indicators:**
- 🟢 **Online** - Device is connected and ready for support
- 🔴 **Offline** - Device is not currently connected
- 🟡 **Connecting** - Device is in the process of connecting

### 2. Device Information

**For each device, you can see:**
- **Customer Name** - Who the device belongs to
- **Device ID** - Unique identifier for the device
- **Support Code** - Original code used to set up the device
- **Last Seen** - When the device was last online
- **IP Address** - Current network location
- **Platform** - Operating system type

### 3. Connection Management

**Initiating Connections:**
1. Locate the customer's device in the device list
2. Verify the device status shows "Online" (green indicator)
3. Click the **"Connect"** button next to the device
4. The system will initiate a direct connection
5. RustDesk client will open automatically with connection details

**Required Tools:**
- ConnectAssist technician client
- Session documentation template
- Common troubleshooting scripts
- Customer information system access
- Escalation contact list

**Workstation Setup:**
- Close unnecessary applications
- Ensure stable internet connection
- Have backup communication method ready
- Prepare screen recording if required

### 3. Customer Information Review

Before calling the customer:
- Review customer's previous support history
- Identify known issues or recurring problems
- Prepare relevant solutions and documentation
- Check customer's technical skill level notes

---

## Session Initiation Process

### 1. Initial Customer Contact

**Phone Call Script:**
```
"Hello, this is [Your Name] from [Company] technical support. 
I understand you're experiencing [brief issue description]. 
I'm going to help you resolve this using our secure remote support system. 
This will allow me to see your screen and help fix the problem directly.

The process is completely safe and secure, and you'll remain in control 
of your computer at all times. Are you ready to get started?"
```

### 2. Guide Customer to ConnectAssist

**Step-by-Step Customer Guidance:**

1. **Website Navigation:**
   ```
   "Please open your web browser - that's Internet Explorer, Chrome, 
   Firefox, or Safari. In the address bar at the top, please type: 
   connectassist.live and press Enter."
   ```

2. **Download Guidance:**
   ```
   "You should see our ConnectAssist website with three download buttons. 
   What type of computer are you using - Windows or Mac?"
   
   For Windows: "Please click the 'Download for Windows' button."
   For Mac: "Please click the 'Download for Mac' button."
   For Linux: "Please click the 'Download for Linux' button."
   ```

3. **Installation Assistance:**
   ```
   Windows: "Look for the downloaded file, usually in your Downloads folder. 
   Double-click on 'connectassist-windows.exe'. If Windows asks for permission, 
   click 'Yes'."
   
   Mac: "Double-click the downloaded file, then drag ConnectAssist to your 
   Applications folder. Open Applications and double-click ConnectAssist."
   ```

### 3. Connection Establishment

**ID and Password Collection:**
```
"Perfect! Now you should see the ConnectAssist window with your ID number 
and password. Can you please read me the ID number first? 
Please read it slowly, digit by digit."

[Record ID]

"Great! Now can you read me the password? Please spell it out letter by letter."

[Record Password]
```

**Connection Initiation:**
1. Open your technician ConnectAssist client
2. Enter customer's ID in the "Partner ID" field
3. Click "Connect"
4. Enter the password when prompted
5. Wait for customer to accept connection

**Customer Acceptance:**
```
"You should now see a message asking if you want to accept the connection. 
Please click 'Accept' to allow me to help you."
```

---

## Session Management

### 1. Session Start Protocol

**Once Connected:**
1. **Verify Connection Quality:**
   - Test mouse movement responsiveness
   - Check screen resolution and clarity
   - Confirm audio communication is clear

2. **Customer Orientation:**
   ```
   "Perfect! I'm now connected to your computer. You'll see your mouse 
   cursor moving - that's me controlling it remotely. Please don't touch 
   your mouse or keyboard unless I ask you to. I'll explain everything 
   I'm doing as we go."
   ```

3. **Initial Assessment:**
   - Take screenshot for documentation
   - Note current system state
   - Identify obvious issues or symptoms

### 2. During the Session

**Communication Best Practices:**
- Explain each action before performing it
- Ask permission for significant changes
- Keep customer engaged with regular updates
- Use simple, non-technical language

**Example Narration:**
```
"I'm going to open the Control Panel now to check your system settings."
"I can see the problem - your antivirus software needs updating. 
I'm going to do that for you now."
"I'm installing a Windows update that should fix this issue. 
This might take a few minutes."
```

**Screen Management:**
- Minimize unnecessary windows
- Use built-in tools when possible
- Avoid installing additional software unless necessary
- Keep customer's desktop organized

### 3. Session Monitoring

**Performance Indicators:**
- Connection stability and latency
- Customer responsiveness and comfort level
- Progress toward issue resolution
- Time elapsed vs. estimated completion

**Quality Checkpoints:**
- Every 15 minutes: "How are we doing? Any questions so far?"
- Before major changes: "I'm about to [action]. Is that okay with you?"
- After each fix: "Let's test this to make sure it's working properly."

---

## Common Support Scenarios

### 1. Slow Computer Performance

**Diagnostic Steps:**
1. Check Task Manager for resource usage
2. Review startup programs
3. Check available disk space
4. Scan for malware
5. Update drivers and software

**Typical Actions:**
```
- Disable unnecessary startup programs
- Run disk cleanup
- Update Windows/macOS
- Install/update antivirus
- Clear browser cache and temporary files
```

### 2. Software Installation/Updates

**Process:**
1. Verify software legitimacy
2. Download from official sources only
3. Create system restore point
4. Install with customer permission
5. Test functionality
6. Document installation details

### 3. Email Configuration

**Common Tasks:**
- Set up email clients (Outlook, Mail app)
- Configure IMAP/POP3 settings
- Troubleshoot sending/receiving issues
- Set up email security features
- Import/export email data

### 4. Internet Connectivity Issues

**Troubleshooting Steps:**
1. Check network adapter status
2. Reset network settings
3. Update network drivers
4. Configure DNS settings
5. Test with different browsers
6. Check firewall/antivirus settings

### 5. Virus/Malware Removal

**Security Protocol:**
1. Disconnect from internet if severely infected
2. Boot into safe mode if necessary
3. Run multiple antivirus scans
4. Remove malicious software
5. Update all security software
6. Educate customer on prevention

---

## Troubleshooting Technical Issues

### 1. Connection Problems

**Customer Can't Connect:**
```bash
# Check server status
cd /opt/connectassist/docker
docker-compose ps

# Verify ports are accessible
netstat -tuln | grep -E ':(21115|21116|21117|21118|21119)'

# Test external connectivity
curl -I https://connectassist.live
```

**Poor Connection Quality:**
- Ask customer to close bandwidth-heavy applications
- Switch to lower quality mode if available
- Consider rescheduling if connection is unusable

### 2. Customer Technical Difficulties

**Can't Find Downloaded File:**
1. Guide to Downloads folder
2. Check browser download history
3. Use Windows/Mac search function
4. Re-download if necessary

**Permission Issues:**
- Guide customer through UAC prompts
- Use "Run as Administrator" option
- Temporarily disable overly restrictive antivirus

### 3. Software Compatibility Issues

**Legacy Software:**
- Check compatibility mode settings
- Research known compatibility issues
- Suggest alternative software if needed
- Document compatibility requirements

---

## Session Documentation

### 1. Required Documentation

**Session Record Template:**
```
Date/Time: [Session start and end times]
Customer: [Name and contact information]
Technician: [Your name and ID]
Issue Description: [Customer's reported problem]
Actions Taken: [Detailed list of all actions performed]
Resolution: [Final outcome and solution]
Follow-up Required: [Any additional steps needed]
Customer Satisfaction: [Rating and feedback]
```

### 2. Technical Details

**System Information to Record:**
- Operating system version
- Installed software relevant to issue
- Hardware specifications if relevant
- Network configuration changes
- Security software status

**Before/After Screenshots:**
- Capture initial problem state
- Document solution implementation
- Show final resolved state

### 3. Knowledge Base Updates

**After Each Session:**
- Update internal knowledge base with new solutions
- Document recurring issues and patterns
- Share effective troubleshooting methods
- Report software bugs or system issues

---

## Escalation Procedures

### 1. When to Escalate

**Technical Escalation Triggers:**
- Issue requires more than 2 hours to resolve
- Problem is outside your expertise area
- Customer requests supervisor
- Security incident detected
- Hardware failure suspected

**Customer Service Escalation:**
- Customer is dissatisfied with service
- Communication breakdown occurs
- Customer requests refund or compensation
- Complaint about technician behavior

### 2. Escalation Process

**Immediate Actions:**
1. Inform customer of escalation
2. Document current session state
3. Save all relevant files and screenshots
4. Contact escalation point

**Escalation Contacts:**
- **Technical Lead:** [Contact Information]
- **Customer Service Manager:** [Contact Information]
- **Security Team:** [Contact Information]
- **After-Hours Emergency:** [Contact Information]

### 3. Handoff Procedures

**Information to Provide:**
- Complete session documentation
- Customer contact information
- Detailed problem description
- Actions already attempted
- Customer's technical skill level
- Any special considerations

---

## Best Practices

### 1. Customer Communication

**Do:**
- Speak clearly and at appropriate pace
- Use simple, non-technical language
- Confirm understanding regularly
- Show patience with elderly customers
- Explain the value of each action

**Don't:**
- Use technical jargon without explanation
- Rush through procedures
- Make changes without permission
- Criticize customer's computer habits
- Leave customer confused about what happened

### 2. Technical Excellence

**Efficiency Tips:**
- Use keyboard shortcuts when appropriate
- Keep commonly used tools readily available
- Develop standard procedures for common issues
- Use remote clipboard for easy text transfer
- Maintain organized desktop during session

**Quality Assurance:**
- Test all fixes before ending session
- Verify customer can reproduce solutions
- Leave system in better state than found
- Document all changes made
- Provide prevention tips

### 3. Time Management

**Session Planning:**
- Set realistic time expectations
- Break complex tasks into smaller steps
- Take breaks for long sessions
- Monitor progress against time estimates
- Communicate delays promptly

---

## Security Guidelines

### 1. Data Protection

**Customer Privacy:**
- Never access personal files without permission
- Avoid viewing sensitive information
- Don't save customer data to your system
- Use secure communication channels only
- Report any data breaches immediately

**System Security:**
- Always use encrypted connections
- Verify customer identity before connecting
- Don't install unauthorized software
- Follow company security policies
- Log all security-related actions

### 2. Authentication Procedures

**Customer Verification:**
- Confirm customer identity at session start
- Verify account information if available
- Use callback procedures for sensitive work
- Document verification methods used

**Session Security:**
- End sessions completely when finished
- Don't leave connections open unattended
- Use secure passwords for any accounts created
- Enable two-factor authentication when possible

### 3. Incident Reporting

**Security Incidents:**
- Suspected malware or hacking attempts
- Unauthorized access attempts
- Data breach or privacy violations
- Customer reports of fraudulent activity
- System security vulnerabilities discovered

**Reporting Process:**
1. Immediately secure the affected system
2. Document all relevant details
3. Contact security team
4. Follow incident response procedures
5. Complete incident report form

---

## Performance Metrics

### 1. Key Performance Indicators

**Technical Metrics:**
- Average session duration
- First-call resolution rate
- Customer satisfaction scores
- Number of escalations
- Repeat issue frequency

**Quality Metrics:**
- Documentation completeness
- Security compliance score
- Customer feedback ratings
- Peer review scores
- Training completion status

### 2. Continuous Improvement

**Regular Reviews:**
- Weekly performance discussions
- Monthly skill assessments
- Quarterly goal setting
- Annual comprehensive reviews
- Ongoing training opportunities

**Skill Development:**
- Stay current with technology trends
- Complete required certifications
- Participate in team training sessions
- Share knowledge with colleagues
- Seek feedback from supervisors

---

## Emergency Procedures

### 1. System Outages

**If ConnectAssist is Down:**
1. Check system status dashboard
2. Contact system administrator
3. Inform customers of estimated downtime
4. Use alternative support methods if available
5. Document all affected sessions

### 2. Security Incidents

**Immediate Response:**
1. Disconnect affected sessions
2. Secure all systems
3. Contact security team
4. Document incident details
5. Follow incident response plan

### 3. Customer Emergencies

**Critical Issues:**
- System completely non-functional
- Suspected security breach
- Data loss situations
- Business-critical system failures

**Response Protocol:**
1. Prioritize based on severity
2. Escalate immediately if needed
3. Provide regular status updates
4. Document all actions taken
5. Follow up to ensure resolution

---

## Tools and Resources

### 1. Essential Software

**Technician Toolkit:**
- ConnectAssist client application
- System diagnostic tools
- Antivirus/anti-malware software
- Network troubleshooting utilities
- Screen recording software
- Documentation templates

### 2. Reference Materials

**Quick Reference Guides:**
- Common Windows/Mac keyboard shortcuts
- Network troubleshooting flowcharts
- Software installation procedures
- Security best practices checklist
- Customer communication scripts

### 3. Support Resources

**Internal Resources:**
- Knowledge base access
- Escalation contact list
- Training materials
- Policy documents
- Procedure manuals

**External Resources:**
- Vendor support contacts
- Software documentation
- Hardware manufacturer resources
- Security advisory services
- Industry best practice guides

---

*This guide should be reviewed and updated regularly to reflect changes in technology, procedures, and best practices. For questions or suggestions, contact the Technical Training Team.*
