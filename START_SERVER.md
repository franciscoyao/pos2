# Start POS System Server

## Quick Start (3 Steps)

### Step 1: Start Docker Desktop
Run this command:
```powershell
.\start-docker.ps1
```

Wait 30-60 seconds for Docker Desktop to fully start. You'll see the Docker icon in your system tray.

### Step 2: Start the Backend Server
Once Docker is running, execute:
```powershell
.\start-pos-system.ps1
```

This will:
- Start PostgreSQL database
- Install dependencies
- Set up database schema
- Start the backend server on http://localhost:3000

### Step 3: Start the Flutter App
Open a new terminal and run:
```powershell
flutter run -d windows
```

Or for web browser:
```powershell
flutter run -d chrome
```

---

## Default Login Credentials

- **Email:** admin@pos.com
- **Password:** admin123

---

## Manual Steps (If Scripts Don't Work)

### 1. Start Docker Desktop
- Open Docker Desktop application manually
- Wait for it to fully start

### 2. Start Database
```powershell
cd backend
docker-compose up -d postgres
```

### 3. Install Dependencies
```powershell
npm install
```

### 4. Setup Database
```powershell
npm run migrate
```

### 5. Start Backend
```powershell
npm start
```

### 6. Start Flutter App (New Terminal)
```powershell
cd ..
flutter run -d windows
```

---

## Troubleshooting

### Docker Desktop Not Starting
- Make sure Docker Desktop is installed
- Check if virtualization is enabled in BIOS
- Restart your computer

### Port 3000 Already in Use
```powershell
# Find process using port 3000
netstat -ano | findstr :3000

# Kill the process (replace PID with actual process ID)
taskkill /PID <PID> /F
```

### Database Connection Error
- Make sure PostgreSQL container is running: `docker ps`
- Check logs: `docker-compose logs postgres`
- Restart database: `docker-compose restart postgres`

---

## Stopping the System

### Stop Backend Server
Press `Ctrl+C` in the terminal running the backend

### Stop Database
```powershell
cd backend
docker-compose down
```

### Stop Flutter App
Press `q` in the terminal running Flutter or close the app window

---

## System URLs

- **Backend API:** http://localhost:3000
- **WebSocket:** ws://localhost:3000/ws
- **API Documentation:** See `backend/API_DOCUMENTATION.md`

---

## Next Steps

1. Login with admin credentials
2. Create menu categories and items
3. Create tables
4. Create additional users (waiters, kitchen staff, cashiers)
5. Start taking orders!

For detailed API documentation, see: `backend/API_DOCUMENTATION.md`
