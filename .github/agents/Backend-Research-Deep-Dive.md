# RoadGuard Backend Logic, Edge Cases & Algorithms
## Comprehensive Technical Research Document

> Deep technical research for Flutter road safety app backend implementation

---

# PART 1: Speed Tracking Technology Research

## 1.1 GPS Speed Tracking

### How GPS Calculates Speed

GPS receivers use **two primary methods** to calculate speed:

#### Method 1: Doppler Shift (Instantaneous Velocity)
```
┌─────────────────────────────────────────────────────────────────┐
│                    DOPPLER SHIFT METHOD                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Satellite ──── Radio Signal ────▶ Moving Receiver              │
│                                                                 │
│  • Measures frequency shift of satellite signals                │
│  • Moving toward satellite = higher frequency                   │
│  • Moving away = lower frequency                                │
│  • Direct velocity measurement without position history         │
│                                                                 │
│  Formula: v = (Δf / f₀) × c                                     │
│  Where:                                                         │
│    v = velocity                                                 │
│    Δf = frequency change                                        │
│    f₀ = original frequency (1575.42 MHz for L1)                 │
│    c = speed of light                                           │
│                                                                 │
│  ✓ More accurate at low speeds                                  │
│  ✓ Works even when position is uncertain                        │
│  ✓ Typical accuracy: ±0.1 m/s (0.36 km/h)                       │
└─────────────────────────────────────────────────────────────────┘
```

#### Method 2: Position Delta (Derived Velocity)
```
┌─────────────────────────────────────────────────────────────────┐
│                   POSITION DELTA METHOD                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Position₁ (t=0) ────────────▶ Position₂ (t=1s)                 │
│       ↓                              ↓                          │
│   (lat1, lon1)                  (lat2, lon2)                    │
│                                                                 │
│  Speed = Distance / Time                                        │
│                                                                 │
│  Haversine Formula for Distance:                                │
│  a = sin²(Δlat/2) + cos(lat1) × cos(lat2) × sin²(Δlon/2)       │
│  c = 2 × atan2(√a, √(1-a))                                     │
│  d = R × c  (R = 6371 km)                                      │
│                                                                 │
│  ✗ Amplifies position errors                                    │
│  ✗ Noisy at low speeds                                          │
│  ✓ Better for average speed over longer intervals               │
└─────────────────────────────────────────────────────────────────┘
```

### GPS Accuracy and Update Rates

```dart
/// GPS Accuracy Specifications
class GPSSpecs {
  // Position Accuracy
  static const horizontalAccuracy = '3-5 meters';      // Open sky
  static const verticalAccuracy = '5-10 meters';       // Open sky
  static const urbanAccuracy = '10-30 meters';         // Urban canyon
  
  // Speed Accuracy  
  static const dopplerSpeedAccuracy = '0.1 m/s';       // ~0.36 km/h
  static const derivedSpeedAccuracy = '1-2 m/s';       // From position
  
  // Update Rates (typical consumer devices)
  static const standardUpdateRate = '1 Hz';            // 1 update/second
  static const highPrecisionRate = '5-10 Hz';          // Gaming GPS
  static const phoneGPSRate = '1 Hz';                  // Most phones
  
  // Time To First Fix (TTFF)
  static const coldStart = '30-60 seconds';            // No almanac data
  static const warmStart = '5-15 seconds';             // Has almanac
  static const hotStart = '1-2 seconds';               // Recent fix
}
```

### GPS Failure Modes

```
┌─────────────────────────────────────────────────────────────────┐
│                    GPS FAILURE SCENARIOS                        │
├──────────────────┬──────────────────────────────────────────────┤
│ Scenario         │ Cause & Mitigation                           │
├──────────────────┼──────────────────────────────────────────────┤
│ TUNNELS          │ Complete signal loss                         │
│                  │ → Use accelerometer dead reckoning           │
│                  │ → Cache last known position + velocity       │
│                  │ → Estimate exit time from tunnel length      │
├──────────────────┼──────────────────────────────────────────────┤
│ URBAN CANYONS    │ Multipath reflections from buildings         │
│                  │ → Position jumps erratically                 │
│                  │ → Use Kalman filter to smooth                │
│                  │ → Reject positions > 3σ from prediction      │
├──────────────────┼──────────────────────────────────────────────┤
│ DENSE FOLIAGE    │ Signal attenuation through trees             │
│                  │ → Accuracy degrades to 10-20m                │
│                  │ → Increase position uncertainty estimate     │
├──────────────────┼──────────────────────────────────────────────┤
│ WEATHER          │ Ionospheric delays during storms             │
│                  │ → Position drift up to 10m                   │
│                  │ → Use WAAS/EGNOS corrections if available    │
├──────────────────┼──────────────────────────────────────────────┤
│ INDOOR           │ No direct satellite visibility               │
│                  │ → Fall back to WiFi/cell positioning         │
│                  │ → Detect indoor via accelerometer patterns   │
├──────────────────┼──────────────────────────────────────────────┤
│ COLD START       │ No cached satellite data                     │
│                  │ → Show "Acquiring GPS..." UI                 │
│                  │ → Use A-GPS (network-assisted) to speed up   │
└──────────────────┴──────────────────────────────────────────────┘
```

### Time To First Fix (TTFF) Deep Dive

```dart
/// TTFF Scenarios and Handling
enum TTFFScenario {
  /// Device just powered on, no cached data
  /// Needs to download full almanac from satellites
  coldStart,    // 30-60 seconds
  
  /// Device has almanac but no recent ephemeris
  /// Knows where satellites should be, needs current positions
  warmStart,    // 5-15 seconds
  
  /// Device has recent fix (< 2 hours old)
  /// Satellite data still valid
  hotStart,     // 1-2 seconds
}

/// A-GPS (Assisted GPS) dramatically reduces TTFF
/// by downloading satellite data via cellular/WiFi
class AGPSBenefits {
  static const coldStartImprovement = '30s → 5s';
  static const warmStartImprovement = '15s → 2s';
  static const hotStartImprovement = '2s → <1s';
}
```

---

## 1.2 Accelerometer-Based Speed Estimation

### Dead Reckoning Explained

```
┌─────────────────────────────────────────────────────────────────┐
│                     DEAD RECKONING                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Starting Position + ∫∫ Acceleration dt² = Current Position    │
│                                                                 │
│  Step 1: Measure acceleration (ax, ay, az)                      │
│  Step 2: Remove gravity component                               │
│  Step 3: Integrate once → velocity                              │
│  Step 4: Integrate again → displacement                         │
│                                                                 │
│  velocity(t) = velocity(0) + ∫₀ᵗ acceleration dt                │
│  position(t) = position(0) + ∫₀ᵗ velocity dt                    │
│                                                                 │
│  CRITICAL PROBLEM: Integration drift                            │
│  • Small errors compound over time                              │
│  • Without correction, error grows quadratically                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Integration Drift Analysis

```dart
/// Integration Drift Calculator
class DriftAnalysis {
  /// Typical MEMS accelerometer bias: 0.01-0.1 m/s²
  static const double typicalBias = 0.05; // m/s²
  
  /// Position error from constant bias
  /// Error = 0.5 × bias × t²
  static double positionError(double timeSeconds) {
    return 0.5 * typicalBias * timeSeconds * timeSeconds;
  }
  
  /// Example drift accumulation:
  ///  1 second:   0.025 meters
  ///  10 seconds: 2.5 meters
  ///  60 seconds: 90 meters   ← UNUSABLE!
  ///  5 minutes:  2.25 km     ← CATASTROPHIC!
}
```

### Phone Accelerometer Specifications

```
┌─────────────────────────────────────────────────────────────────┐
│              TYPICAL PHONE ACCELEROMETER SPECS                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Sensor Type:     MEMS (Micro-Electro-Mechanical Systems)       │
│                                                                 │
│  Range:           ±2g to ±16g (configurable)                    │
│                                                                 │
│  Resolution:      12-16 bits                                    │
│                                                                 │
│  Noise Density:   100-400 µg/√Hz                                │
│                                                                 │
│  Bias Stability:  1-10 mg (0.01-0.1 m/s²)                       │
│                                                                 │
│  Sample Rate:     Up to 400 Hz on Android                       │
│                   Up to 100 Hz on iOS (recommended max)         │
│                                                                 │
│  Accuracy:        ±0.01-0.05 m/s² in ideal conditions           │
│                   ±0.1-0.3 m/s² in real-world usage             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Detecting Car Movement vs Phone Shake

```dart
/// Motion Classification Algorithm
class MotionClassifier {
  /// Vehicle motion characteristics:
  /// - Sustained acceleration in one direction
  /// - Low frequency vibrations (road texture)
  /// - Gradual changes in velocity
  /// - Typical range: 0-3 m/s² for normal driving
  
  /// Phone shake characteristics:
  /// - Rapid oscillations (high frequency)
  /// - Quick direction reversals
  /// - High peak acceleration, zero net displacement
  /// - Typical range: 5-20 m/s² peaks
  
  static bool isVehicleMotion(List<AccelerometerEvent> samples) {
    // 1. Calculate frequency spectrum via FFT
    final spectrum = calculateFFT(samples);
    
    // 2. Vehicle motion has energy at 0-5 Hz
    final lowFreqEnergy = spectrum.energyBetween(0, 5);
    
    // 3. Shake has energy at 5-20 Hz
    final highFreqEnergy = spectrum.energyBetween(5, 20);
    
    // 4. Calculate ratio
    final ratio = lowFreqEnergy / highFreqEnergy;
    
    // Vehicle motion: ratio > 2
    // Phone shake: ratio < 0.5
    return ratio > 2.0;
  }
  
  /// Alternative: Variance-based detection
  static bool isVehicleMotionSimple(List<AccelerometerEvent> samples) {
    // Calculate variance of acceleration magnitude
    final magnitudes = samples.map((e) => 
      sqrt(e.x * e.x + e.y * e.y + e.z * e.z)
    ).toList();
    
    final mean = magnitudes.average;
    final variance = magnitudes
      .map((m) => (m - mean) * (m - mean))
      .average;
    
    // Vehicle: low variance (0.1-1.0)
    // Shake: high variance (5-50)
    return variance < 2.0;
  }
}
```

---

## 1.3 Sensor Fusion & Kalman Filter

### What is a Kalman Filter?

```
┌─────────────────────────────────────────────────────────────────┐
│                    KALMAN FILTER OVERVIEW                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Purpose: Optimally combine noisy measurements with a           │
│           prediction model to estimate true state               │
│                                                                 │
│  Two-Phase Cycle:                                               │
│                                                                 │
│  ┌─────────────┐     ┌──────────────┐                          │
│  │   PREDICT   │ ──▶ │   UPDATE     │                          │
│  │ (Time Step) │     │ (Measurement)│                          │
│  └─────────────┘     └──────────────┘                          │
│        │                    │                                   │
│        ▼                    ▼                                   │
│  Use physics model    Compare prediction                        │
│  to predict next      with measurement,                         │
│  state                blend optimally                           │
│                                                                 │
│  Key Insight: Each sensor has UNCERTAINTY                       │
│  Kalman Filter finds optimal weighted average                   │
│  based on each sensor's reliability                             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Kalman Filter Mathematics

```dart
/// Simplified 1D Kalman Filter for Speed
class SimpleKalmanFilter {
  double _estimate;           // Current best estimate
  double _errorEstimate;      // Uncertainty in estimate
  final double _errorMeasure; // Measurement noise
  final double _processNoise; // How much state changes between updates
  
