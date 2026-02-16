# RoadGuard Tech Stack

> Complete list of dependencies, tools, and versions for the project.

---

## 📦 Flutter & Dart

| Component | Version | Notes |
|-----------|---------|-------|
| **Flutter** | 3.38.x (stable) | Latest stable channel |
| **Dart** | 3.10.x | Bundled with Flutter |
| **Min SDK (Android)** | 21 (Lollipop) | ML Kit requirement |
| **Target SDK (Android)** | 34 (Android 14) | Latest |
| **Min iOS** | 15.5 | ML Kit requirement |

---

## 🧩 Core Dependencies

### State Management
```yaml
flutter_riverpod: ^3.2.0          # State management
riverpod_annotation: ^3.2.0       # Code generation annotations
```

### Local Storage
```yaml
hive_flutter: ^1.1.0              # Local database
hive: ^2.2.3                      # Hive core
```

### Firebase
```yaml
firebase_core: ^2.32.0            # Firebase initialization
firebase_auth: ^4.20.0            # Authentication
cloud_firestore: ^4.17.0          # Cloud database
firebase_analytics: ^10.10.0      # Analytics (optional)
```

### Navigation
```yaml
go_router: ^14.8.1                # Declarative routing
```

---

## 📍 Location & Sensors

### GPS & Location
```yaml
geolocator: ^14.0.2               # Cross-platform location
geocoding: ^3.0.0                 # Address lookup
```

### Sensors
```yaml
sensors_plus: ^7.0.0              # NOT used for speed tracking (GPS-only)
                                   # Kept for future: bump/crash detection (v2.0)
```

> **⚠️ Architecture Note (Feb 2026):** Speed tracking uses GPS Doppler velocity ONLY.
> Accelerometer was removed because passengers hold phones in unpredictable
> orientations, making gravity separation unreliable. See [RoadGuard-Algorithms.md](RoadGuard-Algorithms.md).

### Permissions
```yaml
permission_handler: ^12.0.1       # Runtime permissions
```

---

## 🗺️ Maps

### Google Maps (Online)
```yaml
google_maps_flutter: ^2.14.0      # Google Maps widget
```

### OpenStreetMap (Offline)
```yaml
flutter_map: ^8.2.2               # OSM map widget
latlong2: ^0.9.1                  # Coordinate handling
flutter_map_tile_caching: ^10.1.1 # Offline tile storage
```

---

## 📷 Camera & OCR

### Camera
```yaml
image_picker: ^1.2.1              # Camera/gallery access
camera: ^0.11.0                   # Direct camera control (optional)
```

### OCR
```yaml
google_mlkit_text_recognition: ^0.15.0  # Number plate scanning
```

---

## 🎨 UI & Animation

### Animations
```yaml
flutter_animate: ^4.5.2           # Animation utilities
```

### Icons
```yaml
flutter_svg: ^2.0.15              # SVG rendering
lucide_icons: ^0.265.0            # Modern icon set (or use material)
```

### Utilities
```yaml
cached_network_image: ^3.4.1      # Image caching
shimmer: ^3.0.0                   # Loading skeletons
```

---

## 🔧 Utilities

### Connectivity
```yaml
connectivity_plus: ^7.0.0         # Network status detection
```

### Storage & Data
```yaml
uuid: ^4.5.1                      # Generate unique IDs
intl: ^0.19.0                     # Date/number formatting
shared_preferences: ^2.3.2        # Simple key-value (backup to Hive)
```

### Logging & Debug
```yaml
logger: ^2.5.0                    # Structured logging
```

---

## 🏗️ Build & Code Generation

### Code Generation
```yaml
# dev_dependencies
build_runner: ^2.4.14             # Code generator runner
hive_generator: ^2.0.1            # Hive TypeAdapter generator
riverpod_generator: ^3.2.0        # Riverpod provider generator
json_serializable: ^6.9.3         # JSON serialization
freezed: ^2.5.8                   # Immutable data classes
freezed_annotation: ^2.4.4        # Freezed annotations
```

### Linting
```yaml
# dev_dependencies
flutter_lints: ^5.0.0             # Official lint rules
```

### Testing
```yaml
# dev_dependencies
flutter_test:                     # Widget testing
  sdk: flutter
mockito: ^5.4.5                   # Mocking
```

---

## 📄 Complete pubspec.yaml

