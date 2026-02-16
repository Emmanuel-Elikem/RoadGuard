# RoadGuard Coding Standards

> **PURPOSE:** Coding principles, efficiency rules, and quality standards. Every line of code must follow these guidelines.

---

## 🎯 The Prime Directive

> "Write code that your future self (or another developer) will thank you for."

Before writing ANY code, ask:
1. **Is this the simplest solution?** (KISS)
2. **Will this code be easy to test?**
3. **What will break if this fails?**
4. **Can this be reused elsewhere?** (DRY)

---

## 📐 SOLID Principles (Dart/Flutter)

### S - Single Responsibility Principle

**Every class/function should do ONE thing well.**

```dart
// ❌ BAD: One class doing too much
class TripManager {
  void startTrip() { /* ... */ }
  void stopTrip() { /* ... */ }
  void calculateDistance() { /* ... */ }
  void saveToDatabase() { /* ... */ }
  void uploadToCloud() { /* ... */ }
  void showNotification() { /* ... */ }
  void formatForDisplay() { /* ... */ }
}

// ✅ GOOD: Separated responsibilities
class TripTracker {
  void startTrip() { /* ... */ }
  void stopTrip() { /* ... */ }
}

class DistanceCalculator {
  double calculate(List<Position> points) { /* ... */ }
}

class TripRepository {
  Future<void> saveLocally(Trip trip) { /* ... */ }
  Future<void> uploadToCloud(Trip trip) { /* ... */ }
}

class TripFormatter {
  String formatDuration(Duration d) { /* ... */ }
  String formatDistance(double km) { /* ... */ }
}
```

### O - Open/Closed Principle

**Open for extension, closed for modification.**

```dart
// ❌ BAD: Need to modify class to add new behavior
class SpeedTracker {
  double getSpeed(String source) {
    if (source == 'gps') {
      return _getGpsSpeed();
    } else if (source == 'accelerometer') {
      return _getAccelerometerSpeed();
    } else if (source == 'obd') {  // Had to modify!
      return _getObdSpeed();
    }
    return 0;
  }
}

// ✅ GOOD: Extend without modifying
abstract class SpeedSource {
  double getSpeed();
  String get name;
}

class GpsSpeedSource implements SpeedSource {
  @override
  double getSpeed() => _getGpsSpeed();
  @override
  String get name => 'GPS';
}

class AccelerometerSpeedSource implements SpeedSource {
  @override
  double getSpeed() => _getAccelerometerSpeed();
  @override
  String get name => 'Accelerometer';
}

// New source - just add new class, no modification needed
class ObdSpeedSource implements SpeedSource {
  @override
  double getSpeed() => _getObdSpeed();
  @override
  String get name => 'OBD-II';
}
```

### L - Liskov Substitution Principle

**Subtypes must be substitutable for their base types.**

```dart
// ❌ BAD: Subclass breaks contract
abstract class Bird {
  void fly();
}

class Penguin extends Bird {
  @override
  void fly() {
    throw Exception('Penguins cannot fly!'); // Violates contract!
  }
}

// ✅ GOOD: Proper hierarchy
abstract class Bird {
  void move();
}

abstract class FlyingBird extends Bird {
  void fly();
  @override
  void move() => fly();
}

abstract class SwimmingBird extends Bird {
  void swim();
  @override
  void move() => swim();
}

class Penguin extends SwimmingBird {
  @override
  void swim() { /* ... */ }
}
```

### I - Interface Segregation Principle

**Clients shouldn't depend on interfaces they don't use.**

