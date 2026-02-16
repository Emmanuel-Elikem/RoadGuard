# RoadGuard App Flow

> Complete user journeys and screen navigation for the road safety app.

---

## 🗺️ Navigation Structure

```
App Entry
    │
    ├── Splash Screen (1-2s)
    │       │
    │       └── Check Auth State
    │               │
    │               ├── [Not Authenticated] → Onboarding
    │               │
    │               └── [Authenticated] → Main App
    │
    ├── Onboarding Flow (First-time only)
    │       │
    │       ├── Welcome Slides (3 screens)
    │       ├── Permission Requests
    │       │       ├── Location Permission
    │       │       ├── Camera Permission
    │       │       └── Notification Permission
    │       │
    │       └── Auth Options
    │               ├── Sign Up with Email
    │               ├── Sign In with Google
    │               └── Continue as Guest
    │
    └── Main App (Bottom Navigation)
            │
            ├── 🏠 Home (Dashboard)
            ├── 📊 Stats (Trip History)
            ├── 🔍 Search (Driver Lookup)
            └── ⚙️ Settings (Profile)
```

---

## 📱 Screen-by-Screen Flow

### 1. Splash Screen
**Purpose:** App initialization, auth check

```
┌─────────────────────────────────────────┐
│                                         │
│                                         │
│                                         │
│            [App Logo]                   │
│                                         │
│           RoadGuard                     │
│                                         │
│          ●●○○ (loading)                 │
│                                         │
│                                         │
└─────────────────────────────────────────┘
```

**Logic:**
1. Initialize Hive
2. Initialize Firebase
3. Check `Hive.box('user').get('isLoggedIn')`
4. Route accordingly

**Transitions:**
- → Onboarding (first time)
- → Home (returning user)

---

### 2. Onboarding Slides (First Time Only)
**Purpose:** Introduce app features

**Slide 1: Speed Tracking**
```
┌─────────────────────────────────────────┐
│                                         │
│        [Speedometer Illustration]       │
│                                         │
│         Track Your Speed                │
│                                         │
│   Know how fast you're going,           │
│   stay within safe limits.              │
│                                         │
│               ○ ● ○                     │
│                                         │
│     [Skip]              [Next →]        │
└─────────────────────────────────────────┘
```

**Slide 2: Rate Drivers**
```
┌─────────────────────────────────────────┐
│                                         │
│        [Rating Illustration]            │
│                                         │
│         Rate Other Drivers              │
│                                         │
│   Scan number plates and rate           │
│   drivers to help others stay safe.     │
│                                         │
│               ○ ○ ●                     │
│                                         │
│     [Skip]              [Next →]        │
└─────────────────────────────────────────┘
```

**Slide 3: Community**
```
┌─────────────────────────────────────────┐
│                                         │
│        [Community Illustration]         │
│                                         │
│       Join the Community                │
│                                         │
│   Connect with other safe drivers       │
│   and make Ghana's roads safer.         │
│                                         │
│               ○ ○ ●                     │
│                                         │
│            [Get Started →]              │
└─────────────────────────────────────────┘
```

**Transitions:**
- [Skip] → Permission Request
- [Next] → Next Slide
- [Get Started] → Permission Request

---

### 3. Permission Request Screen
**Purpose:** Request required permissions

```
┌─────────────────────────────────────────┐
│                                         │
│         [Shield Icon]                   │
│                                         │
│       Enable Permissions                │
│                                         │
│   We need a few permissions to          │
│   keep you safe on the road.            │
│                                         │
│   ┌─────────────────────────────────┐   │
│   │ 📍 Location                     │   │
│   │ Track speed and routes          │   │
│   │                    [Required]   │   │
│   └─────────────────────────────────┘   │
│                                         │
│   ┌─────────────────────────────────┐   │
│   │ 📷 Camera                       │   │
│   │ Scan number plates              │   │
│   │                    [Optional]   │   │
│   └─────────────────────────────────┘   │
│                                         │
│   ┌─────────────────────────────────┐   │
│   │ 🔔 Notifications                │   │
│   │ Speed alerts                    │   │
│   │                    [Optional]   │   │
│   └─────────────────────────────────┘   │
│                                         │
│        [Continue →]                     │
│                                         │
└─────────────────────────────────────────┘
```

**Logic:**
1. Request Location (show native dialog)
2. If granted → Request Camera
3. If granted → Request Notifications
4. Handle denials gracefully

