# POS System API Documentation

Base URL: `http://localhost:3000/api`

## Authentication

All endpoints except `/auth/login` require a JWT token in the Authorization header:
```
Authorization: Bearer <token>
```

---

## Auth Endpoints

### Login
```http
POST /auth/login
Content-Type: application/json

{
  "email": "admin@pos.com",
  "password": "admin123"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "uuid",
    "email": "admin@pos.com",
    "name": "Admin User",
    "role": "admin"
  }
}
```

### Get Current User
```http
GET /auth/me
Authorization: Bearer <token>
```

### Logout
```http
POST /auth/logout
Authorization: Bearer <token>
```

---

## User Management (Admin Only)

### List Users
```http
GET /users
Authorization: Bearer <token>
```

### Create User
```http
POST /users
Authorization: Bearer <token>
Content-Type: application/json

{
  "email": "waiter@pos.com",
  "password": "password123",
  "name": "John Doe",
  "role": "waiter"
}
```

**Roles:** `admin`, `waiter`, `kitchen`, `cashier`

### Update User
```http
PUT /users/:id
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "John Updated",
  "role": "waiter",
  "active": true,
  "password": "newpassword" // optional
}
```

### Delete User
```http
DELETE /users/:id
Authorization: Bearer <token>
```

---

## Menu Management

### List Categories
```http
GET /menu/categories
Authorization: Bearer <token>
```

### Create Category (Admin)
```http
POST /menu/categories
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Appetizers",
  "description": "Starters and small plates",
  "display_order": 1
}
```

### Update Category (Admin)
```http
PUT /menu/categories/:id
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Appetizers",
  "description": "Updated description",
  "display_order": 1,
  "active": true
}
```

### List Menu Items
```http
GET /menu/items
Authorization: Bearer <token>
```

### Create Menu Item (Admin)
```http
POST /menu/items
Authorization: Bearer <token>
Content-Type: application/json

{
  "category_id": "uuid",
  "name": "Caesar Salad",
  "description": "Fresh romaine with caesar dressing",
  "price": 12.99,
  "station": "cold",
  "image_url": "https://example.com/image.jpg"
}
```

### Update Menu Item (Admin)
```http
PUT /menu/items/:id
Authorization: Bearer <token>
Content-Type: application/json

{
  "category_id": "uuid",
  "name": "Caesar Salad",
  "description": "Updated description",
  "price": 13.99,
  "station": "cold",
  "image_url": "https://example.com/image.jpg",
  "available": true
}
```

### Delete Menu Item (Admin)
```http
DELETE /menu/items/:id
Authorization: Bearer <token>
```

---

## Order Management

### List Orders
```http
GET /orders?status=pending&table_number=T1&waiter_id=uuid
Authorization: Bearer <token>
```

**Query Parameters:**
- `status` - Filter by status
- `table_number` - Filter by table
- `waiter_id` - Filter by waiter

### Get Active Orders
```http
GET /orders/active
Authorization: Bearer <token>
```

Returns orders with status: pending, sent, accepted, cooking, ready

### Get Order Details
```http
GET /orders/:id
Authorization: Bearer <token>
```

**Response:**
```json
{
  "id": "uuid",
  "order_number": "ORD-1234567890",
  "table_number": "T1",
  "waiter_id": "uuid",
  "waiter_name": "John Doe",
  "type": "dine-in",
  "status": "pending",
  "subtotal": 50.00,
  "tax_amount": 5.00,
  "service_amount": 2.50,
  "total_amount": 57.50,
  "items": [
    {
      "id": "uuid",
      "menu_item_id": "uuid",
      "menu_item_name": "Caesar Salad",
      "quantity": 2,
      "price_at_time": 12.99,
      "status": "pending",
      "station": "cold"
    }
  ]
}
```

### Create Order
```http
POST /orders
Authorization: Bearer <token>
Content-Type: application/json

{
  "table_number": "T1",
  "type": "dine-in",
  "waiter_id": "uuid",
  "items": [
    {
      "menu_item_id": "uuid",
      "quantity": 2,
      "price_at_time": 12.99
    }
  ]
}
```