```dart
// ❌ BAD: Fat interface
abstract class TripService {
  Future<void> startTrip();
  Future<void> stopTrip();
  Future<void> pauseTrip();
  Future<void> saveTrip(Trip trip);
  Future<void> uploadTrip(Trip trip);
  Future<void> deleteTrip(String id);
  Future<List<Trip>> getAllTrips();
  Future<Trip?> getTrip(String id);
  Future<void> syncTrips();
}

// ✅ GOOD: Segregated interfaces
abstract class TripTracker {
  Future<void> startTrip();
  Future<void> stopTrip();
  Future<void> pauseTrip();
}

abstract class TripRepository {
  Future<void> save(Trip trip);
  Future<void> delete(String id);
  Future<Trip?> getById(String id);
  Future<List<Trip>> getAll();
}

abstract class TripSyncService {
  Future<void> upload(Trip trip);
  Future<void> syncAll();
}
```

### D - Dependency Inversion Principle

**Depend on abstractions, not concretions.**

```dart
// ❌ BAD: Direct dependency on concrete class
class TripScreen extends StatelessWidget {
  final HiveTripRepository _repository = HiveTripRepository();
  
  Future<void> _saveTrip(Trip trip) async {
    await _repository.save(trip);  // Tightly coupled to Hive
  }
}

// ✅ GOOD: Depend on abstraction
abstract class TripRepository {
  Future<void> save(Trip trip);
}

class HiveTripRepository implements TripRepository {
  @override
  Future<void> save(Trip trip) async { /* Hive implementation */ }
}

class FirebaseTripRepository implements TripRepository {
  @override
  Future<void> save(Trip trip) async { /* Firebase implementation */ }
}

// In Riverpod provider
final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return HiveTripRepository(); // Can swap to Firebase easily
});

class TripScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(tripRepositoryProvider);
    // Now depends on abstraction!
  }
}
```

---

## 🔄 DRY - Don't Repeat Yourself

### Identify Repetition

```dart
// ❌ BAD: Same logic repeated
class TripSummaryScreen {
  String _formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).toStringAsFixed(0)} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }
}

class TripHistoryScreen {
  String _formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).toStringAsFixed(0)} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }
}

// ✅ GOOD: Extract to shared utility
// lib/core/utils/formatters.dart
class Formatters {
  static String distance(double km) {
    if (km < 1) {
      return '${(km * 1000).toStringAsFixed(0)} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }
  
  static String duration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
  }
  
  static String speed(double kmh) {
    return '${kmh.toStringAsFixed(0)} km/h';
  }
}
```

### Extract Reusable Widgets

```dart
// ❌ BAD: Same widget structure repeated
// In TripScreen
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: theme.surface,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Column(
    children: [
      Text('95', style: theme.displayMedium),
      Text('TOP SPEED', style: theme.labelMedium),
    ],
  ),
)

// In StatsScreen - same thing!
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: theme.surface,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Column(
    children: [
      Text('127', style: theme.displayMedium),
      Text('TOTAL TRIPS', style: theme.labelMedium),
    ],
  ),
)

// ✅ GOOD: Extract to reusable widget
// lib/shared/widgets/stat_card.dart
class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;
  
  const StatCard({
    required this.value,
    required this.label,
    this.valueColor,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.displayMedium?.copyWith(
              color: valueColor,
            ),
          ),
          Text(label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}

// Usage
StatCard(value: '95', label: 'TOP SPEED')
StatCard(value: '127', label: 'TOTAL TRIPS')
```

---

## 🧪 Testing Requirements

### The Testing Mandate

> **EVERY piece of logic MUST be testable. If it's hard to test, the design is wrong.**

### What to Test

| Type | What | Coverage Target |
|------|------|-----------------|
| **Unit Tests** | Business logic, utilities, algorithms | 90%+ |
| **Widget Tests** | UI components in isolation | 70%+ |
| **Integration Tests** | Full user flows | Critical paths |

### Writing Testable Code

