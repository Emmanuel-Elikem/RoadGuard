# RoadGuard AI Agent Instructions

> **PURPOSE:** This is the master instruction file for AI assistants working on the RoadGuard project. Read this ENTIRE file before doing ANY work.

---

## 🚨 CRITICAL: PRE-TASK REQUIREMENTS

**BEFORE doing ANY task, you MUST:**

1. **Read the Mistakes Log:** `.github/agents/RoadGuard-Mistakes-Log.md`
2. **Read the Design System:** `.github/agents/RoadGuard-Design-System.md`
3. **Read the App Flow:** `.github/agents/RoadGuard-App-Flow.md`
4. **Confirm understanding** in your first response

---

## 📱 Project Overview

**App Name:** RoadGuard (Working Title - Easily Changeable via `app_config.dart`)
**Purpose:** Road safety app for Ghana - track speed, rate drivers, search vehicle history
**Platform:** Flutter (Android first, iOS-ready architecture)
**Design Language:** "Digital Copilot" - Neo-Modern Bento UI with floating elements

---

## 🎯 Core Principles

### 1. Offline-First Architecture
- ALL features must work without internet
- Use Hive for local storage
- Sync queue for when online
- Pre-cache searchable data

### 2. Battery Optimization
- Dark mode default for OLED screens
- Efficient GPS polling
- Hybrid speed tracking (GPS + Accelerometer)

### 3. Design Consistency
- ALWAYS reference `RoadGuard-Design-System.md` for UI decisions
- ALL styles come from `lib/core/theme/` files
- NO hardcoded colors, sizes, or fonts in widgets

### 4. Clean Architecture
```
lib/
├── core/                 # App-wide utilities
│   ├── config/          # App configuration
│   ├── theme/           # Design system
│   ├── constants/       # App constants
│   └── utils/           # Helper functions
├── features/            # Feature modules
│   ├── tracking/        # Speed tracking
│   ├── rating/          # Driver rating
│   ├── search/          # Plate search
│   ├── social/          # Connected Transit
│   └── settings/        # App settings
├── shared/              # Shared widgets
│   ├── widgets/         # Reusable components
│   └── services/        # Shared services
└── main.dart
```

---

## 🔧 Technical Standards

### Flutter Version
- Flutter: 3.38.x (stable)
- Dart: 3.10.x

### State Management
- Riverpod 2.x for app state
- Local state with StatefulWidget only when necessary

### Key Packages
```yaml
# Core
flutter_riverpod: ^2.4.0
hive_flutter: ^1.1.0
go_router: ^12.0.0

# Location & Sensors
geolocator: ^10.0.0
sensors_plus: ^4.0.0

# Maps
flutter_map: ^6.0.0
latlong2: ^0.9.0

# Firebase
firebase_core: ^2.24.0
cloud_firestore: ^4.13.0
firebase_auth: ^4.15.0

# OCR
google_mlkit_text_recognition: ^0.11.0

# UI
flutter_animate: ^4.3.0
```

---

## 📝 Coding Standards

### File Naming
- All lowercase with underscores: `speed_tracker_screen.dart`
- Widgets: `*_widget.dart`
- Screens: `*_screen.dart`
- Services: `*_service.dart`
- Controllers: `*_controller.dart`

### No Comments Policy
**FORBIDDEN comment styles:**
- ❌ `// Step 1: Initialize`
- ❌ `// This function does X`
- ❌ Numbered steps or guiding comments

**ALLOWED comments:**
- ✅ Section headers: `// Speed Tracking`
- ✅ Warnings: `// WARNING: Do not remove`
- ✅ TODOs: `// TODO: Implement caching`

### Import Organization
```dart
// Packages
import 'package:flutter/material.dart';

// Core
import 'package:roadguard/core/theme/app_theme.dart';

// Features
import 'package:roadguard/features/tracking/tracking_screen.dart';

// Shared
import 'package:roadguard/shared/widgets/app_button.dart';
```

---

## 🎨 UI Implementation Rules

### ALWAYS Reference Design System
Before creating ANY UI element:
1. Check `RoadGuard-Design-System.md` for the pattern
2. Use theme values from `lib/core/theme/`
3. NEVER hardcode colors, sizes, or fonts

### Component Checklist
- [ ] Uses `AppColors` for all colors
- [ ] Uses `AppDimensions` for spacing/radius
- [ ] Uses `AppTypography` for text styles
- [ ] Supports both light and dark mode
- [ ] Has proper touch targets (min 48px)
- [ ] Follows "Floating Island" navigation pattern

---

## 🚫 Common Mistakes to Avoid

1. **Hardcoding colors** → Use `AppColors.primary`
2. **Hardcoding text styles** → Use `AppTypography.headlineLarge`
3. **Ignoring offline state** → Always handle no-network
4. **Print statements** → Use `debugPrint` and remove before commit
5. **Case-sensitive imports** → Use lowercase filenames
6. **Multiple `runApp()` calls** → Only ONE in `main.dart`

---

## ✅ Task Completion Checklist

After EVERY task:
- [ ] Code compiles without errors
- [ ] Follows design system
- [ ] Works offline
- [ ] Light AND dark mode work
- [ ] No hardcoded values
- [ ] Mistakes logged if any
- [ ] Teaching explanation provided

---

## 📚 Reference Files

| File | Purpose |
|------|---------|
| `RoadGuard-Design-System.md` | All UI/UX patterns, colors, motion |
| `RoadGuard-App-Flow.md` | User journeys, screen flows |
| `RoadGuard-Mistakes-Log.md` | Error tracking |
| `RoadGuard-Database-Schema.md` | Data structure |
| `RoadGuard-MVP-Plan.md` | Task tracking |

---

## 🔒 Security Requirements

- Sanitize all user inputs
- No API keys in code (use environment variables)
- Validate number plate format before OCR
- Rate limit Firebase writes
- Anonymous user tracking for Connected Transit

---

**Remember:** The goal is a PREMIUM, POLISHED app that feels like a "Digital Copilot" - smooth, tactile, and professional.