  SimpleKalmanFilter({
    required double initialEstimate,
    required double initialError,
    required double measurementNoise,
    required double processNoise,
  }) : _estimate = initialEstimate,
       _errorEstimate = initialError,
       _errorMeasure = measurementNoise,
       _processNoise = processNoise;
  
  double update(double measurement) {
    // PREDICT STEP
    // (In simple case, prediction = previous estimate)
    // Increase uncertainty due to process noise
    _errorEstimate += _processNoise;
    
    // UPDATE STEP
    // Calculate Kalman Gain (how much to trust measurement)
    final kalmanGain = _errorEstimate / (_errorEstimate + _errorMeasure);
    
    // Update estimate: blend prediction with measurement
    _estimate = _estimate + kalmanGain * (measurement - _estimate);
    
    // Update uncertainty
    _errorEstimate = (1 - kalmanGain) * _errorEstimate;
    
    return _estimate;
  }
}

/// Full 2D Kalman Filter for Position + Velocity
/// State vector: [x, y, vx, vy]
class FullKalmanFilter {
  // State transition matrix (constant velocity model)
  // x(k+1) = x(k) + vx(k) * dt
  // y(k+1) = y(k) + vy(k) * dt
  // vx(k+1) = vx(k)
  // vy(k+1) = vy(k)
  
  Matrix4 getStateTransitionMatrix(double dt) {
    return Matrix4([
      [1, 0, dt, 0 ],  // x
      [0, 1, 0,  dt],  // y
      [0, 0, 1,  0 ],  // vx
      [0, 0, 0,  1 ],  // vy
    ]);
  }
  
  // Process noise covariance (uncertainty in model)
  // Accounts for accelerations not in our simple model
  Matrix4 getProcessNoise(double dt, double accelVariance) {
    final dt2 = dt * dt;
    final dt3 = dt2 * dt;
    final dt4 = dt3 * dt;
    final q = accelVariance;
    
    return Matrix4([
      [dt4/4*q, 0,       dt3/2*q, 0      ],
      [0,       dt4/4*q, 0,       dt3/2*q],
      [dt3/2*q, 0,       dt2*q,   0      ],
      [0,       dt3/2*q, 0,       dt2*q  ],
    ]);
  }
}
```

### Fusing GPS + Accelerometer

```dart
/// Sensor Fusion Strategy
class SensorFusion {
  final kalman = FullKalmanFilter();
  
  /// GPS characteristics:
  /// - Absolute position (no drift)
  /// - Noisy (3-30m accuracy)
  /// - Low update rate (1 Hz)
  /// - Can fail completely
  
  /// Accelerometer characteristics:
  /// - Relative changes only
  /// - Low noise (0.01 m/s²)
  /// - High update rate (100 Hz)
  /// - Drifts over time
  
  void fuseData(GPSReading? gps, AccelerometerReading accel, Duration dt) {
    // PREDICT: Use accelerometer for high-frequency prediction
    // Between GPS updates, accelerometer predicts position changes
    kalman.predict(
      controlInput: accel,
      dt: dt,
      processNoise: accelerometerUncertainty,
    );
    
    // UPDATE: When GPS available, correct the prediction
    if (gps != null && gps.accuracy < maxAcceptableAccuracy) {
      kalman.update(
        measurement: gps.position,
        measurementNoise: gps.accuracy,
      );
    }
  }
}
```

### Flutter Packages for Sensor Fusion

```yaml
# Available packages (from pub.dev research)
dependencies:
  # Kalman Filter implementations
  simple_kalman: ^1.0.2           # 1D Kalman filter (380 downloads)
  kalman_filter: ^0.0.1           # General purpose (13 downloads)
  
  # Background location with sensor fusion built-in
  flutter_background_geolocation: ^5.0.2  # RECOMMENDED
  # - 829 likes, 40,604 downloads
  # - Built-in motion detection
  # - Battery-conscious tracking
  # - Handles GPS failures automatically
  # - Commercial license required for production
  
  # Alternative background tracking
  locus: ^2.0.1                   # Free alternative (438 downloads)
  background_task: ^0.2.0+2       # Simpler option
  
  # Sensors
  sensors_plus: ^7.0.0            # Accelerometer, gyroscope
```

### Fallback Strategy When GPS Lost

```dart
/// GPS Fallback State Machine
enum GPSState {
  available,      // GPS working normally
  degraded,       // High uncertainty (accuracy > 30m)
  lost,           // No GPS for > 3 seconds
  recovered,      // Just regained signal
}

class GPSFallbackManager {
  GPSState _state = GPSState.available;
  DateTime? _lostTime;
  Position? _lastGoodPosition;
  double _lastGoodSpeed = 0;
  
  // Accelerometer-based dead reckoning buffer
  final _accelBuffer = <AccelerometerEvent>[];
  
  void onGPSUpdate(Position? position) {
    if (position == null || position.accuracy > 50) {
      _handleGPSLoss();
      return;
    }
    
    if (_state == GPSState.lost) {
      _handleGPSRecovery(position);
    }
    
    _state = GPSState.available;
    _lastGoodPosition = position;
    _lastGoodSpeed = position.speed;
  }
  
  void _handleGPSLoss() {
    _lostTime ??= DateTime.now();
    _state = GPSState.lost;
    
    // Switch to dead reckoning
    // Use last known speed + direction
    // Update position using accelerometer integration
    // BUT limit dead reckoning to 60 seconds max
    // After that, uncertainty is too high
  }
  
  Position estimateCurrentPosition() {
    if (_state == GPSState.available) {
      return _lastGoodPosition!;
    }
    
    // Dead reckoning calculation
    final elapsed = DateTime.now().difference(_lostTime!);
    
    // Simple: assume constant velocity
    final distance = _lastGoodSpeed * elapsed.inSeconds;
    final bearing = _lastGoodPosition!.heading;
    
    return calculateNewPosition(
      _lastGoodPosition!,
      distance,
      bearing,
      // Uncertainty grows with time
      accuracy: 10 + (elapsed.inSeconds * 5),
    );
  }
}
```

---

## 1.4 OBD-II Integration (Future Enhancement)

### Available OBD-II Data

```
┌─────────────────────────────────────────────────────────────────┐
│                    OBD-II DATA AVAILABLE                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  STANDARD PIDs (Mode 01 - Real-time data):                      │
│                                                                 │
│  Speed & Motion:                                                │
│  ├─ PID 0D: Vehicle Speed (0-255 km/h)        ← VERY USEFUL     │
│  ├─ PID 0C: Engine RPM                                          │
│  └─ PID 11: Throttle Position                                   │
│                                                                 │
│  Engine Status:                                                 │
│  ├─ PID 04: Calculated Engine Load                              │
│  ├─ PID 05: Coolant Temperature                                 │
│  ├─ PID 0F: Intake Air Temperature                              │
│  └─ PID 2F: Fuel Tank Level                                     │
│                                                                 │
│  Diagnostics:                                                   │
│  ├─ PID 01: Monitor Status (check engine light)                 │
│  ├─ PID 21: Distance with MIL on                                │
│  └─ DTC codes (Mode 03)                                         │
│                                                                 │
│  EXTENDED PIDs (Manufacturer-specific):                         │
│  ├─ Steering angle                                              │
│  ├─ Brake pressure                                              │
│  ├─ ABS status                                                  │
│  └─ Varies by vehicle                                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Flutter OBD-II Packages

```yaml
# Available package (limited options)
dependencies:
  bluetooth_obd: ^0.0.6     # 20 likes, 37 downloads
  # - Connects to ELM327 Bluetooth adapters
  # - Reads standard PIDs
  # - Android only (no iOS Bluetooth Classic)
  
  # For BLE OBD adapters:
  flutter_blue_plus: ^1.32.0  # Generic BLE
  # Would need custom protocol implementation
```

### OBD-II Limitations

```
┌─────────────────────────────────────────────────────────────────┐
│                    OBD-II LIMITATIONS                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Hardware Requirements:                                         │
│  ✗ User must purchase OBD adapter ($15-50)                      │
│  ✗ Must be installed in car's OBD port                          │
│  ✗ ELM327 clones have quality issues                            │
│                                                                 │
│  Platform Issues:                                               │
│  ✗ iOS doesn't support Bluetooth Classic                        │
│    (Most OBD adapters use Classic, not BLE)                     │
│  ✗ WiFi OBD adapters have interference issues                   │
│                                                                 │
│  Update Rate:                                                   │
│  ✗ Typical: 2-10 updates per second                             │
│  ✗ Limited by CAN bus polling                                   │
│                                                                 │
│  Vehicle Compatibility:                                         │
│  ✗ Pre-1996 vehicles (US) / Pre-2001 (EU) not supported         │
│  ✗ Some PIDs not implemented by all manufacturers               │
│                                                                 │
│  RECOMMENDATION:                                                │
│  → Keep as optional "enhanced accuracy" feature                  │
│  → GPS + Accelerometer should be primary                         │
│  → OBD provides ground truth for calibration                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

# PART 2: Backend Edge Cases to Handle

## 2.1 Connectivity Chaos

### User Loses Connection Mid-Trip

```dart
/// Offline-First Trip Recording
class OfflineTripManager {
  final HiveBox<TripSegment> _localQueue;
  final FirebaseFirestore _firestore;
  final ConnectivityChecker _connectivity;
  
  /// Strategy: Write-Ahead Log (WAL) pattern
  /// 1. ALWAYS write to local storage FIRST
  /// 2. Attempt sync to server
  /// 3. Mark as synced only after confirmation
  /// 4. Retry unsynced segments when online
  
  Future<void> recordLocation(LocationEvent event) async {
    // Step 1: Create trip segment
    final segment = TripSegment(
      id: uuid.v4(),
      tripId: currentTripId,
      timestamp: DateTime.now(),
      serverTimestamp: null, // Set by server
      position: event.position,
      speed: event.speed,
      accuracy: event.accuracy,
      syncStatus: SyncStatus.pending,
      retryCount: 0,
    );
    
    // Step 2: ALWAYS save locally first (survives crash)
    await _localQueue.put(segment.id, segment);
    
    // Step 3: Attempt server sync (non-blocking)
    _attemptSync(segment);
  }
  
  Future<void> _attemptSync(TripSegment segment) async {
    if (!await _connectivity.isConnected) {
      return; // Will sync later
    }
    
    try {
      // Use Firestore transaction for atomicity
      await _firestore.runTransaction((txn) async {
        final tripRef = _firestore.collection('trips').doc(segment.tripId);
        final segmentRef = tripRef.collection('segments').doc(segment.id);
        
        txn.set(segmentRef, segment.toJson());
        txn.update(tripRef, {
          'lastSegmentTime': FieldValue.serverTimestamp(),
          'segmentCount': FieldValue.increment(1),
        });
      });
      
      // Mark as synced locally
      segment.syncStatus = SyncStatus.synced;
      segment.serverTimestamp = DateTime.now();
      await _localQueue.put(segment.id, segment);
      
    } catch (e) {
      // Will retry later
      segment.retryCount++;
      await _localQueue.put(segment.id, segment);
    }
  }
  
