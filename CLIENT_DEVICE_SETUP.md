# 📱 Client Device Setup Guide

## ✅ Server is Ready! Now Configure Your Client Devices

Your server is now accessible at: **http://192.168.1.162:3000**

---

## 🎯 Quick Setup for Each Device

### Step 1: Update Configuration File

On each client device (tablet, phone, other computer), edit this file:

**File:** `assets/config.json`

**Change from:**
```json
{
    "baseUrl": "http://localhost:3000"
}
```

**Change to:**
```json
{
    "baseUrl": "http://192.168.1.162:3000"
}
```

### Step 2: Rebuild the App

After changing the config file:

```bash
# For Windows
flutter run -d windows

# For Web
flutter run -d chrome

# For Android
flutter run -d <device-id>

# For iOS
flutter run -d <device-id>
```

### Step 3: Connect and Login

1. Make sure the device is on the **same WiFi network** as the server
2. Launch the app
3. Login with your credentials:
   - Admin: admin@pos.com / admin123
   - Waiter: waiter@pos.com / waiter123
   - Kitchen: kitchen@pos.com / kitchen123
   - Cashier: cashier@pos.com / cashier123

---

## 📋 Device Setup Examples

### Example 1: Waiter Tablet

**Purpose:** Take orders from customers

**Setup:**
1. Copy the Flutter project to the tablet
2. Edit `assets/config.json`:
```json
{
    "baseUrl": "http://192.168.1.162:3000"
}
```
3. Run: `flutter run -d <tablet-device-id>`
4. Login as: **waiter@pos.com**

**Usage:**
- Select tables
- Create orders
- Add menu items
- Submit to kitchen

---

### Example 2: Kitchen Display

**Purpose:** View and manage incoming orders

**Setup:**
1. Copy the Flutter project to kitchen computer/tablet
2. Edit `assets/config.json`:
```json
{
    "baseUrl": "http://192.168.1.162:3000"
}
```
3. Run: `flutter run -d windows` (or chrome)
4. Login as: **kitchen@pos.com**

**Usage:**
- View incoming orders
- Update order item status
- Mark items as prepared
- Notify when ready

---

### Example 3: Cashier Terminal

**Purpose:** Process payments and generate bills

**Setup:**
1. Copy the Flutter project to cashier computer
2. Edit `assets/config.json`:
```json
{
    "baseUrl": "http://192.168.1.162:3000"
}
```
3. Run: `flutter run -d windows`
4. Login as: **cashier@pos.com**

**Usage:**
- View completed orders
- Process payments
- Generate bills
- Handle transactions

---

## 🧪 Testing Client Connection

### Test 1: Network Connectivity

From the client device, test if you can reach the server:

```bash
ping 192.168.1.162
```

Should show successful ping responses.

### Test 2: Backend API Access

```bash
curl http://192.168.1.162:3000/api/auth/me
```

Should return:
```json
{"error":"Authentication required"}
```

This means the backend is accessible! ✅

### Test 3: Login Test

```bash
curl -X POST http://192.168.1.162:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@pos.com","password":"admin123"}'
```

Should return JSON with token and user information.

---

## 📱 Platform-Specific Instructions

### Windows Desktop

```bash
# Navigate to project
cd path/to/pos_system

# Edit config
notepad assets/config.json

# Run app
flutter run -d windows
```

### Web Browser

```bash
# Edit config
notepad assets/config.json

# Run in Chrome
flutter run -d chrome

# Or run in Edge
flutter run -d edge
```

### Android Device

```bash
# Connect device via USB or WiFi
# Enable USB debugging on device

# Check device is connected
flutter devices

# Edit config
nano assets/config.json

# Run on device
flutter run -d <device-id>
```

### iOS Device

```bash
# Connect device via USB
# Trust computer on device

# Check device is connected
flutter devices

# Edit config
nano assets/config.json

# Run on device
flutter run -d <device-id>
```

---

## 🔧 Troubleshooting

### Problem: Can't connect to server

**Check 1: Same WiFi Network**
```bash
# On client device, check IP
ipconfig  # Windows
ifconfig  # Mac/Linux

# Should be 192.168.1.x
```

**Check 2: Ping Server**
```bash
ping 192.168.1.162
```

**Check 3: Test Backend**
```bash
curl http://192.168.1.162:3000/api/auth/me
```

**Check 4: Verify Config File**
Make sure `assets/config.json` has the correct server IP.

### Problem: App shows connection error

**Solution 1: Rebuild the app**
```bash
flutter clean
flutter pub get
flutter run -d <device>
```

**Solution 2: Check server is running**
On server computer:
```bash
curl http://localhost:3000/api/auth/me
```

**Solution 3: Check firewall on client device**
Make sure client device firewall isn't blocking outgoing connections.

### Problem: Login fails

**Solution 1: Verify credentials**
- Admin: admin@pos.com / admin123
- Create other users in Admin Panel first

**Solution 2: Check backend logs**
Look at the terminal running the backend for error messages.

**Solution 3: Test API directly**
```bash
curl -X POST http://192.168.1.162:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@pos.com","password":"admin123"}'
```

---

## 📊 Multi-Device Setup Checklist

### Server Computer (192.168.1.162)
- [x] Backend running on port 3000
- [x] Database connected
- [x] Firewall rule enabled
- [x] Admin user created

### Client Device 1 (Waiter Tablet)
- [ ] Flutter project copied
- [ ] config.json updated
- [ ] App built and running
- [ ] Waiter user created
- [ ] Connected to same WiFi
- [ ] Successfully logged in

### Client Device 2 (Kitchen Display)
- [ ] Flutter project copied
- [ ] config.json updated
- [ ] App built and running
- [ ] Kitchen user created
- [ ] Connected to same WiFi
- [ ] Successfully logged in

### Client Device 3 (Cashier Terminal)
- [ ] Flutter project copied
- [ ] config.json updated
- [ ] App built and running
- [ ] Cashier user created
- [ ] Connected to same WiFi
- [ ] Successfully logged in

---

## 🎯 Quick Reference

### Server Information
- **IP:** 192.168.1.162
- **URL:** http://192.168.1.162:3000
- **API:** http://192.168.1.162:3000/api
- **WebSocket:** ws://192.168.1.162:3000/ws

### Config File Location
```
assets/config.json
```

### Config Content
```json
{
    "baseUrl": "http://192.168.1.162:3000"
}
```

### Test Commands
```bash
# Ping server
ping 192.168.1.162

# Test API
curl http://192.168.1.162:3000/api/auth/me

# Test login
curl -X POST http://192.168.1.162:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@pos.com","password":"admin123"}'
```

---

## 🌐 Network Requirements

### All Devices Must:
1. ✅ Be on same WiFi network
2. ✅ Have IP in 192.168.1.x range
3. ✅ Be able to ping 192.168.1.162
4. ✅ Have config.json pointing to server IP

### WiFi Network:
- Same SSID for all devices
- No guest network isolation
- No AP isolation enabled

---

## 🎉 Success!

Once you complete these steps for each device:

1. ✅ All devices can connect to server
2. ✅ Users can login from any device
3. ✅ Real-time updates work across devices
4. ✅ Orders sync between waiter, kitchen, and cashier
5. ✅ Your multi-device POS system is operational!

---

## 📞 Need Help?

### Check Server Status
On server computer:
```bash
curl http://localhost:3000/api/auth/me
```

### Check Client Connection
On client device:
```bash
curl http://192.168.1.162:3000/api/auth/me
```

### View Backend Logs
Check the terminal where backend is running for error messages.

---

**Your server is ready! Now set up your client devices and start using your multi-device POS system!** 🚀
