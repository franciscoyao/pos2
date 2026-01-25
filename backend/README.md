# 🚀 **ULTIMATE POS SYSTEM BACKEND**

> **The most advanced, feature-rich Point of Sale backend system built with cutting-edge technology**

[![Node.js](https://img.shields.io/badge/Node.js-18+-green.svg)](https://nodejs.org/)
[![NestJS](https://img.shields.io/badge/NestJS-10+-red.svg)](https://nestjs.com/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5+-blue.svg)](https://www.typescriptlang.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-blue.svg)](https://www.postgresql.org/)
[![Redis](https://img.shields.io/badge/Redis-7+-red.svg)](https://redis.io/)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com/)

## 🌟 **ENTERPRISE-GRADE FEATURES**

### 🔥 **Core Capabilities**
- **🔄 Real-time Multi-Device Synchronization** - Instant updates across all devices
- **⚡ Advanced Conflict Resolution** - Smart handling of concurrent updates
- **📱 Multi-Device Support** - Tablets, phones, desktops, kiosks
- **🌐 Offline-First Architecture** - Works seamlessly without internet
- **🔐 Enterprise Security** - JWT, RBAC, device authentication
- **📊 Advanced Analytics** - Real-time metrics and business intelligence
- **🖨️ Smart Printer Management** - Multi-station printing with failover
- **💳 Advanced Payment Processing** - Multiple methods, split bills, tips
- **🎯 Role-Based Access Control** - Granular permissions system
- **📈 Performance Monitoring** - Prometheus metrics and health checks

### 🏗️ **Advanced Architecture**
- **Microservices-Ready** - Modular, scalable design
- **Event-Driven** - CQRS pattern with event sourcing
- **Queue-Based Processing** - Background jobs with Bull
- **Advanced Caching** - Multi-layer Redis caching
- **WebSocket Real-time** - Room-based broadcasting
- **API Versioning** - Backward compatibility
- **Comprehensive Logging** - Winston with structured logging
- **Health Monitoring** - Terminus health checks
- **Rate Limiting** - DDoS protection
- **Data Validation** - Comprehensive input validation

### 💼 **Business Features**
- **📋 Advanced Order Management** - Complex workflows and status tracking
- **🍽️ Dynamic Menu System** - Categories, modifiers, allergens
- **🪑 Smart Table Management** - Visual layouts, capacity tracking
- **👥 Staff Management** - Performance tracking, shift management
- **💰 Financial Reporting** - Sales analytics, tax reporting
- **🔧 System Configuration** - Dynamic settings management
- **📱 Kiosk Support** - Self-service ordering
- **🏪 Multi-Location Ready** - Franchise and chain support

## 🚀 **QUICK START**

### Prerequisites
- Node.js 18+
- PostgreSQL 15+
- Redis 7+
- Docker (optional)

### 1. **Installation**
```bash
# Clone the repository
git clone <repository-url>
cd backend

# Install dependencies
npm install

# Copy environment configuration
cp .env.example .env
```

### 2. **Database Setup**
```bash
# Start PostgreSQL and Redis (Docker)
docker-compose up -d postgres redis

# Or configure your existing databases in .env
```

### 3. **Configuration**
```bash
# Edit .env file with your settings
nano .env

# Key configurations:
# - DATABASE_URL
# - REDIS_HOST
# - JWT_SECRET
# - CORS_ORIGINS
```

### 4. **Start Development**
```bash
# Development mode with hot reload
npm run start:dev

# Production mode
npm run build
npm run start:prod
```

### 5. **Access the System**
- **API**: http://localhost:3000/api
- **Documentation**: http://localhost:3000/docs
- **Health Check**: http://localhost:3000/health
- **Metrics**: http://localhost:3000/metrics
- **WebSocket**: ws://localhost:3000/sync

## 📡 **API ENDPOINTS**

### 🔐 **Authentication**
```http
POST /api/auth/login          # User login (PIN or password)
POST /api/auth/refresh        # Refresh access token
POST /api/auth/logout         # Logout user
POST /api/auth/register       # Register new user
GET  /api/auth/profile        # Get user profile
```

### 📋 **Orders**
```http
GET    /api/orders            # Get all orders
GET    /api/orders/active     # Get active orders
GET    /api/orders/sync       # Get orders for sync
POST   /api/orders            # Create new order
PUT    /api/orders/:id        # Update order
DELETE /api/orders/:id        # Delete order
PUT    /api/orders/:id/status # Update order status
POST   /api/orders/:id/payments # Add payment
```

### 🪑 **Tables**
```http
GET    /api/tables            # Get all tables
GET    /api/tables/available  # Get available tables
POST   /api/tables            # Create table
PUT    /api/tables/:id        # Update table
DELETE /api/tables/:id        # Delete table
PUT    /api/tables/:id/status # Update table status
```

### 🍽️ **Menu Management**
```http
GET    /api/menu-items        # Get menu items
GET    /api/categories        # Get categories
POST   /api/menu-items        # Create menu item
PUT    /api/menu-items/:id    # Update menu item
DELETE /api/menu-items/:id    # Delete menu item
```

### 🔄 **Synchronization**
```http
POST /sync/register-device    # Register device
POST /sync/process           # Process sync changes
GET  /sync/devices           # Get connected devices
POST /sync/heartbeat         # Device heartbeat
```

### 📊 **Analytics**
```http
GET /api/analytics/sales     # Sales metrics
GET /api/analytics/performance # Performance metrics
GET /api/analytics/popularity  # Popular items
GET /api/analytics/staff     # Staff performance
```

## 🔄 **REAL-TIME SYNCHRONIZATION**

### **WebSocket Events**
```javascript
// Device registration
socket.emit('device:register', {
  deviceId: 'tablet-001',
  deviceType: 'tablet',
  capabilities: {
    canTakeOrders: true,
    canManageKitchen: false
  }
});

// Listen for updates
socket.on('order:update', (order) => {
  console.log('Order updated:', order);
});

socket.on('table:update', (table) => {
  console.log('Table updated:', table);
});
```

### **Sync Protocol**
```javascript
// Sync changes
const syncRequest = {
  deviceId: 'tablet-001',
  lastSyncVersion: 150,
  changes: [
    {
      entityType: 'order',
      entityId: 123,
      action: 'update',
      data: { status: 'ready' },
      version: 151,
      timestamp: new Date()
    }
  ]
};

const response = await fetch('/sync/process', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(syncRequest)
});
```

## 🏗️ **ARCHITECTURE OVERVIEW**

### **System Components**
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │    │   Tablet App    │    │   Kiosk App     │
│   (Waiter)      │    │   (Kitchen)     │    │   (Customer)    │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────▼─────────────┐
                    │     Load Balancer        │
                    │      (Nginx)             │
                    └─────────────┬─────────────┘
                                 │
                    ┌─────────────▼─────────────┐
                    │    NestJS Backend        │
                    │   (Multiple Instances)   │
                    └─────────────┬─────────────┘
                                 │
          ┌──────────────────────┼──────────────────────┐
          │                      │                      │
┌─────────▼───────┐    ┌─────────▼───────┐    ┌─────────▼───────┐
│   PostgreSQL    │    │     Redis       │    │   File Storage  │
│   (Primary DB)  │    │   (Cache/Queue) │    │   (Uploads)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### **Data Flow**
```
Device → WebSocket → Event Gateway → Service Layer → Repository → Database
  ↓                                      ↓
Cache ← Queue System ← Event Emitter ← Sync Service
```

## 🔧 **CONFIGURATION**

### **Environment Variables**
```bash
# Core Configuration
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://user:pass@host:5432/db
REDIS_HOST=localhost
JWT_SECRET=your-secret-key

# Feature Flags
ENABLE_KIOSK=true
ENABLE_ANALYTICS=true
ENABLE_NOTIFICATIONS=true
ENABLE_OFFLINE_MODE=true

# Performance
CACHE_TTL=300
QUEUE_CONCURRENCY=5
RATE_LIMIT_MAX=100

# Security
BCRYPT_ROUNDS=12
MAX_LOGIN_ATTEMPTS=5
SESSION_TIMEOUT=480
```

### **Business Settings**
```json
{
  "tax.rate": 0.08,
  "service.rate": 0.15,
  "currency.symbol": "$",
  "order.delay_threshold": 15,
  "kiosk.timeout": 300,
  "printer.auto_print": true
}
```

## 📊 **MONITORING & ANALYTICS**

### **Health Checks**
```bash
# Application health
GET /health

# Database connectivity
GET /health/database

# Redis connectivity  
GET /health/redis

# Memory usage
GET /health/memory
```

### **Prometheus Metrics**
```bash
# Order metrics
pos_orders_total{status="completed",type="dine-in"}
pos_order_duration_seconds{status="completed"}

# Sales metrics
pos_sales_total{period="daily"}
pos_payment_methods_total{method="card"}

# Performance metrics
pos_kitchen_time_seconds{station="kitchen"}
pos_sync_operations_total{operation="create"}
```

### **Business Intelligence**
- **Real-time Dashboard** - Live sales and performance metrics
- **Sales Analytics** - Revenue trends, popular items, peak hours
- **Staff Performance** - Order processing times, efficiency metrics
- **Kitchen Analytics** - Preparation times, delayed orders
- **Customer Insights** - Order patterns, preferences

## 🖨️ **PRINTER MANAGEMENT**

### **Supported Printers**
- **Thermal Printers** - ESC/POS compatible
- **Network Printers** - IP-based printing
- **Bluetooth Printers** - Mobile device pairing
- **USB Printers** - Direct connection

### **Print Stations**
```javascript
// Kitchen printer configuration
{
  "role": "kitchen",
  "stations": ["kitchen"],
  "filterSettings": {
    "categories": [1, 2, 3], // Food categories
    "menuTypes": ["dine-in", "takeaway"]
  },
  "printSettings": {
    "printTime": true,
    "printTable": true,
    "printSpecialInstructions": true
  }
}

// Receipt printer configuration
{
  "role": "receipt",
  "printSettings": {
    "printLogo": true,
    "printHeader": true,
    "printFooter": true,
    "autoCut": true
  }
}
```

## 💳 **PAYMENT PROCESSING**

### **Supported Methods**
- **Cash** - With change calculation
- **Credit/Debit Cards** - Stripe integration
- **Digital Wallets** - Apple Pay, Google Pay
- **Gift Cards** - Store credit system
- **Split Payments** - Multiple methods per order

### **Split Bill Options**
```javascript
// Split by item
{
  "splitType": "item",
  "splitDetails": {
    "itemIds": [1, 2, 3],
    "customerName": "John Doe"
  }
}

// Split equally
{
  "splitType": "equal",
  "splitDetails": {
    "splitCount": 4,
    "splitIndex": 1
  }
}

// Split by amount
{
  "splitType": "amount",
  "splitDetails": {
    "splitAmount": 25.50
  }
}
```

## 🔐 **SECURITY FEATURES**

### **Authentication & Authorization**
- **JWT Tokens** - Secure API access
- **Refresh Tokens** - Long-term sessions
- **Device Authentication** - Device-specific access
- **Role-Based Access** - Granular permissions
- **PIN Authentication** - Quick staff access

### **Security Measures**
- **Rate Limiting** - DDoS protection
- **Input Validation** - SQL injection prevention
- **CORS Configuration** - Cross-origin security
- **Helmet Security** - HTTP security headers
- **Audit Logging** - Complete activity trail

### **Data Protection**
- **Encryption at Rest** - Database encryption
- **Encryption in Transit** - HTTPS/WSS
- **PCI Compliance** - Payment data security
- **GDPR Compliance** - Data privacy protection

## 🚀 **DEPLOYMENT**

### **Docker Deployment**
```bash
# Build and run with Docker Compose
docker-compose up -d

# Scale the application
docker-compose up -d --scale backend=3

# Production deployment
docker-compose -f docker-compose.prod.yml up -d
```

### **Kubernetes Deployment**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pos-backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: pos-backend
  template:
    metadata:
      labels:
        app: pos-backend
    spec:
      containers:
      - name: backend
        image: pos-backend:latest
        ports:
        - containerPort: 3000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: pos-secrets
              key: database-url
```

### **Cloud Deployment**
- **AWS** - ECS, RDS, ElastiCache
- **Google Cloud** - Cloud Run, Cloud SQL, Memorystore
- **Azure** - Container Instances, PostgreSQL, Redis Cache
- **Heroku** - Easy deployment with add-ons

## 📈 **PERFORMANCE OPTIMIZATION**

### **Caching Strategy**
```javascript
// Multi-layer caching
L1: Application Cache (Memory)
L2: Redis Cache (Distributed)
L3: Database Query Cache
L4: CDN Cache (Static Assets)

// Cache invalidation
- Time-based expiration
- Event-based invalidation
- Manual cache clearing
- Cache warming strategies
```

### **Database Optimization**
- **Connection Pooling** - Efficient connection management
- **Query Optimization** - Indexed queries and joins
- **Read Replicas** - Distributed read operations
- **Partitioning** - Large table optimization

### **Performance Metrics**
- **Response Times** - API endpoint performance
- **Throughput** - Requests per second
- **Error Rates** - System reliability
- **Resource Usage** - CPU, memory, disk

## 🧪 **TESTING**

### **Test Coverage**
```bash
# Unit tests
npm run test

# Integration tests
npm run test:e2e

# Test coverage
npm run test:cov

# Load testing
npm run test:load
```

### **Test Types**
- **Unit Tests** - Individual component testing
- **Integration Tests** - API endpoint testing
- **E2E Tests** - Complete workflow testing
- **Load Tests** - Performance under stress
- **Security Tests** - Vulnerability scanning

## 🔧 **MAINTENANCE**

### **Database Maintenance**
```bash
# Backup database
npm run db:backup

# Restore database
npm run db:restore

# Run migrations
npm run migration:run

# Seed data
npm run db:seed
```

### **System Maintenance**
- **Log Rotation** - Automated log management
- **Cache Cleanup** - Remove expired entries
- **Database Optimization** - Index maintenance
- **Security Updates** - Regular dependency updates

## 🤝 **INTEGRATION GUIDES**

### **Flutter Integration**
```dart
// HTTP client setup
final dio = Dio();
dio.options.baseUrl = 'http://localhost:3000/api';
dio.options.headers['x-device-id'] = deviceId;

// WebSocket connection
final socket = io('ws://localhost:3000/sync');
socket.emit('device:register', {
  'deviceId': deviceId,
  'deviceType': 'tablet',
  'capabilities': {'canTakeOrders': true}
});
```

### **Third-party Integrations**
- **Payment Gateways** - Stripe, PayPal, Square
- **Accounting Software** - QuickBooks, Xero
- **Inventory Systems** - Custom API integration
- **Loyalty Programs** - Points and rewards systems

## 📚 **API DOCUMENTATION**

Complete API documentation is available at:
- **Interactive Docs**: http://localhost:3000/docs
- **OpenAPI Spec**: http://localhost:3000/docs-json
- **Postman Collection**: Available in `/docs` folder

## 🐛 **TROUBLESHOOTING**

### **Common Issues**
1. **Database Connection** - Check DATABASE_URL and network
2. **Redis Connection** - Verify Redis server status
3. **WebSocket Issues** - Check CORS and firewall settings
4. **Sync Conflicts** - Review conflict resolution settings
5. **Performance Issues** - Monitor metrics and logs

### **Debug Mode**
```bash
# Enable debug logging
DEBUG=* npm run start:dev

# Check system health
curl http://localhost:3000/health

# Monitor metrics
curl http://localhost:3000/metrics
```

## 📄 **LICENSE**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 **CONTRIBUTING**

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 **SUPPORT**

- **Documentation**: [API Docs](http://localhost:3000/docs)
- **Issues**: [GitHub Issues](https://github.com/your-repo/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-repo/discussions)
- **Email**: support@possystem.com

---

**Built with ❤️ for the future of Point of Sale systems**

*This backend powers the next generation of POS applications with enterprise-grade features, real-time synchronization, and unmatched performance.*