# RoadGuard Speed Tracking & Algorithms

> **PURPOSE:** Technical documentation for GPS-based speed tracking and all computational algorithms. This is the "how it actually works" document.
>
> **IMPORTANT DECISION (Feb 2026):** After real-device testing, the team decided to use **GPS-only** for speed tracking. Accelerometer/sensor fusion was removed because:
> - Passengers hold phones in unpredictable orientations → accelerometer gives wildly inaccurate values
> - GPS Doppler velocity is accurate to ±0.1 m/s — more than sufficient
> - Sensor fusion added complexity without real benefit for the passenger use case
> - Kalman filter tuning was impractical without a fixed phone mount

---

## 🚗 How Speed Tracking Really Works

### The Challenge

We need to display the user's speed accurately and smoothly. The challenges:

| Problem | Impact | Solution |
|---------|--------|----------|
| GPS is slow (1 Hz update) | Speedometer feels laggy | Smooth interpolation in UI |
| GPS can be inaccurate (±3m position) | Speed jumps around | Use Doppler velocity (not position delta) |
| GPS fails indoors/tunnels | No speed at all | Show status banner, display last known speed |
| GPS cold start takes time | User sees 0 for a while | Show "Getting your location..." banner |
| Users expect instant results | Frustration | Clear status communication |

### The Solution: GPS-Only with Smart Status Feedback

```
┌─────────────────────────────────────────────────────────────────┐
│                    SPEED TRACKING SYSTEM                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────────┐      │
│  │                    GPS RECEIVER                       │      │
│  │                                                       │      │
│  │  • Doppler Velocity (primary speed source)           │      │
│  │  • Position (for distance calculation)               │      │
│  │  • Accuracy (for signal quality assessment)          │      │
│  │  • 1 Hz updates (Android: up to 5 Hz with FLP)      │      │
│  │                                                       │      │
│  └──────────────────────┬───────────────────────────────┘      │
│                         │                                       │
│                         ▼                                       │
│  ┌──────────────────────────────────────────────────────┐      │
│  │              GPS SIGNAL QUALITY CHECK                 │      │
│  │                                                       │      │
│  │  • Accuracy < 10m    → "Good signal" (green)         │      │
│  │  • Accuracy 10-25m   → "Weak signal" (amber)        │      │
│  │  • Accuracy > 25m    → "Poor signal" (red)           │      │
│  │  • No fix / timeout  → "No location" (red)          │      │
│  │                                                       │      │
│  │  Update GPS Status Banner accordingly                │      │
│  │                                                       │      │
│  └──────────────────────┬───────────────────────────────┘      │
│                         │                                       │
│                         ▼                                       │
│  ┌──────────────────────────────────────────────────────┐      │
│  │              SPEED SMOOTHING & OUTPUT                  │      │
│  │                                                       │      │
│  │  • Clamp negative speeds to 0                        │      │
│  │  • Apply EMA (Exponential Moving Average) smoothing  │      │
│  │  • Jitter filter: ignore speed < 2 km/h when "still" │      │
│  │  • Output to UI with digit-slide animation           │      │
│  │                                                       │      │
│  └──────────────────────────────────────────────────────┘      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📍 GPS Speed: The Primary (And Only) Speed Source

### Method 1: GPS Doppler Velocity (Primary)

GPS chips calculate speed directly from Doppler shift of satellite signals. This is **more accurate** than calculating from position changes.

```dart
Position position = await Geolocator.getCurrentPosition();
double gpsSpeed = position.speed;  // meters per second
double speedKmh = gpsSpeed * 3.6;  // convert to km/h
```

**Accuracy:** ±0.1 m/s (±0.36 km/h) in good conditions — excellent for our needs.

### Method 2: Position Delta (Fallback only if Doppler unavailable)

If Doppler velocity returns 0 or is unavailable, calculate from position changes:

```dart
double calculateSpeedFromPositions(Position p1, Position p2) {
  final distanceMeters = Geolocator.distanceBetween(
    p1.latitude, p1.longitude,
    p2.latitude, p2.longitude,
  );
  
  final timeDiffMs = p2.timestamp!.difference(p1.timestamp!).inMilliseconds;
  final timeDiffSec = timeDiffMs / 1000.0;
  
  if (timeDiffSec <= 0) return 0;
  
  final speedMs = distanceMeters / timeDiffSec;
  return speedMs * 3.6; // km/h
}
```

**Accuracy:** ±3 m/s (±10 km/h) — much worse, only use as fallback.

### GPS Configuration

```dart
const LocationSettings gpsSettings = LocationSettings(
  accuracy: LocationAccuracy.bestForNavigation,
  distanceFilter: 0,  // Report all movements (we filter ourselves)
);

