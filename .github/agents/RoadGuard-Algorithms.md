# RoadGuard Speed Tracking & Algorithms

> **PURPOSE:** Technical documentation for speed tracking, sensor fusion, and all computational algorithms. This is the "how it actually works" document.

---

## 🚗 How Speed Tracking Really Works

### The Challenge

We need to display the user's speed accurately and smoothly. The challenges:

| Problem | Impact |
|---------|--------|
| GPS is slow (1 Hz update) | Speedometer feels laggy |
| GPS is inaccurate (±3m position) | Speed jumps around |
| GPS fails indoors/tunnels | No speed at all |
| Pure accelerometer drifts | Completely wrong after 60s |
| Users expect car-like accuracy | High expectations |

### The Solution: Sensor Fusion

We combine multiple sensors to get the best of each:

```
┌─────────────────────────────────────────────────────────────────┐
│                    SPEED TRACKING SYSTEM                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐       │
│  │    GPS      │     │ Accelerometer│    │  Gyroscope  │       │
│  │             │     │             │     │             │       │
│  │ • Position  │     │ • Accel X,Y,Z│    │ • Rotation  │       │
│  │ • Velocity  │     │ • 100 Hz    │     │ • Tilt      │       │
│  │ • 1 Hz      │     │             │     │             │       │
│  └──────┬──────┘     └──────┬──────┘     └──────┬──────┘       │
│         │                   │                   │               │
│         │                   │                   │               │
│         ▼                   ▼                   ▼               │
│  ┌──────────────────────────────────────────────────────┐      │
│  │                  KALMAN FILTER                        │      │
│  │                                                       │      │
│  │  GPS (accurate but slow) ──┐                         │      │
│  │                            ├──► Optimal Estimate     │      │
│  │  IMU (fast but drifty) ────┘                         │      │
│  │                                                       │      │
│  └──────────────────────────────────────────────────────┘      │
│                            │                                    │
│                            ▼                                    │
│  ┌──────────────────────────────────────────────────────┐      │
│  │               SMOOTHED SPEED OUTPUT                   │      │
│  │                                                       │      │
│  │  • Updates at 10 Hz (smooth UI)                      │      │
│  │  • Accurate when GPS available                       │      │
│  │  • Reasonable for ~60s without GPS                   │      │
│  │                                                       │      │
│  └──────────────────────────────────────────────────────┘      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📍 GPS Speed Calculation

### Method 1: GPS Doppler Velocity (Preferred)

GPS chips calculate speed directly from Doppler shift of satellite signals. This is **more accurate** than calculating from position changes.

```dart
// geolocator provides this directly
Position position = await Geolocator.getCurrentPosition();
double gpsSpeed = position.speed;  // meters per second
double speedKmh = gpsSpeed * 3.6;  // convert to km/h
```

**Accuracy:** ±0.1 m/s (±0.36 km/h) in good conditions

### Method 2: Position Delta (Fallback)

If Doppler velocity is unavailable, calculate from position changes:

```dart
double calculateSpeedFromPositions(Position p1, Position p2) {
  // Distance using Haversine formula (geolocator does this)
  final distanceMeters = Geolocator.distanceBetween(
    p1.latitude, p1.longitude,
    p2.latitude, p2.longitude,
  );
  
  // Time difference
  final timeDiffMs = p2.timestamp!.difference(p1.timestamp!).inMilliseconds;
  final timeDiffSec = timeDiffMs / 1000.0;
  
  // Speed = distance / time
  if (timeDiffSec <= 0) return 0;
  
  final speedMs = distanceMeters / timeDiffSec;
  return speedMs * 3.6; // km/h
}
```

**Accuracy:** ±3 m/s (±10 km/h) - GPS position error amplifies!

### GPS Configuration

```dart
const LocationSettings gpsSettings = LocationSettings(
  accuracy: LocationAccuracy.bestForNavigation,  // Highest accuracy
  distanceFilter: 0,  // Report all movements (we filter ourselves)
);

// Or for Android with more control:
const AndroidSettings androidSettings = AndroidSettings(
  accuracy: LocationAccuracy.bestForNavigation,
  distanceFilter: 0,
  intervalDuration: Duration(seconds: 1),  // Request 1 Hz
  forceLocationManager: false,  // Use FusedLocationProvider
);
```

---

## 📱 Accelerometer Dead Reckoning

### The Theory

Physics: **v = v₀ + a × t**

If we know the acceleration, we can estimate velocity change.

### The Problem: Drift

Phone accelerometers are noisy. Even a tiny constant error compounds:

```
Error of 0.01 m/s² over 60 seconds:
v_error = 0.01 × 60 = 0.6 m/s error
position_error = 0.5 × 0.01 × 60² = 18 meters!

