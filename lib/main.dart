/// RoadGuard - Your Digital Copilot for Road Safety
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/router.dart';
import 'core/theme/theme.dart';
import 'error_app.dart';
import 'firebase_options.dart';
import 'shared/services/location_service.dart';
import 'shared/services/map_tile_service.dart';
import 'shared/services/storage_service.dart';

void main() async {
  // CRITICAL: This must be called before any async operations
  // It initializes Flutter's binding with the native platform
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize local storage (Hive)
    // MUST happen before runApp() so storage is ready
    await StorageService.initialize();

    // Initialize offline map tile caching (FMTC)
    // Non-fatal if it fails — maps will still work online
    await MapTileService.instance.initialize();

    // Initialize Background Location Service
    // This configures the plugin so it's ready to start when requested
    await LocationService.instance.initialize();

    // Allow orientations that iOS Info.plist supports - app is for PASSENGERS, not drivers
    // Note: portraitDown removed as iOS iPhone doesn't support upside-down orientation
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  } catch (e) {
    // If initialization fails, show error screen
    runApp(ErrorApp(error: e));
    return;
  }

  runApp(const ProviderScope(child: RoadGuardApp()));
}

/// Root application widget.
class RoadGuardApp extends ConsumerWidget {
  const RoadGuardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Dark mode only - update system UI
    _updateSystemUI(context);

    return MaterialApp.router(
      title: 'RoadGuard',
      debugShowCheckedModeBanner: false,

      // Dark mode only - "The Cockpit"
      theme: createDarkTheme(),
      darkTheme: createDarkTheme(),
      themeMode: ThemeMode.dark,

      routerConfig: router,
    );
  }

  /// Configure system UI overlay for dark mode.
  void _updateSystemUI(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColorsDark.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }
}