const AndroidSettings androidSettings = AndroidSettings(
  accuracy: LocationAccuracy.bestForNavigation,
  distanceFilter: 0,
  intervalDuration: Duration(seconds: 1),  // Request 1 Hz
  forceLocationManager: false,  // Use FusedLocationProvider
);
```

### Speed Smoothing (EMA Filter)

Since GPS updates at 1 Hz, speed can appear "jumpy". Apply a simple Exponential Moving Average:

```dart
class SpeedSmoother {
  double _smoothedSpeed = 0;
  final double _alpha = 0.4; // Smoothing factor (0.0-1.0), higher = more responsive
  
  double smooth(double rawSpeed) {
    if (rawSpeed < 0) rawSpeed = 0; // Clamp negatives
    
    // Jitter filter: if speed is very low and we were stationary, stay at 0
    if (rawSpeed < 2.0 && _smoothedSpeed < 2.0) {
      _smoothedSpeed = 0;
      return 0;
    }
    
    _smoothedSpeed = _alpha * rawSpeed + (1 - _alpha) * _smoothedSpeed;
    return _smoothedSpeed;
  }
  
  void reset() {
    _smoothedSpeed = 0;
  }
}
```

---

## 📡 GPS Signal Status & User Feedback

### Why This Matters

GPS takes time to get a "fix" (especially cold start). Users need to know WHY the speed isn't showing, without technical jargon.

### Signal Quality Classification

```dart
enum GpsSignalQuality {
  acquiring,   // No fix yet, waiting for satellites
  good,        // Accuracy < 10m — reliable speed
  weak,        // Accuracy 10-25m — speed may fluctuate  
  poor,        // Accuracy > 25m — speed unreliable
  lost,        // No update for > 10 seconds
}

GpsSignalQuality classifySignal(Position? position, Duration? timeSinceLastUpdate) {
  if (position == null) return GpsSignalQuality.acquiring;
  
  if (timeSinceLastUpdate != null && timeSinceLastUpdate > Duration(seconds: 10)) {
    return GpsSignalQuality.lost;
  }
  
  final accuracy = position.accuracy;
  if (accuracy < 10) return GpsSignalQuality.good;
  if (accuracy < 25) return GpsSignalQuality.weak;
  return GpsSignalQuality.poor;
}
```

### Status Banner Messages (Plain Language — see UX Copy Guide)

| Quality | Banner Visible? | Message | Color |
|---------|----------------|---------|-------|
| `acquiring` | Yes | "Getting your location..." | Amber (pulsing dot) |
| `good` | No (auto-hide) | — | — |
| `weak` | Yes | "Location signal is weak" | Amber |
| `poor` | Yes | "Location signal is poor — speed may be wrong" | Red |
| `lost` | Yes | "Location lost — check your surroundings" | Red |

### Banner Animation Specification

```
┌──────────────────────────────────────────┐
│ 🟡 Getting your location...              │  ← Slides in from top
└──────────────────────────────────────────┘
     ↑
     300ms easeOutCubic slide + fade
     Auto-dismisses when GPS quality = "good"
     250ms easeIn slide out