Real phone drift is often 10x worse → 180m error in 60s
```

### Accelerometer Processing

```dart
class AccelerometerProcessor {
  // Gravity removal (phone measures gravity + movement)
  Vector3 _gravityEstimate = Vector3(0, 0, 9.81);
  
  // High-pass filter to remove gravity
  static const double _alpha = 0.8;
  
  Vector3 removeGravity(AccelerometerEvent event) {
    // Low-pass filter to estimate gravity
    _gravityEstimate = Vector3(
      _alpha * _gravityEstimate.x + (1 - _alpha) * event.x,
      _alpha * _gravityEstimate.y + (1 - _alpha) * event.y,
      _alpha * _gravityEstimate.z + (1 - _alpha) * event.z,
    );
    
    // Subtract gravity to get linear acceleration
    return Vector3(
      event.x - _gravityEstimate.x,
      event.y - _gravityEstimate.y,
      event.z - _gravityEstimate.z,
    );
  }
  
  // Convert phone coordinates to world coordinates
  // (requires gyroscope for orientation)
  Vector3 toWorldCoordinates(Vector3 phoneAccel, Quaternion orientation) {
    return orientation.rotateVector(phoneAccel);
  }
}
```

### When to Use Accelerometer

```dart
enum SpeedSource {
  gps,           // Primary - GPS Doppler velocity
  gpsDelta,      // Fallback 1 - Position change
  imuFused,      // Fallback 2 - Kalman-fused IMU
  imuOnly,       // Last resort - Pure accelerometer (max 60s)
}

SpeedSource _determineSource(Position? gps, Duration gpsAge) {
  if (gps != null && gpsAge < Duration(seconds: 3)) {
    return gps.speedAccuracy < 1.0 
      ? SpeedSource.gps 
      : SpeedSource.gpsDelta;
  }
  
  if (gpsAge < Duration(seconds: 30)) {
    return SpeedSource.imuFused;  // Kalman filter bridges the gap
  }
  
  if (gpsAge < Duration(seconds: 60)) {
    return SpeedSource.imuOnly;  // Risky but better than nothing
  }
  
  // GPS lost for too long - speed becomes unreliable
  return SpeedSource.imuOnly; // Show warning to user
}
```

---

## 🧮 Kalman Filter: The Magic

### What Is It?

A Kalman Filter is an algorithm that **optimally combines** noisy measurements to estimate the true state.

For us: Combine slow-but-accurate GPS with fast-but-drifty accelerometer.

### Simplified 1D Kalman Filter for Speed

```dart
class SpeedKalmanFilter {
  // State estimate
  double _speedEstimate = 0;      // Our best guess of speed
  double _errorEstimate = 1;      // How uncertain we are
  
  // Process noise (how much the true speed can change per update)
  final double _processNoise = 0.5;  // m/s² - tuned for driving
  
  // Measurement noise (how noisy our sensors are)
  final double _gpsMeasurementNoise = 0.5;   // GPS is pretty good
  final double _imuMeasurementNoise = 2.0;   // IMU drifts a lot
  
  double update({
    double? gpsMeasurement,
    double? imuPrediction,
    required Duration dt,
  }) {
    final dtSec = dt.inMilliseconds / 1000.0;
    
    // ====== PREDICTION STEP ======
    // Our prediction is: speed stays roughly the same
    final predictedSpeed = _speedEstimate;
    final predictedError = _errorEstimate + _processNoise * dtSec;
    
    // ====== UPDATE STEP ======
    if (gpsMeasurement != null) {
      // We have GPS! Trust it more.
      final kalmanGain = predictedError / 
          (predictedError + _gpsMeasurementNoise);
      
      _speedEstimate = predictedSpeed + 
          kalmanGain * (gpsMeasurement - predictedSpeed);
      _errorEstimate = (1 - kalmanGain) * predictedError;
      
    } else if (imuPrediction != null) {
      // No GPS, use IMU with less trust
      final kalmanGain = predictedError / 
          (predictedError + _imuMeasurementNoise);
      
      _speedEstimate = predictedSpeed + 
          kalmanGain * (imuPrediction - predictedSpeed);
      _errorEstimate = (1 - kalmanGain) * predictedError;
      
    } else {
      // No measurements at all - just use prediction
      _speedEstimate = predictedSpeed;
      _errorEstimate = predictedError;
    }
    
    return _speedEstimate;
  }
  
  // Reset when starting a new trip
  void reset() {
    _speedEstimate = 0;
    _errorEstimate = 1;
  }
  
