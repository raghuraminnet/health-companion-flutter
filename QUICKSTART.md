# 🚀 Health Companion - Quick Start Guide

## One-Command Setup

```bash
#1. Clone the repo
git clone https://github.com/raghuraminnet/health-companion-flutter.git
cd health-companion-flutter

# 2. Run setup (clones API repo + prepares everything)
chmod +x setup.sh
./setup.sh

# 3. Start everything with Docker
docker-compose up -d --build

# 4. Wait2-3 minutes, then access:
# http://YOUR_SERVER_IP:3002
```

---

## What This Does

| Service | Port | Description |
|---------|------|-------------|
| **Flutter Web** | 3002 | The mobile PWA |
| **API Server** | 38257 | Backend REST API |
| **PostgreSQL** | 5432 | Database |

---

## Services

### 🌐 Flutter Web App
- **URL:** http://localhost:3002 (or http://YOUR_SERVER_IP:3002)
- **Features:** BP, Mood, Water, Steps, Weight tracking
- **Themes:** Dark, Light, Pink, White

### 🔗 Backend API
- **URL:** http://localhost:38257
- **Health Check:** http://localhost:38257/api/health

### 🗄️ PostgreSQL Database
- **Host:** postgres (from within docker network)
- **Port:** 5432
- **User:** healthuser
- **Password:** healthpass123
- **Database:** healthapp

---

## Useful Commands

```bash
# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f api
docker-compose logs -f flutter-web

# Stop everything
docker-compose down

# Rebuild after code changes
docker-compose up -d --build

# Restart a specific service
docker-compose restart api
```

---

## Troubleshooting

### App shows blank screen
```bash
# Rebuild with HTML renderer
docker-compose exec flutter-web flutter build web --release
```

### API not responding
```bash
# Check API logs
docker-compose logs api

# Restart API
docker-compose restart api
```

### Database connection error
```bash
# Check if postgres is running
docker-compose ps postgres

# View postgres logs
docker-compose logs postgres
```

---

## Development

### Run Flutter locally (without Docker)
```bash
flutter pub get
flutter run -d chrome
```

### Run API locally
```bash
cd ../bp-tracker
npm install
node server/index.js
```

---

## Repository Structure

```
health-companion-flutter/ # This repo (Flutter Web)
├── docker-compose.yml # Full stack deployment
├── setup.sh                   # Setup script
├── Dockerfile                 # Flutter web Docker image
├── nginx.conf                 # Nginx config
├── lib/                       # Flutter source code
└── build/web/                # Built web app

../bp-tracker/                 # API repo (cloned by setup.sh)
├── server/
│   ├── index.js # Express API server
│   └── db.js                  # PostgreSQL connection
├── Dockerfile                # API Docker image
└── package.json
```

---

## Customization

### Change Ports
Edit `docker-compose.yml`:
```yaml
services:
  flutter-web:
    ports:
      - "80:80" # Change3002 to 80
 api:
    ports:
      - "3000:38257"  # Change 38257 to 3000
```

### Change Database Password
Edit `docker-compose.yml`:
```yaml
postgres:
  environment:
    POSTGRES_PASSWORD: your-new-password
api:
  environment:
    PG_PASSWORD: your-new-password
```

### Update API URL in Flutter App
Edit `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'http://YOUR_SERVER_IP:38257/api';
```

---

## License

MIT