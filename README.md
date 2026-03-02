# 🍽️ POS System - Restaurant Point of Sale

A complete, full-stack Point of Sale system built with Flutter and Node.js, designed for restaurants with multi-device support and real-time order synchronization.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)
![Node.js](https://img.shields.io/badge/Node.js-18+-green.svg)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14+-blue.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

## ✨ Features

### 🎯 Core Functionality
- **Multi-Role Support**: Admin, Waiter, Kitchen, Cashier interfaces
- **Real-Time Updates**: WebSocket integration for live order synchronization
- **Multi-Device Ready**: Same codebase works on all devices
- **Network Deployment**: Server-client architecture for restaurant-wide deployment

### 📱 User Interfaces
- **Admin Panel**: Complete system management, reports, user management
- **Waiter Interface**: Table management, order creation, customer service
- **Kitchen Display**: Order queue, status updates, preparation tracking
- **Cashier Terminal**: Payment processing, bill generation

### 🔧 Technical Features
- JWT Authentication
- Role-based access control
- PostgreSQL database
- RESTful API
- WebSocket for real-time updates
- Responsive design
- Cross-platform (Windows, Web, Mobile)

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.0+
- Node.js 18+
- PostgreSQL 14+
- Git

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/pos-system.git
cd pos-system
```

2. **Backend Setup**
```bash
cd backend
npm install
cp .env.example .env
# Edit .env with your database credentials
npm run migrate
npm run create-admin
npm start
```

3. **Frontend Setup**
```bash
cd ..
flutter pub get
flutter run -d windows  # or chrome, or your device
```

4. **Login**
- Email: `admin@pos.com`
- Password: `admin123`

## 📖 Documentation

- **[Getting Started](GETTING_STARTED.md)** - Complete setup guide
- **[Deployment Guide](DEPLOYMENT_GUIDE.md)** - Production deployment instructions
- **[Network Setup](NETWORK_ACCESS_GUIDE.md)** - Multi-device configuration
- **[API Documentation](backend/API_DOCUMENTATION.md)** - Backend API reference
- **[Client Setup](CLIENT_DEVICE_SETUP.md)** - Configure client devices

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│         Flutter Frontend                │
│  - Admin, Waiter, Kitchen, Cashier UI  │
│  - Real-time WebSocket connection      │
└──────────────┬──────────────────────────┘
               │ HTTP/WebSocket
               ▼
┌─────────────────────────────────────────┐
│      Node.js Backend (Express)          │
│  - REST API                             │
│  - JWT Authentication                   │
│  - WebSocket Server                     │
└──────────────┬──────────────────────────┘
               │ SQL
               ▼
┌─────────────────────────────────────────┐
│      PostgreSQL Database                │
│  - Users, Menu, Orders, Tables          │
└─────────────────────────────────────────┘
```

## 🔐 Default Credentials

**Admin Account:**
- Email: `admin@pos.com`
- Password: `admin123`

⚠️ **Change these immediately in production!**

## 📊 API Endpoints

### Authentication
- `POST /api/auth/login` - User login
- `GET /api/auth/me` - Get current user

### Menu Management
- `GET /api/menu/categories` - List categories
- `GET /api/menu/items` - List menu items
- `POST /api/menu/items` - Create menu item (Admin)

### Orders
- `GET /api/orders` - List orders
- `POST /api/orders` - Create order
- `PATCH /api/orders/:id/status` - Update order status
- `POST /api/orders/:id/pay` - Process payment

### Reports
- `GET /api/reports/stats` - Sales statistics
- `GET /api/reports/sales-by-day` - Daily sales
- `GET /api/reports/top-selling-items` - Popular items

See [API Documentation](backend/API_DOCUMENTATION.md) for complete reference.

## 🌐 Multi-Device Deployment

### Server Setup
1. Run backend on main computer
2. Enable Windows Firewall (port 3000)
3. Note your server IP address

### Client Devices
1. Copy Flutter project to device
2. Edit `assets/config.json`:
```json
{
    "baseUrl": "http://YOUR_SERVER_IP:3000"
}
```
3. Run the app
4. Login with appropriate role

See [Network Access Guide](NETWORK_ACCESS_GUIDE.md) for details.

## 🛠️ Development

### Project Structure
```
pos-system/
├── lib/                    # Flutter frontend
│   ├── features/          # Feature modules
│   ├── data/              # Repositories & services
│   └── core/              # Shared utilities
├── backend/               # Node.js backend
│   ├── src/
│   │   ├── routes/       # API endpoints
│   │   ├── database/     # Database schema
│   │   └── middleware/   # Auth middleware
│   └── scripts/          # Utility scripts
└── assets/               # App assets
```

### Running Tests
```bash
# Backend tests
cd backend
npm test

# Frontend tests
flutter test
```

### Building for Production
```bash
# Flutter Web
flutter build web

# Flutter Windows
flutter build windows

# Flutter Android
flutter build apk

# Flutter iOS
flutter build ios
```

## 🔧 Configuration

### Backend (.env)
```env
PORT=3000
DATABASE_URL=postgresql://user:password@localhost:5432/pos_system
JWT_SECRET=your-secret-key
NODE_ENV=production
```

### Frontend (assets/config.json)
```json
{
    "baseUrl": "http://localhost:3000"
}
```

## 📝 Scripts

### Backend
- `npm start` - Start server
- `npm run dev` - Development mode with auto-reload
- `npm run migrate` - Run database migrations
- `npm run create-admin` - Create admin user

### Utility Scripts
- `start-backend.bat` - Quick backend start
- `start-flutter.bat` - Quick Flutter start
- `enable-network-access.ps1` - Configure firewall
- `start-pos-system.ps1` - Complete system startup

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Node.js and Express communities
- PostgreSQL team

## 📞 Support

For issues and questions:
- Open an issue on GitHub
- Check the [documentation](GETTING_STARTED.md)
- Review [common issues](DEPLOYMENT_GUIDE.md#troubleshooting)

## 🗺️ Roadmap

- [ ] Mobile app optimization
- [ ] Offline mode support
- [ ] Advanced reporting and analytics
- [ ] Multi-location support
- [ ] Inventory management
- [ ] Customer loyalty program
- [ ] Online ordering integration

## 📸 Screenshots

### Admin Dashboard
![Admin Dashboard](screenshots/admin-dashboard.png)

### Waiter Interface
![Waiter Interface](screenshots/waiter-interface.png)

### Kitchen Display
![Kitchen Display](screenshots/kitchen-display.png)

---

**Built with ❤️ for restaurants**
