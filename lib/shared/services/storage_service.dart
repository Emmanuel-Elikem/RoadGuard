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

import '../../features/trip/domain/models/rating_model.dart';
import '../../features/trip/domain/models/trip_model.dart';

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

  // Boxes (opened during initialization)
  late Box<dynamic> _settings;
  late Box<dynamic> _user;
  late Box<TripModel> _trips;

  Box<TripModel> get tripsBox => _trips;

  /// Initialize Hive and open all boxes.
  ///
  /// MUST be called in main() before runApp().
  static Future<void> initialize() async {
    // Initialize Hive with Flutter support (handles path resolution)
    await Hive.initFlutter();

    // Register Adapters
    Hive.registerAdapter(RatingModelAdapter());
    Hive.registerAdapter(TripModelAdapter());

    // Create instance
    _instance = StorageService._();

    // Open boxes
    // Box names are like table names - keep them lowercase
    _instance!._settings = await Hive.openBox(_settingsBox);
    _instance!._user = await Hive.openBox(_userBox);
    _instance!._trips = await Hive.openBox<TripModel>(_tripsBox);

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