```dart
// ❌ BAD: Hard to test (direct dependencies)
class SpeedTracker {
  void onLocationUpdate() {
    final position = Geolocator.getCurrentPosition();  // Can't mock!
    final speed = position.speed;
    
    HiveBox.put('lastSpeed', speed);  // Can't verify!
    
    if (speed > 80) {
      Vibration.vibrate();  // Side effect!
    }
  }
}

// ✅ GOOD: Testable (dependencies injected)
class SpeedTracker {
  final LocationService _locationService;
  final SpeedRepository _repository;
  final HapticService _hapticService;
  
  SpeedTracker({
    required LocationService locationService,
    required SpeedRepository repository,
    required HapticService hapticService,
  }) : _locationService = locationService,
       _repository = repository,
       _hapticService = hapticService;
  
  Future<void> onLocationUpdate() async {
    final position = await _locationService.getCurrentPosition();
    final speed = position.speed;
    
    await _repository.saveLastSpeed(speed);
    
    if (speed > 80) {
      await _hapticService.vibrate();
    }
  }
}

// Test
test('triggers haptic when speed exceeds 80', () async {
  final mockLocation = MockLocationService();
  final mockRepo = MockSpeedRepository();
  final mockHaptic = MockHapticService();
  
  when(mockLocation.getCurrentPosition()).thenAnswer(
    (_) async => Position(speed: 85),
  );
  
  final tracker = SpeedTracker(
    locationService: mockLocation,
    repository: mockRepo,
    hapticService: mockHaptic,
  );
  
  await tracker.onLocationUpdate();
  
  verify(mockHaptic.vibrate()).called(1);
});
```

### Self-Testing Before "Done"

Before saying ANY task is complete:

1. **Compile Check:** Does it compile without errors?
2. **Lint Check:** `flutter analyze` passes?
3. **Null Safety:** All nullability handled?
4. **Edge Cases:** What if input is null/empty/huge?
5. **Error Paths:** What happens when it fails?
6. **UI Check:** Does it look right in both light/dark mode?
7. **Memory Check:** Any obvious leaks (unclosed streams, etc.)?

```dart
// Mental checklist for every function:
Future<Result<Trip>> saveTrip(Trip trip) async {
  // ✓ What if trip is null? (Can't happen with null safety)
  // ✓ What if trip.id is empty? → Validate
  // ✓ What if Hive write fails? → Try-catch, return failure
  // ✓ What if sync fails? → Queue for later, still return success
  // ✓ Is this idempotent? → Use trip.id as key
  
  if (trip.id.isEmpty) {
    return Result.failure(ValidationError('Trip ID required'));
  }
  
  try {
    await _hiveBox.put(trip.id, trip);
  } catch (e) {
    return Result.failure(StorageError('Failed to save: $e'));
  }
  
  _syncQueue.enqueue(trip);  // Fire and forget
  
  return Result.success(trip);
}
```

---

## ⚡ Performance Optimization

### Widget Rebuild Optimization

```dart
// ❌ BAD: Entire widget rebuilds when ANY state changes
class DashboardScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speed = ref.watch(speedProvider);
    final trips = ref.watch(tripsProvider);
    final user = ref.watch(userProvider);
    
    return Column(
      children: [
        Text('Speed: $speed'),  // Rebuilds when trips change!
        Text('Trips: ${trips.length}'),  // Rebuilds when speed changes!
        Text('User: ${user.name}'),  // Rebuilds when anything changes!
      ],
    );
  }
}

// ✅ GOOD: Use .select() to watch only what you need
class DashboardScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const SpeedDisplay(),      // Separate widgets
        const TripCountDisplay(),
        const UserGreeting(),
      ],
    );
  }
}

class SpeedDisplay extends ConsumerWidget {
  const SpeedDisplay();
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only rebuilds when speed changes
    final speed = ref.watch(speedProvider);
    return Text('Speed: $speed');
  }
}

class TripCountDisplay extends ConsumerWidget {
  const TripCountDisplay();
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only rebuilds when trip count changes
    final count = ref.watch(tripsProvider.select((trips) => trips.length));
    return Text('Trips: $count');
  }
}
```

### Avoid Expensive Operations in Build

