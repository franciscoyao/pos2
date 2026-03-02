# 🌐 Network Access Guide - Use Your Computer as a POS Server

## ✅ Your Server is Running!

Your computer is now a fully functional POS server accessible on your network.

### Server Details
- **Local URL:** http://localhost:3000
- **Your IP Address:** 192.168.1.162
- **Network URL:** http://192.168.1.162:3000

---

## 📱 Accessing from Other Devices

### Step 1: Configure Windows Firewall

Run this command in PowerShell **as Administrator**:

```powershell
New-NetFirewallRule -DisplayName "POS System Server" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow
```

Or manually:
1. Open Windows Defender Firewall
2. Click "Advanced settings"
3. Click "Inbound Rules" → "New Rule"
4. Select "Port" → Next
5. Select "TCP" and enter "3000" → Next
6. Select "Allow the connection" → Next
7. Check all profiles → Next
8. Name it "POS System Server" → Finish

### Step 2: Update Client Device Configuration

On devices that will connect to this server (tablets, phones, other computers):

**For Flutter Apps:**
Edit `assets/config.json`:
```json
{
    "baseUrl": "http://192.168.1.162:3000"
}
```

**For Web Browsers:**
Simply navigate to: `http://192.168.1.162:3000`

### Step 3: Test Connection

From another device on the same network:
```bash
# Test if server is reachable
curl http://192.168.1.162:3000/api/auth/me

# Or open in browser
http://192.168.1.162:3000
```

---

## 🖥️ Server Computer Setup

### Keep Server Running 24/7

**Option 1: Prevent Sleep**
1. Settings → System → Power & Sleep
2. Set "When plugged in, PC goes to sleep after" to "Never"

**Option 2: Create Startup Service**

Create a Windows Task Scheduler task:
1. Open Task Scheduler
2. Create Basic Task → Name: "POS Backend"
3. Trigger: "When the computer starts"
4. Action: "Start a program"
5. Program: `C:\Program Files\nodejs\node.exe`
6. Arguments: `C:\Pos 2\backend\src\server.js`
7. Start in: `C:\Pos 2\backend`

---

## 📊 Network Architecture

```
┌─────────────────────────────────────────────┐
│         Your Computer (Server)              │
│         IP: 192.168.1.162                   │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │  PostgreSQL Database (Port 5432)    │   │
│  └─────────────────────────────────────┘   │
│                    ↕                        │
│  ┌─────────────────────────────────────┐   │
│  │  Node.js Backend (Port 3000)        │   │
│  │  - REST API                         │   │
│  │  - WebSocket Server                 │   │
│  └─────────────────────────────────────┘   │
└──────────────────┬──────────────────────────┘
                   │
        Local Network (WiFi/Ethernet)
                   │
    ┌──────────────┼──────────────┐
    │              │              │
    ▼              ▼              ▼
┌─────────┐  ┌─────────┐  ┌─────────┐
│ Tablet  │  │  Phone  │  │   PC    │
│ (Waiter)│  │(Kitchen)│  │(Cashier)│
└─────────┘  └─────────┘  └─────────┘
```

---

## 🔒 Security Considerations

### For Local Network (Current Setup)
✅ Secure for home/office network
✅ All devices must be on same WiFi/network
✅ Not accessible from internet

### For Internet Access (Advanced)
⚠️ **NOT RECOMMENDED without proper security setup**

If you need internet access, you'll need:
- HTTPS/SSL certificates
- Stronger authentication
- Rate limiting
- DDoS protection
- Reverse proxy (nginx)
- VPN or secure tunnel

See `DEPLOYMENT_GUIDE.md` for production setup.

---

## 📱 Client Device Setup Examples

### Windows Desktop Client
```json
// assets/config.json
{
    "baseUrl": "http://192.168.1.162:3000"
}
```

Then run:
```powershell
flutter run -d windows
```

### Web Browser Client
Just navigate to:
```
http://192.168.1.162:3000
```

### Android/iOS Client
1. Update `assets/config.json` with server IP
2. Rebuild the app
3. Install on device
4. Make sure device is on same WiFi network

---

## 🧪 Testing Network Access

### From Server Computer (localhost)
```powershell
curl http://localhost:3000/api/auth/me
```

### From Another Device on Network
```bash
curl http://192.168.1.162:3000/api/auth/me
```

Both should return:
```json
{"error":"Authentication required"}
```

This means the server is accessible!

---

## 🔧 Troubleshooting

### Can't Connect from Other Devices

**1. Check Firewall**
```powershell
Get-NetFirewallRule -DisplayName "POS System Server"
```

**2. Verify Server is Running**
```powershell
curl http://localhost:3000/api/auth/me
```

**3. Check IP Address**
```powershell
ipconfig | Select-String "IPv4"
```

**4. Test Port is Open**
From another device:
```bash
telnet 192.168.1.162 3000
```

**5. Verify Same Network**
- Server and client must be on same WiFi/network
- Check both devices have 192.168.1.x IP addresses

### Server Stops When Computer Sleeps
- Disable sleep mode (see "Keep Server Running 24/7" above)
- Or use Task Scheduler to restart on wake

### IP Address Changes
- Your router may assign different IPs
- Set a static IP in router settings
- Or use your computer's hostname instead of IP

---

## 📊 Monitoring Server

### Check Server Status
```powershell
# Test if backend is responding
curl http://localhost:3000/api/auth/me

# Check if port 3000 is listening
netstat -ano | findstr :3000

# View backend logs
# (Check the terminal where backend is running)
```

### View Connected Clients
WebSocket connections will show in backend logs when clients connect.

---

## 🚀 Production Deployment

For a production environment with internet access, consider:

1. **Cloud Hosting**
   - AWS, Azure, Google Cloud
   - Heroku, DigitalOcean, Render
   - See `DEPLOYMENT_GUIDE.md`

2. **VPS (Virtual Private Server)**
   - More control
   - Fixed IP address
   - Better uptime

3. **Local Server with VPN**
   - Keep server at your location
   - Access via VPN (WireGuard, OpenVPN)
   - More secure than port forwarding

---

## 📞 Quick Reference

### Server URLs
- **Local:** http://localhost:3000
- **Network:** http://192.168.1.162:3000
- **API:** http://192.168.1.162:3000/api
- **WebSocket:** ws://192.168.1.162:3000/ws

### Admin Credentials
- **Email:** admin@pos.com
- **Password:** admin123

### Firewall Command
```powershell
New-NetFirewallRule -DisplayName "POS System Server" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow
```

### Restart Backend
```powershell
cd "C:\Pos 2\backend"
npm start
```

---

## ✅ Current Status

- ✅ Backend running on port 3000
- ✅ Database connected (PostgreSQL 18)
- ✅ Admin user created
- ✅ Ready for network access
- ⚠️ Firewall rule may need to be added

**Your computer is now a POS server!** 🎉

Add the firewall rule and other devices on your network can connect!
