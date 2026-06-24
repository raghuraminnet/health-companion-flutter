# Health Companion Flutter App

A native mobile health tracking app built with Flutter, providing a native iOS/Android experience for the Health Companion platform.

## Features

- **Blood Pressure Tracking** - Log and monitor BP readings with visual status indicators
- **Mood Tracking** - Daily mood logging with ratings for sleep quality and energy
- **Water Intake** - Track daily water consumption with quick-add buttons
- **Steps Counter** - Log and monitor daily step count with distance/calorie calculations
- **Weight Management** - Track weight history with trend analysis
- **Pregnancy Tracking** - Last-period-based week/day tracker with baby-size + tips
- **4 Themes** - Dark, Light, Pink, and White themes (plus a v2 light/dark pair)
- **Offline Support** - Local data caching with SharedPreferences

## Design System (v2)

The app uses a Plus Jakarta Sans + per-metric accent design system
(Friendly Wellness — Direction B). Tokens live in
`lib/screens/v2/v2_theme.dart`:

- `V2Colors` — surface, text, per-metric accents (BP / Mood / Water / Steps / Weight / Pregnancy)
- `V2Type` — Plus Jakarta Sans typography scale via `google_fonts`
- `buildV2LightTheme()` / `buildV2DarkTheme()` — Material 3 themes wired in `main.dart`

Every tracker screen (`bp_v2`, `mood_v2`, `water_v2`, `steps_v2`, `weight_v2`,
`pregnancy_v2`) follows the same layout:

- Top bar with back / tune actions
- Hero card with progress ring + delta badge
- 7-day chart (LineChart / BarChart via `fl_chart`)
- History list with soft-tinted icons
- Pill-shaped FAB that opens a modal bottom sheet for logging

## Architecture

```
lib/
├── main.dart                  # App entry point; wires v2 theme
├── models/                    # Data models
│   ├── user.dart
│   ├── bp_entry.dart          # BP, Mood, Water, Steps, Weight entries
│   └── pregnancy.dart         # PregnancyProfile + helpers (week, size, dev)
├── services/
│   └── api_service.dart       # API communication (singleton)
├── screens/
│   ├── auth_screen.dart       # Login/Register → DashboardV2
│   ├── pregnancy_screen.dart  # Pregnancy tracker (local-only data)
│   ├── profile_screen.dart    # Account + theme picker + logout
│   ├── settings_screen.dart   # Trackers, goals, units
│   └── v2/                    # v2 design system screens
│       ├── v2_theme.dart      # V2Colors, V2Type, buildV2{Light,Dark}Theme
│       ├── dashboard_v2.dart  # Wellness score hero + metric grid + recent
│       ├── bp_v2.dart         # Blood Pressure
│       ├── mood_v2.dart       # Mood
│       ├── water_v2.dart      # Water intake
│       ├── steps_v2.dart      # Steps
│       ├── weight_v2.dart     # Weight
│       ├── pregnancy_v2.dart  # Pregnancy tracker (design-system migration)
│       ├── preview_v2.dart    # v2 preview entry point
│       └── sample_data.dart   # Demo data for v2 screens
├── widgets/
│   └── quick_add_dialog.dart  # Shared quick-add dialog (v1 fallback)
├── utils/
│   └── theme.dart             # v1 theme configuration
└── assets/
    └── fonts/                 # Plus Jakarta Sans (5 weights)
```

## Getting Started

### Prerequisites

- Flutter 3.0+ SDK
- Dart 3.0+
- Android Studio / Xcode (for native builds)
- Docker (for containerized deployment)

### Local Development

```bash
# Clone the repository
git clone https://github.com/raghuraminnet/health-companion-flutter.git
cd health-companion-flutter

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Build for Web (PWA)

```bash
flutter build web --release
```

### Build for Android

```bash
flutter build apk --debug
# APK will be at: build/app/outputs/flutter-apk/app-debug.apk
```

### Build for iOS

```bash
flutter build ios --debug
# Requires Xcode
```

## Hostinger Docker Deployment

### Option 1: DockerManager (Recommended)

1. **Upload files** to your Hostinger VPS:
   ```bash
   scp -r health-companion-flutter user@your-server:/var/www/
   ```

2. **SSH into your server** and navigate to the app directory:
   ```bash
   cd /var/www/health-companion-flutter
   ```

3. **In Hostinger DockerManager**, select "Compose Manually" and paste the contents of `docker-compose.yml`

4. **Deploy** - The app will be available at `http://YOUR_SERVER_IP:3002`

### Option 2: Manual Docker Commands

```bash
# SSH into your server
ssh user@your-server

# Navigate to app directory
cd /var/www/health-companion-flutter

# Build and start
docker build -t health-companion-flutter .
docker run -d --name health-companion-flutter -p 3002:80 --restart unless-stopped health-companion-flutter
```

### Option 3: Using the deploy script

```bash
chmod +x deploy-hostinger.sh
./deploy-hostinger.sh
```

### Accessing the App

After deployment, access the Flutter PWA at:
```
http://YOUR_SERVER_IP:3002
```

To bind to port 80 (standard HTTP):
```bash
docker run -d --name health-companion-flutter -p 80:80 --restart unless-stopped health-companion-flutter
```

## Docker Configuration

The `docker-compose.yml` exposes port **3002** by default. Edit to change:

```yaml
ports:
  - "80:80"    # Standard HTTP
  # or
  - "8080:80"  # Custom port
```

## Configuration

Create a `.env` file:

```env
API_URL=http://localhost:38257
```

For production, point to your deployed backend:

```env
API_URL=https://api.your-domain.com
```

## API Endpoints

The Flutter app connects to the Health Companion API:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/auth/register` | POST | User registration |
| `/api/auth/login` | POST | User login |
| `/api/auth/me` | GET | Get current user |
| `/api/bp` | GET/POST | Blood pressure entries |
| `/api/mood` | GET/POST | Mood entries |
| `/api/water` | GET/POST | Water intake entries |
| `/api/steps` | GET/POST | Steps entries |
| `/api/weight` | GET/POST | Weight entries |
| `/api/preferences` | GET/PUT | User preferences |
| `/api/settings` | GET/PUT | User settings |
| `/api/stats` | GET | Dashboard statistics |

## Themes

The app supports two theme systems:

**v1 themes (legacy, kept for back-compat with stored user preferences):**

| Theme | Description |
|-------|-------------|
| `dark` | Deep navy + lavender (default) |
| `light` | Soft gray + purple |
| `pink` | Rose blush + pink |
| `white` | Pure white + blue (Apple-style) |

**v2 themes (current):**

| Theme | Description |
|-------|-------------|
| `v2-light` | Friendly Wellness — light bg, per-metric accents, Plus Jakarta Sans (default) |
| `v2-dark` | Focus — deep bg, emerald primary, same typography |

## Native Features

- **Push Notifications** - Local notifications for reminders (via flutter_local_notifications)
- **Charts** - Visual data representation (via fl_chart)
- **Progress Indicators** - Circular and linear progress (via percent_indicator)
- **Typography** - Plus Jakarta Sans via `google_fonts`, with `.ttf` fallback in `assets/fonts/`

## Testing

Visual regression harness lives in `test/screenshots_test.dart`:

```bash
flutter test test/screenshots_test.dart
```

Reference renders are committed under `test/goldens/`. Update them with
`flutter test --update-goldens test/screenshots_test.dart` when intentional
design changes ship.

## Repository

https://github.com/raghuraminnet/health-companion-flutter

## License

MIT License