# RoadGuard Backend Logic & Error Handling

> **PURPOSE:** Complete backend architecture, error handling, retry logic, and edge case solutions. Read this BEFORE implementing any backend/service code.

---

## 🚨 CRITICAL MINDSET

> "A junior developer hopes everything works; a world-class senior developer **assumes everything will break** and plans for it."

Every piece of code must answer:
1. What happens when this fails?
2. What happens when the network dies mid-operation?
3. What happens when the user does something stupid?
4. What happens when 50,000 users do this simultaneously?

---

## 📊 System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           USER DEVICE                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                │
│  │   UI Layer  │◄──►│  Providers  │◄──►│ Repositories│                │
│  │  (Widgets)  │    │ (Riverpod)  │    │  (Abstract) │                │
│  └─────────────┘    └─────────────┘    └──────┬──────┘                │
│                                               │                         │
│                     ┌─────────────────────────┼─────────────────────┐  │
│                     │                         │                     │  │
│                     ▼                         ▼                     ▼  │
│           ┌─────────────────┐       ┌─────────────────┐   ┌──────────┐│
│           │  Local Source   │       │  Remote Source  │   │  Sync    ││
│           │     (Hive)      │       │   (Firebase)    │   │  Queue   ││
│           │                 │       │                 │   │          ││
│           │ • Trip State    │       │ • Auth          │   │ • Pending││
│           │ • Cached Data   │       │ • Firestore     │   │ • Retry  ││
│           │ • Settings      │       │ • Storage       │   │ • Failed ││
│           └─────────────────┘       └─────────────────┘   └──────────┘│
│                     │                         │                        │
│                     └────────────┬────────────┘                        │
│                                  │                                     │
│                     ┌────────────▼────────────┐                        │
│                     │    Connectivity         │                        │
│                     │    Service              │                        │
│                     │                         │                        │
│                     │  Online? → Sync Queue   │                        │
│                     │  Offline? → Queue Ops   │                        │
│                     └─────────────────────────┘                        │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ HTTPS / WebSocket
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         FIREBASE BACKEND                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐        │
│  │  Firebase Auth  │  │    Firestore    │  │ Cloud Functions │        │
│  │                 │  │                 │  │                 │        │
│  │ • Email/Pass    │  │ • users/        │  │ • onRatingCreate│        │
│  │ • Google Auth   │  │ • drivers/      │  │ • calcLeaderbd  │        │
│  │ • Anonymous     │  │ • trips/        │  │ • cleanupData   │        │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘        │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 The Golden Rule: Offline-First Flow

```
EVERY write operation follows this flow:

1. Validate input locally
2. Write to Hive IMMEDIATELY (success = user sees feedback)
3. Add to Sync Queue
4. Attempt Firebase upload (async, don't block UI)
5. On success: Mark synced, remove from queue
6. On failure: Increment retry counter, schedule retry
7. On persistent failure: Move to dead letter queue, notify user
```

**Code Pattern:**
```dart
Future<Result<T>> saveData<T>(T data) async {
  // 1. Validate
  final validation = validate(data);
  if (validation.isFailure) return Result.failure(validation.error);
  
  // 2. Save locally FIRST (this is the "source of truth" until synced)
  await _hiveBox.put(data.id, data);
  
  // 3. Queue for sync
  await _syncQueue.enqueue(SyncOperation(
    id: uuid.v4(),
    type: SyncType.create,
    collection: 'trips',
    documentId: data.id,
    payload: data.toJson(),
    createdAt: DateTime.now(),
  ));
  
  // 4. Attempt sync (fire and forget - don't await)
  _syncService.processQueue(); // No await!
  
  // 5. Return success immediately (user doesn't wait for network)
  return Result.success(data);
}
```

---

## 🚦 Error Code Registry

### Standard Error Codes