  /// Call on app startup and when connectivity restored
  Future<void> syncPendingSegments() async {
    final pending = _localQueue.values
        .where((s) => s.syncStatus == SyncStatus.pending)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    for (final segment in pending) {
      await _attemptSync(segment);
      
      // Don't hammer the server
      await Future.delayed(Duration(milliseconds: 100));
    }
  }
}
```

### App Crashes During Trip - Recovery

```dart
/// Trip Recovery System
class TripRecoveryManager {
  static const _activeTripKey = 'active_trip_id';
  static const _tripStateKey = 'trip_state';
  
  /// Called on every app startup
  Future<TripRecoveryResult> checkForUnfinishedTrip() async {
    final prefs = await SharedPreferences.getInstance();
    final activeTripId = prefs.getString(_activeTripKey);
    
    if (activeTripId == null) {
      return TripRecoveryResult.noTripFound;
    }
    
    // Load trip state from Hive
    final tripBox = await Hive.openBox<Trip>('trips');
    final trip = tripBox.get(activeTripId);
    
    if (trip == null) {
      // Corrupt state, clean up
      await prefs.remove(_activeTripKey);
      return TripRecoveryResult.corrupted;
    }
    
    // Check how long since last segment
    final lastSegment = await _getLastSegment(activeTripId);
    final timeSinceLastSegment = 
        DateTime.now().difference(lastSegment?.timestamp ?? trip.startTime);
    
    if (timeSinceLastSegment > Duration(hours: 24)) {
      // Trip is stale, auto-end it
      await _autoEndTrip(trip, reason: 'stale');
      return TripRecoveryResult.autoEnded;
    }
    
    // Recoverable! Ask user what to do
    return TripRecoveryResult.recoverable(
      trip: trip,
      lastPosition: lastSegment?.position,
      timeSinceLastUpdate: timeSinceLastSegment,
    );
  }
  
  /// User chooses to resume
  Future<void> resumeTrip(String tripId) async {
    // Add recovery marker to trip
    await _addSegment(tripId, TripSegment(
      type: SegmentType.recoveryMarker,
      timestamp: DateTime.now(),
      metadata: {'reason': 'app_crash_recovery'},
    ));
    
    // Continue tracking
    _tripTracker.start(tripId, isResume: true);
  }
  
  /// User chooses to end
  Future<void> endRecoveredTrip(String tripId) async {
    await _autoEndTrip(
      tripId,
      reason: 'user_ended_after_recovery',
    );
  }
}
```

### Data Syncs Out of Order

```dart
/// Handling Out-of-Order Data
/// 
/// Problem: Segments arrive at server as: 3, 1, 4, 2
/// Need to reconstruct timeline correctly

class OrderedDataHandler {
  /// Solution 1: Client-side timestamps with server verification
  /// 
  /// Each segment has:
  /// - clientTimestamp: When client recorded it
  /// - clientSequence: Monotonic counter (never resets)
  /// - serverTimestamp: When server received it
  
  TripSegment createSegment(Position position) {
    return TripSegment(
      clientTimestamp: DateTime.now(),
      clientSequence: _getNextSequence(),
      position: position,
    );
  }
  
  int _sequence = 0;
  int _getNextSequence() => ++_sequence;
  
  /// Solution 2: Server-side reordering on query
  /// 
  /// Firestore query:
  /// .orderBy('clientTimestamp', descending: false)
  /// .orderBy('clientSequence', descending: false)
  
  Query getOrderedSegments(String tripId) {
    return _firestore
        .collection('trips')
        .doc(tripId)
        .collection('segments')
        .orderBy('clientTimestamp')
        .orderBy('clientSequence');
  }
  
  /// Solution 3: Gap detection and filling
  void detectGaps(List<TripSegment> segments) {
    for (int i = 1; i < segments.length; i++) {
      final gap = segments[i].clientSequence - segments[i-1].clientSequence;
      if (gap > 1) {
        // Missing segments detected!
        _requestMissingSegments(
          tripId: segments[i].tripId,
          fromSeq: segments[i-1].clientSequence + 1,
          toSeq: segments[i].clientSequence - 1,
        );
      }
    }
  }
}
```

### Idempotency - Preventing Duplicate Submissions

```dart
/// Idempotent Operation Handler
/// 
/// Problem: Network timeout after server processed request
/// Client doesn't know if it succeeded, retries
/// Without idempotency, action happens twice

class IdempotentOperations {
  /// Strategy 1: Client-generated idempotency key
  Future<void> submitRating({
    required String driverId,
    required int rating,
    required String comment,
  }) async {
    // Generate deterministic key based on operation parameters
    final idempotencyKey = generateIdempotencyKey(
      userId: currentUser.id,
      driverId: driverId,
      timestamp: DateTime.now().toIso8601String().substring(0, 13), // Hour precision
      operation: 'rating',
    );
    
    await _firestore.runTransaction((txn) async {
      // Check if operation already processed
      final existingOp = await txn.get(
        _firestore.collection('idempotency_keys').doc(idempotencyKey)
      );
      
      if (existingOp.exists) {
        // Already processed, return cached result
        return existingOp.data()!['result'];
      }
      
      // Process operation
      final ratingRef = _firestore
          .collection('drivers')
          .doc(driverId)
          .collection('ratings')
          .doc();
      
      txn.set(ratingRef, {
        'rating': rating,
        'comment': comment,
        'userId': currentUser.id,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Store idempotency record (expires after 24 hours)
      txn.set(
        _firestore.collection('idempotency_keys').doc(idempotencyKey),
        {
          'result': {'ratingId': ratingRef.id},
          'createdAt': FieldValue.serverTimestamp(),
          'expiresAt': DateTime.now().add(Duration(hours: 24)),
        },
      );
    });
  }
  
  String generateIdempotencyKey(Map<String, String> params) {
    final sorted = params.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final canonical = sorted.map((e) => '${e.key}=${e.value}').join('&');
    return sha256.convert(utf8.encode(canonical)).toString();
  }
}
```

### Wrong Device Clock Handling

```dart
/// Clock Skew Detection and Handling
class ClockSkewManager {
  Duration? _estimatedSkew;
  
  /// Estimate clock skew on app startup
  Future<void> calibrateClock() async {
    // Method 1: Use server timestamp
    final before = DateTime.now();
    
    // Make a simple server request
    final serverDoc = await _firestore
        .collection('system')
        .doc('clock')
        .get();
    
    final after = DateTime.now();
    
    // Server timestamp
    final serverTime = (serverDoc.data()!['timestamp'] as Timestamp).toDate();
    
    // Estimate: server time was at midpoint of request
    final requestMidpoint = before.add(
      after.difference(before) ~/ 2
    );
    
    _estimatedSkew = serverTime.difference(requestMidpoint);
    
    // If skew > 5 minutes, warn user
    if (_estimatedSkew!.abs() > Duration(minutes: 5)) {
      _showClockWarning();
    }
  }
  
  /// Always store both client and server timestamps
  Map<String, dynamic> createTimestampedRecord(Map<String, dynamic> data) {
    return {
      ...data,
      'clientTimestamp': DateTime.now().toIso8601String(),
      'estimatedSkew': _estimatedSkew?.inMilliseconds,
      'serverTimestamp': FieldValue.serverTimestamp(),
    };
  }
  
  /// For trip calculations, use server timestamps when available
  Duration calculateTripDuration(Trip trip) {
    // Prefer server timestamps
    if (trip.serverStartTime != null && trip.serverEndTime != null) {
      return trip.serverEndTime!.difference(trip.serverStartTime!);
    }
    
    // Fallback to client timestamps with skew correction
    final correctedStart = trip.clientStartTime.add(_estimatedSkew ?? Duration.zero);
    final correctedEnd = trip.clientEndTime.add(_estimatedSkew ?? Duration.zero);
    return correctedEnd.difference(correctedStart);
  }
}
```

---

## 2.2 Data Integrity

### Preventing Duplicate Ratings

```dart
/// Rating Deduplication Strategy
class RatingDeduplicator {
  /// Rule: One rating per user per driver per 24-hour period
  /// Exception: Different vehicles/trips
  
  Future<bool> canUserRateDriver({
    required String userId,
    required String driverId,
    required String? plateNumber,
  }) async {
    final recentRatings = await _firestore
        .collection('ratings')
        .where('userId', isEqualTo: userId)
        .where('driverId', isEqualTo: driverId)
        .where('timestamp', isGreaterThan: 
            Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 24))))
        .get();
    
    if (recentRatings.docs.isEmpty) {
      return true; // No recent rating
    }
    
    // If same plate number, it's a duplicate
    final samePlate = recentRatings.docs.any(
      (doc) => doc.data()['plateNumber'] == plateNumber
    );
    
    if (samePlate) {
      return false; // Duplicate!
    }
    
    // Different vehicle (same driver owns multiple), allow
    return true;
  }
  
  /// Firestore Rules for server-side enforcement
  /// 
  /// match /ratings/{ratingId} {
  ///   allow create: if
  ///     // Authenticated
  ///     request.auth != null &&
  ///     // User ID matches
  ///     request.resource.data.userId == request.auth.uid &&
  ///     // Check for recent duplicate (requires Cloud Function)
  ///     !exists(/databases/$(database)/documents/rating_locks/$(ratingLockId));
  /// }
}
```

### Concurrent Writes to Same Driver

```dart
/// Handling Concurrent Rating Updates
/// 
/// Problem: 10 users rate same driver simultaneously
/// Each reads rating=4.0, adds their rating, writes back
/// Result: Only last write survives, others lost

