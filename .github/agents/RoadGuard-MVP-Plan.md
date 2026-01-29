# RoadGuard MVP Plan

> 10-week development roadmap with client demo milestones.

---

## 📅 Timeline Overview

```
Week 1-2   │ Foundation & Auth
Week 3-4   │ Core Speed Tracking
Week 5-6   │ Rating System & OCR
Week 7-8   │ Maps & Route Display
Week 9     │ Cloud Sync & Stats
Week 10    │ Polish & Beta Release
```

---

## 🎯 Client Demo Milestones

| Milestone | Week | Deliverable | Demo Focus |
|-----------|------|-------------|------------|
| **M1** | 2 | Auth + Navigation | "Look and feel" |
| **M2** | 4 | Speed Tracking | Core feature working |
| **M3** | 6 | OCR + Ratings | Rate a driver demo |
| **M4** | 8 | Maps + Routes | Visual trip display |
| **M5** | 9 | Cloud Sync | Data persistence |
| **M6** | 10 | Beta APK | Full app handoff |

---

## 📋 Week-by-Week Breakdown

### Week 1: Project Foundation
**Goal:** Project setup, architecture, tooling

#### Tasks
- [ ] **W1.1** Initialize Flutter project with clean architecture
  - [ ] Create folder structure (`lib/core`, `lib/features`, `lib/shared`)
  - [ ] Set up `pubspec.yaml` with initial dependencies
  - [ ] Configure `analysis_options.yaml`
  
- [ ] **W1.2** Set up Riverpod state management
  - [ ] Install `flutter_riverpod`
  - [ ] Create `ProviderScope` wrapper
  - [ ] Create sample provider to test setup
  
- [ ] **W1.3** Implement theme system
  - [ ] Create `app_theme.dart` with light/dark themes
  - [ ] Define color scheme from Design System
  - [ ] Define text styles
  - [ ] Create spacing/dimension constants
  
- [ ] **W1.4** Set up Hive local storage
  - [ ] Install `hive_flutter`
  - [ ] Initialize Hive in `main.dart`
  - [ ] Create `SettingsBox` for app preferences
  
- [ ] **W1.5** Configure Firebase
  - [ ] Create Firebase project
  - [ ] Add `google-services.json` (Android)
  - [ ] Add `GoogleService-Info.plist` (iOS)
  - [ ] Initialize Firebase in `main.dart`

**Deliverable:** Project builds and runs with theme switching

---

### Week 2: Authentication & Navigation
**Goal:** User can sign up/in and navigate the app

#### Tasks
- [ ] **W2.1** Implement Firebase Auth
  - [ ] Email/password sign up
  - [ ] Email/password sign in
  - [ ] Google sign in
  - [ ] Guest/anonymous auth
  - [ ] Sign out
  
- [ ] **W2.2** Create auth flow screens
  - [ ] Splash screen with loading indicator
  - [ ] Onboarding slides (3 screens)
  - [ ] Auth screen (sign in/up toggle)
  - [ ] Password reset screen
  
- [ ] **W2.3** Set up navigation (go_router)
  - [ ] Define route constants
  - [ ] Create `AppRouter` with guards
  - [ ] Implement redirect logic (auth state)
  
- [ ] **W2.4** Build floating bottom navigation
  - [ ] Create `FloatingNavBar` widget
  - [ ] Implement "mercury indicator" animation
  - [ ] Connect to go_router shell route
  
- [ ] **W2.5** Create placeholder screens
  - [ ] Home (dashboard placeholder)
  - [ ] Stats (placeholder)
  - [ ] Search (placeholder)
  - [ ] Settings (placeholder)

**Deliverable:** ✅ **MILESTONE 1** - Auth working, navigation smooth

---

### Week 3: Speed Tracking - Part 1
**Goal:** GPS-based speed tracking works

#### Tasks
- [ ] **W3.1** Set up location permissions
  - [ ] Create `PermissionService`
  - [ ] Handle all permission states
  - [ ] Create permission request UI
  
- [ ] **W3.2** Implement GPS tracking
  - [ ] Install `geolocator`
  - [ ] Create `LocationService`
  - [ ] Get current position
  - [ ] Start position stream
  - [ ] Calculate speed from GPS
  
- [ ] **W3.3** Build speedometer UI
  - [ ] Create `SpeedometerWidget`
  - [ ] Implement circular progress ring
  - [ ] Large speed number display
  - [ ] Speed limit warning state
  
- [ ] **W3.4** Home screen - Idle state
  - [ ] Floating search bar (non-functional placeholder)
  - [ ] Safety tip ticker
  - [ ] Speedometer display
  - [ ] Location status indicator
  - [ ] "Start Tracking" button

**Deliverable:** Speed displays in real-time on Home screen

---

### Week 4: Speed Tracking - Part 2
**Goal:** Full trip tracking with history