| Code | Name | Description | User Message | Retry? |
|------|------|-------------|--------------|--------|
| `E001` | `NETWORK_UNAVAILABLE` | No internet connection | "You're offline. Data saved locally." | Auto when online |
| `E002` | `NETWORK_TIMEOUT` | Request timed out | "Connection slow. Retrying..." | Yes, with backoff |
| `E003` | `SERVER_ERROR` | Firebase 5xx error | "Server busy. We'll retry automatically." | Yes, with backoff |
| `E004` | `UNAUTHORIZED` | Auth token expired | "Please sign in again." | No, re-auth needed |
| `E005` | `FORBIDDEN` | Permission denied | "You don't have access to this." | No |
| `E006` | `NOT_FOUND` | Document doesn't exist | "Data not found." | No |
| `E007` | `CONFLICT` | Duplicate or version conflict | (Handle silently) | No, resolve conflict |
| `E008` | `RATE_LIMITED` | Too many requests | "Slow down! Try again in a moment." | Yes, long delay |
| `E009` | `QUOTA_EXCEEDED` | Firebase quota hit | "Service temporarily unavailable." | Yes, long delay |
| `E010` | `VALIDATION_ERROR` | Invalid input data | "Please check your input." | No, fix input |
| `E011` | `GPS_UNAVAILABLE` | Location permission denied | "Location access required." | No, need permission |
| `E012` | `GPS_TIMEOUT` | Couldn't get location | "Couldn't get your location. Trying again..." | Yes |
| `E013` | `CAMERA_UNAVAILABLE` | Camera permission denied | "Camera access required for scanning." | No |
| `E014` | `OCR_FAILED` | Couldn't read plate | "Couldn't read the plate. Try again or enter manually." | Yes (user retries) |
| `E015` | `SYNC_FAILED` | Sync operation failed | (Silent, auto-retry) | Yes |
| `E016` | `TRIP_RECOVERY_NEEDED` | Crashed mid-trip | "We found an unfinished trip. Resume?" | N/A |

### Error Classification

```dart
enum ErrorSeverity {
  recoverable,    // Can retry automatically
  userAction,     // User needs to do something
  fatal,          // Cannot proceed
}

enum RetryStrategy {
  none,           // Don't retry
  immediate,      // Retry once immediately
  exponential,    // Exponential backoff
  userInitiated,  // Wait for user to retry
}
```

---

## 🔁 Retry Logic: Exponential Backoff

### The Algorithm

```dart
class RetryConfig {
  static const int maxAttempts = 5;
  static const Duration baseDelay = Duration(seconds: 2);
  static const Duration maxDelay = Duration(minutes: 5);
  static const double jitterFactor = 0.3; // ±30% randomness
  
  static Duration getDelay(int attempt) {
    // delay = base × 2^attempt
    final exponentialDelay = baseDelay * pow(2, attempt);
    
    // Cap at max
    final cappedDelay = exponentialDelay > maxDelay ? maxDelay : exponentialDelay;
    
    // Add jitter to prevent "thundering herd"
    final jitter = Random().nextDouble() * jitterFactor * 2 - jitterFactor;
    final jitteredDelay = cappedDelay * (1 + jitter);
    
    return jitteredDelay;
  }
}
```

### Retry Schedule Example

| Attempt | Base Delay | With Jitter (example) |
|---------|------------|----------------------|
| 1 | 2s | 1.4s - 2.6s |
| 2 | 4s | 2.8s - 5.2s |
| 3 | 8s | 5.6s - 10.4s |
| 4 | 16s | 11.2s - 20.8s |
| 5 | 32s | 22.4s - 41.6s |
| 6+ | STOP | Move to dead letter queue |

### Why Jitter?

Without jitter, if 1000 users lose connection at the same time:
- All retry at exactly 2s → Server overloaded
- All retry at exactly 4s → Server overloaded again

With jitter, the 1000 users spread their retries across 1.4s-2.6s window, reducing spike.

---

## 📦 Sync Queue System

### Queue Structure

