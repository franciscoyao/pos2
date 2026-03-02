# Deployment Guide - POS System

Complete guide for deploying your POS system to production.

## 🎯 Pre-Deployment Checklist

- [ ] Change default admin password
- [ ] Set strong JWT_SECRET (32+ random characters)
- [ ] Configure production database
- [ ] Set up SSL/HTTPS
- [ ] Configure CORS for your domain
- [ ] Set up database backups
- [ ] Configure monitoring
- [ ] Test all features
- [ ] Prepare rollback plan

## 🚀 Backend Deployment Options

### Option 1: Render.com (Recommended for Beginners)

**Pros:** Free tier, automatic deployments, built-in PostgreSQL, SSL included
**Cons:** Cold starts on free tier

#### Steps:

1. **Prepare Repository**
```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin <your-github-repo>
git push -u origin main
```

2. **Create Render Account**
- Go to https://render.com
- Sign up with GitHub

3. **Create PostgreSQL Database**
- Click "New +" → "PostgreSQL"
- Name: `pos-database`
- Plan: Free or Starter
- Create Database
- Copy "Internal Database URL"

4. **Create Web Service**
- Click "New +" → "Web Service"
- Connect your repository
- Settings:
  - Name: `pos-backend`
  - Environment: `Node`
  - Build Command: `npm install`
  - Start Command: `npm start`
  - Plan: Free or Starter

5. **Add Environment Variables**
```
DATABASE_URL=<your-internal-database-url>
JWT_SECRET=<generate-random-32-char-string>
NODE_ENV=production
PORT=3000
```

6. **Deploy**
- Click "Create Web Service"
- Wait for deployment
- Run migration: Add "Deploy Hook" or manual command

7. **Run Migrations**
```bash
# In Render Shell
npm run setup
```

8. **Get Your URL**
- Your backend: `https://pos-backend.onrender.com`

---

### Option 2: Heroku

**Pros:** Easy deployment, good documentation, add-ons marketplace
**Cons:** Paid plans required for production

#### Steps:

1. **Install Heroku CLI**
```bash
# Mac
brew tap heroku/brew && brew install heroku

# Windows
# Download from https://devcenter.heroku.com/articles/heroku-cli
```

2. **Login and Create App**
```bash
heroku login
cd backend
heroku create pos-backend-app
```

3. **Add PostgreSQL**
```bash
heroku addons:create heroku-postgresql:mini
```

4. **Set Environment Variables**
```bash
heroku config:set JWT_SECRET=$(openssl rand -base64 32)
heroku config:set NODE_ENV=production
```

5. **Deploy**
```bash
git push heroku main
```

6. **Run Migrations**
```bash
heroku run npm run setup
```

7. **Open App**
```bash
heroku open
```

---

### Option 3: DigitalOcean App Platform

**Pros:** Good performance, reasonable pricing, easy scaling
**Cons:** Requires payment method

#### Steps:

1. **Create Account**
- Go to https://www.digitalocean.com
- Sign up and add payment method

2. **Create Database**
- Create → Databases → PostgreSQL
- Choose plan and region
- Create cluster
- Copy connection string

3. **Create App**
- Create → Apps
- Connect GitHub repository
- Select `backend` folder
- Configure:
  - Build Command: `npm install`
  - Run Command: `npm start`

4. **Add Environment Variables**
```
DATABASE_URL=<your-database-url>
JWT_SECRET=<random-string>
NODE_ENV=production
```

5. **Deploy**
- Click "Create Resources"
- Wait for deployment

---

### Option 4: AWS (Advanced)

**Pros:** Full control, highly scalable, many services
**Cons:** Complex setup, requires AWS knowledge

#### Architecture:
```
Route 53 (DNS)
    ↓
CloudFront (CDN)
    ↓
Application Load Balancer
    ↓
ECS/Fargate (Containers)
    ↓
RDS PostgreSQL
```

#### Steps:

1. **Create RDS PostgreSQL**
```bash
aws rds create-db-instance \
  --db-instance-identifier pos-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --master-username admin \
  --master-user-password <password> \
  --allocated-storage 20
```

2. **Create ECR Repository**
```bash
aws ecr create-repository --repository-name pos-backend
```

3. **Build and Push Docker Image**
```bash
cd backend
docker build -t pos-backend .
docker tag pos-backend:latest <ecr-url>/pos-backend:latest
docker push <ecr-url>/pos-backend:latest
```

4. **Create ECS Cluster**
```bash
aws ecs create-cluster --cluster-name pos-cluster
```