class ConcurrentWriteHandler {
  /// Solution: Firestore Transactions + Atomic Increments
  Future<void> addRating({
    required String driverId,
    required int rating,
  }) async {
    final driverRef = _firestore.collection('drivers').doc(driverId);
    final ratingRef = driverRef.collection('ratings').doc();
    
    await _firestore.runTransaction((txn) async {
      // Read current stats (creates lock)
      final driverDoc = await txn.get(driverRef);
      
      // Write new rating
      txn.set(ratingRef, {
        'rating': rating,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Update stats atomically
      if (driverDoc.exists) {
        txn.update(driverRef, {
          'ratingSum': FieldValue.increment(rating),
          'ratingCount': FieldValue.increment(1),
        });
      } else {
        txn.set(driverRef, {
          'ratingSum': rating,
          'ratingCount': 1,
        });
      }
    });
  }
  
  /// Alternative: Use Cloud Functions for aggregation
  /// 
  /// exports.onRatingCreated = functions.firestore
  ///   .document('drivers/{driverId}/ratings/{ratingId}')
  ///   .onCreate(async (snap, context) => {
  ///     const rating = snap.data().rating;
  ///     const driverRef = snap.ref.parent.parent;
  ///     
  ///     await driverRef.update({
  ///       ratingSum: admin.firestore.FieldValue.increment(rating),
  ///       ratingCount: admin.firestore.FieldValue.increment(1),
  ///     });
  ///   });
}
```

### Preventing Data Loss on Crash

```dart
/// Crash-Safe Data Persistence
class CrashSafeStorage {
  /// Strategy: Multi-layer persistence
  /// 
  /// Layer 1: In-memory (fastest, lost on crash)
  /// Layer 2: Hive with write-ahead log (survives crash)
  /// Layer 3: Firebase (survives app uninstall)
  
  final _memoryCache = <String, dynamic>{};
  late final Box<dynamic> _hiveBox;
  
  Future<void> saveTrip(Trip trip) async {
    // Layer 1: Memory (instant)
    _memoryCache[trip.id] = trip;
    
    // Layer 2: Hive (< 5ms, crash safe)
    // Hive uses write-ahead logging internally
    await _hiveBox.put(trip.id, trip.toJson());
    
    // Layer 3: Firebase (async, network dependent)
    _syncToFirebase(trip);
  }
  
  /// Recovery on startup
  Future<List<Trip>> recoverTrips() async {
    // Check Hive for unsynced trips
    final localTrips = _hiveBox.values
        .map((json) => Trip.fromJson(json))
        .where((trip) => !trip.isSynced)
        .toList();
    
    for (final trip in localTrips) {
      _syncToFirebase(trip);
    }
    
    return localTrips;
  }
}
```

### Firebase Quota Handling

```dart
/// Firebase Quota Management
/// 
/// Firestore Limits (Spark/Free tier):
/// - 50,000 reads/day
/// - 20,000 writes/day
/// - 20,000 deletes/day
/// - 1 GB storage
/// 
/// Blaze (Pay-as-you-go):
/// - $0.06 per 100K reads
/// - $0.18 per 100K writes

class QuotaManager {
  int _estimatedReadsToday = 0;
  int _estimatedWritesToday = 0;
  
  static const _dailyReadLimit = 45000;  // Leave buffer
  static const _dailyWriteLimit = 18000;
  
  /// Track operations locally
  void trackOperation(OperationType type, int count) {
    switch (type) {
      case OperationType.read:
        _estimatedReadsToday += count;
        break;
      case OperationType.write:
        _estimatedWritesToday += count;
        break;
    }
    
    _checkQuotaWarnings();
  }
  
  void _checkQuotaWarnings() {
    if (_estimatedReadsToday > _dailyReadLimit * 0.8) {
      _enableReadThrottling();
    }
    if (_estimatedWritesToday > _dailyWriteLimit * 0.8) {
      _enableWriteThrottling();
    }
  }
  
  /// Throttling strategies
  void _enableReadThrottling() {
    // 1. Increase cache TTL
    // 2. Reduce refresh frequency
    // 3. Batch queries
    // 4. Show cached data with "Offline Mode" indicator
  }
  
  void _enableWriteThrottling() {
    // 1. Batch writes (max 500 per batch)
    // 2. Queue non-critical writes
    // 3. Increase location recording interval
    // 4. Alert user if critical
  }
  
  /// Batch write optimization
  Future<void> batchWriteSegments(List<TripSegment> segments) async {
    // Firestore batch limit: 500 operations
    const batchSize = 500;
    
    for (var i = 0; i < segments.length; i += batchSize) {
      final batch = _firestore.batch();
      final chunk = segments.skip(i).take(batchSize);
      
      for (final segment in chunk) {
        final ref = _firestore
            .collection('trips')
            .doc(segment.tripId)
            .collection('segments')
            .doc(segment.id);
        batch.set(ref, segment.toJson());
      }
      
      await batch.commit();
      trackOperation(OperationType.write, chunk.length);
    }
  }
}
```

---

## 2.3 Performance at Scale

### Geohashing for Location Queries

```
┌─────────────────────────────────────────────────────────────────┐
│                        GEOHASHING                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Problem: Finding nearby drivers among 50,000 users             │
│                                                                 │
│  Naive approach:                                                │
│  - Load ALL drivers                                             │
│  - Calculate distance to each                                   │
│  - Filter by radius                                             │
│  ❌ O(n) reads = 50,000 reads = $30/day at scale!               │
│                                                                 │
│  Geohash solution:                                              │
│  - Encode lat/lng into string: "s02equ04" (Accra example)       │
│  - Nearby locations share prefix                                │
│  - Query by prefix = O(1) index lookup                          │
│                                                                 │
│  Geohash precision:                                             │
│  ├─ 1 char:  ±2500 km                                           │
│  ├─ 2 chars: ±630 km                                            │
│  ├─ 3 chars: ±78 km                                             │
│  ├─ 4 chars: ±20 km                                             │
│  ├─ 5 chars: ±2.4 km                                            │
│  ├─ 6 chars: ±610 m                                             │
│  ├─ 7 chars: ±76 m                                              │
│  └─ 8 chars: ±19 m                                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

```dart
/// Geohash Implementation with geoflutterfire_plus
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

class NearbyDriversQuery {
  final geo = GeoFlutterFire();
  
  /// Query drivers within 5km radius
  Stream<List<Driver>> getNearbyDrivers({
    required double lat,
    required double lng,
    double radiusKm = 5.0,
  }) {
    // Create query reference
    final collectionRef = _firestore.collection('active_drivers');
    
    // Create geo point
    final center = GeoFirePoint(lat, lng);
    
    // Query with geohash
    return geo.collection(collectionRef: collectionRef)
        .within(
          center: center,
          radius: radiusKm,
          field: 'position', // Field containing GeoPoint
          geopointFrom: (data) => data['position'] as GeoPoint,
        )
        .map((docs) => docs.map((doc) => Driver.fromDoc(doc)).toList());
  }
  
  /// Store driver with geohash
  Future<void> updateDriverLocation(String driverId, double lat, double lng) async {
    final point = GeoFirePoint(lat, lng);
    
    await _firestore.collection('active_drivers').doc(driverId).set({
      'position': point.geoPoint,
      'geohash': point.geohash,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
```

### Caching Strategies for Driver Ratings

```dart
/// Multi-Level Caching Strategy
class RatingCache {
  // Level 1: Memory cache (LRU, 1000 entries max)
  final _memoryCache = LruCache<String, DriverRating>(maxSize: 1000);
  
  // Level 2: Hive local storage
  late final Box<DriverRating> _hiveCache;
  
  // Level 3: Firestore (source of truth)
  final FirebaseFirestore _firestore;
  
  /// Cache TTL
  static const _memoryCacheTTL = Duration(minutes: 5);
  static const _localCacheTTL = Duration(hours: 1);
  
  Future<DriverRating?> getRating(String driverId) async {
    // Level 1: Check memory
    final memEntry = _memoryCache.get(driverId);
    if (memEntry != null && !memEntry.isExpired(_memoryCacheTTL)) {
      return memEntry;
    }
    
    // Level 2: Check Hive
    final localEntry = _hiveCache.get(driverId);
    if (localEntry != null && !localEntry.isExpired(_localCacheTTL)) {
      // Promote to memory cache
      _memoryCache.put(driverId, localEntry);
      return localEntry;
    }
    
    // Level 3: Fetch from Firestore
    final doc = await _firestore.collection('drivers').doc(driverId).get();
    if (!doc.exists) return null;
    
    final rating = DriverRating.fromDoc(doc);
    
    // Populate caches
    _memoryCache.put(driverId, rating);
    await _hiveCache.put(driverId, rating);
    
    return rating;
  }
  
  /// Invalidate on update
  Future<void> invalidate(String driverId) async {
    _memoryCache.remove(driverId);
    await _hiveCache.delete(driverId);
  }
  
  /// Preload popular drivers
  Future<void> preloadPopularDrivers() async {
    final popular = await _firestore
        .collection('drivers')
        .orderBy('ratingCount', descending: true)
        .limit(100)
        .get();
    
    for (final doc in popular.docs) {
      final rating = DriverRating.fromDoc(doc);
      _memoryCache.put(doc.id, rating);
      await _hiveCache.put(doc.id, rating);
    }
  }
}
```

### Pagination for Large Datasets

```dart
/// Cursor-Based Pagination
/// 
/// Why cursor-based over offset-based?
/// - Offset: Skip 1000 items = read 1000 items = $$$
/// - Cursor: Start after document = index lookup = cheap

class PaginatedQuery<T> {
  final Query _baseQuery;
  final T Function(DocumentSnapshot) _fromDoc;
  
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  
  Future<List<T>> fetchNextPage({int limit = 20}) async {
    if (!_hasMore) return [];
    
    Query query = _baseQuery.limit(limit);
    
    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }
    
    final snapshot = await query.get();
    
    if (snapshot.docs.length < limit) {
      _hasMore = false;
    }
    
    if (snapshot.docs.isNotEmpty) {
      _lastDocument = snapshot.docs.last;
    }
    
    return snapshot.docs.map(_fromDoc).toList();
  }
  
  void reset() {
    _lastDocument = null;
    _hasMore = true;
  }
}

/// Usage
final tripsQuery = PaginatedQuery<Trip>(
  _firestore
      .collection('trips')
      .where('userId', isEqualTo: userId)
      .orderBy('startTime', descending: true),
  Trip.fromDoc,
);

// First page
final page1 = await tripsQuery.fetchNextPage(limit: 20);

// Next page
final page2 = await tripsQuery.fetchNextPage(limit: 20);
```

---

## 2.4 Security Edge Cases

### Rate Limiting

```dart
/// Client-Side + Server-Side Rate Limiting
class RateLimiter {
  // Token bucket algorithm
  final Map<String, _TokenBucket> _buckets = {};
  
  /// Client-side check (UI feedback, but not secure)
  bool canPerformAction(String action, {int maxPerMinute = 10}) {
    final bucket = _buckets.putIfAbsent(
      action,
      () => _TokenBucket(maxTokens: maxPerMinute, refillPerMinute: maxPerMinute),
    );
    
    return bucket.tryConsume();
  }
}

class _TokenBucket {
  final int maxTokens;
  final int refillPerMinute;
  double _tokens;
  DateTime _lastRefill;
  
  _TokenBucket({required this.maxTokens, required this.refillPerMinute})
      : _tokens = maxTokens.toDouble(),
        _lastRefill = DateTime.now();
  
  bool tryConsume() {
    _refill();
    
    if (_tokens >= 1) {
      _tokens -= 1;
      return true;
    }
    return false;
  }
  
  void _refill() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastRefill).inSeconds / 60.0;
    _tokens = min(maxTokens.toDouble(), _tokens + (elapsed * refillPerMinute));
    _lastRefill = now;
  }
}

/// Server-side enforcement (Firestore Rules + Cloud Functions)
/// 
/// // Firestore Rules
/// match /ratings/{ratingId} {
///   allow create: if
///     // Rate limit: max 10 ratings per hour
///     request.time > 
///       resource.data.get('lastRating', timestamp.date(1970,1,1)) + 
///       duration.value(6, 'minutes');
/// }
/// 
/// // Cloud Function rate limiter
/// exports.checkRateLimit = functions.https.onCall(async (data, context) => {
///   const userId = context.auth.uid;
///   const action = data.action;
///   
///   const rateLimitDoc = await admin.firestore()
///     .collection('rate_limits')
///     .doc(`${userId}_${action}`)
///     .get();
///   
///   const now = admin.firestore.Timestamp.now();
///   const windowStart = new Date(now.toDate() - 60000); // 1 minute
///   
///   const recentActions = rateLimitDoc.data()?.actions?.filter(
///     t => t.toDate() > windowStart
///   ) ?? [];
///   
///   if (recentActions.length >= 10) {
///     throw new functions.https.HttpsError(
///       'resource-exhausted',
///       'Rate limit exceeded. Try again later.'
///     );
///   }
///   
///   // Record this action
///   await admin.firestore()
///     .collection('rate_limits')
///     .doc(`${userId}_${action}`)
///     .set({
///       actions: [...recentActions, now],
///     });
///   
///   return { allowed: true };
/// });
```

### Detecting Fake GPS Coordinates

```dart
/// GPS Spoofing Detection
class GPSSpoofDetector {
  final List<Position> _history = [];
  
  /// Detection heuristics
  SpoofDetectionResult analyze(Position position) {
    final results = <SpoofIndicator>[];
    
    // 1. Check for mock location flag (Android)
    if (position.isMocked == true) {
      results.add(SpoofIndicator.mockFlagSet);
    }
    
    // 2. Check for impossible speed
    if (_history.isNotEmpty) {
      final lastPos = _history.last;
      final distance = Geolocator.distanceBetween(
        lastPos.latitude, lastPos.longitude,
        position.latitude, position.longitude,
      );
      final timeDiff = position.timestamp!.difference(lastPos.timestamp!);
      final speed = distance / timeDiff.inSeconds; // m/s
      
      // Max possible: ~340 m/s (supersonic, impossible for car)
      // Suspicious: > 70 m/s (250 km/h)
      if (speed > 70) {
        results.add(SpoofIndicator.impossibleSpeed);
      }
    }
    
    // 3. Check for teleportation
    if (_history.length >= 2) {
      final recentHistory = _history.takeLast(10);
      final avgPosition = _calculateCentroid(recentHistory);
      final distanceFromAvg = Geolocator.distanceBetween(
        avgPosition.latitude, avgPosition.longitude,
        position.latitude, position.longitude,
      );
      
      // Sudden jump > 1km is suspicious
      if (distanceFromAvg > 1000) {
        results.add(SpoofIndicator.teleportation);
      }
    }
    
    // 4. Check altitude consistency
    if (position.altitude != null && _history.isNotEmpty) {
      final lastAlt = _history.last.altitude;
      if (lastAlt != null) {
        final altChange = (position.altitude! - lastAlt).abs();
        // Vertical speed > 50 m/s is impossible for car
        // (even for steep hills)
        if (altChange > 50) {
          results.add(SpoofIndicator.impossibleAltitudeChange);
        }
      }
    }
    
    // 5. Check accelerometer correlation
    // If accelerometer shows no movement but GPS shows motion
    // → Spoofing likely
    
    _history.add(position);
    if (_history.length > 100) _history.removeAt(0);
    
    return SpoofDetectionResult(
      isSuspicious: results.isNotEmpty,
      indicators: results,
      confidence: _calculateConfidence(results),
    );
  }
}
```

### Preventing Self-Rating Manipulation

```dart
/// Rating Integrity Rules
/// 
/// Firestore Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    match /drivers/{driverId} {
      // Anyone can read driver info
      allow read: if true;
      
      // Only system can modify aggregate stats
      allow write: if false;
    }
    
    match /drivers/{driverId}/ratings/{ratingId} {
      // Can read own ratings
      allow read: if request.auth != null;
      
      // Create rating with restrictions
      allow create: if
        // Must be authenticated
        request.auth != null &&
        // Can't rate yourself
        request.auth.uid != driverId &&
        // Rating must be 1-5
        request.resource.data.rating >= 1 &&
        request.resource.data.rating <= 5 &&
        // User ID must match auth
        request.resource.data.userId == request.auth.uid &&
        // Timestamp must be server time
        request.resource.data.timestamp == request.time;
      
      // Can't edit or delete ratings
      allow update, delete: if false;
    }
  }
}
```

---

# PART 3: Retry & Error Handling Patterns

## Exponential Backoff Algorithm

```dart
/// Exponential Backoff with Jitter
class ExponentialBackoff {
  final int maxRetries;
  final Duration baseDelay;
  final Duration maxDelay;
  final double multiplier;
  final bool useJitter;
  
  const ExponentialBackoff({
    this.maxRetries = 5,
    this.baseDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 32),
    this.multiplier = 2.0,
    this.useJitter = true,
  });
  
  /// Calculate delay for attempt number (0-indexed)
  Duration getDelay(int attempt) {
    // Exponential: base * multiplier^attempt
    final exponentialMs = baseDelay.inMilliseconds * 
        pow(multiplier, attempt).toInt();
    
    // Cap at max
    final cappedMs = min(exponentialMs, maxDelay.inMilliseconds);
    
    // Add jitter to prevent thundering herd
    if (useJitter) {
      // Full jitter: random between 0 and calculated delay
      final jitteredMs = Random().nextInt(cappedMs + 1);
      return Duration(milliseconds: jitteredMs);
    }
    
    return Duration(milliseconds: cappedMs);
  }
  
  /// Execute with retry
  Future<T> execute<T>(Future<T> Function() operation) async {
    Exception? lastException;
    
    for (var attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        lastException = e as Exception;
        
        // Check if retryable
        if (!_isRetryable(e)) {
          rethrow;
        }
        
        if (attempt < maxRetries - 1) {
          final delay = getDelay(attempt);
          await Future.delayed(delay);
        }
      }
    }
    
    throw lastException!;
  }
  
  bool _isRetryable(dynamic error) {
    // Network errors
    if (error is SocketException) return true;
    if (error is TimeoutException) return true;
    
    // Firebase errors
    if (error is FirebaseException) {
      // Retry on temporary failures
      return ['unavailable', 'resource-exhausted', 'internal']
          .contains(error.code);
    }
    
    return false;
  }
}

/// Example retry sequences:
/// Attempt 0: 0-1000ms (with jitter)
/// Attempt 1: 0-2000ms
/// Attempt 2: 0-4000ms
/// Attempt 3: 0-8000ms
/// Attempt 4: 0-16000ms
/// Attempt 5: 0-32000ms
```

## Circuit Breaker Pattern

```dart
/// Circuit Breaker State Machine
enum CircuitState {
  closed,    // Normal operation, requests pass through
  open,      // Failing, reject requests immediately
  halfOpen,  // Testing if service recovered
}

class CircuitBreaker {
  final int failureThreshold;      // Failures before opening
  final Duration openDuration;      // How long to stay open
  final Duration halfOpenTimeout;   // How long to test in half-open
  
  CircuitState _state = CircuitState.closed;
  int _failureCount = 0;
  int _successCount = 0;
  DateTime? _lastFailureTime;
  DateTime? _lastStateChange;
  
  CircuitBreaker({
    this.failureThreshold = 5,
    this.openDuration = const Duration(seconds: 30),
    this.halfOpenTimeout = const Duration(seconds: 10),
  });
  
  Future<T> execute<T>(Future<T> Function() operation) async {
    _checkStateTransition();
    
    switch (_state) {
      case CircuitState.closed:
        return _executeInClosed(operation);
      
      case CircuitState.open:
        throw CircuitBreakerOpenException(
          'Circuit is open. Retry after ${_timeUntilHalfOpen}',
        );
      
      case CircuitState.halfOpen:
        return _executeInHalfOpen(operation);
    }
  }
  
  Future<T> _executeInClosed<T>(Future<T> Function() operation) async {
    try {
      final result = await operation();
      _onSuccess();
      return result;
    } catch (e) {
      _onFailure();
      rethrow;
    }
  }
  
  Future<T> _executeInHalfOpen<T>(Future<T> Function() operation) async {
    try {
      final result = await operation();
      _onSuccess();
      // Success in half-open = close circuit
      _transitionTo(CircuitState.closed);
      return result;
    } catch (e) {
      _onFailure();
      // Failure in half-open = reopen circuit
      _transitionTo(CircuitState.open);
      rethrow;
    }
  }
  
  void _onSuccess() {
    _failureCount = 0;
    _successCount++;
  }
  
  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();
    
    if (_failureCount >= failureThreshold) {
      _transitionTo(CircuitState.open);
    }
  }
  
  void _checkStateTransition() {
    if (_state == CircuitState.open) {
      final timeSinceOpen = DateTime.now().difference(_lastStateChange!);
      if (timeSinceOpen >= openDuration) {
        _transitionTo(CircuitState.halfOpen);
      }
    }
  }
  
  void _transitionTo(CircuitState newState) {
    _state = newState;
    _lastStateChange = DateTime.now();
    _failureCount = 0;
    _successCount = 0;
  }
}
```

## Dead Letter Queue for Failed Operations

```dart
/// Dead Letter Queue (DLQ) Implementation
class DeadLetterQueue {
  final HiveBox<FailedOperation> _dlq;
  final int maxRetries;
  final Duration retentionPeriod;
  
  DeadLetterQueue({
    required HiveBox<FailedOperation> box,
    this.maxRetries = 3,
    this.retentionPeriod = const Duration(days: 7),
  }) : _dlq = box;
  
  /// Add failed operation to DLQ
  Future<void> enqueue(FailedOperation operation) async {
    operation.enqueuedAt = DateTime.now();
    operation.retryCount = 0;
    await _dlq.put(operation.id, operation);
    
    // Log for monitoring
    _logger.warning('Operation moved to DLQ', {
      'id': operation.id,
      'type': operation.type,
      'error': operation.lastError,
    });
  }
  
  /// Process DLQ items
  Future<void> processQueue() async {
    final now = DateTime.now();
    final items = _dlq.values.toList();
    
    for (final item in items) {
      // Remove expired items
      if (now.difference(item.enqueuedAt) > retentionPeriod) {
        await _permanentlyFail(item, 'Retention period exceeded');
        continue;
      }
      
      // Skip if max retries exceeded
      if (item.retryCount >= maxRetries) {
        await _permanentlyFail(item, 'Max retries exceeded');
        continue;
      }
      
      // Attempt retry
      try {
        await _retry(item);
        // Success! Remove from DLQ
        await _dlq.delete(item.id);
        _logger.info('DLQ item succeeded on retry', {'id': item.id});
      } catch (e) {
        // Failed again
        item.retryCount++;
        item.lastError = e.toString();
        item.lastRetryAt = now;
        await _dlq.put(item.id, item);
      }
    }
  }
  
  Future<void> _retry(FailedOperation item) async {
    switch (item.type) {
      case OperationType.syncTrip:
        await _tripService.syncTrip(item.payload['tripId']);
        break;
      case OperationType.submitRating:
        await _ratingService.submitRating(
          driverId: item.payload['driverId'],
          rating: item.payload['rating'],
        );
        break;
      // ... other operation types
    }
  }
  
  Future<void> _permanentlyFail(FailedOperation item, String reason) async {
    // Move to permanent failure log
    await _firestore.collection('failed_operations').add({
      ...item.toJson(),
      'permanentlyFailedAt': FieldValue.serverTimestamp(),
      'permanentFailureReason': reason,
    });
    
    // Remove from DLQ
    await _dlq.delete(item.id);
    
    // Alert if needed
    _alertService.notifyOperationPermanentlyFailed(item);
  }
}
```

## Jitter to Prevent Thundering Herd

```
┌─────────────────────────────────────────────────────────────────┐
│                    THUNDERING HERD PROBLEM                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Scenario: Server goes down for 30 seconds                      │
│  - 10,000 clients are retrying                                  │
│  - Server comes back up                                         │
│  - All 10,000 clients retry at exactly the same time            │
│  - Server immediately overloaded again                          │
│  - Repeat forever = "thundering herd"                           │
│                                                                 │
│  Without Jitter (all retry at same time):                       │
│                                                                 │
│  Requests │████████████████████████████████████████             │
│           │                                     ▲               │
│           │                                     │               │
│           └─────────────────────────────────────┘               │
│              ↑ Server recovers                 Overload!        │
│                                                                 │
│  With Jitter (randomized retry times):                          │
│                                                                 │
│  Requests │    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░                │
│           │  ░░    ░░    ░░    ░░    ░░    ░░                   │
│           │░░  ░░    ░░    ░░    ░░    ░░    ░░                 │
│           └─────────────────────────────────────────────────────│
│              ↑ Server recovers                                  │
│              Requests spread over time = manageable             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

```dart
/// Jitter Strategies
class JitterStrategies {
  static final _random = Random();
  
  /// Full Jitter: delay = random(0, min(cap, base * 2^attempt))
  /// Best for avoiding correlated retries
  static Duration fullJitter(Duration calculated) {
    return Duration(
      milliseconds: _random.nextInt(calculated.inMilliseconds + 1),
    );
  }
  
  /// Equal Jitter: delay = calculated/2 + random(0, calculated/2)
  /// Guarantees minimum delay
  static Duration equalJitter(Duration calculated) {
    final half = calculated.inMilliseconds ~/ 2;
    return Duration(
      milliseconds: half + _random.nextInt(half + 1),
    );
  }
  
  /// Decorrelated Jitter: delay = min(cap, random(base, previous * 3))
  /// Avoids correlated spikes even more
  static Duration decorrelatedJitter(Duration base, Duration previous, Duration cap) {
    final min = base.inMilliseconds;
    final max = previous.inMilliseconds * 3;
    final range = max - min;
    final jittered = min + _random.nextInt(range + 1);
    return Duration(milliseconds: min(jittered, cap.inMilliseconds));
  }
}
```

---

# PART 4: State Machine for Trip Management

## Trip State Definitions

```
┌─────────────────────────────────────────────────────────────────┐
│                     TRIP STATE MACHINE                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│                        ┌─────────┐                              │
│                        │  IDLE   │                              │
│                        └────┬────┘                              │
│                             │ startTrip()                       │
│                             ▼                                   │
│                      ┌───────────┐                              │
│           ┌──────────│ STARTING  │──────────┐                   │
│           │          └─────┬─────┘          │                   │
│           │ fail()         │ ready()        │ timeout()         │
│           ▼                ▼                ▼                   │
│     ┌──────────┐     ┌──────────┐     ┌──────────┐              │
│     │  FAILED  │     │  ACTIVE  │     │  FAILED  │              │
│     └──────────┘     └────┬─────┘     └──────────┘              │
│           │               │                 │                   │
│           │         ┌─────┴─────┐           │                   │
│           │         │           │           │                   │
│           │    pause()     endTrip()        │                   │
│           │         │           │           │                   │
│           │         ▼           ▼           │                   │
│           │   ┌─────────┐ ┌─────────┐       │                   │
│           │   │ PAUSED  │ │ ENDING  │       │                   │
│           │   └────┬────┘ └────┬────┘       │                   │
│           │        │           │            │                   │
│           │   resume()    completed()       │                   │
│           │        │           │            │                   │
│           │        │           ▼            │                   │
│           │        │    ┌───────────┐       │                   │
│           │        └───▶│ COMPLETED │◀──────┘                   │
│           │             └───────────┘       │                   │
│           │                  │              │                   │
│           └──────────────────┴──────────────┘                   │
│                        retry()                                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## State Machine Implementation

```dart
/// Trip States
enum TripState {
  idle,       // No trip in progress
  starting,   // Acquiring GPS, initializing
  active,     // Trip in progress
  paused,     // User paused trip
  ending,     // Finalizing trip data
  completed,  // Trip successfully finished
  failed,     // Trip encountered unrecoverable error
}

/// State Transition Events
sealed class TripEvent {}
class StartTrip extends TripEvent {}
class GPSReady extends TripEvent {}
class GPSTimeout extends TripEvent {}
class PauseTrip extends TripEvent {}
class ResumeTrip extends TripEvent {}
class EndTrip extends TripEvent {}
class TripCompleted extends TripEvent {}
class TripFailed extends TripEvent { final String reason; TripFailed(this.reason); }
class RecoverTrip extends TripEvent {}
class RetryTrip extends TripEvent {}

/// State Machine
class TripStateMachine {
  TripState _state = TripState.idle;
  Trip? _currentTrip;
  
  // Persistence for crash recovery
  final SharedPreferences _prefs;
  final HiveBox<Trip> _tripBox;
  
  TripState get state => _state;
  Trip? get currentTrip => _currentTrip;
  
  /// Process event and return new state
  TripState processEvent(TripEvent event) {
    final newState = _transition(_state, event);
    
    if (newState != _state) {
      _onStateExit(_state);
      _state = newState;
      _onStateEnter(_state);
      _persistState();
    }
    
    return _state;
  }
  
  /// State transition logic
  TripState _transition(TripState current, TripEvent event) {
    switch ((current, event)) {
      // From IDLE
      case (TripState.idle, StartTrip()):
        return TripState.starting;
      case (TripState.idle, RecoverTrip()):
        return TripState.active; // Crash recovery
      
      // From STARTING
      case (TripState.starting, GPSReady()):
        return TripState.active;
      case (TripState.starting, GPSTimeout()):
        return TripState.failed;
      case (TripState.starting, TripFailed()):
        return TripState.failed;
      
      // From ACTIVE
      case (TripState.active, PauseTrip()):
        return TripState.paused;
      case (TripState.active, EndTrip()):
        return TripState.ending;
      case (TripState.active, TripFailed()):
        return TripState.failed;
      
      // From PAUSED
      case (TripState.paused, ResumeTrip()):
        return TripState.active;
      case (TripState.paused, EndTrip()):
        return TripState.ending;
      
      // From ENDING
      case (TripState.ending, TripCompleted()):
        return TripState.completed;
      case (TripState.ending, TripFailed()):
        return TripState.failed;
      
      // From FAILED
      case (TripState.failed, RetryTrip()):
        return TripState.starting;
      
      // From COMPLETED
      case (TripState.completed, StartTrip()):
        return TripState.starting;
      
      // Invalid transitions
      default:
        _logger.warning('Invalid transition: $current + $event');
        return current; // Stay in current state
    }
  }
  
  /// State entry actions
  void _onStateEnter(TripState state) {
    switch (state) {
      case TripState.starting:
        _initializeTrip();
        _startGPSTimeout();
        break;
      
      case TripState.active:
        _startLocationTracking();
        _startSpeedMonitoring();
        break;
      
      case TripState.paused:
        _pauseLocationTracking();
        break;
      
      case TripState.ending:
        _stopLocationTracking();
        _calculateTripStats();
        _syncToServer();
        break;
      
      case TripState.completed:
        _cleanupTrip();
        _showTripSummary();
        break;
      
      case TripState.failed:
        _stopLocationTracking();
        _saveFailedTripForRecovery();
        break;
      
      case TripState.idle:
        break;
    }
  }
  
  /// State exit actions
  void _onStateExit(TripState state) {
    switch (state) {
      case TripState.starting:
        _cancelGPSTimeout();
        break;
      case TripState.active:
        // Nothing to clean up
        break;
      default:
        break;
    }
  }
  
  /// Persist state for crash recovery
  void _persistState() {
    _prefs.setString('trip_state', _state.name);
    if (_currentTrip != null) {
      _tripBox.put(_currentTrip!.id, _currentTrip!);
    }
  }
  
  /// Recover from crash
  Future<void> recoverFromCrash() async {
    final savedState = _prefs.getString('trip_state');
    if (savedState == null) return;
    
    final state = TripState.values.byName(savedState);
    
    // Only recover from states that indicate an active trip
    if ([TripState.starting, TripState.active, TripState.paused].contains(state)) {
      final lastTripId = _prefs.getString('current_trip_id');
      if (lastTripId != null) {
        _currentTrip = _tripBox.get(lastTripId);
        if (_currentTrip != null) {
          processEvent(RecoverTrip());
        }
      }
    }
  }
}
```

## Guards and Conditions

```dart
/// State Transition Guards
class TripGuards {
  /// Can we start a trip?
  static bool canStartTrip({
    required bool hasLocationPermission,
    required bool isGPSEnabled,
    required bool hasActiveTrip,
  }) {
    if (!hasLocationPermission) {
      throw TripException('Location permission required');
    }
    if (!isGPSEnabled) {
      throw TripException('Please enable GPS');
    }
    if (hasActiveTrip) {
      throw TripException('Please end current trip first');
    }
    return true;
  }
  
  /// Can we end a trip?
  static bool canEndTrip({
    required Duration tripDuration,
    required double distanceMeters,
  }) {
    // Minimum trip requirements
    if (tripDuration < Duration(seconds: 30)) {
      throw TripException('Trip too short (min 30 seconds)');
    }
    if (distanceMeters < 100) {
      throw TripException('Trip too short (min 100 meters)');
    }
    return true;
  }
  
  /// Should we auto-pause?
  static bool shouldAutoPause({
    required double currentSpeed,
    required Duration stationaryDuration,
  }) {
    // Auto-pause if stationary for > 5 minutes
    return currentSpeed < 1.0 && stationaryDuration > Duration(minutes: 5);
  }
  
  /// Should we auto-end?
  static bool shouldAutoEnd({
    required Duration stationaryDuration,
    required DateTime lastMovementTime,
  }) {
    // Auto-end if stationary for > 30 minutes
    return stationaryDuration > Duration(minutes: 30);
  }
}
```

---

# PART 5: Coding Standards & Best Practices

## SOLID Principles in Flutter/Dart

### Single Responsibility Principle (SRP)

```dart
/// ❌ BAD: Class does too many things
class UserManager {
  void login(String email, String password) { /* ... */ }
  void saveToDatabase(User user) { /* ... */ }
  void sendWelcomeEmail(User user) { /* ... */ }
  void validateEmail(String email) { /* ... */ }
  void uploadAvatar(File image) { /* ... */ }
}

/// ✅ GOOD: Each class has one responsibility
class AuthService {
  Future<User> login(String email, String password) async { /* ... */ }
  Future<void> logout() async { /* ... */ }
}

class UserRepository {
  Future<void> save(User user) async { /* ... */ }
  Future<User?> findById(String id) async { /* ... */ }
}

class EmailService {
  Future<void> sendWelcome(User user) async { /* ... */ }
}

class EmailValidator {
  bool isValid(String email) => /* ... */;
}

class AvatarUploader {
  Future<String> upload(File image) async { /* ... */ }
}
```

### Open/Closed Principle (OCP)

```dart
/// ❌ BAD: Must modify class to add new rating types
class RatingCalculator {
  double calculate(String type, List<int> ratings) {
    switch (type) {
      case 'average':
        return ratings.reduce((a, b) => a + b) / ratings.length;
      case 'weighted':
        // Complex weighted calculation
        return 0.0;
      // Adding new type requires modifying this class
    }
  }
}

/// ✅ GOOD: Open for extension, closed for modification
abstract class RatingStrategy {
  double calculate(List<int> ratings);
}

class AverageRating implements RatingStrategy {
  @override
  double calculate(List<int> ratings) {
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }
}

class WeightedRating implements RatingStrategy {
  final List<double> weights;
  WeightedRating(this.weights);
  
  @override
  double calculate(List<int> ratings) {
    double sum = 0;
    for (var i = 0; i < ratings.length; i++) {
      sum += ratings[i] * weights[i % weights.length];
    }
    return sum / weights.reduce((a, b) => a + b);
  }
}

// New rating types can be added without modifying existing code
class MedianRating implements RatingStrategy {
  @override
  double calculate(List<int> ratings) {
    final sorted = List<int>.from(ratings)..sort();
    return sorted[sorted.length ~/ 2].toDouble();
  }
}
```

### Liskov Substitution Principle (LSP)

```dart
/// ❌ BAD: Subclass breaks parent contract
abstract class Vehicle {
  void startEngine();
  void accelerate();
}

class Car extends Vehicle {
  @override
  void startEngine() { /* ... */ }
  
  @override
  void accelerate() { /* ... */ }
}

class Bicycle extends Vehicle {
  @override
  void startEngine() {
    throw UnsupportedError('Bicycles have no engine!'); // ❌ Breaks LSP
  }
  
  @override
  void accelerate() { /* ... */ }
}

/// ✅ GOOD: Proper abstraction hierarchy
abstract class Vehicle {
  void move();
}

abstract class MotorizedVehicle extends Vehicle {
  void startEngine();
}

class Car extends MotorizedVehicle {
  @override
  void startEngine() { /* ... */ }
  
  @override
  void move() { /* ... */ }
}

class Bicycle extends Vehicle {
  @override
  void move() { /* ... */ }
  // No engine to start - interface makes sense
}
```

### Interface Segregation Principle (ISP)

```dart
/// ❌ BAD: Fat interface forces unnecessary implementations
abstract class TripTracker {
  void startTrip();
  void endTrip();
  void pauseTrip();
  void recordLocation(Position pos);
  void connectOBD();          // Not all trackers use OBD
  void calibrateAltimeter();  // Not all trackers need this
  void enableNightMode();     // UI concern in tracker?
}

/// ✅ GOOD: Small, focused interfaces
abstract class TripController {
  void startTrip();
  void endTrip();
  void pauseTrip();
}

abstract class LocationRecorder {
  void recordLocation(Position pos);
}

abstract class OBDConnector {
  void connect();
  void disconnect();
  Stream<OBDData> get dataStream;
}

abstract class AltimeterCalibrator {
  void calibrate(double knownAltitude);
}

// Implement only what you need
class BasicTripTracker implements TripController, LocationRecorder {
  @override
  void startTrip() { /* ... */ }
  
  @override
  void endTrip() { /* ... */ }
  
  @override
  void pauseTrip() { /* ... */ }
  
  @override
  void recordLocation(Position pos) { /* ... */ }
}

class AdvancedTripTracker implements TripController, LocationRecorder, OBDConnector {
  // Implements all three interfaces
}
```

### Dependency Inversion Principle (DIP)

```dart
/// ❌ BAD: High-level depends on low-level
class TripService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Geolocator _geolocator = Geolocator();
  
  // Tightly coupled to specific implementations
  // Hard to test, hard to swap implementations
}

/// ✅ GOOD: Depend on abstractions
abstract class TripRepository {
  Future<void> saveTrip(Trip trip);
  Future<Trip?> getTrip(String id);
}

abstract class LocationProvider {
  Stream<Position> get positionStream;
  Future<Position> getCurrentPosition();
}

class TripService {
  final TripRepository _repository;
  final LocationProvider _locationProvider;
  
  // Dependencies injected - easy to test, easy to swap
  TripService({
    required TripRepository repository,
    required LocationProvider locationProvider,
  }) : _repository = repository,
       _locationProvider = locationProvider;
}

// Concrete implementations
class FirebaseTripRepository implements TripRepository {
  final FirebaseFirestore _firestore;
  FirebaseTripRepository(this._firestore);
  
  @override
  Future<void> saveTrip(Trip trip) async { /* ... */ }
  
  @override
  Future<Trip?> getTrip(String id) async { /* ... */ }
}

class GeolocatorLocationProvider implements LocationProvider {
  @override
  Stream<Position> get positionStream => Geolocator.getPositionStream();
  
  @override
  Future<Position> getCurrentPosition() => Geolocator.getCurrentPosition();
}

// For testing
class MockTripRepository implements TripRepository {
  final Map<String, Trip> _trips = {};
  
  @override
  Future<void> saveTrip(Trip trip) async {
    _trips[trip.id] = trip;
  }
  
  @override
  Future<Trip?> getTrip(String id) async => _trips[id];
}
```

## DRY Principle Implementation

```dart
/// ❌ BAD: Repeated code
class DriverRatingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(/* ... */),
      ),
    );
  }
}

class TripSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(/* ... */),
      ),
    );
  }
}

/// ✅ GOOD: Reusable base component
class AppCard extends StatelessWidget {
  final Widget child;
  final double elevation;
  final EdgeInsets padding;
  
  const AppCard({
    required this.child,
    this.elevation = 2,
    this.padding = const EdgeInsets.all(16),
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

// Now use it
class DriverRatingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(/* driver-specific content */),
    );
  }
}

/// DRY for validation logic
class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Invalid email format';
    }
    return null;
  }
  
  static String? plateNumber(String? value) {
    if (value == null || value.isEmpty) return 'Plate number required';
    // Ghana plate format: XX-XXXX-YY
    if (!RegExp(r'^[A-Z]{2}-\d{4}-\d{2}$').hasMatch(value)) {
      return 'Invalid plate format (XX-1234-00)';
    }
    return null;
  }
}

/// DRY for API calls
extension FirestoreDocRef on DocumentReference {
  Future<T?> getOrNull<T>(T Function(Map<String, dynamic>) fromJson) async {
    final doc = await get();
    if (!doc.exists) return null;
    return fromJson(doc.data() as Map<String, dynamic>);
  }
}
```

## Repository Pattern

```dart
/// Repository Pattern Implementation
/// Separates data access from business logic

// Domain entity (clean, no dependencies)
class Driver {
  final String id;
  final String name;
  final String plateNumber;
  final double rating;
  final int ratingCount;
  
  Driver({
    required this.id,
    required this.name,
    required this.plateNumber,
    required this.rating,
    required this.ratingCount,
  });
}

// Repository interface (abstraction)
abstract class DriverRepository {
  Future<Driver?> getById(String id);
  Future<Driver?> getByPlate(String plateNumber);
  Future<List<Driver>> getNearby(double lat, double lng, double radiusKm);
  Future<void> updateRating(String id, int newRating);
  Stream<Driver> watchDriver(String id);
}

// Firestore implementation
class FirestoreDriverRepository implements DriverRepository {
  final FirebaseFirestore _firestore;
  final GeoFlutterFire _geo;
  
  FirestoreDriverRepository(this._firestore) : _geo = GeoFlutterFire();
  
  CollectionReference get _collection => _firestore.collection('drivers');
  
  @override
  Future<Driver?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return _fromFirestore(doc);
  }
  
  @override
  Future<Driver?> getByPlate(String plateNumber) async {
    final query = await _collection
        .where('plateNumber', isEqualTo: plateNumber.toUpperCase())
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return _fromFirestore(query.docs.first);
  }
  
  @override
  Future<List<Driver>> getNearby(double lat, double lng, double radiusKm) async {
    final center = GeoFirePoint(lat, lng);
    final docs = await _geo
        .collection(collectionRef: _collection)
        .within(center: center, radius: radiusKm, field: 'position')
        .first;
    return docs.map(_fromFirestore).toList();
  }
  
  @override
  Future<void> updateRating(String id, int newRating) async {
    await _firestore.runTransaction((txn) async {
      final doc = await txn.get(_collection.doc(id));
      final data = doc.data() as Map<String, dynamic>;
      
      final currentSum = data['ratingSum'] ?? 0;
      final currentCount = data['ratingCount'] ?? 0;
      
      txn.update(_collection.doc(id), {
        'ratingSum': currentSum + newRating,
        'ratingCount': currentCount + 1,
        'rating': (currentSum + newRating) / (currentCount + 1),
      });
    });
  }
  
  @override
  Stream<Driver> watchDriver(String id) {
    return _collection.doc(id).snapshots().map(_fromFirestore);
  }
  
  Driver _fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Driver(
      id: doc.id,
      name: data['name'] ?? '',
      plateNumber: data['plateNumber'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      ratingCount: data['ratingCount'] ?? 0,
    );
  }
}

// Cached repository decorator
class CachedDriverRepository implements DriverRepository {
  final DriverRepository _inner;
  final RatingCache _cache;
  
  CachedDriverRepository(this._inner, this._cache);
  
  @override
  Future<Driver?> getById(String id) async {
    // Check cache first
    final cached = await _cache.get(id);
    if (cached != null) return cached;
    
    // Fetch and cache
    final driver = await _inner.getById(id);
    if (driver != null) {
      await _cache.put(id, driver);
    }
    return driver;
  }
  
  // ... other methods with caching logic
}
```

## Clean Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     CLEAN ARCHITECTURE                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  lib/                                                           │
│  ├── core/                    # Shared utilities                │
│  │   ├── error/               # Failure classes                 │
│  │   ├── usecases/            # Base use case class             │
│  │   └── utils/               # Extensions, helpers             │
│  │                                                              │
│  └── features/                # Feature modules                 │
│      └── tracking/            # Speed tracking feature          │
│          │                                                      │
│          ├── domain/          # INNERMOST - Business rules      │
│          │   ├── entities/    # Pure Dart classes               │
│          │   │   ├── trip.dart                                  │
│          │   │   └── location_point.dart                        │
│          │   ├── repositories/  # Abstract interfaces           │
│          │   │   └── trip_repository.dart                       │
│          │   └── usecases/    # Business logic                  │
│          │       ├── start_trip.dart                            │
│          │       ├── end_trip.dart                              │
│          │       └── get_current_speed.dart                     │
│          │                                                      │
│          ├── data/            # MIDDLE - Data access            │
│          │   ├── models/      # DTOs with fromJson/toJson       │
│          │   │   ├── trip_model.dart                            │
│          │   │   └── location_model.dart                        │
│          │   ├── datasources/ # Actual data fetching            │
│          │   │   ├── trip_local_datasource.dart                 │
│          │   │   └── trip_remote_datasource.dart                │
│          │   └── repositories/  # Implement domain interfaces   │
│          │       └── trip_repository_impl.dart                  │
│          │                                                      │
│          └── presentation/    # OUTER - UI                      │
│              ├── providers/   # Riverpod state                  │
│              │   └── tracking_provider.dart                     │
│              ├── pages/       # Full screens                    │
│              │   └── tracking_page.dart                         │
│              └── widgets/     # Reusable UI components          │
│                  └── speedometer.dart                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

```dart
/// Domain Layer - Use Case Example
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class StartTrip implements UseCase<Trip, NoParams> {
  final TripRepository repository;
  final LocationProvider locationProvider;
  
  StartTrip({required this.repository, required this.locationProvider});
  
  @override
  Future<Either<Failure, Trip>> call(NoParams params) async {
    try {
      // Business logic
      final position = await locationProvider.getCurrentPosition();
      
      final trip = Trip(
        id: uuid.v4(),
        startTime: DateTime.now(),
        startPosition: position,
        status: TripStatus.active,
      );
      
      await repository.saveTrip(trip);
      
      return Right(trip);
    } on LocationPermissionDenied {
      return Left(PermissionFailure('Location permission required'));
    } on Exception catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
```

## Dependency Injection with Riverpod

```dart
/// Riverpod Dependency Injection
/// 
/// Benefits:
/// - Compile-time safety
/// - Automatic disposal
/// - Easy testing with overrides
/// - Scoped dependencies

// Core dependencies
@riverpod
FirebaseFirestore firestore(FirestoreRef ref) {
  return FirebaseFirestore.instance;
}

@riverpod
SharedPreferences sharedPreferences(SharedPreferencesRef ref) {
  throw UnimplementedError('Must be overridden in main()');
}

// Repository layer
@riverpod
TripRepository tripRepository(TripRepositoryRef ref) {
  return FirestoreTripRepository(ref.watch(firestoreProvider));
}

@riverpod
DriverRepository driverRepository(DriverRepositoryRef ref) {
  final firestore = ref.watch(firestoreProvider);
  final cache = ref.watch(ratingCacheProvider);
  
  return CachedDriverRepository(
    FirestoreDriverRepository(firestore),
    cache,
  );
}

// Use case layer
@riverpod
StartTrip startTripUseCase(StartTripUseCaseRef ref) {
  return StartTrip(
    repository: ref.watch(tripRepositoryProvider),
    locationProvider: ref.watch(locationProviderProvider),
  );
}

// Presentation layer
@riverpod
class TripNotifier extends _$TripNotifier {
  @override
  TripState build() => TripState.initial();
  
  Future<void> startTrip() async {
    state = state.copyWith(isLoading: true);
    
    final result = await ref.read(startTripUseCaseProvider).call(NoParams());
    
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (trip) => state = state.copyWith(
        isLoading: false,
        currentTrip: trip,
        tripStatus: TripStatus.active,
      ),
    );
  }
}

// In main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: RoadGuardApp(),
    ),
  );
}

// In tests
void main() {
  test('start trip creates new trip', () async {
    final container = ProviderContainer(
      overrides: [
        tripRepositoryProvider.overrideWithValue(MockTripRepository()),
        locationProviderProvider.overrideWithValue(MockLocationProvider()),
      ],
    );
    
    final notifier = container.read(tripNotifierProvider.notifier);
    await notifier.startTrip();
    
    expect(container.read(tripNotifierProvider).currentTrip, isNotNull);
  });
}
```

## Unit Testing Requirements

```dart
/// Testing Strategy for RoadGuard
/// 
/// Test Pyramid:
/// ┌───────────────┐
/// │   E2E Tests   │  ← Few, slow, high confidence
/// │    (5-10%)    │
/// ├───────────────┤
/// │ Widget Tests  │  ← Moderate, test UI behavior
/// │   (20-30%)    │
/// ├───────────────┤
/// │  Unit Tests   │  ← Many, fast, test logic
/// │   (60-75%)    │
/// └───────────────┘

// Example Unit Tests

group('SpeedCalculator', () {
  late SpeedCalculator calculator;
  
  setUp(() {
    calculator = SpeedCalculator();
  });
  
  test('calculates speed from two positions correctly', () {
    final pos1 = Position(
      latitude: 5.6037,
      longitude: -0.1870,
      timestamp: DateTime(2024, 1, 1, 12, 0, 0),
    );
    final pos2 = Position(
      latitude: 5.6047,  // ~111 meters north
      longitude: -0.1870,
      timestamp: DateTime(2024, 1, 1, 12, 0, 10),  // 10 seconds later
    );
    
    final speed = calculator.calculateSpeed(pos1, pos2);
    
    // ~111 meters in 10 seconds = ~11.1 m/s = ~40 km/h
    expect(speed, closeTo(40, 2));  // Within 2 km/h
  });
  
  test('returns 0 for identical positions', () {
    final pos = Position(latitude: 5.6037, longitude: -0.1870);
    expect(calculator.calculateSpeed(pos, pos), equals(0));
  });
  
  test('handles GPS jitter at stationary', () {
    // Small movements < 2 meters should be treated as stationary
    final pos1 = Position(latitude: 5.6037000, longitude: -0.1870000);
    final pos2 = Position(latitude: 5.6037001, longitude: -0.1870001);
    
    expect(calculator.calculateSpeed(pos1, pos2), equals(0));
  });
});

group('TripStateMachine', () {
  late TripStateMachine machine;
  late MockTripRepository mockRepo;
  
  setUp(() {
    mockRepo = MockTripRepository();
    machine = TripStateMachine(repository: mockRepo);
  });
  
  test('transitions from idle to starting on startTrip', () {
    expect(machine.state, equals(TripState.idle));
    
    machine.processEvent(StartTrip());
    
    expect(machine.state, equals(TripState.starting));
  });
  
  test('transitions from starting to active on gpsReady', () {
    machine.processEvent(StartTrip());
    machine.processEvent(GPSReady());
    
    expect(machine.state, equals(TripState.active));
  });
  
  test('ignores invalid transitions', () {
    // Can't pause when not active
    machine.processEvent(PauseTrip());
    
    expect(machine.state, equals(TripState.idle));
  });
  
  test('saves trip on state change', () async {
    machine.processEvent(StartTrip());
    
    verify(mockRepo.saveTrip(any)).called(1);
  });
});

group('RateLimiter', () {
  test('allows actions within limit', () {
    final limiter = RateLimiter();
    
    for (var i = 0; i < 10; i++) {
      expect(limiter.canPerformAction('rate_driver'), isTrue);
    }
  });
  
  test('blocks actions exceeding limit', () {
    final limiter = RateLimiter();
    
    // Exhaust tokens
    for (var i = 0; i < 10; i++) {
      limiter.canPerformAction('rate_driver');
    }
    
    // 11th should fail
    expect(limiter.canPerformAction('rate_driver'), isFalse);
  });
  
  test('refills tokens over time', () async {
    final limiter = RateLimiter();
    
    // Exhaust tokens
    for (var i = 0; i < 10; i++) {
      limiter.canPerformAction('rate_driver');
    }
    
    // Wait for refill (fake time in test)
    await Future.delayed(Duration(minutes: 1));
    
    // Should work again
    expect(limiter.canPerformAction('rate_driver'), isTrue);
  });
});
```

## Code Efficiency Best Practices

```dart
/// AVOIDING UNNECESSARY WIDGET REBUILDS

// ❌ BAD: Rebuilds entire list on any change
class DriverList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drivers = ref.watch(allDriversProvider);
    
    return ListView.builder(
      itemCount: drivers.length,
      itemBuilder: (context, index) => DriverCard(driver: drivers[index]),
    );
  }
}

// ✅ GOOD: Only rebuilds changed items
class DriverList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverIds = ref.watch(driverIdsProvider);
    
    return ListView.builder(
      itemCount: driverIds.length,
      itemBuilder: (context, index) => DriverCardById(id: driverIds[index]),
    );
  }
}

class DriverCardById extends ConsumerWidget {
  final String id;
  const DriverCardById({required this.id});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only rebuilds when THIS driver changes
    final driver = ref.watch(driverByIdProvider(id));
    return DriverCard(driver: driver);
  }
}

/// AVOIDING MEMORY LEAKS

// ❌ BAD: Stream subscription not cancelled
class TrackingPage extends StatefulWidget {
  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  @override
  void initState() {
    super.initState();
    // LEAK! Never cancelled!
    locationService.positionStream.listen((pos) {
      setState(() => _position = pos);
    });
  }
}

// ✅ GOOD: Properly managed subscription
class _TrackingPageState extends State<TrackingPage> {
  StreamSubscription<Position>? _subscription;
  
  @override
  void initState() {
    super.initState();
    _subscription = locationService.positionStream.listen((pos) {
      if (mounted) {
        setState(() => _position = pos);
      }
    });
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

// ✅ BETTER: Use Riverpod for automatic lifecycle management
@riverpod
Stream<Position> positionStream(PositionStreamRef ref) {
  // Automatically cancelled when provider is disposed
  return locationService.positionStream;
}

class TrackingPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positionAsync = ref.watch(positionStreamProvider);
    
    return positionAsync.when(
      data: (position) => SpeedDisplay(position: position),
      loading: () => CircularProgressIndicator(),
      error: (e, s) => ErrorWidget(e),
    );
  }
}

/// CONST CONSTRUCTORS

// ❌ BAD: Recreates widget every build
Widget build(BuildContext context) {
  return Column(
    children: [
      Text('Speed'),  // Recreated every build
      Icon(Icons.speed),  // Recreated every build
    ],
  );
}

// ✅ GOOD: Const widgets are cached
Widget build(BuildContext context) {
  return Column(
    children: const [
      Text('Speed'),  // Cached
      Icon(Icons.speed),  // Cached
    ],
  );
}

/// SELECT TO REDUCE REBUILDS

// ❌ BAD: Rebuilds on ANY trip change
class SpeedDisplay extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(currentTripProvider);
    return Text('${trip.currentSpeed} km/h');
  }
}

// ✅ GOOD: Only rebuilds when speed changes
class SpeedDisplay extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speed = ref.watch(
      currentTripProvider.select((trip) => trip.currentSpeed),
    );
    return Text('$speed km/h');
  }
}
```

---

## Flutter Packages Summary

### Recommended for RoadGuard

```yaml
# Core packages already in your tech stack ✓

# Additional recommended packages:

dependencies:
  # Sensor Fusion & Location
  flutter_background_geolocation: ^5.0.2   # Premium, best-in-class
  # OR
  locus: ^2.0.1                            # Free alternative
  
  # Geospatial queries
  geoflutterfire_plus: ^0.0.34             # Firebase geo queries
  
  # Retry & Resilience  
  polly_dart: ^0.0.7                       # Circuit breaker, retry
  # OR implement manually (recommended for learning)
  
  # Kalman Filter (if implementing manually)
  simple_kalman: ^1.0.2
  
  # State Machine (optional)
  immutable_fsm: ^1.1.0
  # OR implement manually (recommended)

  # OBD-II (future, Android only)
  bluetooth_obd: ^0.0.6
```

---

**Document Version:** 1.0  
**Research Date:** January 29, 2026  
**Total Sections:** 5 Parts, 20+ Sub-topics  
**Code Examples:** 50+ implementations