```dart
@HiveType(typeId: 10)
class SyncOperation extends HiveObject {
  @HiveField(0)
  final String id;                    // UUID for idempotency
  
  @HiveField(1)
  final String operationType;         // 'create' | 'update' | 'delete'
  
  @HiveField(2)
  final String collection;            // Firestore collection name
  
  @HiveField(3)
  final String documentId;            // Target document
  
  @HiveField(4)
  final String payloadJson;           // Data as JSON string
  
  @HiveField(5)
  final DateTime createdAt;           // When operation was created
  
  @HiveField(6)
  final DateTime? scheduledAt;        // When to attempt next (for backoff)
  
  @HiveField(7)
  int attemptCount;                   // Number of attempts
  
  @HiveField(8)
  String? lastError;                  // Last error message
  
  @HiveField(9)
  String? idempotencyKey;             // Hash for deduplication
  
  @HiveField(10)
  SyncPriority priority;              // high, medium, low
}

enum SyncPriority { high, medium, low }
```

### Queue Processing Logic

```dart
class SyncQueueService {
  final Box<SyncOperation> _queue;
  final FirebaseService _firebase;
  final ConnectivityService _connectivity;
  
  bool _isProcessing = false;
  
  Future<void> processQueue() async {
    // Prevent concurrent processing
    if (_isProcessing) return;
    _isProcessing = true;
    
    try {
      // Check connectivity
      if (!await _connectivity.isOnline) {
        _isProcessing = false;
        return;
      }
      
      // Get pending operations (sorted by priority, then by createdAt)
      final pending = _queue.values
          .where((op) => op.scheduledAt == null || 
                         op.scheduledAt!.isBefore(DateTime.now()))
          .toList()
        ..sort((a, b) {
          // High priority first
          final priorityCompare = a.priority.index.compareTo(b.priority.index);
          if (priorityCompare != 0) return priorityCompare;
          // Then oldest first
          return a.createdAt.compareTo(b.createdAt);
        });
      
      for (final operation in pending) {
        await _processOperation(operation);
      }
    } finally {
      _isProcessing = false;
    }
  }
  
  Future<void> _processOperation(SyncOperation op) async {
    try {
      // Check idempotency - has this already been processed?
      if (await _firebase.operationExists(op.idempotencyKey)) {
        await op.delete(); // Already done, remove from queue
        return;
      }
      
      // Execute the operation
      await _executeOperation(op);
      
      // Success! Remove from queue
      await op.delete();
      
    } on NetworkException catch (e) {
      // Network error - schedule retry
      op.attemptCount++;
      op.lastError = e.toString();
      
      if (op.attemptCount >= RetryConfig.maxAttempts) {
        // Move to dead letter queue
        await _moveToDeadLetter(op);
      } else {
        // Schedule retry with exponential backoff
        op.scheduledAt = DateTime.now().add(
          RetryConfig.getDelay(op.attemptCount),
        );
        await op.save();
      }
      
    } on PermanentException catch (e) {
      // Permanent error (validation, auth) - don't retry
      await _moveToDeadLetter(op);
    }
  }
  
  Future<void> _moveToDeadLetter(SyncOperation op) async {
    // Store in separate "dead letter" box for manual review
    final deadLetterBox = Hive.box<SyncOperation>('dead_letter_queue');
    await deadLetterBox.put(op.id, op);
    await op.delete(); // Remove from main queue
    
    // Notify user if important
    if (op.priority == SyncPriority.high) {
      _notifyUser('Some data couldn\'t sync. Check Settings > Sync Status.');
    }
  }
}
```

### Sync Triggers

```dart
// When to process the sync queue:

// 1. App comes to foreground
WidgetsBindingObserver.didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    _syncService.processQueue();
  }
}

// 2. Network connectivity restored
_connectivity.onConnectivityChanged.listen((status) {
  if (status != ConnectivityResult.none) {
    _syncService.processQueue();
  }
});

// 3. After any local write operation
await _hiveBox.put(data);
_syncService.processQueue(); // Fire and forget

// 4. Periodic background sync (WorkManager)
Workmanager().registerPeriodicTask(
  'sync-queue-periodic',
  'processSync',
  frequency: Duration(minutes: 15),
  constraints: Constraints(
    networkType: NetworkType.connected,
    requiresBatteryNotLow: true,
  ),
);

// 5. Manual "Sync Now" button in settings
onPressed: () => _syncService.processQueue(force: true);
```

---

## 🔑 Idempotency: Preventing Duplicates

### The Problem

User with poor 3G clicks "Submit Rating" 5 times. Without protection:
- 5 ratings created
- Driver's average is skewed
- Database is polluted