5. **Create Task Definition**
```json
{
  "family": "pos-backend",
  "containerDefinitions": [{
    "name": "pos-backend",
    "image": "<ecr-url>/pos-backend:latest",
    "memory": 512,
    "cpu": 256,
    "essential": true,
    "portMappings": [{
      "containerPort": 3000,
      "protocol": "tcp"
    }],
    "environment": [
      {"name": "NODE_ENV", "value": "production"},
      {"name": "DATABASE_URL", "value": "<rds-url>"},
      {"name": "JWT_SECRET", "value": "<secret>"}
    ]
  }]
}
```

6. **Create Service**
```bash
aws ecs create-service \
  --cluster pos-cluster \
  --service-name pos-service \
  --task-definition pos-backend \
  --desired-count 2 \
  --launch-type FARGATE
```

---

### Option 5: VPS (Ubuntu Server)

**Pros:** Full control, cost-effective for high traffic
**Cons:** Requires server management skills

#### Steps:

1. **Create VPS**
- DigitalOcean Droplet, AWS EC2, or Linode
- Ubuntu 22.04 LTS
- At least 1GB RAM

2. **Connect to Server**
```bash
ssh root@your-server-ip
```

3. **Install Dependencies**
```bash
# Update system
apt update && apt upgrade -y

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# Install PostgreSQL
apt install -y postgresql postgresql-contrib

# Install Nginx
apt install -y nginx

# Install PM2
npm install -g pm2
```

4. **Setup PostgreSQL**
```bash
sudo -u postgres psql
CREATE DATABASE pos_system;
CREATE USER pos_user WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE pos_system TO pos_user;
\q
```

5. **Deploy Application**
```bash
# Clone repository
cd /var/www
git clone <your-repo-url> pos-system
cd pos-system/backend

# Install dependencies
npm install --production

# Create .env
cat > .env << EOF
DATABASE_URL=postgresql://pos_user:secure_password@localhost:5432/pos_system
JWT_SECRET=$(openssl rand -base64 32)
NODE_ENV=production
PORT=3000
EOF

# Run migrations
npm run setup

# Start with PM2
pm2 start src/server.js --name pos-backend
pm2 save
pm2 startup
```

6. **Configure Nginx**
```bash
cat > /etc/nginx/sites-available/pos << 'EOF'
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    location /ws {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
    }
}
EOF

ln -s /etc/nginx/sites-available/pos /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx
```

7. **Setup SSL with Let's Encrypt**
```bash
apt install -y certbot python3-certbot-nginx
certbot --nginx -d your-domain.com
```

8. **Setup Firewall**
```bash
ufw allow 22
ufw allow 80
ufw allow 443
ufw enable
```

---

## 📱 Flutter Frontend Deployment

### Web Deployment

#### Option 1: Firebase Hosting

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize
firebase init hosting

# Build Flutter web
flutter build web

# Deploy
firebase deploy --only hosting
```

#### Option 2: Netlify

```bash
# Build
flutter build web

# Install Netlify CLI
npm install -g netlify-cli

# Deploy
cd build/web
netlify deploy --prod
```

#### Option 3: Vercel

```bash
# Build
flutter build web

# Install Vercel CLI
npm install -g vercel

# Deploy
cd build/web
vercel --prod
```

### Mobile Deployment

#### Android (Google Play Store)

1. **Prepare App**
```bash
# Update version in pubspec.yaml
version: 1.0.0+1

# Build release APK
flutter build apk --release

# Or build App Bundle (recommended)
flutter build appbundle --release
```

2. **Sign App**
- Create keystore
- Configure signing in `android/app/build.gradle`

3. **Upload to Play Console**
- Go to https://play.google.com/console
- Create app
- Upload APK/Bundle
- Fill in store listing
- Submit for review

#### iOS (App Store)

1. **Prepare App**
```bash
# Update version
version: 1.0.0+1

# Build
flutter build ios --release
```

2. **Configure Xcode**
- Open `ios/Runner.xcworkspace`
- Set signing team
- Configure capabilities

3. **Upload to App Store Connect**
- Archive in Xcode
- Upload to App Store Connect
- Fill in app information
- Submit for review

### Desktop Deployment

#### Windows

```bash
flutter build windows --release
# Output: build/windows/runner/Release/
```

Create installer with Inno Setup or NSIS.

#### macOS

```bash
flutter build macos --release
# Output: build/macos/Build/Products/Release/
```

Create DMG with create-dmg.

#### Linux

```bash
flutter build linux --release
# Output: build/linux/x64/release/bundle/
```

Create AppImage or Snap package.

---

## 🔧 Post-Deployment Configuration

### 1. Update Flutter Config

Edit `assets/config.json`:
```json
{
  "baseUrl": "https://your-backend-url.com"
}
```

Rebuild and redeploy Flutter app.

### 2. Setup Database Backups

**Render/Heroku:**
- Automatic backups included in paid plans

**VPS:**
```bash
# Create backup script
cat > /root/backup-db.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
pg_dump pos_system > /backups/pos_$DATE.sql
find /backups -name "pos_*.sql" -mtime +7 -delete
EOF