```yaml
name: roadguard
description: Road safety app for Ghana - track speed, rate drivers, stay safe.
publish_to: 'none'
version: 0.1.0+1

environment:
  sdk: '>=3.10.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # Core
  flutter_riverpod: ^3.2.0
  riverpod_annotation: ^3.2.0
  go_router: ^14.8.1
  
  # Local Storage
  hive_flutter: ^1.1.0
  hive: ^2.2.3
  
  # Firebase
  firebase_core: ^2.32.0
  firebase_auth: ^4.20.0
  cloud_firestore: ^4.17.0
  
  # Location & Sensors
  geolocator: ^14.0.2
  geocoding: ^3.0.0
  sensors_plus: ^7.0.0            # Future: crash detection (v2.0), NOT speed
  permission_handler: ^12.0.1
  
  # Maps
  google_maps_flutter: ^2.14.0
  flutter_map: ^8.2.2
  latlong2: ^0.9.1
  flutter_map_tile_caching: ^10.1.1
  
  # Camera & OCR
  image_picker: ^1.2.1
  google_mlkit_text_recognition: ^0.15.0
  
  # UI
  flutter_animate: ^4.5.2
  flutter_svg: ^2.0.15
  cached_network_image: ^3.4.1
  shimmer: ^3.0.0
  
  # Utilities
  connectivity_plus: ^7.0.0
  uuid: ^4.5.1
  intl: ^0.19.0
  logger: ^2.5.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  build_runner: ^2.4.14
  hive_generator: ^2.0.1
  riverpod_generator: ^3.2.0
  json_serializable: ^6.9.3
  freezed: ^2.5.8
  freezed_annotation: ^2.4.4
  mockito: ^5.4.5

flutter:
  uses-material-design: true
  
  assets:
    - assets/images/
    - assets/icons/
    
  fonts:
    - family: SFMono
      fonts:
        - asset: assets/fonts/SFMono-Regular.otf
        - asset: assets/fonts/SFMono-Bold.otf
          weight: 700
```

---

## 🔧 Android Configuration

### android/app/build.gradle
```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.roadguard.app"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "0.1.0"
    }
}
```

### android/app/src/main/AndroidManifest.xml
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    
    <application
        android:label="RoadGuard"
        android:icon="@mipmap/ic_launcher">
        
        <!-- Google Maps API Key -->
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="${MAPS_API_KEY}"/>
            
        <!-- ... rest of manifest -->
    </application>
</manifest>
```

---

## 🍎 iOS Configuration

### ios/Podfile
```ruby
platform :ios, '15.5'

# ... rest of Podfile

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.5'
    end
  end
end
```

### ios/Runner/Info.plist
```xml
<!-- Location permission descriptions -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>RoadGuard needs your location to check your speed while riding.</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>RoadGuard needs location access to keep checking speed even when the app is in the background.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>RoadGuard needs your location to check speed, even when the app is in the background.</string>

<!-- Camera permission -->
<key>NSCameraUsageDescription</key>
<string>RoadGuard needs camera access to scan car numbers.</string>

<!-- Photo library (for image_picker) -->
<key>NSPhotoLibraryUsageDescription</key>
<string>RoadGuard needs photo access to select images of car numbers.</string>
```

---

## 🛠️ Development Tools

| Tool | Purpose |
|------|---------|
| **VS Code** | Primary IDE |
| **Flutter Extension** | Flutter tooling |
| **Dart Extension** | Dart language support |
| **Android Studio** | Android emulator, build tools |
| **Xcode** | iOS simulator, build tools |
| **Firebase CLI** | Firebase deployment |
| **Git** | Version control |

### VS Code Extensions
```json
{
  "recommendations": [
    "dart-code.dart-code",
    "dart-code.flutter",
    "github.copilot",
    "usernamehw.errorlens",
    "streetsidesoftware.code-spell-checker"
  ]
}
```

---

## 🔐 API Keys Required

| Service | Key Type | Where to Get |
|---------|----------|--------------|
| **Google Maps** | API Key | [Google Cloud Console](https://console.cloud.google.com) |
| **Firebase** | Config files | [Firebase Console](https://console.firebase.google.com) |

### Environment Variables
```bash
# .env (DO NOT COMMIT)
MAPS_API_KEY=your_google_maps_api_key_here
```

---

## 📁 Folder Structure

```
lib/
├── main.dart                     # Entry point
├── firebase_options.dart         # Firebase config (generated)
│
├── core/                         # App-wide utilities
│   ├── constants/
│   │   ├── strings.dart
│   │   └── routes.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   └── app_dimensions.dart
│   ├── utils/
│   │   ├── extensions.dart
│   │   └── validators.dart
│   └── services/
│       ├── hive_service.dart
│       └── connectivity_service.dart
│
├── features/                     # Feature modules
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── tracking/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── rating/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── maps/
│   │   └── ...
│   └── settings/
│       └── ...
│
└── shared/                       # Shared widgets
    ├── widgets/
    │   ├── floating_nav_bar.dart
    │   ├── speedometer.dart
    │   └── app_card.dart
    └── providers/
        └── common_providers.dart
```

---

## ✅ Setup Checklist

Before starting development:

- [ ] Flutter 3.38.x installed (`flutter --version`)
- [ ] Android Studio installed with SDK 34
- [ ] Xcode installed (for iOS, macOS only)
- [ ] Firebase CLI installed (`firebase --version`)
- [ ] VS Code with Flutter extension
- [ ] Git configured
- [ ] Google Maps API key obtained
- [ ] Firebase project created
- [ ] `google-services.json` downloaded
- [ ] `GoogleService-Info.plist` downloaded (iOS)

---

**Document Version:** 1.0  
**Last Updated:** [Auto-generated]