### The Solution: Idempotency Keys

```dart
String generateIdempotencyKey(RatingModel rating) {
  // Create a unique fingerprint of this specific operation
  final components = [
    rating.raterId,
    rating.plateNumber,
    rating.createdAt.toIso8601String(),
    rating.isGood.toString(),
    rating.tags.join(','),
  ].join('|');
  
  // Hash it for a consistent key
  return sha256.convert(utf8.encode(components)).toString();
}
```

### Server-Side Check (Cloud Function)

```typescript
// Firebase Cloud Function
export const onRatingCreate = functions.firestore
  .document('drivers/{plateNumber}/ratings/{ratingId}')
  .onCreate(async (snap, context) => {
    const rating = snap.data();
    const idempotencyKey = rating.idempotencyKey;
    
    // Check if we've seen this key before
    const existingRef = admin.firestore()
      .collection('idempotency_keys')
      .doc(idempotencyKey);
    
    const existing = await existingRef.get();
    if (existing.exists) {
      // Duplicate! Delete this rating
      await snap.ref.delete();
      return;
    }
    
    // Mark as processed
    await existingRef.set({
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
      operation: 'rating_create',
    });
    
    // Proceed with aggregation...
  });
```

---

## 🎰 Circuit Breaker Pattern

### When to Use

When a service is failing repeatedly, stop hammering it. Give it time to recover.

```dart
class CircuitBreaker {
  final String serviceName;
  final int failureThreshold;
  final Duration resetTimeout;
  
  CircuitState _state = CircuitState.closed;
  int _failureCount = 0;
  DateTime? _lastFailure;
  
  CircuitBreaker({
    required this.serviceName,
    this.failureThreshold = 5,
    this.resetTimeout = const Duration(seconds: 30),
  });
  
  Future<T> execute<T>(Future<T> Function() operation) async {
    // Check if circuit is open
    if (_state == CircuitState.open) {
      if (DateTime.now().difference(_lastFailure!) > resetTimeout) {
        // Try half-open
        _state = CircuitState.halfOpen;
      } else {
        throw CircuitOpenException('$serviceName is temporarily unavailable');
      }
    }
    
    try {
      final result = await operation();
      
      // Success! Reset if needed
      if (_state == CircuitState.halfOpen) {
        _state = CircuitState.closed;
        _failureCount = 0;
      }
      
      return result;
      
    } catch (e) {
      _failureCount++;
      _lastFailure = DateTime.now();
      
      if (_failureCount >= failureThreshold) {
        _state = CircuitState.open;
        debugPrint('Circuit breaker OPEN for $serviceName');
      }
      
      rethrow;
    }
  }
}

enum CircuitState { closed, open, halfOpen }
```

### Usage

```dart
final firebaseCircuit = CircuitBreaker(serviceName: 'Firebase');

Future<void> uploadTrip(Trip trip) async {
  await firebaseCircuit.execute(() async {
    await _firestore.collection('trips').doc(trip.id).set(trip.toJson());
  });
}
```

---

## 🗺️ Trip State Machine

### States

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│    ┌──────┐                                                      │
│    │ IDLE │ ◄───────────────────────────────────────────────┐   │
│    └──┬───┘                                                  │   │
│       │ startTrip()                                          │   │
│       ▼                                                      │   │
│    ┌──────────┐                                              │   │
│    │ STARTING │  (Acquiring GPS, initializing sensors)       │   │
│    └──┬───────┘                                              │   │
│       │ locationAcquired()                                   │   │
│       ▼                                                      │   │
│    ┌────────┐    pause()    ┌────────┐                       │   │
│    │ ACTIVE │ ◄───────────► │ PAUSED │                       │   │
│    └──┬─────┘    resume()   └────────┘                       │   │
│       │                                                      │   │
│       │ stopTrip()                                           │   │
│       ▼                                                      │   │
│    ┌────────┐                                                │   │
│    │ ENDING │  (Finalizing stats, saving data)               │   │
│    └──┬─────┘                                                │   │
│       │ saved()                                              │   │
│       ▼                                                      │   │
│    ┌───────────┐                                             │   │
│    │ COMPLETED │ ────────────────────────────────────────────┘   │
│    └───────────┘          reset()                                │
│                                                                  │
│    At ANY state, crash can occur:                               │
│    ┌────────┐                                                    │
│    │ FAILED │  (Persisted state enables recovery)               │
│    └────────┘                                                    │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### State Persistence