#### Tasks
- [ ] **W4.1** Implement trip recording
  - [ ] Create `TripModel` Hive model
  - [ ] Start/stop trip functionality
  - [ ] Record speed points during trip
  - [ ] Calculate trip statistics
  
- [ ] **W4.2** Add accelerometer fusion
  - [ ] Install `sensors_plus`
  - [ ] Create `AccelerometerService`
  - [ ] Implement Kalman filter smoothing
  - [ ] Fuse GPS + accelerometer data
  
- [ ] **W4.3** Home screen - Tracking state
  - [ ] Recording indicator
  - [ ] Live stats display (top/avg/distance)
  - [ ] "Stop Tracking" button
  - [ ] Speed alert warning
  
- [ ] **W4.4** Trip summary screen
  - [ ] Display trip statistics
  - [ ] Placeholder for map
  - [ ] "Save Trip" action
  - [ ] Prompt to rate driver
  
- [ ] **W4.5** Save trips to Hive
  - [ ] Store completed trips locally
  - [ ] List trips in Stats tab
  - [ ] Trip detail view

**Deliverable:** ✅ **MILESTONE 2** - Complete trip can be recorded and saved

---

### Week 5: Rating System
**Goal:** User can rate drivers

#### Tasks
- [ ] **W5.1** Create rating data models
  - [ ] `DriverModel` for Hive
  - [ ] `RatingModel` for Hive
  - [ ] Register TypeAdapters
  
- [ ] **W5.2** Build rating flow UI
  - [ ] Good/Bad selection screen
  - [ ] Tag chips for quick feedback
  - [ ] Optional comment field
  - [ ] Submit confirmation
  
- [ ] **W5.3** Implement manual plate entry
  - [ ] Plate number text field
  - [ ] Ghana plate format validation
  - [ ] Plate confirmation screen
  
- [ ] **W5.4** Store ratings locally
  - [ ] Save to `ratings_box`
  - [ ] Update `drivers_box` with aggregate
  - [ ] Queue for cloud sync
  
- [ ] **W5.5** Build driver detail screen
  - [ ] Display plate number
  - [ ] Show rating summary
  - [ ] Show common tags
  - [ ] "Rate this driver" action

**Deliverable:** Can manually enter plate and submit rating

---

### Week 6: OCR Number Plate Scanning
**Goal:** Camera can scan and recognize plates

#### Tasks
- [ ] **W6.1** Set up camera
  - [ ] Install `image_picker` or `camera`
  - [ ] Request camera permission
  - [ ] Create camera preview screen
  
- [ ] **W6.2** Integrate ML Kit OCR
  - [ ] Install `google_mlkit_text_recognition`
  - [ ] Create `OcrService`
  - [ ] Process image for text
  
- [ ] **W6.3** Ghana plate pattern matching
  - [ ] Define regex patterns (GR-XXXX-XX, etc.)
  - [ ] Extract plate from OCR results
  - [ ] Handle multiple plates detected
  
- [ ] **W6.4** OCR UI flow
  - [ ] Camera viewfinder with guide box
  - [ ] Capture button
  - [ ] Processing indicator
  - [ ] Result display with edit option
  
- [ ] **W6.5** Connect OCR to rating flow
  - [ ] Scan → Confirm → Rate
  - [ ] Handle OCR failures gracefully
  - [ ] "Enter manually" fallback

**Deliverable:** ✅ **MILESTONE 3** - Scan plate and rate driver end-to-end

---

### Week 7: Maps - Part 1
**Goal:** Display maps with location

#### Tasks
- [ ] **W7.1** Set up Google Maps (online)
  - [ ] Install `google_maps_flutter`
  - [ ] Get API key from Google Cloud
  - [ ] Configure Android/iOS
  - [ ] Basic map display
  
- [ ] **W7.2** Set up OpenStreetMap (offline fallback)
  - [ ] Install `flutter_map`
  - [ ] Install `flutter_map_tile_caching`
  - [ ] Basic OSM display
  - [ ] Tile caching setup
  
- [ ] **W7.3** Create hybrid map widget
  - [ ] Detect online/offline status
  - [ ] Switch between providers
  - [ ] Consistent styling
  
- [ ] **W7.4** Show current location
  - [ ] Center on user position
  - [ ] Location marker
  - [ ] Map controls (zoom, recenter)
  
- [ ] **W7.5** Home screen map integration
  - [ ] Mini map during tracking
  - [ ] Expand to fullscreen

**Deliverable:** Map shows current location, works offline

---

### Week 8: Maps - Part 2 (Routes)
**Goal:** Display trip routes on map

#### Tasks
- [ ] **W8.1** Record route points
  - [ ] Store lat/lng during trip
  - [ ] Optimize point frequency
  - [ ] Save route with trip
  
- [ ] **W8.2** Display route polyline
  - [ ] Draw line on map
  - [ ] Color code by speed
  - [ ] Start/end markers
  