```

```dart
/// Banner behavior rules:
/// 1. Show IMMEDIATELY when tracking starts (acquiring state)
/// 2. Auto-hide when signal becomes "good" (accuracy < 10m)
/// 3. Re-appear if signal degrades during tracking
/// 4. Non-blocking — user can see speedometer underneath
/// 5. Slim height (~40px) — just enough for icon + message
/// 6. Do NOT show "km/h", "±Xm", "GPS" or any technical jargon
```

---

## ❌ DEPRECATED: Accelerometer & Sensor Fusion

> **Removed in Feb 2026 after real-device testing.**
>
> **Why it was removed:**
> - RoadGuard is for **passengers**, not drivers. Passengers hold phones loosely in hands, pockets, bags — orientation is unpredictable
> - Accelerometer requires gravity removal, which needs stable orientation → fails for passengers
> - Even with Kalman filter, accelerometer drift made speeds jump wildly on start
> - GPS Doppler velocity alone is accurate enough (±0.36 km/h)
> - Complexity wasn't worth it — simpler = more reliable
>
> **If needed in future:** Consider only for OBD-II integration (v2.0) where vehicle ECU provides exact speed.
> The `sensors_plus` package can be kept for future features (e.g., bump detection, crash detection) but NOT for speed calculation.

---

## 📏 Distance Calculation

### The Haversine Formula

For calculating distance between two GPS coordinates on a sphere (Earth):

```dart
double haversineDistance(
  double lat1, double lon1,
  double lat2, double lon2,
) {
  const earthRadius = 6371000; // meters
  
  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);
  
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
      sin(dLon / 2) * sin(dLon / 2);
  
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  
  return earthRadius * c;
}

double _toRadians(double degrees) => degrees * pi / 180;
```

### Trip Distance Accumulation

```dart
class TripDistanceTracker {
  double _totalDistance = 0;
  Position? _lastPosition;
  
  // Minimum movement to count (filters GPS jitter when stationary)
  static const double _minMovementMeters = 5.0;
  
  void addPosition(Position position) {
    if (_lastPosition == null) {
      _lastPosition = position;
      return;
    }
    
    final distance = Geolocator.distanceBetween(
      _lastPosition!.latitude, _lastPosition!.longitude,
      position.latitude, position.longitude,
    );
    
    // Only count if moved significantly (GPS noise filter)
    if (distance >= _minMovementMeters) {
      _totalDistance += distance;
      _lastPosition = position;
    }
  }
  
  double get totalDistanceKm => _totalDistance / 1000;
}
```

---

## 🚘 Ghana Number Plate Validation

### Plate Formats

Ghana uses several number plate formats:

| Format | Example | Description |
|--------|---------|-------------|
| `XX-XXXX-XX` | `GR-1234-21` | Standard format (Region-Number-Year) |
| `XX XXXX XX` | `GR 1234 21` | With spaces |
| `XX-XXXXX-XX` | `GR-12345-21` | 5-digit number |
| Government | `GT-1234-21` | Government vehicles |

### Regional Codes

```dart
const Map<String, String> ghanaRegions = {
  'GR': 'Greater Accra',
  'GA': 'Greater Accra (old)',
  'AS': 'Ashanti',
  'BA': 'Brong Ahafo',
  'AH': 'Ahafo',
  'BO': 'Bono',
  'BE': 'Bono East',
  'CR': 'Central',
  'ER': 'Eastern',
  'NR': 'Northern',
  'NE': 'North East',
  'SV': 'Savannah',
  'UE': 'Upper East',
  'UW': 'Upper West',
  'VR': 'Volta',
  'OR': 'Oti',
  'WR': 'Western',
  'WN': 'Western North',
  'GT': 'Government',
  'GV': 'Government',
  'CD': 'Corps Diplomatique',
  'CC': 'Consular Corps',
};
```

### Validation Regex

```dart
class PlateValidator {
  // Main pattern: 2 letters - 4 or 5 digits - 2 digits
  static final RegExp _plateRegex = RegExp(
    r'^([A-Z]{2})[\s\-]?(\d{4,5})[\s\-]?(\d{2})$',
    caseSensitive: false,
  );
  
  // Valid region codes
  static const Set<String> _validRegions = {
    'GR', 'GA', 'AS', 'BA', 'AH', 'BO', 'BE', 'CR', 'ER',
    'NR', 'NE', 'SV', 'UE', 'UW', 'VR', 'OR', 'WR', 'WN',
    'GT', 'GV', 'CD', 'CC',
  };
  