chmod +x /root/backup-db.sh

# Add to crontab (daily at 2 AM)
crontab -e
0 2 * * * /root/backup-db.sh
```

### 3. Setup Monitoring

**Option 1: UptimeRobot**
- Free monitoring
- Email alerts
- Monitor: `https://your-backend/health`

**Option 2: New Relic**
```bash
npm install newrelic
# Configure newrelic.js
```

**Option 3: Sentry (Error Tracking)**
```bash
npm install @sentry/node
# Add to server.js
```

### 4. Setup Logging

**PM2 Logs:**
```bash
pm2 logs pos-backend
pm2 logs --lines 100
```

**Centralized Logging:**
- Papertrail
- Loggly
- CloudWatch (AWS)

---

## 🔒 Security Hardening

### 1. Environment Variables
Never commit `.env` files. Use platform-specific secret management.

### 2. Rate Limiting
```bash
npm install express-rate-limit
```

```javascript
import rateLimit from 'express-rate-limit';

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});

app.use('/api/', limiter);
```

### 3. Helmet (Security Headers)
```bash
npm install helmet
```

```javascript
import helmet from 'helmet';
app.use(helmet());
```

### 4. CORS Configuration
```javascript
app.use(cors({
  origin: ['https://your-frontend-domain.com'],
  credentials: true
}));
```

### 5. Database Security
- Use SSL for database connections
- Restrict database access by IP
- Use strong passwords
- Regular security updates

---

## 📊 Performance Optimization

### 1. Enable Compression
```bash
npm install compression
```

```javascript
import compression from 'compression';
app.use(compression());
```

### 2. Database Optimization
- Add indexes
- Use connection pooling
- Optimize queries
- Regular VACUUM (PostgreSQL)

### 3. Caching (Optional)
```bash
npm install redis
```

### 4. CDN for Static Assets
- CloudFlare
- AWS CloudFront
- Fastly

---

## 🧪 Testing Production

### 1. Health Check
```bash
curl https://your-backend/health
```

### 2. API Test
```bash
curl -X POST https://your-backend/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@pos.com","password":"admin123"}'
```

### 3. WebSocket Test
```javascript
const ws = new WebSocket('wss://your-backend/ws');
ws.onopen = () => console.log('Connected');
ws.onmessage = (msg) => console.log('Message:', msg.data);
```

### 4. Load Testing
```bash
npm install -g artillery
artillery quick --count 10 --num 100 https://your-backend/api/menu/items
```

---

## 🔄 Continuous Deployment

### GitHub Actions

Create `.github/workflows/deploy.yml`:
```yaml
name: Deploy

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Deploy to Render
        env:
          RENDER_API_KEY: ${{ secrets.RENDER_API_KEY }}
        run: |
          curl -X POST https://api.render.com/deploy/srv-xxx
```

---

## 📱 Mobile App Distribution

### TestFlight (iOS)
- Upload to App Store Connect
- Add testers
- Distribute beta

### Google Play Internal Testing
- Upload to Play Console
- Create internal testing track
- Add testers

### Firebase App Distribution
```bash
firebase appdistribution:distribute app-release.apk \
  --app YOUR_APP_ID \
  --groups testers
```

---

## 🎯 Go-Live Checklist

- [ ] Backend deployed and accessible
- [ ] Database migrated and backed up
- [ ] SSL/HTTPS configured
- [ ] Environment variables set
- [ ] Monitoring configured
- [ ] Logging configured
- [ ] Frontend deployed
- [ ] Mobile apps submitted (if applicable)
- [ ] DNS configured
- [ ] Load testing completed
- [ ] Security audit completed
- [ ] Documentation updated
- [ ] Team trained
- [ ] Support plan in place
- [ ] Rollback plan ready

---

## 🆘 Troubleshooting

### Backend won't start
```bash
# Check logs
pm2 logs pos-backend
# or
heroku logs --tail
```

### Database connection issues
- Verify DATABASE_URL
- Check firewall rules
- Verify database is running

### WebSocket not connecting
- Check WSS protocol (not WS)
- Verify proxy configuration
- Check CORS settings

### High response times
- Check database queries
- Review server resources
- Enable caching
- Optimize code

---

## 📞 Support Resources

- Backend logs: Check platform-specific logs
- Database: Use platform's database console
- Monitoring: Check UptimeRobot/New Relic
- Errors: Check Sentry dashboard

---

**Congratulations! Your POS system is now live! 🎉**