- [ ] **W8.3** Trip summary with map
  - [ ] Show complete route
  - [ ] Animate route drawing
  - [ ] Trip stats overlay
  
- [ ] **W8.4** Map region download
  - [ ] Region picker UI
  - [ ] Download progress
  - [ ] Storage management
  
- [ ] **W8.5** Polish map interactions
  - [ ] Smooth transitions
  - [ ] Gesture handling
  - [ ] Performance optimization

**Deliverable:** ✅ **MILESTONE 4** - Trips show routes on map

---

### Week 9: Cloud Sync & Stats
**Goal:** Data syncs to Firebase

#### Tasks
- [ ] **W9.1** Implement sync service
  - [ ] Process sync queue
  - [ ] Handle connectivity changes
  - [ ] Retry logic
  - [ ] Conflict resolution
  
- [ ] **W9.2** Sync trips to Firebase
  - [ ] Upload completed trips
  - [ ] Update user stats
  - [ ] Handle partial uploads
  
- [ ] **W9.3** Sync ratings to Firebase
  - [ ] Upload new ratings
  - [ ] Update driver aggregates (Cloud Function)
  - [ ] Refresh driver cache
  
- [ ] **W9.4** Stats tab completion
  - [ ] User statistics dashboard
  - [ ] Trip history list
  - [ ] Pull to refresh
  
- [ ] **W9.5** Search functionality
  - [ ] Search local drivers
  - [ ] Fetch from cloud if not found
  - [ ] Recent searches

**Deliverable:** ✅ **MILESTONE 5** - Data persists to cloud

---

### Week 10: Polish & Beta
**Goal:** App is ready for beta testing

#### Tasks
- [ ] **W10.1** Settings screen completion
  - [ ] Profile editing
  - [ ] Theme toggle
  - [ ] Speed limit setting
  - [ ] Notification preferences
  
- [ ] **W10.2** Error handling
  - [ ] Network error states
  - [ ] Permission denied states
  - [ ] Graceful fallbacks
  
- [ ] **W10.3** Loading states & animations
  - [ ] Skeleton loaders
  - [ ] Button loading states
  - [ ] Page transitions
  
- [ ] **W10.4** Performance optimization
  - [ ] Profile app performance
  - [ ] Fix memory leaks
  - [ ] Reduce battery usage
  
- [ ] **W10.5** Testing & bug fixes
  - [ ] Manual testing checklist
  - [ ] Fix critical bugs
  - [ ] Device testing (various Android)
  
- [ ] **W10.6** Build beta APK
  - [ ] Configure release signing
  - [ ] Build release APK
  - [ ] Internal testing

**Deliverable:** ✅ **MILESTONE 6** - Beta APK delivered to client

---

## 📊 Progress Tracker

### Overall Progress
```
Week 1:  ░░░░░░░░░░ 0%
Week 2:  ░░░░░░░░░░ 0%
Week 3:  ░░░░░░░░░░ 0%
Week 4:  ░░░░░░░░░░ 0%
Week 5:  ░░░░░░░░░░ 0%
Week 6:  ░░░░░░░░░░ 0%
Week 7:  ░░░░░░░░░░ 0%
Week 8:  ░░░░░░░░░░ 0%
Week 9:  ░░░░░░░░░░ 0%
Week 10: ░░░░░░░░░░ 0%
```

### Milestone Status
| Milestone | Status | Notes |
|-----------|--------|-------|
| M1 - Auth & Nav | ⬜ Not Started | |
| M2 - Speed Tracking | ⬜ Not Started | |
| M3 - OCR & Ratings | ⬜ Not Started | |
| M4 - Maps & Routes | ⬜ Not Started | |
| M5 - Cloud Sync | ⬜ Not Started | |
| M6 - Beta Release | ⬜ Not Started | |

---

## 🔧 Technical Decisions Log

| Decision | Choice | Rationale |
|----------|--------|-----------|
| State Management | Riverpod 3.x | Modern, testable, good docs |
| Local Storage | Hive | Fast, no native deps, offline-first |
| Cloud DB | Firebase Firestore | Real-time sync, easy auth |
| Maps (Online) | Google Maps | Best accuracy for Ghana |
| Maps (Offline) | flutter_map + OSM | Free, cacheable |
| OCR | Google ML Kit | On-device, free, accurate |
| Navigation | go_router | Declarative, deep linking |

---

## ⚠️ Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| OCR accuracy on dusty plates | Medium | High | Image preprocessing, manual fallback |
| GPS jitter in poor signal | High | Medium | Kalman filter, accelerometer fusion |
| Firebase costs scaling | Low | Medium | Aggressive caching, local-first |
| Play Store approval delays | Medium | Low | Start submission early |

---

**Document Version:** 1.0  
**Last Updated:** [Auto-generated]