  static PlateValidationResult validate(String input) {
    // Normalize: uppercase, remove extra spaces
    final normalized = input.toUpperCase().trim();
    
    // Check format
    final match = _plateRegex.firstMatch(normalized);
    if (match == null) {
      return PlateValidationResult.invalid(
        'Invalid format. Expected: XX-XXXX-XX',
      );
    }
    
    final region = match.group(1)!;
    final number = match.group(2)!;
    final year = match.group(3)!;
    
    // Check region code
    if (!_validRegions.contains(region)) {
      return PlateValidationResult.invalid(
        'Unknown region code: $region',
      );
    }
    
    // Check year is reasonable (1990-2030)
    final yearNum = int.parse(year);
    if (yearNum < 90 && yearNum > 30) {
      // 90-99 = 1990s, 00-30 = 2000-2030
      return PlateValidationResult.invalid(
        'Invalid year: $year',
      );
    }
    
    // Format consistently: XX-XXXX-XX
    final formatted = '$region-$number-$year';
    
    return PlateValidationResult.valid(formatted, region);
  }
  
  /// Extract plates from OCR text
  static List<String> extractFromText(String ocrText) {
    final candidates = <String>[];
    
    // Find all potential plate patterns
    final matches = RegExp(
      r'[A-Z]{2}[\s\-]?\d{4,5}[\s\-]?\d{2}',
      caseSensitive: false,
    ).allMatches(ocrText);
    
    for (final match in matches) {
      final result = validate(match.group(0)!);
      if (result.isValid) {
        candidates.add(result.formattedPlate!);
      }
    }
    
    return candidates;
  }
}

class PlateValidationResult {
  final bool isValid;
  final String? formattedPlate;
  final String? region;
  final String? errorMessage;
  
  PlateValidationResult.valid(this.formattedPlate, this.region)
      : isValid = true, errorMessage = null;
  
  PlateValidationResult.invalid(this.errorMessage)
      : isValid = false, formattedPlate = null, region = null;
}
```

---

## 📊 Rating Aggregation Algorithm

### The Problem

When a new rating is added, we need to update the driver's aggregate stats:
- `averageRating`
- `totalRatings`
- `goodRatings` / `badRatings`
- `commonTags`

### Local Calculation (Optimistic)

```dart
class RatingAggregator {
  static DriverStats addRating(DriverStats current, RatingModel newRating) {
    final newTotalRatings = current.totalRatings + 1;
    final newGoodRatings = newRating.isGood 
        ? current.goodRatings + 1 
        : current.goodRatings;
    final newBadRatings = newRating.isGood 
        ? current.badRatings 
        : current.badRatings + 1;
    
    // Calculate new average
    // Good = 5 stars, Bad = 1 star
    final totalScore = (newGoodRatings * 5) + (newBadRatings * 1);
    final newAverageRating = totalScore / newTotalRatings;
    
    // Update tag frequency
    final tagCounts = Map<String, int>.from(current.tagCounts);
    for (final tag in newRating.tags) {
      tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
    }
    
    // Get top 5 tags
    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final commonTags = sortedTags.take(5).map((e) => e.key).toList();
    
    return DriverStats(
      plateNumber: current.plateNumber,
      totalRatings: newTotalRatings,
      goodRatings: newGoodRatings,
      badRatings: newBadRatings,
      averageRating: newAverageRating,
      commonTags: commonTags,
      tagCounts: tagCounts,
      lastUpdated: DateTime.now(),
    );
  }
}
```

### Cloud Function (Server-Side Truth)

```typescript
// functions/src/ratings.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const onRatingCreated = functions.firestore
  .document('drivers/{plateNumber}/ratings/{ratingId}')
  .onCreate(async (snap, context) => {
    const rating = snap.data();
    const plateNumber = context.params.plateNumber;
    
    const driverRef = admin.firestore()
      .collection('drivers')
      .doc(plateNumber);
    
    await admin.firestore().runTransaction(async (transaction) => {
      const driverDoc = await transaction.get(driverRef);
      
      let currentStats = driverDoc.exists 
        ? driverDoc.data()! 
        : {
            totalRatings: 0,
            goodRatings: 0,
            badRatings: 0,
            averageRating: 0,
            tagCounts: {},
          };
      
      // Update counts
      currentStats.totalRatings += 1;
      if (rating.isGood) {
        currentStats.goodRatings += 1;
      } else {
        currentStats.badRatings += 1;
      }
      
      // Recalculate average
      const totalScore = (currentStats.goodRatings * 5) + 
                         (currentStats.badRatings * 1);
      currentStats.averageRating = totalScore / currentStats.totalRatings;
      
      // Update tag counts
      for (const tag of rating.tags || []) {
        currentStats.tagCounts[tag] = 
          (currentStats.tagCounts[tag] || 0) + 1;
      }
      
      // Get top 5 tags
      const sortedTags = Object.entries(currentStats.tagCounts)
        .sort((a, b) => (b[1] as number) - (a[1] as number))
        .slice(0, 5)
        .map(([tag]) => tag);
      
      currentStats.commonTags = sortedTags;
      currentStats.lastUpdated = admin.firestore.FieldValue.serverTimestamp();
      
      transaction.set(driverRef, currentStats, { merge: true });
    });
  });
