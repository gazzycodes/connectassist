# SSH Access Troubleshooting Guide - ConnectAssist VPS

## 🔍 Current SSH Access Issue

**Problem**: Cannot authenticate to VPS via SSH using password authentication  
**VPS**: 103.195.103.198 (connectassist.live)  
**Status**: SSH connection establishes but all password attempts fail  

---

## 🧪 Diagnostic Information

### SSH Connection Test Results
```bash
# Connection establishes successfully
ssh -v root@103.195.103.198
# Output: Connection established, SSH handshake completes
# Server supports: publickey,password authentication
# Issue: All password attempts result in "Permission denied"
```

### Attempted Credentials
- **root@103.195.103.198** + `ConnectAssist2024!` → Permission denied
- **root@103.195.103.198** + `Kx9#mP2$vL8@nQ5!` → Permission denied
- **ubuntu@103.195.103.198** + `ConnectAssist2024!` → Permission denied
- **root@connectassist.live** + both passwords → Permission denied

### Server Response Analysis
```
debug1: Authentications that can continue: publickey,password
debug1: Next authentication method: password
root@103.195.103.198's password:
debug1: Authentications that can continue: publickey,password
Permission denied, please try again.
```

**Analysis**: 
- Server accepts password authentication (not disabled)
- Password is being rejected by the server
- No account lockout messages (would show different error)
- SSH service is running and responsive

---

## 🔧 Troubleshooting Steps

### Step 1: Verify Current Credentials
**Possible Issues:**
- Password may have been changed by VPS provider
- Initial setup may have used different credentials
- Account may have been modified for security

**Actions to Take:**
1. Check VPS provider (Evolution Host) control panel
2. Look for password reset options
3. Verify if root access is enabled
4. Check for any security notifications

### Step 2: Alternative User Accounts
**Common VPS User Accounts:**
- `ubuntu` (Ubuntu systems)
- `admin` (some providers)
- `connectassist` (custom user)
- `deploy` (deployment user)

**Test Commands:**
```bash
ssh ubuntu@103.195.103.198
ssh admin@103.195.103.198
ssh connectassist@103.195.103.198
```

### Step 3: SSH Key Authentication
**Generate SSH Key Pair:**
```bash
# Generate new SSH key
ssh-keygen -t ed25519 -C "connectassist-deployment"

# Copy public key (to be added to server)
cat ~/.ssh/id_ed25519.pub
```

**Add to Server** (requires VPS provider control panel):
- Copy public key content
- Add to `~/.ssh/authorized_keys` on server
- Set proper permissions (600 for file, 700 for .ssh directory)

### Step 4: VPS Provider Control Panel Access
**Evolution Host Control Panel:**
- Log into provider dashboard
- Look for "Console" or "Terminal" access
- Use web-based terminal to access server
- Check SSH configuration and user accounts

### Step 5: SSH Configuration Check
**Server SSH Config** (`/etc/ssh/sshd_config`):
```bash
# Check if these settings allow access:
PermitRootLogin yes
PasswordAuthentication yes
PubkeyAuthentication yes
AuthenticationMethods publickey,password
```

---

## 🚨 Emergency Access Methods

### Method 1: VPS Provider Console
**Access via Web Browser:**
1. Log into Evolution Host control panel
2. Find "Console" or "VNC" access option
3. Access server directly through web interface
4. No SSH required

### Method 2: Recovery Mode
**If Available:**
1. Boot server in recovery/rescue mode
2. Mount file system
3. Reset root password
4. Restart in normal mode

### Method 3: Provider Support
**Contact Evolution Host:**
- Request password reset
- Ask for SSH access assistance
- Verify account status and permissions
- Request alternative access methods

---

## 🔐 Security Considerations

### Possible Security Measures
1. **Fail2Ban**: May have blocked IP after multiple failed attempts
2. **Account Lockout**: Root account may be temporarily locked
3. **SSH Restrictions**: Provider may have restricted root access
4. **IP Whitelisting**: SSH access may be limited to specific IPs

### Check for IP Blocking
```bash
# Test from different IP/network if possible
ssh -o ConnectTimeout=10 root@103.195.103.198

# Check if connection is immediately rejected vs. password failure
```

---

## 📋 Immediate Action Plan

### Priority 1: VPS Provider Contact
**Contact Evolution Host Support:**
- Explain SSH access issue
- Request current root password
- Ask about any recent security changes
- Request web-based console access

### Priority 2: Alternative Access
**While waiting for provider response:**
- Try SSH from different IP address
- Test different user accounts
- Check for any provider-specific access methods

### Priority 3: Deployment Preparation
**Prepare for when access is restored:**
- Have deployment scripts ready
- Prepare SSH key for future use
- Document working access method

---

## 🛠️ Quick Fixes to Try

### Fix 1: Different SSH Client
```bash
# Try with different SSH options
ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no root@103.195.103.198

# Try with different cipher
ssh -c aes128-ctr root@103.195.103.198

# Try with different key exchange
ssh -o KexAlgorithms=diffie-hellman-group14-sha256 root@103.195.103.198
```

### Fix 2: Network Troubleshooting
```bash
# Test basic connectivity
ping 103.195.103.198

# Test SSH port specifically
telnet 103.195.103.198 22

# Check for any network filtering
traceroute 103.195.103.198
```

### Fix 3: Password Variations
**Try common variations:**
- Check for extra spaces or special characters
- Try without special characters if copy/paste issues
- Verify keyboard layout (US vs. other layouts)

---

## 📞 Support Information

### VPS Provider Details
**Evolution Host**
- **Server IP**: 103.195.103.198
- **Domain**: connectassist.live
- **Service**: VPS Hosting
- **Support**: Contact through provider control panel

### Current System Status
- **Website**: ✅ https://connectassist.live (accessible)
- **SSL**: ✅ Valid certificate
- **Services**: ✅ RustDesk containers running
- **SSH**: ❌ Authentication failing

---

## 🎯 Success Criteria

SSH access will be considered restored when:
- ✅ Can authenticate with valid credentials
- ✅ Can execute commands as root or sudo user
- ✅ Can access `/opt/connectassist` directory
- ✅ Can run `git pull` to update code
- ✅ Can execute deployment scripts

---

## 📝 Next Steps After Access Restored

1. **Immediate Actions:**
   ```bash
   cd /opt/connectassist
   git pull origin main
   chmod +x manual-deploy.sh
   ./manual-deploy.sh
   ```

2. **Set Up SSH Key Authentication:**
   ```bash
   mkdir -p ~/.ssh
   echo "YOUR_PUBLIC_KEY" >> ~/.ssh/authorized_keys
   chmod 600 ~/.ssh/authorized_keys
   chmod 700 ~/.ssh
   ```

3. **Deploy Customer Portal Integration:**
   - Run deployment script
   - Test all endpoints
   - Verify complete functionality

---

*This troubleshooting guide will be updated as new information becomes available.*