```dart
// ❌ BAD: Expensive operation every build
@override
Widget build(BuildContext context) {
  final sortedTrips = trips.toList()..sort((a, b) => b.date.compareTo(a.date));
  final totalDistance = trips.fold(0.0, (sum, t) => sum + t.distance);
  
  return ListView(
    children: sortedTrips.map((t) => TripCard(t)).toList(),
  );
}

// ✅ GOOD: Cache expensive operations
class TripListNotifier extends Notifier<TripListState> {
  @override
  TripListState build() {
    final trips = ref.watch(rawTripsProvider);
    
    // Calculate once, not every build
    final sorted = trips.toList()..sort((a, b) => b.date.compareTo(a.date));
    final total = trips.fold(0.0, (sum, t) => sum + t.distance);
    
    return TripListState(
      sortedTrips: sorted,
      totalDistance: total,
    );
  }
}
```

### Use const Constructors

```dart
// ❌ BAD: New widget instance every build
return Container(
  padding: EdgeInsets.all(16),  // New instance every time
  child: Row(
    children: [
      Icon(Icons.speed),  // New instance
      SizedBox(width: 8),  // New instance
      Text('Speed'),
    ],
  ),
);

// ✅ GOOD: const where possible
return Container(
  padding: const EdgeInsets.all(16),  // Same instance reused
  child: const Row(
    children: [
      Icon(Icons.speed),
      SizedBox(width: 8),
      Text('Speed'),
    ],
  ),
);

// Mark widgets as const when they don't depend on state
class SpeedIcon extends StatelessWidget {
  const SpeedIcon({super.key});  // const constructor
  
  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.speed, size: 24);
  }
}
```

### Memory Management

```dart
// ❌ BAD: Stream subscription never cancelled
class LocationTracker extends StatefulWidget {
  @override
  _LocationTrackerState createState() => _LocationTrackerState();
}

class _LocationTrackerState extends State<LocationTracker> {
  @override
  void initState() {
    super.initState();
    Geolocator.getPositionStream().listen((position) {
      // Memory leak! Subscription lives forever
      _updatePosition(position);
    });
  }
}

// ✅ GOOD: Cancel subscription on dispose
class _LocationTrackerState extends State<LocationTracker> {
  StreamSubscription<Position>? _positionSubscription;
  
  @override
  void initState() {
    super.initState();
    _positionSubscription = Geolocator.getPositionStream().listen((position) {
      _updatePosition(position);
    });
  }
  
  @override
  void dispose() {
    _positionSubscription?.cancel();  // Clean up!
    super.dispose();
  }
}

// ✅ BEST: Use Riverpod's autoDispose
final positionStreamProvider = StreamProvider.autoDispose<Position>((ref) {
  // Automatically cancelled when no longer watched
  return Geolocator.getPositionStream();
});
```

---

## 📝 Code Style Rules

### Naming Conventions

```dart
// Classes: PascalCase
class TripTracker {}
class SpeedKalmanFilter {}

// Files: snake_case
// trip_tracker.dart
// speed_kalman_filter.dart

// Variables/Functions: camelCase
final currentSpeed = 0.0;
void calculateDistance() {}

// Constants: camelCase (not SCREAMING_CASE)
const maxSpeedLimit = 120.0;
const defaultTimeout = Duration(seconds: 30);

// Private: prefix with underscore
double _lastKnownSpeed = 0.0;
void _processData() {}

// Providers: descriptive with Provider suffix
final speedProvider = StateProvider<double>((ref) => 0);
final tripListProvider = NotifierProvider<TripListNotifier, List<Trip>>(() => TripListNotifier());
```

### File Organization

```dart
// Order within a file:

// 1. Library-level documentation
/// This service handles all GPS-related operations.

// 2. Imports (grouped and sorted)
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:roadguard/core/utils/extensions.dart';
import 'package:roadguard/features/tracking/domain/trip.dart';

// 3. Part directives (if any)

// 4. Constants

// 5. Typedefs

// 6. Main class(es)

// 7. Helper classes (if small, otherwise separate file)
```

