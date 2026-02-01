/// RoadGuard - Your Digital Copilot for Road Safety
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/router.dart';
import 'core/theme/theme.dart';
import 'firebase_options.dart';
import 'shared/services/storage_service.dart';

void main() async {
  // CRITICAL: This must be called before any async operations
  // It initializes Flutter's binding with the native platform
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize local storage (Hive)
  // MUST happen before runApp() so storage is ready
  await StorageService.initialize();

  // Lock to portrait mode
  // Most users hold phones vertically while driving
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: RoadGuardApp()));
}

/// Root application widget.
class RoadGuardApp extends ConsumerWidget {
  const RoadGuardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Update system UI based on theme
    _updateSystemUI(themeMode, context);

    return MaterialApp.router(
      title: 'RoadGuard',
      debugShowCheckedModeBanner: false,

      // Light theme - "The Soft Look"
      theme: createLightTheme(),

      // Dark theme - "The Cockpit"
      darkTheme: createDarkTheme(),

      // Which theme to use (system/light/dark)
      themeMode: themeMode,

      routerConfig: router,
    );
  }

  /// Configure system UI overlay style based on current theme.
  void _updateSystemUI(ThemeMode themeMode, BuildContext context) {
    // Determine if we're actually in dark mode
    final brightness = switch (themeMode) {
      ThemeMode.dark => Brightness.dark,
      ThemeMode.light => Brightness.light,
      ThemeMode.system => MediaQuery.platformBrightnessOf(context),
    };

    final isDark = brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: isDark
            ? AppColorsDark.background
            : AppColorsLight.background,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
    );
  }
}