**Transitions:**
- Location denied permanently → Settings redirect
- All done → Auth Screen

---

### 4. Auth Screen
**Purpose:** User authentication

```
┌─────────────────────────────────────────┐
│                                         │
│  ←                                      │
│                                         │
│         Welcome to                      │
│         RoadGuard                       │
│                                         │
│   ┌─────────────────────────────────┐   │
│   │ ✉️  Email                        │   │
│   └─────────────────────────────────┘   │
│                                         │
│   ┌─────────────────────────────────┐   │
│   │ 🔒 Password                     │   │
│   └─────────────────────────────────┘   │
│                                         │
│        [Sign In]                        │
│                                         │
│        ─────── OR ───────               │
│                                         │
│   ┌─────────────────────────────────┐   │
│   │   [G] Continue with Google      │   │
│   └─────────────────────────────────┘   │
│                                         │
│     Don't have an account? Sign Up      │
│                                         │
│        Continue as Guest                │
│                                         │
└─────────────────────────────────────────┘
```

**States:**
- Sign In mode
- Sign Up mode (adds name field)
- Password reset flow

**Transitions:**
- Success → Home
- Continue as Guest → Home (limited features)

---

### 5. Home Dashboard
**Purpose:** Main hub, start speed check

**State: Idle**
```
┌─────────────────────────────────────────┐
│  👋 Hello, Kofi                         │
├─────────────────────────────────────────┤
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ 🔍 Search car number...            │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ 💡 Did you know? 70% of accidents..│ │
│ └─────────────────────────────────────┘ │
│                                         │
│            ╭───────────────╮            │
│           ╱                 ╲           │
│          │        0          │          │
│          │      km/h         │          │
│           ╲                 ╱           │
│            ╰───────────────╯            │
│                                         │
│     ┌───────────────────────────┐       │
│     │ ▶  START SPEED CHECK      │       │
│     └───────────────────────────┘       │
│                                         │
│   ┌───────────────────────────────┐     │
│   │ 🏠 │  📊  │  🔍  │  ⚙️      │     │
│   └───────────────────────────────┘     │
└─────────────────────────────────────────┘
```

**State: Tracking Active**
```
┌─────────────────────────────────────────┐
│  🔴 LIVE                         12:34  │
├─────────────────────────────────────────┤
│                                         │
│   ┌─────────────────────────────────┐   │
│   │ 🟡 Getting your location...     │   │ ← GPS Status Banner
│   └─────────────────────────────────┘   │   (auto-hides when good)
│                                         │
│            ╭───────────────╮            │
│           ╱                 ╲           │
│          │       85          │          │
│          │      km/h         │          │  ← Digits roll
│           ╲                 ╱           │     with animation
│            ╰───────────────╯            │
│                                         │
│   ┌────────┐ ┌────────┐ ┌────────┐     │
│   │   95   │ │   68   │ │  4.2   │     │
│   │FASTEST │ │AVERAGE │ │   KM   │     │
│   └────────┘ └────────┘ └────────┘     │
│                                         │
│     ┌───────────────────────────┐       │
│     │   ⏹  STOP                 │       │
│     └───────────────────────────┘       │
│                                         │
└─────────────────────────────────────────┘
```

**Interactions:**
- [START SPEED CHECK] → Begin GPS tracking, show GPS status banner
- [STOP] → End trip → Trip Summary
- Speed > limit → "Overspeeding! Slow down" toast (red)
- GPS signal weak/lost → Status banner slides in
- GPS signal good → Status banner auto-hides

---

### 6. Trip Summary
**Purpose:** Review completed trip, prompt rating

```
┌─────────────────────────────────────────┐
│  ←  Trip Summary                        │
├─────────────────────────────────────────┤
│                                         │
│   ┌─────────────────────────────────┐   │
│   │                                 │   │
│   │    [MAP WITH ROUTE LINE]        │   │
│   │     ●━━━━━━━━━━━━●             │   │
│   │   Achimota         Kaneshie     │   │
│   │                                 │   │
│   └─────────────────────────────────┘   │
│                                         │
│   ┌────────────────┐ ┌────────────────┐ │
│   │      95        │ │      68        │ │
│   │   TOP SPEED    │ │   AVG SPEED    │ │
│   └────────────────┘ └────────────────┘ │
│                                         │
│   ┌────────────────┐ ┌────────────────┐ │
│   │     4.2        │ │     00:23      │ │
│   │   DISTANCE     │ │   DURATION     │ │
│   └────────────────┘ └────────────────┘ │
│                                         │
│   ┌─────────────────────────────────┐   │
│   │ Rate a driver you encountered?  │   │
│   │                                 │   │
│   │     [📷 SCAN PLATE]            │   │
│   │                                 │   │
│   │       Skip for now              │   │
│   └─────────────────────────────────┘   │
│                                         │
│        [SAVE TRIP]                      │
│                                         │
└─────────────────────────────────────────┘
```

