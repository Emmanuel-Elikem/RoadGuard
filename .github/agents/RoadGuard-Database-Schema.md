# RoadGuard Database Schema

> Complete data structure for Hive (local) and Firebase (cloud).

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        DATA FLOW                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌──────────────┐         ┌──────────────┐                    │
│   │   UI Layer   │◄───────►│   Riverpod   │                    │
│   │  (Widgets)   │         │  (Providers) │                    │
│   └──────────────┘         └──────┬───────┘                    │
│                                   │                             │
│                          ┌────────▼────────┐                    │
│                          │   Repository    │                    │
│                          │    Layer        │                    │
│                          └────────┬────────┘                    │
│                                   │                             │
│              ┌────────────────────┼────────────────────┐       │
│              ▼                    ▼                    ▼        │
│   ┌──────────────────┐  ┌──────────────────┐  ┌────────────┐  │
│   │   Hive (Local)   │  │  Firebase Cloud  │  │   Sync     │  │
│   │   Primary Data   │  │  Secondary/Backup│  │   Queue    │  │
│   └──────────────────┘  └──────────────────┘  └────────────┘  │
│                                                                 │
│   OFFLINE-FIRST: Read/Write to Hive → Sync to Firebase later   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📦 Hive Local Storage

### Box Structure

| Box Name | Type | Purpose | Sync to Cloud? |
|----------|------|---------|----------------|
| `user_box` | `Box<UserModel>` | Current user profile | ✅ Yes |
| `trips_box` | `Box<TripModel>` | Trip history | ✅ Yes |
| `drivers_box` | `Box<DriverModel>` | Cached driver ratings | ✅ Yes (read) |
| `ratings_box` | `Box<RatingModel>` | User's submitted ratings | ✅ Yes |
| `settings_box` | `Box` | App settings | ❌ Local only |
| `sync_queue_box` | `Box<SyncOperation>` | Pending sync operations | N/A (Queue) |
| `cache_box` | `Box` | Misc cached data | ❌ Local only |

---

### Hive Models

#### UserModel (typeId: 0)
```dart
@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  final String id;                    // Firebase UID
  
  @HiveField(1)
  final String? email;
  
  @HiveField(2)
  final String? displayName;
  
  @HiveField(3)
  final String? photoUrl;
  
  @HiveField(4)
  final DateTime createdAt;
  
  @HiveField(5)
  final DateTime lastLoginAt;
  
  @HiveField(6)
  final bool isGuest;                 // True if anonymous
  
  // Stats (calculated locally, synced periodically)
  @HiveField(10)
  int totalTrips;
  
  @HiveField(11)
  double totalDistance;               // in km
  
  @HiveField(12)
  int totalRatingsGiven;
  
  @HiveField(13)
  double averageSpeed;                // km/h
  
  @HiveField(14)
  double topSpeed;                    // km/h all-time
}
```

#### TripModel (typeId: 1)
```dart
@HiveType(typeId: 1)
class TripModel extends HiveObject {
  @HiveField(0)
  final String id;                    // UUID
  
  @HiveField(1)
  final String? userId;               // Owner (null if guest)
  
  @HiveField(2)
  final DateTime startTime;
  
  @HiveField(3)
  final DateTime? endTime;
  
  @HiveField(4)
  final double? startLat;
  
  @HiveField(5)
  final double? startLng;
  
  @HiveField(6)
  final double? endLat;
  
  @HiveField(7)
  final double? endLng;
  
  @HiveField(8)
  final String? startAddress;         // Reverse geocoded
  
  @HiveField(9)
  final String? endAddress;
  
  // Trip statistics
  @HiveField(10)
  double distance;                    // km
  
  @HiveField(11)
  double avgSpeed;                    // km/h
  
  @HiveField(12)
  double topSpeed;                    // km/h
  
  @HiveField(13)
  int duration;                       // seconds
  
  @HiveField(14)
  int speedAlertCount;                // Times exceeded limit
  
  // Route data (stored as JSON string for efficiency)
  @HiveField(20)
  String? routePointsJson;            // List<LatLng> as JSON
  
  @HiveField(21)
  String? speedLogJson;               // List<SpeedPoint> as JSON
  
  // Sync status
  @HiveField(30)
  bool isSynced;
  
  @HiveField(31)
  DateTime? lastSyncAt;
}
```

