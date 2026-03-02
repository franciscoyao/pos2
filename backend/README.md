# POS System Backend

A comprehensive REST API backend for the POS system with real-time WebSocket support.

## Features

- 🔐 JWT Authentication
- 👥 User Management (Admin, Waiter, Kitchen, Cashier roles)
- 🍽️ Menu Management (Categories & Items)
- 📋 Order Management with real-time updates
- 🪑 Table Management
- 💰 Payment Processing
- 🔄 Table Split & Merge
- 📡 WebSocket for live order updates
- 🗄️ PostgreSQL Database

## Tech Stack

- Node.js + Express
- PostgreSQL
- JWT for authentication
- WebSocket (ws) for real-time updates
- bcryptjs for password hashing

## Setup

### Prerequisites

- Node.js 18+ 
- PostgreSQL 14+

### Installation

1. Install dependencies:
```bash
cd backend
npm install
```

2. Create PostgreSQL database:
```bash
createdb pos_system
```

3. Configure environment:
```bash
cp .env.example .env
```

Edit `.env` with your settings:
```
PORT=3000
DATABASE_URL=postgresql://postgres:password@localhost:5432/pos_system
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
NODE_ENV=development
```

4. Run migrations:
```bash
npm run migrate
```

5. Start server:
```bash
# Development
npm run dev

# Production
npm start
```

## API Endpoints

### Authentication
- `POST /api/auth/login` - Login
- `GET /api/auth/me` - Get current user
- `POST /api/auth/logout` - Logout

### Users (Admin only)
- `GET /api/users` - List all users
- `POST /api/users` - Create user
- `PUT /api/users/:id` - Update user
- `DELETE /api/users/:id` - Delete user

### Menu
- `GET /api/menu/categories` - List categories
- `POST /api/menu/categories` - Create category (Admin)
- `PUT /api/menu/categories/:id` - Update category (Admin)
- `GET /api/menu/items` - List menu items
- `POST /api/menu/items` - Create menu item (Admin)
- `PUT /api/menu/items/:id` - Update menu item (Admin)
- `DELETE /api/menu/items/:id` - Delete menu item (Admin)

### Orders
- `GET /api/orders` - List orders (with filters)
- `GET /api/orders/active` - Get active orders
- `GET /api/orders/:id` - Get order details
- `POST /api/orders` - Create order
- `PATCH /api/orders/:id/status` - Update order status
- `PATCH /api/orders/items/:id/status` - Update order item status
- `POST /api/orders/:id/pay` - Pay for order
- `POST /api/orders/split` - Split table
- `POST /api/orders/merge` - Merge tables

### Tables
- `GET /api/tables` - List all tables
- `GET /api/tables/:table_number/status` - Get table status
- `POST /api/tables` - Create table
- `PUT /api/tables/:id` - Update table
- `DELETE /api/tables/:id` - Delete table

### WebSocket
- `ws://localhost:3000/ws` - Real-time order updates

## WebSocket Events

The server broadcasts these events:
- `order_created` - New order created
- `order_updated` - Order status changed
- `item_updated` - Order item status changed
- `order_paid` - Order paid
- `table_split` - Table split operation
- `tables_merged` - Tables merged

## Default Credentials

After migration, use these credentials:
- Email: `admin@pos.com`
- Password: `admin123`

**⚠️ Change these immediately in production!**

## Database Schema

- `users` - System users with roles
- `categories` - Menu categories
- `menu_items` - Menu items
- `tables` - Restaurant tables
- `orders` - Customer orders
- `order_items` - Items in orders
- `payments` - Payment records

## Security

- Passwords hashed with bcrypt
- JWT tokens for authentication
- Role-based access control
- SQL injection protection via parameterized queries

## Development

Run with auto-reload:
```bash
npm run dev
```

## Production Deployment

1. Set `NODE_ENV=production`
2. Use strong `JWT_SECRET`
3. Enable SSL for PostgreSQL
4. Use environment variables for sensitive data
5. Set up reverse proxy (nginx/Apache)
6. Enable HTTPS
7. Configure CORS properly

## License

MIT
