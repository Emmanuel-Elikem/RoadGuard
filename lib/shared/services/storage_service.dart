/// Local storage service using Hive for offline-first data persistence.

/// Hive is a lightweight key-value database written in pure Dart.
/// Unlike SharedPreferences, it can store complex objects.
/// Unlike SQLite, it doesn't require SQL knowledge.
///
/// Key concepts:
/// - Box: A container for data (like a table in SQL)
/// - Adapter: Converts custom objects to/from storable format
/// - TypeId: Unique identifier for each adapter (0-223 range)
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../features/trip/domain/models/driver_model.dart';
import '../../features/trip/domain/models/driver_model_adapter.dart';
import '../../features/trip/domain/models/rating_model.dart';
import '../../features/trip/domain/models/rating_model_adapter.dart';
import '../../features/trip/domain/models/trip_model.dart';
import '../../features/trip/domain/models/trip_model_adapter.dart';

/// Provider for accessing the storage service
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});

/// Service for managing local storage using Hive.
///
/// ARCHITECTURE NOTE:
/// This is a singleton pattern - only one instance exists.
/// We use a private constructor and a static instance getter.
class StorageService {
  static StorageService? _instance;
  static StorageService get instance {
    if (_instance == null) {
      throw StateError(
        'StorageService not initialized. Call StorageService.initialize() first.',
      );
    }
    return _instance!;
  }

  StorageService._();

  // Box names as constants to prevent typos
  static const String _settingsBox = 'settings';
  static const String _userBox = 'user';
  static const String _tripsBox = 'trips';
  static const String _ratingsBox = 'ratings';
  static const String _driversBox = 'drivers';

  /// Schema version — bump when Hive model fields change.
  /// This triggers a one-time box reset on next launch.
  static const int _schemaVersion = 3;

  // Boxes (opened during initialization)
  late Box<dynamic> _settings;
  late Box<dynamic> _user;
  late Box<TripModel> _trips;
  late Box<RatingModel> _ratings;
  late Box<DriverModel> _drivers;

  Box<TripModel> get tripsBox => _trips;
  Box<RatingModel> get ratingsBox => _ratings;
  Box<DriverModel> get driversBox => _drivers;

  /// Returns trips belonging to the current user.
  List<TripModel> get currentUserTrips {
    final uid = userId;
    if (uid == null) return [];
    return _trips.values.where((t) => t.userId == uid).toList();
  }

  /// Initialize Hive and open all boxes.
  ///
  /// MUST be called in main() before runApp().
  static Future<void> initialize() async {
    // Initialize Hive with Flutter support (handles path resolution)
    await Hive.initFlutter();

    // Register Adapters
    Hive.registerAdapter(RatingModelAdapter());
    Hive.registerAdapter(TripModelAdapter());
    Hive.registerAdapter(DriverModelAdapter());

    // Create instance
    _instance = StorageService._();

    // Open settings box first (needed for schema version check)
    _instance!._settings = await Hive.openBox(_settingsBox);

    // Schema migration: handle schema version changes
    final storedVersion = _instance!._settings.get(
      'schemaVersion',
      defaultValue: 0,
    );
    if (storedVersion != _schemaVersion) {
      debugPrint(
        'Schema version changed ($storedVersion → $_schemaVersion).',
      );
      // Pre-launch: clear data boxes on schema change in all builds.
      // Post-launch: replace with forward migration logic.
      debugPrint('Clearing data boxes for schema migration.');
      await Hive.deleteBoxFromDisk(_tripsBox);
      await Hive.deleteBoxFromDisk(_ratingsBox);
      await Hive.deleteBoxFromDisk(_driversBox);
      await _instance!._settings.put('schemaVersion', _schemaVersion);
    }

    // Open remaining boxes
    _instance!._user = await Hive.openBox(_userBox);
    _instance!._trips = await Hive.openBox<TripModel>(_tripsBox);
    _instance!._ratings = await Hive.openBox<RatingModel>(_ratingsBox);
    _instance!._drivers = await Hive.openBox<DriverModel>(_driversBox);

    debugPrint('StorageService initialized');
  }

  // ==========================================
  // SETTINGS
  // ==========================================

  /// Check if this is the first app launch.
  bool get isFirstLaunch => _settings.get('isFirstLaunch', defaultValue: true);

  /// Mark that user has completed onboarding.
  Future<void> setFirstLaunchComplete() async {
    await _settings.put('isFirstLaunch', false);
  }

  /// Get the current theme mode preference.
  /// Returns: 'system', 'light', or 'dark'
  String get themeMode => _settings.get('themeMode', defaultValue: 'dark');

  /// Set the theme mode preference.
  Future<void> setThemeMode(String mode) async {
    if (!['system', 'light', 'dark'].contains(mode)) {
      throw ArgumentError('Invalid theme mode: $mode');
    }
    await _settings.put('themeMode', mode);
  }

  /// Get the speed limit warning threshold (km/h).
  int get speedLimitThreshold =>
      _settings.get('speedLimitThreshold', defaultValue: 50);

  /// Set the speed limit warning threshold.
  Future<void> setSpeedLimitThreshold(int kmh) async {
    if (kmh < 1 || kmh > 200) {
      throw ArgumentError('Speed limit must be between 1 and 200 km/h');
    }
    await _settings.put('speedLimitThreshold', kmh);
  }

  // ==========================================
  // USER DATA
  // ==========================================

  /// Check if user is logged in.
  bool get isLoggedIn => _user.get('isLoggedIn', defaultValue: false);

  /// Get the current user ID.
  String? get userId => _user.get('userId');

  /// Get the user display name.
  String? get userName => _user.get('userName');

  /// Save user login data.
  Future<void> saveUserLogin({
    required String id,
    required String name,
    required bool isGuest,
  }) async {
    await _user.put('isLoggedIn', true);
    await _user.put('userId', id);
    await _user.put('userName', name);
    await _user.put('isGuest', isGuest);
  }

  /// Clear user data on logout.
  Future<void> clearUser() async {
    await _user.clear();
  }

  /// Clear all user-specific data (trips, ratings, drivers).
  /// Called on sign-out to prevent data leaking between accounts.
  Future<void> clearUserData() async {
    await _trips.clear();
    await _ratings.clear();
    await _drivers.clear();
    await _user.clear();
  }

  // ==========================================
  // CLEANUP
  // ==========================================

  /// Clear all stored data (for debugging/testing).
  Future<void> clearAll() async {
    await _settings.clear();
    await _user.clear();
    await _trips.clear();
  }

  /// Close all boxes (call on app dispose).
  Future<void> dispose() async {
    await Hive.close();
    _instance = null;
  }
}