```dart
@HiveType(typeId: 20)
class TripState extends HiveObject {
  @HiveField(0)
  TripStatus status;  // idle, starting, active, paused, ending, completed, failed
  
  @HiveField(1)
  String? activeTripId;
  
  @HiveField(2)
  DateTime? startedAt;
  
  @HiveField(3)
  DateTime? lastUpdateAt;
  
  @HiveField(4)
  double? lastKnownLat;
  
  @HiveField(5)
  double? lastKnownLng;
  
  @HiveField(6)
  double currentDistance;
  
  @HiveField(7)
  double topSpeed;
  
  @HiveField(8)
  List<String> speedLogJsonChunks;  // Chunked to avoid huge single writes
}
```

### Crash Recovery Flow

```dart
// On app startup:
Future<void> checkTripRecovery() async {
  final stateBox = Hive.box<TripState>('trip_state');
  final savedState = stateBox.get('current');
  
  if (savedState == null) return;
  
  switch (savedState.status) {
    case TripStatus.idle:
    case TripStatus.completed:
      // Nothing to recover
      return;
      
    case TripStatus.starting:
    case TripStatus.active:
    case TripStatus.paused:
      // Trip was in progress!
      final timeSinceLast = DateTime.now().difference(savedState.lastUpdateAt!);
      
      if (timeSinceLast > Duration(hours: 2)) {
        // Too old, probably abandoned - offer to discard or save partial
        _showRecoveryDialog(RecoveryOption.savePartial, savedState);
      } else {
        // Recent - offer to resume
        _showRecoveryDialog(RecoveryOption.resume, savedState);
      }
      break;
      
    case TripStatus.ending:
      // Was in the middle of saving - finish it
      await _finalizeTripSave(savedState);
      break;
      
    case TripStatus.failed:
      // Previous failure - ask what to do
      _showRecoveryDialog(RecoveryOption.retry, savedState);
      break;
  }
}

void _showRecoveryDialog(RecoveryOption option, TripState state) {
  // Show dialog: "We found an unfinished trip from [time]. Resume or discard?"
}
```

### State Persistence Frequency

```dart
// Save state every 30 seconds during active trip
Timer.periodic(Duration(seconds: 30), (_) {
  if (_currentState.status == TripStatus.active) {
    _persistState();
  }
});

// Also save on every significant event
void _onSpeedUpdate(double speed) {
  _currentState.topSpeed = max(_currentState.topSpeed, speed);
  _persistState(); // Frequent but lightweight
}
```

---

## ⚠️ Edge Case Registry

### Category: Connectivity

| Scenario | Detection | Handling |
|----------|-----------|----------|
| Network dies mid-upload | Timeout exception | Queue operation, retry later |
| Network dies mid-download | Timeout exception | Show cached data, retry |
| Flaky connection (on/off) | Connectivity stream | Debounce state changes (5s) |
| Very slow network | Timeout > 30s | Show loading, allow cancel |

### Category: GPS/Location

| Scenario | Detection | Handling |
|----------|-----------|----------|
| GPS permission denied | `PermissionStatus.denied` | Show permission screen |
| GPS permanently denied | `PermissionStatus.deniedForever` | Deep link to settings |
| GPS disabled in settings | `isLocationServiceEnabled == false` | Prompt to enable |
| No GPS fix (indoor) | Timeout > 30s | Use last known + accelerometer |
| GPS returns null | Position is null | Fall back to dead reckoning |
| Mock location detected | `position.isMocked == true` | Warn user, flag data |

### Category: User Behavior