**Interactions:**
- [SCAN PLATE] → Camera (OCR) → Rating Flow
- [Skip for now] → Just save trip
- [SAVE TRIP] → Save to Hive → Queue sync → Home

---

### 7. Rating Flow
**Purpose:** Rate another driver

**Step 1: Scan Plate**
```
┌─────────────────────────────────────────┐
│  ←  Scan Number Plate                   │
├─────────────────────────────────────────┤
│                                         │
│   ┌─────────────────────────────────┐   │
│   │                                 │   │
│   │         [CAMERA VIEW]           │   │
│   │                                 │   │
│   │      ┌─────────────────┐        │   │
│   │      │  GR-1234-21     │        │   │
│   │      └─────────────────┘        │   │
│   │                                 │   │
│   └─────────────────────────────────┘   │
│                                         │
│   Position the plate within the box     │
│                                         │
│     ┌───────────────────────────┐       │
│     │    📸 CAPTURE             │       │
│     └───────────────────────────┘       │
│                                         │
│         [Enter manually]                │
│                                         │
└─────────────────────────────────────────┘
```

**Step 2: Confirm Plate**
```
┌─────────────────────────────────────────┐
│  ←  Confirm Plate                       │
├─────────────────────────────────────────┤
│                                         │
│   ┌─────────────────────────────────┐   │
│   │       Detected Plate            │   │
│   │                                 │   │
│   │        GR-1234-21               │   │
│   │                                 │   │
│   │       [Edit]                    │   │
│   └─────────────────────────────────┘   │
│                                         │
│           Is this correct?              │
│                                         │
│     ┌───────────────────────────┐       │
│     │    ✅ YES, CONTINUE       │       │
│     └───────────────────────────┘       │
│                                         │
│         [Scan again]                    │
│                                         │
└─────────────────────────────────────────┘
```

**Step 3: Rate Driver**
```
┌─────────────────────────────────────────┐
│  ←  Rate Driver                         │
├─────────────────────────────────────────┤
│                                         │
│         GR-1234-21                      │
│                                         │
│     How was this driver?                │
│                                         │
│   ┌────────────────┐ ┌────────────────┐ │
│   │                │ │                │ │
│   │      😊        │ │      😞        │ │
│   │                │ │                │ │
│   │     GOOD       │ │      BAD       │ │
│   │                │ │                │ │
│   └────────────────┘ └────────────────┘ │
│                                         │
│                                         │
│   Quick feedback (optional):            │
│                                         │
│   ┌──────────┐ ┌──────────┐ ┌────────┐ │
│   │Safe      │ │Courteous │ │Calm    │ │
│   └──────────┘ └──────────┘ └────────┘ │
│                                         │
│   ┌──────────────────────────────────┐  │
│   │ Add a comment (optional)...      │  │
│   └──────────────────────────────────┘  │
│                                         │
│     ┌───────────────────────────┐       │
│     │    SUBMIT RATING          │       │
│     └───────────────────────────┘       │
│                                         │
└─────────────────────────────────────────┘
```

**Interactions:**
- Tap GOOD/BAD → Select (animate)
- Tap chip → Toggle selection
- [SUBMIT] → Save locally → Queue sync → Success toast → Home

---

### 8. Stats Tab
**Purpose:** View trip history and personal stats