```

---

## ⚡ Speed Alert Logic (Overspeeding Alerts)

> **UX NOTE:** Never say "Speed limit exceeded" — say "Overspeeding!" See [RoadGuard-UX-Copy-Guide.md](RoadGuard-UX-Copy-Guide.md) for all copy rules.

### Alert Thresholds

```dart
class SpeedAlertConfig {
  static const double defaultLimitKmh = 50.0; // Ghana urban default
  static const double warningBuffer = 5.0;    // Warn at limit - 5
  
  double userSpeedLimit;
  bool alertsEnabled;
  bool hapticEnabled;
  
  SpeedAlertLevel getAlertLevel(double currentSpeed) {
    if (!alertsEnabled) return SpeedAlertLevel.none;
    
    if (currentSpeed >= userSpeedLimit) {
      return SpeedAlertLevel.danger;  // "Overspeeding!"
    }
    
    if (currentSpeed >= userSpeedLimit - warningBuffer) {
      return SpeedAlertLevel.warning;  // "Almost at limit"
    }
    
    return SpeedAlertLevel.none;
  }
}

enum SpeedAlertLevel { none, warning, danger }
```

### Alert UI Behavior (User-Facing Messages)

| Level | Toast/SnackBar Message | Color | Haptic |
|-------|----------------------|-------|--------|
| `warning` | "Almost at your speed limit" | Amber | Light |
| `danger` | "Overspeeding! Slow down" | Red | Heavy |
| Back to normal | (auto-dismiss) | — | — |

```dart
class SpeedAlertController {
  SpeedAlertLevel _currentLevel = SpeedAlertLevel.none;
  
  void onSpeedUpdate(double speed, SpeedAlertConfig config) {
    final newLevel = config.getAlertLevel(speed);
    
    if (newLevel != _currentLevel) {
      _onLevelChanged(_currentLevel, newLevel, config);
      _currentLevel = newLevel;
    }
  }
  
  void _onLevelChanged(
    SpeedAlertLevel oldLevel,
    SpeedAlertLevel newLevel,
    SpeedAlertConfig config,
  ) {
    switch (newLevel) {
      case SpeedAlertLevel.warning:
        // Show amber toast: "Almost at your speed limit"
        if (config.hapticEnabled) {
          HapticFeedback.lightImpact();
        }
        break;
        
      case SpeedAlertLevel.danger:
        // Show red toast: "Overspeeding! Slow down"
        // Speedometer ring turns red + pulse animation
        if (config.hapticEnabled) {
          HapticFeedback.heavyImpact();
        }
        break;
        
      case SpeedAlertLevel.none:
        // Auto-dismiss any active toast
        break;
    }
  }
}
```

---

## 🔋 Battery Optimization

### GPS Polling Strategy

```dart
class AdaptiveLocationService {
  LocationAccuracy _currentAccuracy = LocationAccuracy.best;
  Duration _currentInterval = Duration(seconds: 1);
  