#### SpeedPoint (not stored directly, embedded in JSON)
```dart
class SpeedPoint {
  final double lat;
  final double lng;
  final double speed;                 // km/h
  final DateTime timestamp;
  final String source;                // 'gps' | 'accelerometer' | 'fused'
}
```

#### DriverModel (typeId: 2)
```dart
@HiveType(typeId: 2)
class DriverModel extends HiveObject {
  @HiveField(0)
  final String plateNumber;           // Primary key (e.g., "GR-1234-21")
  
  @HiveField(1)
  double averageRating;               // 1.0 - 5.0
  
  @HiveField(2)
  int totalRatings;
  
  @HiveField(3)
  int goodRatings;                    // Count of positive
  
  @HiveField(4)
  int badRatings;                     // Count of negative
  
  @HiveField(5)
  List<String> commonTags;            // Most frequent tags
  
  @HiveField(6)
  DateTime lastUpdated;               // From cloud
  
  @HiveField(7)
  String? region;                     // GR=Greater Accra, AS=Ashanti
}
```

#### RatingModel (typeId: 3)
```dart
@HiveType(typeId: 3)
class RatingModel extends HiveObject {
  @HiveField(0)
  final String id;                    // UUID
  
  @HiveField(1)
  final String plateNumber;           // Driver rated
  
  @HiveField(2)
  final String? raterId;              // Who rated (null if guest)
  
  @HiveField(3)
  final bool isGood;                  // true=good, false=bad
  
  @HiveField(4)
  final List<String> tags;            // ['safe', 'courteous', etc.]
  
  @HiveField(5)
  final String? comment;              // Optional text
  
  @HiveField(6)
  final DateTime createdAt;
  
  @HiveField(7)
  final double? lat;                  // Where rating was given
  
  @HiveField(8)
  final double? lng;
  
  // Sync status
  @HiveField(10)
  bool isSynced;
  
  @HiveField(11)
  DateTime? syncedAt;
}
```

#### SyncOperation (typeId: 10)
```dart
@HiveType(typeId: 10)
class SyncOperation extends HiveObject {
  @HiveField(0)
  final String id;                    // UUID
  
  @HiveField(1)
  final String operation;             // 'create' | 'update' | 'delete'
  
  @HiveField(2)
  final String collection;            // 'trips' | 'ratings' | 'users'
  
  @HiveField(3)
  final String documentId;            // Target document
  
  @HiveField(4)
  final String dataJson;              // Payload as JSON
  
  @HiveField(5)
  final DateTime createdAt;
  
  @HiveField(6)
  int retryCount;                     // Increment on failure
  
  @HiveField(7)
  String? lastError;                  // Last failure reason
}
```

---

## ☁️ Firebase Cloud Structure

### Firestore Collections

```
firestore/
│
├── users/
│   └── {uid}/
│       ├── email: string
│       ├── displayName: string
│       ├── photoUrl: string?
│       ├── createdAt: timestamp
│       ├── lastLoginAt: timestamp
│       ├── isGuest: boolean
│       │
│       ├── stats/
│       │   ├── totalTrips: number
│       │   ├── totalDistance: number
│       │   ├── totalRatingsGiven: number
│       │   ├── averageSpeed: number
│       │   └── topSpeed: number
│       │
│       └── settings/ (future: sync preferences)
│           └── ...
│
├── drivers/
│   └── {plateNumber}/                # e.g., "GR-1234-21"
│       ├── plateNumber: string
│       ├── region: string
│       ├── averageRating: number
│       ├── totalRatings: number
│       ├── goodRatings: number
│       ├── badRatings: number
│       ├── commonTags: array<string>
│       ├── lastUpdated: timestamp
│       │
│       └── ratings/ (subcollection)
│           └── {ratingId}/
│               ├── raterId: string
│               ├── isGood: boolean
│               ├── tags: array<string>
│               ├── comment: string?
│               ├── createdAt: timestamp
│               ├── location: geopoint?
│               └── tripId: string?
│
├── trips/
│   └── {tripId}/
│       ├── userId: string
│       ├── startTime: timestamp
│       ├── endTime: timestamp
│       ├── startLocation: geopoint
│       ├── endLocation: geopoint
│       ├── startAddress: string?
│       ├── endAddress: string?
│       ├── distance: number
│       ├── avgSpeed: number
│       ├── topSpeed: number
│       ├── duration: number
│       ├── speedAlertCount: number
│       │
│       └── route/ (subcollection, optional for detailed analysis)
│           └── {pointId}/
│               ├── lat: number
│               ├── lng: number
│               ├── speed: number
│               ├── timestamp: timestamp
│               └── source: string
│
├── leaderboards/
│   └── {regionId}/                   # e.g., "GR" for Greater Accra
│       ├── weekly/
│       │   └── {rank}/
│       │       ├── userId: string
│       │       ├── displayName: string
│       │       ├── score: number
│       │       └── updatedAt: timestamp
│       │
│       └── monthly/
│           └── ... (same structure)
│
└── communities/ (future feature)
    └── {communityId}/
        ├── name: string
        ├── description: string
        ├── createdBy: string
        ├── createdAt: timestamp
        ├── memberCount: number
        │
        ├── members/ (subcollection)
        │   └── {userId}/
        │       ├── role: string  # 'admin' | 'member'
        │       └── joinedAt: timestamp
        │
        └── posts/ (subcollection)
            └── {postId}/
                └── ...
```