| Scenario | Detection | Handling |
|----------|-----------|----------|
| Double-tap submit | Multiple calls in < 500ms | Debounce, use idempotency key |
| Rage-tap (10x clicks) | Rapid fire events | Rate limit client-side |
| Rate same driver 100x | Check history | "You already rated this driver today" |
| Submit while offline | No connectivity | Save locally, show "Saved offline" |
| Close app mid-trip | App lifecycle | Persist state, recover on launch |
| Phone dies mid-trip | N/A (can't detect) | State was persisted, recover on launch |
| Clock set to wrong date | Compare to server time | Use server timestamp for sync |

### Category: Data Integrity

| Scenario | Detection | Handling |
|----------|-----------|----------|
| Duplicate rating | Idempotency key exists | Ignore duplicate |
| Out-of-order sync | Timestamp comparison | Use `createdAt` not `syncedAt` |
| Concurrent driver update | Version conflict | Last-write-wins for ratings |
| Corrupted local data | Parse exception | Clear and re-sync from server |
| Hive box corruption | HiveError | Delete box, reinitialize |

---

## 📊 Monitoring & Observability

### Key Metrics to Track

```dart
class AppMetrics {
  // Sync health
  int syncQueueLength;
  int deadLetterCount;
  double syncSuccessRate;
  Duration avgSyncLatency;
  
  // Trip health
  int tripsStarted;
  int tripsCompleted;
  int tripsCrashed;
  double tripRecoveryRate;
  
  // GPS health  
  double gpsSuccessRate;
  int gpsTimeouts;
  Duration avgTimeToFix;
  
  // Error rates
  Map<String, int> errorsByCode;
  int totalErrors;
  int userFacingErrors;
}
```

### Logging Strategy

```dart
// Use structured logging
class AppLogger {
  void log({
    required LogLevel level,
    required String event,
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final entry = {
      'timestamp': DateTime.now().toIso8601String(),
      'level': level.name,
      'event': event,
      'data': data,
      'error': error?.toString(),
    };
    
    // Local debug
    if (kDebugMode) {
      debugPrint(jsonEncode(entry));
    }
    
    // Production: Send to Firebase Crashlytics / Analytics
    if (level == LogLevel.error) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }
  }
}

// Usage
_logger.log(
  level: LogLevel.info,
  event: 'trip_started',
  data: {'tripId': trip.id, 'location': '${lat},${lng}'},
);

_logger.log(
  level: LogLevel.error,
  event: 'sync_failed',
  data: {'operationId': op.id, 'attempt': op.attemptCount},
  error: e,
  stackTrace: stackTrace,
);
```

---

## 🔥 Firebase Gotchas & Important Notes

### Firebase Console Warnings You May See

#### "Insecure Rules" Warning
If you see "Your Cloud Firestore database has insecure security rules" in the Firebase console:
- **What it means:** Your rules allow read/write without authentication
- **Fix:** Update Firestore rules to require authentication:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

#### "No Billing Account" for Cloud Functions
- Cloud Functions require billing to be enabled (Blaze plan)
- Free tier includes 125K invocations/month
- For MVP, can use Firestore triggers without Functions

#### Email Action URLs
- Firebase Auth email links use `firebaseapp.com` domain by default
- For production, configure custom domain in Firebase Console → Auth → Templates

### Best Practices for This Project

1. **Security Rules:** Always test rules in Firebase Rules Playground before deploying
2. **Indexes:** Firestore will throw errors for missing indexes - follow the link in the error to create them
3. **Offline Mode:** Firestore has built-in offline persistence - enable it:
```dart
await FirebaseFirestore.instance.enablePersistence();
```
4. **Rate Limiting:** Firebase has rate limits - use Circuit Breaker pattern (see above)

---

## ✅ Backend Implementation Checklist

Before implementing ANY backend/service code:

- [ ] Error codes defined for all failure modes
- [ ] Retry strategy specified (or explicitly "no retry")
- [ ] Offline behavior documented
- [ ] Idempotency key generation for write operations
- [ ] State persistence for long-running operations
- [ ] Circuit breaker for external services
- [ ] Timeout configured for all network calls
- [ ] User-facing error messages are helpful
- [ ] Logging added for debugging
- [ ] Recovery path for interrupted operations

---

**Remember:** Every network call can fail. Every database write can be interrupted. Every user input can be invalid. Plan for it.
