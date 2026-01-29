# RoadGuard - Global Copilot Instructions

> These instructions apply to ALL Copilot interactions in this workspace automatically.

---

## Project Summary

**RoadGuard** is a Flutter mobile app for road safety in Ghana featuring:
- Real-time speed tracking (GPS + accelerometer fusion)
- Driver rating system (rate vehicles by plate number)
- Vehicle history search
- Offline-first architecture

---

## Tech Stack

| Category | Technology |
|----------|------------|
| Framework | Flutter 3.38.x, Dart 3.10.x |
| State | Riverpod 3.x |
| Local Storage | Hive 2.x |
| Backend | Firebase (Firestore, Auth, Functions) |
| Maps | flutter_map + OpenStreetMap (offline capable) |
| OCR | Google ML Kit (on-device) |

---

## Critical Rules

### 1. Offline-First (MANDATORY)
Every feature MUST work without internet. Save to Hive first, then queue for Firebase sync.

### 2. No Hardcoded Values
```dart
// ❌ NEVER
color: Color(0xFF1A1A2E)
fontSize: 24

// ✅ ALWAYS
color: AppColors.background
style: AppTypography.headlineMedium
```

### 3. File Naming
All lowercase with underscores: `speed_tracker_service.dart`

### 4. Error Handling
Always wrap async operations in try-catch, return `Result<T>` types.

### 5. Testing
Code must be testable - inject dependencies, don't create them inline.

---

## Architecture

```
lib/
├── core/           # App-wide config, theme, utils
├── features/       # Feature modules (tracking, rating, search)
├── shared/         # Reusable widgets and services
└── main.dart
```

---

## Documentation

For detailed specifications, see `.github/agents/`:
- `RoadGuard.agent.md` - Main agent with all linked docs
- `RoadGuard-Coding-Standards.md` - SOLID, DRY, testing rules
- `RoadGuard-Design-System.md` - UI patterns, colors, motion
- `RoadGuard-Backend-Logic.md` - Error handling, sync queue
- `RoadGuard-Mistakes-Log.md` - Known issues (auto-log mistakes here!)

---

## Git Workflow

- **main**: Production releases only
- **develop**: Integration branch
- **feature/***: New features
- **bugfix/***: Bug fixes
- **hotfix/***: Emergency production fixes

Commit messages: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`

---

## Self-Correction Protocol

If you make a mistake or detect an error:
1. Fix it immediately
2. Add entry to `RoadGuard-Mistakes-Log.md`
3. Commit with message: `docs: log mistake MXXX`

---

**Goal:** Build a premium, polished app that works reliably offline and feels like a "Digital Copilot".