  // Get confidence level (0-1)
  double get confidence => 1 / (1 + _errorEstimate);
}
```

### Visual: Kalman Filter in Action

```
Time:     0s      1s      2s      3s      4s      5s
         ─────────────────────────────────────────────
GPS:      50 ─────────── 52 ───────── [LOST] ────────
                 ╲                     
Accel:    ── 51 ── 50 ── 53 ── 55 ── 54 ── 52 ──
                   ╲       ╲       ╲
Kalman:   50 ── 50.5 ── 52 ── 53.5 ── 54 ── 53 ──
                             ↑
                    GPS lost, IMU takes over
                    (with increasing uncertainty)
```

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

## ⚡ Speed Alert Logic

### Alert Thresholds

```dart
class SpeedAlertConfig {
  static const double defaultLimitKmh = 80.0;
  static const double warningBuffer = 5.0;  // Warn at limit - 5
  
  // User can customize
  double userSpeedLimit;
  bool alertsEnabled;
  bool hapticEnabled;
  
  SpeedAlertLevel getAlertLevel(double currentSpeed) {
    if (!alertsEnabled) return SpeedAlertLevel.none;
    
    if (currentSpeed >= userSpeedLimit) {
      return SpeedAlertLevel.danger;
    }
    
    if (currentSpeed >= userSpeedLimit - warningBuffer) {
      return SpeedAlertLevel.warning;
    }
    
    return SpeedAlertLevel.none;
  }
}

enum SpeedAlertLevel { none, warning, danger }
```

### Alert UI Behavior

```dart
class SpeedAlertController {
  SpeedAlertLevel _currentLevel = SpeedAlertLevel.none;
  DateTime? _lastHaptic;
  
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
        // Change speedometer color to orange
        // Light haptic
        if (config.hapticEnabled) {
          HapticFeedback.lightImpact();
        }
        break;
        
      case SpeedAlertLevel.danger:
        // Change speedometer color to red
        // Pulse animation
        // Heavy haptic
        if (config.hapticEnabled) {
          HapticFeedback.heavyImpact();
        }
        // Log for trip summary
        _logSpeedAlert(newLevel);
        break;
        
      case SpeedAlertLevel.none:
        // Return to normal colors
        break;
    }
  }
  
  void _logSpeedAlert(SpeedAlertLevel level) {
    // Record for trip statistics
    _tripRecorder.addEvent(TripEvent.speedAlert(
      timestamp: DateTime.now(),
      level: level,
    ));
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
    // Reduce GPS polling
    // Pause accelerometer processing
    // Save battery
  }
}
```

---

## 📋 Algorithm Checklist

Before implementing speed tracking:

- [ ] Kalman filter parameters tuned for driving scenarios
- [ ] GPS timeout handling (what happens after 30s without fix?)
- [ ] Accelerometer gravity removal tested
- [ ] Distance calculation uses Haversine
- [ ] Speed smoothing prevents UI jitter
- [ ] Battery optimization adapts to conditions
- [ ] Stationary detection prevents false movement
- [ ] Speed alerts respect user-configured limits
- [ ] All calculations handle null/error cases
- [ ] Unit tests for edge cases (0 speed, max speed, GPS loss)

---

## 🔮 Future: OBD-II Integration

For "Pro" users who want dashboard-accurate speed:

```dart
// Using obd2_plugin or similar
class OBD2SpeedSource {
  BluetoothDevice? _obdDevice;
  
  Stream<double> get speedStream async* {
    if (_obdDevice == null) {
      throw OBDNotConnectedException();
    }
    
    // OBD-II PID for vehicle speed: 0x0D
    while (true) {
      final response = await _obdDevice!.sendCommand('010D');
      final speed = _parseSpeedResponse(response);
      yield speed; // km/h directly from car's ECU
      await Future.delayed(Duration(milliseconds: 200)); // 5 Hz
    }
  }
  
  double _parseSpeedResponse(String response) {
    // Response format: "41 0D XX" where XX is speed in hex
    final parts = response.split(' ');
    if (parts.length >= 3 && parts[0] == '41' && parts[1] == '0D') {
      return int.parse(parts[2], radix: 16).toDouble();
    }
    throw InvalidOBDResponse(response);
  }
}
```

**Benefits:**
- Works in tunnels (no GPS needed)
- Matches dashboard exactly
- Very fast updates (5-10 Hz)

**Limitations:**
- Requires Bluetooth OBD-II adapter ($5-20)
- Android only (iOS Bluetooth restrictions)
- Only for the driver (not passengers)

---

**Remember:** Speed tracking is the CORE feature. It must be accurate, smooth, and battery-efficient. Test thoroughly in real driving conditions.