```
┌─────────────────────────────────────────┐
│  Your Trips                             │
├─────────────────────────────────────────┤
│                                         │
│   ┌────────────────┐ ┌────────────────┐ │
│   │      127       │ │     68.5       │ │
│   │    TRIPS       │ │  AVERAGE km/h  │ │
│   └────────────────┘ └────────────────┘ │
│                                         │
│   ┌────────────────┐ ┌────────────────┐ │
│   │     1,234      │ │      45        │ │
│   │  KM TRAVELLED  │ │ RATINGS GIVEN  │ │
│   └────────────────┘ └────────────────┘ │
│                                         │
│   Recent Trips                          │
│                                         │
│   ┌─────────────────────────────────┐   │
│   │ 📍 Achimota → Kaneshie          │   │
│   │    4.2 km • 23 min • Avg 52km/h │   │
│   │    Today, 2:30 PM               │   │
│   └─────────────────────────────────┘   │
│                                         │
│   ┌─────────────────────────────────┐   │
│   │ 📍 Osu → Airport City           │   │
│   │    8.1 km • 35 min • Avg 61km/h │   │
│   │    Yesterday, 8:15 AM           │   │
│   └─────────────────────────────────┘   │
│                                         │
│   ┌─────────────────────────────────┐   │
│   │ 📍 ... more trips               │   │
│   └─────────────────────────────────┘   │
│                                         │
│   ┌───────────────────────────────┐     │
│   │ 🏠 │  📊  │  🔍  │  ⚙️      │     │
│   └───────────────────────────────┘     │
└─────────────────────────────────────────┘
```

**Interactions:**
- Tap trip card → Trip Detail screen
- Pull to refresh → Sync from Firebase

---

### 9. Search Tab
**Purpose:** Look up driver ratings

```
┌─────────────────────────────────────────┐
│  Search Drivers                         │
├─────────────────────────────────────────┤
│                                         │
│   ┌─────────────────────────────────┐   │
│   │ 🔍 Enter number plate...        │   │
│   └─────────────────────────────────┘   │
│                                         │
│        OR                               │
│                                         │
│   ┌─────────────────────────────────┐   │
│   │   📷 SCAN WITH CAMERA           │   │
│   └─────────────────────────────────┘   │
│                                         │
│                                         │
│   Recent Searches                       │
│                                         │
│   ┌─────────────────────────────────┐   │
│   │ GR-1234-21     ★ 4.2  👍 85%   │   │
│   └─────────────────────────────────┘   │
│   ┌─────────────────────────────────┐   │
│   │ GT-5678-19     ★ 3.1  👍 62%   │   │
│   └─────────────────────────────────┘   │
│   ┌─────────────────────────────────┐   │
│   │ AS-9012-20     ★ 4.8  👍 96%   │   │
│   └─────────────────────────────────┘   │
│                                         │
│                                         │
│   ┌───────────────────────────────┐     │
│   │ 🏠 │  📊  │  🔍  │  ⚙️      │     │
│   └───────────────────────────────┘     │
└─────────────────────────────────────────┘
```

**Interactions:**
- Type plate → Real-time Hive search (offline) 
- [SCAN] → Camera OCR → Results
- Tap result → Driver Detail

---

### 10. Driver Detail
**Purpose:** View driver's full rating profile

```
┌─────────────────────────────────────────┐
│  ←  Driver Profile                      │
├─────────────────────────────────────────┤
│                                         │
│         ┌───────────────────┐           │
│         │                   │           │
│         │    GR-1234-21     │           │
│         │                   │           │
│         └───────────────────┘           │
│                                         │
│              ★ 4.2                      │
│          Based on 127 ratings           │
│                                         │
│   ┌────────────────┐ ┌────────────────┐ │
│   │      85%       │ │      15%       │ │
│   │     GOOD       │ │      BAD       │ │
│   │    (108)       │ │     (19)       │ │
│   └────────────────┘ └────────────────┘ │
│                                         │
│   Common Tags:                          │
│                                         │
│   ┌──────────┐ ┌──────────┐ ┌────────┐ │
│   │Safe (45) │ │Courteous │ │Calm    │ │
│   └──────────┘ └──────────┘ └────────┘ │
│                                         │
│   Recent Comments:                      │
│                                         │
│   ┌─────────────────────────────────┐   │
│   │ "Very careful driver, would     │   │
│   │  recommend!" - Anonymous        │   │
│   │  2 days ago                     │   │
│   └─────────────────────────────────┘   │
│                                         │
│     ┌───────────────────────────┐       │
│     │    ✏️ RATE THIS DRIVER    │       │
│     └───────────────────────────┘       │
│                                         │
└─────────────────────────────────────────┘
```

**Interactions:**
- [RATE THIS DRIVER] → Rating Flow (skip scan)
- Tap tag → Show who gave this tag

---

### 11. Settings Tab
**Purpose:** User profile and app settings

