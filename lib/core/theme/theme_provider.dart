/// Theme Provider - Manages app theme state with persistence.
///
/// Uses Riverpod for state management and Hive for persistence.
/// Supports: System (follow device), Light, and Dark modes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/services/storage_service.dart';

/// Available theme modes for the app.
enum AppThemeMode {
  /// Follow system/device theme setting.
  system,

  /// Always use light theme.
  light,

  /// Always use dark theme.
  dark,
}

/// Extension to convert between AppThemeMode and Flutter's ThemeMode.
extension AppThemeModeX on AppThemeMode {
  /// Convert to Flutter's ThemeMode.
  ThemeMode toThemeMode() {
    return switch (this) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    };
  }

  /// Convert from string (for storage).
  static AppThemeMode fromString(String? value) {
    return switch (value) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      _ => AppThemeMode.system,
    };
  }

  /// Convert to string (for storage).
  String toStorageString() {
    return switch (this) {
      AppThemeMode.system => 'system',
      AppThemeMode.light => 'light',
      AppThemeMode.dark => 'dark',
    };
  }

  /// Human-readable name for UI.
  String get displayName {
    return switch (this) {
      AppThemeMode.system => 'System',
      AppThemeMode.light => 'Light',
      AppThemeMode.dark => 'Dark',
    };
  }

  /// Icon for the theme mode.
  IconData get icon {
    return switch (this) {
      AppThemeMode.system => Icons.brightness_auto,
      AppThemeMode.light => Icons.light_mode,
      AppThemeMode.dark => Icons.dark_mode,
    };
  }
}

/// Notifier that manages theme state.
class ThemeNotifier extends Notifier<AppThemeMode> {
  @override
  AppThemeMode build() {
    // Load saved theme from storage on initialization
    final savedTheme = StorageService.instance.themeMode;
    return AppThemeModeX.fromString(savedTheme);
  }

  /// Set the theme mode and persist to storage.
  Future<void> setThemeMode(AppThemeMode mode) async {
    state = mode;
    await StorageService.instance.setThemeMode(mode.toStorageString());
  }

  /// Cycle through theme modes: System → Light → Dark → System
  Future<void> cycleTheme() async {
    final nextMode = switch (state) {
      AppThemeMode.system => AppThemeMode.light,
      AppThemeMode.light => AppThemeMode.dark,
      AppThemeMode.dark => AppThemeMode.system,
    };
    await setThemeMode(nextMode);
  }
}

/// Provider for the current theme mode.
final themeProvider = NotifierProvider<ThemeNotifier, AppThemeMode>(
  ThemeNotifier.new,
);

/// Provider that converts AppThemeMode to Flutter's ThemeMode.
final themeModeProvider = Provider<ThemeMode>((ref) {
  final appThemeMode = ref.watch(themeProvider);
  return appThemeMode.toThemeMode();
});

/// Provider to check if current effective theme is dark.
/// This considers system setting when in system mode.
final isDarkModeProvider = Provider<bool>((ref) {
  final mode = ref.watch(themeProvider);

  return switch (mode) {
    AppThemeMode.dark => true,
    AppThemeMode.light => false,
    // For system mode, we return true as default (will be overridden by actual check in UI)
    AppThemeMode.system => true,
  };
});