---

## 🔄 Sync Strategy

### Priority Levels

| Priority | Data Type | Sync Frequency | Conflict Resolution |
|----------|-----------|----------------|---------------------|
| 🔴 High | Ratings | Immediate when online | Last-write-wins |
| 🟠 Medium | Trips | On trip end | Client wins |
| 🟡 Low | User stats | Every 15 min | Server wins |
| 🟢 Lowest | Driver cache | Daily refresh | Server is source |

### Sync Queue Processing

```dart
// Pseudo-code for sync queue
Future<void> processSyncQueue() async {
  if (!isOnline) return;
  
  final queue = Hive.box<SyncOperation>('sync_queue_box');
  
  for (final op in queue.values.toList()) {
    try {
      await _executeSyncOperation(op);
      await op.delete();  // Remove from queue on success
    } catch (e) {
      op.retryCount++;
      op.lastError = e.toString();
      await op.save();
      
      if (op.retryCount > 5) {
        // Move to dead letter queue or alert user
      }
    }
  }
}
```

### Offline Detection

```dart
// Use connectivity_plus
final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged;
});

// React to connectivity changes
ref.listen(connectivityProvider, (prev, next) {
  if (next == ConnectivityResult.none) {
    // Show offline banner
  } else {
    // Trigger sync queue processing
    ref.read(syncServiceProvider).processSyncQueue();
  }
});
```

---

## 📋 TypeId Registry

Keep track of Hive type IDs to avoid conflicts:

| typeId | Model | Status |
|--------|-------|--------|
| 0 | `UserModel` | Active |
| 1 | `TripModel` | Active |
| 2 | `DriverModel` | Active |
| 3 | `RatingModel` | Active |
| 4 | Reserved | - |
| 5 | Reserved | - |
| ... | ... | ... |
| 10 | `SyncOperation` | Active |
| 11 | Reserved | - |
| 20+ | Future models | - |

---

## 🔐 Security Rules (Firestore)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users: Only owner can read/write
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Drivers: Anyone can read, authenticated can create ratings
    match /drivers/{plateNumber} {
      allow read: if true;  // Public ratings
      allow write: if false; // Only via Cloud Functions
      
      match /ratings/{ratingId} {
        allow read: if true;
        allow create: if request.auth != null;
        allow update, delete: if false;  // Ratings are immutable
      }
    }
    
    // Trips: Only owner can access
    match /trips/{tripId} {
      allow read, write: if request.auth != null 
        && request.auth.uid == resource.data.userId;
      allow create: if request.auth != null;
    }
    
    // Leaderboards: Public read only
    match /leaderboards/{regionId}/{document=**} {
      allow read: if true;
      allow write: if false;  // Only via Cloud Functions
    }
  }
}
```

---

## 📊 Indexes Required

```yaml
# firestore.indexes.json
indexes:
  - collectionGroup: ratings
    fields:
      - fieldPath: plateNumber
        order: ASCENDING
      - fieldPath: createdAt
        order: DESCENDING
        
  - collectionGroup: trips
    fields:
      - fieldPath: userId
        order: ASCENDING
      - fieldPath: startTime
        order: DESCENDING
        
  - collectionGroup: drivers
    fields:
      - fieldPath: region
        order: ASCENDING
      - fieldPath: averageRating
        order: DESCENDING
```

---

**Document Version:** 1.0  
**Last Updated:** [Auto-generated]