```
┌─────────────────────────────────────────┐
│  Settings                               │
├─────────────────────────────────────────┤
│                                         │
│   ┌─────────────────────────────────┐   │
│   │  👤  Kofi Mensah                │   │
│   │      kofi@email.com             │   │
│   │      [Edit Profile]             │   │
│   └─────────────────────────────────┘   │
│                                         │
│   App Settings                          │
│                                         │
│   ┌─────────────────────────────────┐   │
│   │ 🌙 Dark Mode              [ON]  │   │
│   ├─────────────────────────────────┤   │
│   │ 📍 Track when app is     [ON]   │   │
│   │    closed                        │   │
│   ├─────────────────────────────────┤   │
│   │ 🔔 Speed Warning         [ON]   │   │
│   ├─────────────────────────────────┤   │
│   │ ⚡ Speed Limit           50km/h │   │
│   └─────────────────────────────────┘   │
│                                         │
│   Data                                  │
│                                         │
│   ┌─────────────────────────────────┐   │
│   │ 🔄 Save Online         Last: 2m │   │
│   ├─────────────────────────────────┤   │
│   │ 📦 Saved Data         245 MB    │   │
│   ├─────────────────────────────────┤   │
│   │ 🗺️ Download Maps              →│   │
│   └─────────────────────────────────┘   │
│                                         │
│   ┌─────────────────────────────────┐   │
│   │ ℹ️ About                       →│   │
│   ├─────────────────────────────────┤   │
│   │ 🚪 Sign Out                     │   │
│   └─────────────────────────────────┘   │
│                                         │
│   ┌───────────────────────────────┐     │
│   │ 🏠 │  📊  │  🔍  │  ⚙️      │     │
│   └───────────────────────────────┘     │
└─────────────────────────────────────────┘
```

**Interactions:**
- Toggle settings → Save immediately
- [Save Online] → Push data to cloud
- [Download Maps] → Map region picker
- [Sign Out] → Confirm dialog → Clear → Auth screen

---

## 🔄 State Management

### Global App State (Riverpod)
```dart
// Authentication state
authStateProvider       // User | null

// Location state  
locationProvider        // Position | null
isTrackingProvider      // bool
currentTripProvider     // Trip | null

// User data
userProfileProvider     // UserProfile
userStatsProvider       // UserStats
userTripsProvider       // List<Trip>

// Settings
settingsProvider        // AppSettings
themeProvider           // ThemeMode

// Connectivity
connectivityProvider    // ConnectivityStatus
syncStatusProvider      // SyncStatus
```

### Offline Behavior
| Action | Offline | Online |
|--------|---------|--------|
| Start tracking | ✅ Works | ✅ Works |
| Save trip | ✅ Saves to Hive | ✅ Saves + syncs |
| Rate driver | ✅ Queued | ✅ Instant |
| Search plate | ✅ Local only | ✅ Local + cloud |
| View stats | ✅ Cached | ✅ Fresh data |

---

## ⚠️ Error States

### No Location Permission
```
┌─────────────────────────────────────────┐
│                                         │
│            🚫                           │
│                                         │
│   Location Access Required              │
│                                         │
│   To track your speed, we need          │
│   access to your location.              │
│                                         │
│     [Open Settings]                     │
│                                         │
└─────────────────────────────────────────┘
```

### Offline Mode Banner
```
┌─────────────────────────────────────────┐
│ ⚡ You're offline. Data will sync later.│
└─────────────────────────────────────────┘
```

### OCR Failed
```
┌─────────────────────────────────────────┐
│                                         │
│   Couldn't read the plate               │
│                                         │
│   [Try again]  [Enter manually]         │
│                                         │
└─────────────────────────────────────────┘
```

---

## 🎯 Key User Journeys

### Journey 1: First-Time User
```
Splash → Onboarding Slides → Permissions → Auth (Sign Up) → Home
```

### Journey 2: Daily Commute
```
Home → Start Tracking → [Drive] → Stop → Trip Summary → (Optional: Rate) → Home
```

### Journey 3: Check a Driver
```
Search Tab → Scan Plate / Type Plate → View Driver → (Optional: Rate) → Back
```

### Journey 4: Rate After Incident
```
Home → Search Tab → Scan Plate → Driver Detail → Rate (BAD) → Add Comment → Submit
```

---

**Document Version:** 1.0  
**Last Updated:** [Auto-generated]
