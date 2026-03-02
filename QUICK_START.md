# Quick Start Guide - POS System

Get your POS system running in 5 minutes!

## Prerequisites

- Node.js 18+ installed
- PostgreSQL 14+ installed
- Flutter SDK installed

## Option 1: Docker (Easiest)

```bash
# Navigate to backend
cd backend

# Start everything with Docker
docker-compose up -d

# Create admin user
docker-compose exec backend npm run create-admin

# Backend is now running on http://localhost:3000
```

## Option 2: Manual Setup

### Step 1: Database Setup (2 minutes)

```bash
# Create database
createdb pos_system

# Or using psql
psql -U postgres
CREATE DATABASE pos_system;
\q
```

### Step 2: Backend Setup (2 minutes)

```bash
# Navigate to backend
cd backend

# Install dependencies
npm install

# Create environment file
cp .env.example .env

# Edit .env with your database password
# DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@localhost:5432/pos_system

# Run setup (migrations + create admin)
npm run setup

# Start server
npm run dev
```

You should see:
```
🚀 Server running on port 3000
📡 WebSocket available at ws://localhost:3000/ws
```

### Step 3: Frontend Setup (1 minute)

```bash
# In project root
flutter pub get

# Run the app
flutter run
```

## Login

Use these credentials:
- **Email:** admin@pos.com
- **Password:** admin123

## What's Next?

1. **Create Menu Items**
   - Go to Admin → Menu
   - Add categories (Appetizers, Main Course, Desserts, etc.)
   - Add menu items with prices

2. **Create Users**
   - Go to Admin → Users
   - Add waiters, kitchen staff, cashiers
   - Each gets their own login

3. **Set Up Tables**
   - Go to Admin → Tables
   - Add your restaurant tables (T1, T2, T3, etc.)

4. **Start Taking Orders**
   - Login as waiter
   - Select table
   - Add items
   - Send to kitchen

## Testing the System

### Test Backend API

```bash
# Health check
curl http://localhost:3000/health

# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@pos.com","password":"admin123"}'
```

### Test Real-time Updates

1. Open app on two devices/windows
2. Create order on device 1
3. See it appear instantly on device 2

## Common Issues

### Backend won't start
```bash
# Check if PostgreSQL is running
pg_isready

# Check if port 3000 is free
lsof -i :3000  # Mac/Linux
netstat -ano | findstr :3000  # Windows
```

### Frontend can't connect
1. Check backend is running: `curl http://localhost:3000/health`
2. Check `assets/config.json` has correct URL
3. Run `flutter clean && flutter pub get`

### Database errors
```bash
# Reset database
dropdb pos_system
createdb pos_system
cd backend
npm run setup
```

## Production Deployment

### Quick Deploy to Render.com

1. Push code to GitHub
2. Go to https://render.com
3. Create new Web Service
4. Connect your repository
5. Add PostgreSQL database
6. Set environment variables:
   - `JWT_SECRET`: random secure string
   - `NODE_ENV`: production
7. Deploy!

### Update Flutter Config

Edit `assets/config.json`:
```json
{
  "baseUrl": "https://your-app.onrender.com"
}
```

## Features Overview

✅ **Multi-user System**
- Admin, Waiter, Kitchen, Cashier roles
- Each user has own login

✅ **Real-time Updates**
- Orders appear instantly in kitchen
- Status updates sync across devices
- Multiple waiters work simultaneously

✅ **Table Management**
- Split bills between tables
- Merge tables
- Track table status

✅ **Order Management**
- Create orders
- Track status (pending → cooking → ready)
- Kitchen stations (hot, cold, bar)

✅ **Payment Processing**
- Multiple payment methods
- Partial payments
- Split bills

## Architecture

```
Flutter App (Frontend)
    ↕ REST API + WebSocket
Node.js Backend
    ↕
PostgreSQL Database
```

## API Endpoints

- `POST /api/auth/login` - Login
- `GET /api/menu/items` - Get menu
- `POST /api/orders` - Create order
- `GET /api/orders/active` - Active orders
- `PATCH /api/orders/:id/status` - Update status
- `POST /api/orders/:id/pay` - Process payment

Full API docs: `backend/API_DOCUMENTATION.md`

## Support

- Backend logs: Check terminal running `npm run dev`
- Frontend logs: Check Flutter console
- Database: `psql pos_system`

## Next Steps

1. ✅ System is running
2. 📝 Add your menu items
3. 👥 Create user accounts
4. 🪑 Set up tables
5. 🎉 Start taking orders!

## Tips

- Use Chrome DevTools to debug WebSocket
- Check Network tab for API calls
- Use Postman for API testing
- Monitor backend logs for errors

## Security Notes

⚠️ **Before Production:**
- Change admin password
- Use strong JWT_SECRET
- Enable HTTPS
- Configure CORS properly
- Set up database backups

---

**Need help?** Check the full documentation:
- `BACKEND_SETUP.md` - Detailed setup guide
- `backend/README.md` - Backend documentation
- `backend/API_DOCUMENTATION.md` - API reference