  /// Adjust based on current speed and battery
  void adaptToConditions({
    required double currentSpeed,
    required int batteryLevel,
    required bool isCharging,
  }) {
    if (isCharging) {
      // Full power mode
      _currentAccuracy = LocationAccuracy.bestForNavigation;
      _currentInterval = Duration(seconds: 1);
      return;
    }
    
    if (batteryLevel < 20) {
      // Battery saver mode
      _currentAccuracy = LocationAccuracy.medium;
      _currentInterval = Duration(seconds: 5);
      return;
    }
    
    // Speed-based adaptation
    if (currentSpeed < 10) {
      // Moving slowly (walking, traffic)
      _currentAccuracy = LocationAccuracy.high;
      _currentInterval = Duration(seconds: 3);
    } else if (currentSpeed < 60) {
      // City driving
      _currentAccuracy = LocationAccuracy.bestForNavigation;
      _currentInterval = Duration(seconds: 2);
    } else {
      // Highway driving - need high frequency
      _currentAccuracy = LocationAccuracy.bestForNavigation;
      _currentInterval = Duration(seconds: 1);
    }
  }
}
```

### When to Stop Tracking

```dart
class StationaryDetector {
  final List<double> _recentSpeeds = [];
  static const int _sampleSize = 10;
  static const double _stationaryThreshold = 2.0; // km/h
  
  bool isStationary(double speed) {
    _recentSpeeds.add(speed);
    if (_recentSpeeds.length > _sampleSize) {
      _recentSpeeds.removeAt(0);
    }
    
    if (_recentSpeeds.length < _sampleSize) return false;
    
    final avgSpeed = _recentSpeeds.reduce((a, b) => a + b) / _sampleSize;
    return avgSpeed < _stationaryThreshold;
  }
  
  void onStationary() {
    // Reduce GPS polling frequency
    // Save battery
    // Show "Vehicle appears stopped" status (optional)
  }
}
```

---

## 📋 Algorithm Checklist

Before implementing speed tracking:

- [ ] GPS-only speed source (no accelerometer for speed)
- [ ] GPS Doppler velocity as primary speed source
- [ ] Position delta as fallback when Doppler unavailable
- [ ] EMA speed smoothing to prevent UI jitter
- [ ] Jitter filter: ignore < 2 km/h when stationary
- [ ] GPS signal quality classification (good/weak/poor/lost)
- [ ] GPS status banner shows plain-language messages
- [ ] Banner auto-shows on tracking start, auto-hides when signal good
- [ ] Banner re-appears if signal degrades during trip
- [ ] Distance calculation uses Haversine with jitter filter
- [ ] Speed alerts use plain language ("Overspeeding!")
- [ ] Battery optimization adapts GPS frequency to conditions
- [ ] Stationary detection prevents false movement
- [ ] All calculations handle null/error cases
- [ ] Unit tests for edge cases (0 speed, max speed, GPS loss)

---

## 🔮 Future Enhancements (v2.0+)

### OBD-II Integration
For "Pro" users who want dashboard-accurate speed via Bluetooth OBD-II adapter.

### Peer Speed Sharing (Researched, Parked)
> **Concept:** If multiple passengers in the same vehicle are using RoadGuard, and one passenger's GPS fails, they could "tap into" a nearby user's GPS data (within 5-10m radius).
>
> **Why parked for v2.0:**
> - High complexity (needs Bluetooth/WiFi P2P or Nearby Connections API)
> - If GPS is failing, proximity detection is also unreliable
> - Privacy concerns with broadcasting location to strangers
> - Narrow use case (both users need app, one needs to have good GPS)
> - Edge cases with multiple users on a trotro (20+ potential peers)
>
> **Best approach if revisited:** Google's Nearby Connections API (works without internet, Android-only)
>
> **Alternative:** Cloud-based proximity matching via Firebase, but defeats purpose if user's network is also down

### Crash/Accident Detection
Using accelerometer (not for speed) to detect sudden deceleration events that could indicate an accident.

---

**Remember:** GPS-only speed tracking is the CORE feature. It must be accurate, smooth, and battery-efficient. Test thoroughly in real driving conditions. Always communicate GPS status to the user in plain, non-technical language.
