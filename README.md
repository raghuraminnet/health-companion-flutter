# Health Companion Flutter App

A native mobile health tracking app built with Flutter, providing a native iOS/Android experience for the Health Companion platform.

## Features

- **Blood Pressure Tracking** - Log and monitor BP readings with visual status indicators
- **Mood Tracking** - Daily mood logging with ratings for sleep quality and energy
- **Water Intake** - Track daily water consumption with quick-add buttons
- **Steps Counter** - Log and monitor daily step count with distance/calorie calculations
- **Weight Management** - Track weight history with trend analysis
- **4 Themes** - Dark, Light, Pink, and White themes
- **Offline Support** - Local data caching with SharedPreferences

## Architecture

```
lib/
├── main.dart              # App entry point
├── models/                # Data models
│   ├── user.dart
│   └── bp_entry.dart      # BP, Mood, Water, Steps, Weight entries
├── services/
│   └── api_service.dart   # API communication layer
├── screens/
│   ├── auth_screen.dart   # Login/Register
│   ├── dashboard_screen.dart
│   ├── blood_pressure_screen.dart
│   ├── mood_screen.dart
│   ├── water_screen.dart
│   ├── steps_screen.dart
│   ├── weight_screen.dart
│   └── profile_screen.dart
└── utils/
    └── theme.dart         # Theme configuration
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

## Docker Deployment

### Web App (PWA)

```bash
# Build and run
docker-compose up -d

# Access at http://localhost:3000
```

### Build Android APK in Docker

```bash
docker-compose run flutter-android-build
# APK will be at ./flutter_apk_output/
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

The app supports 4 color themes:

| Theme | Description |
|-------|-------------|
| `dark` | Deep navy + lavender (default) |
| `light` | Soft gray + purple |
| `pink` | Rose blush + pink |
| `white` | Pure white + blue (Apple-style) |

## Native Features

- **Push Notifications** - Local notifications for reminders (via flutter_local_notifications)
- **Charts** - Visual data representation (via fl_chart)
- **Progress Indicators** - Circular and linear progress (via percent_indicator)

## Repository

https://github.com/raghuraminnet/health-companion-flutter

## License

MIT License