**Order Types:** `dine-in`, `takeaway`, `delivery`

### Update Order Status
```http
PATCH /orders/:id/status
Authorization: Bearer <token>
Content-Type: application/json

{
  "status": "cooking"
}
```

**Status Values:** `pending`, `sent`, `accepted`, `cooking`, `ready`, `completed`, `paid`, `cancelled`

### Update Order Item Status
```http
PATCH /orders/items/:id/status
Authorization: Bearer <token>
Content-Type: application/json

{
  "status": "cooking"
}
```

### Pay for Order
```http
POST /orders/:id/pay
Authorization: Bearer <token>
Content-Type: application/json

{
  "method": "cash",
  "amount": 57.50,
  "items": [
    {
      "id": "uuid",
      "quantity": 2,
      "priceAtTime": 12.99
    }
  ]
}
```

**Payment Methods:** `cash`, `card`, `mobile`

### Split Table
```http
POST /orders/split
Authorization: Bearer <token>
Content-Type: application/json

{
  "source_order_id": "uuid",
  "target_table": "T2",
  "item_ids": ["uuid1", "uuid2"]
}
```

### Merge Tables
```http
POST /orders/merge
Authorization: Bearer <token>
Content-Type: application/json

{
  "from_table": "T1",
  "to_table": "T2"
}
```

---

## Table Management

### List Tables
```http
GET /tables
Authorization: Bearer <token>
```

### Get Table Status
```http
GET /tables/:table_number/status
Authorization: Bearer <token>
```

**Response:**
```json
{
  "status": "occupied",
  "orders": [
    {
      "id": "uuid",
      "order_number": "ORD-123",
      "status": "pending",
      "items": [...]
    }
  ]
}
```

### Create Table
```http
POST /tables
Authorization: Bearer <token>
Content-Type: application/json

{
  "table_number": "T1",
  "capacity": 4
}
```

### Update Table
```http
PUT /tables/:id
Authorization: Bearer <token>
Content-Type: application/json

{
  "table_number": "T1",
  "capacity": 6,
  "status": "available"
}
```

**Table Status:** `available`, `occupied`, `reserved`

### Delete Table
```http
DELETE /tables/:id
Authorization: Bearer <token>
```

---

## WebSocket

Connect to: `ws://localhost:3000/ws`

### Events Received

**Order Created:**
```json
{
  "type": "order_created",
  "order": { ... }
}
```

**Order Updated:**
```json
{
  "type": "order_updated",
  "order": { ... }
}
```

**Item Updated:**
```json
{
  "type": "item_updated",
  "item": { ... }
}
```

**Order Paid:**
```json
{
  "type": "order_paid",
  "order": { ... }
}
```

**Table Split:**
```json
{
  "type": "table_split",
  "source_order_id": "uuid",
  "target_order_id": "uuid"
}
```

**Tables Merged:**
```json
{
  "type": "tables_merged",
  "from_table": "T1",
  "to_table": "T2"
}
```

---

## Error Responses

### 400 Bad Request
```json
{
  "error": "Validation error message",
  "errors": [
    {
      "field": "email",
      "message": "Invalid email format"
    }
  ]
}
```

### 401 Unauthorized
```json
{
  "error": "Authentication required"
}
```

### 403 Forbidden
```json
{
  "error": "Insufficient permissions"
}
```

### 404 Not Found
```json
{
  "error": "Resource not found"
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal server error"
}
```

---

## Rate Limiting

Currently no rate limiting is implemented. Consider adding in production.

## CORS

CORS is enabled for all origins in development. Configure properly for production.

## Testing with cURL

### Login and Save Token
```bash
TOKEN=$(curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@pos.com","password":"admin123"}' \
  | jq -r '.token')
```

### Use Token
```bash
curl http://localhost:3000/api/menu/items \
  -H "Authorization: Bearer $TOKEN"
```

## Testing with Postman

1. Import the API endpoints
2. Create environment variable `token`
3. Add to Authorization tab: Bearer Token with `{{token}}`
4. Login first to get token
5. Use token for subsequent requests