### Function Length

```dart
// ❌ BAD: Function doing too much
Future<void> processTrip() async {
  // 100 lines of code...
}

// ✅ GOOD: Break into focused functions
Future<void> processTrip() async {
  final trip = _buildTrip();
  await _validateTrip(trip);
  await _saveTrip(trip);
  await _queueSync(trip);
  _notifyCompletion(trip);
}

Trip _buildTrip() { /* 10-15 lines */ }
Future<void> _validateTrip(Trip trip) async { /* 10-15 lines */ }
Future<void> _saveTrip(Trip trip) async { /* 10-15 lines */ }
// etc.
```

---

## 🚫 Anti-Patterns to Avoid

### God Classes

```dart
// ❌ A class that does everything
class AppManager {
  void handleLogin() {}
  void handleLogout() {}
  void startTrip() {}
  void stopTrip() {}
  void rateDriver() {}
  void syncData() {}
  void showNotification() {}
  // ... 50 more methods
}
```

### Magic Numbers

```dart
// ❌ BAD
if (speed > 80) {
  showAlert();
}

await Future.delayed(Duration(milliseconds: 300));

// ✅ GOOD
const speedLimitKmh = 80.0;
const animationDuration = Duration(milliseconds: 300);

if (speed > speedLimitKmh) {
  showAlert();
}

await Future.delayed(animationDuration);
```

### Nested Callbacks (Callback Hell)

```dart
// ❌ BAD
getUser((user) {
  getTrips(user.id, (trips) {
    getStats(trips, (stats) {
      updateUI(stats);
    });
  });
});

// ✅ GOOD
final user = await getUser();
final trips = await getTrips(user.id);
final stats = await getStats(trips);
updateUI(stats);
```

### Mutable Global State

```dart
// ❌ BAD
class Globals {
  static double currentSpeed = 0;
  static Trip? activeTrip;
  static bool isTracking = false;
}

// ✅ GOOD: Use Riverpod providers
final speedProvider = StateProvider<double>((ref) => 0);
final activeTripProvider = StateProvider<Trip?>((ref) => null);
final isTrackingProvider = StateProvider<bool>((ref) => false);
```

---

## ✅ Pre-Commit Checklist

Before committing ANY code:

```markdown
## Code Quality
- [ ] Compiles without errors
- [ ] `flutter analyze` shows no issues
- [ ] No TODO comments without ticket numbers
- [ ] No print() statements (use debugPrint)
- [ ] No hardcoded strings/colors/dimensions
- [ ] All user-facing text follows [RoadGuard-UX-Copy-Guide.md](RoadGuard-UX-Copy-Guide.md)
- [ ] No technical jargon in UI (GPS, sync, tracking, permission, etc.)
- [ ] No raw error objects exposed to users (`$e`, `error.toString()`)

## Architecture
- [ ] Follows SOLID principles
- [ ] No code duplication (DRY)
- [ ] Dependencies are injected (testable)
- [ ] Business logic is in appropriate layer

## Error Handling
- [ ] All async operations have try-catch
- [ ] Errors are logged appropriately
- [ ] User sees helpful error messages
- [ ] Failures don't crash the app

## Performance
- [ ] No expensive operations in build()
- [ ] Widget rebuilds minimized (const, .select())
- [ ] Streams/subscriptions properly disposed
- [ ] No obvious memory leaks

## Testing
- [ ] Edge cases considered
- [ ] Null/empty/error inputs handled
- [ ] Unit tests for new logic (if applicable)
- [ ] Manually tested on device
```

---

## 🎓 Learning Resources

- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)
- [Riverpod Documentation](https://riverpod.dev/)
- [Clean Architecture in Flutter](https://resocoder.com/flutter-clean-architecture-tdd/)

---

**Remember:** Good code is code that others (including future you) can understand, maintain, and extend without fear.
