/// RoadGuard - Your Digital Copilot for Road Safety
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/router.dart';
import 'core/theme/theme.dart';
import 'error_app.dart';
import 'features/tracking/domain/providers/tracking_providers.dart';
import 'features/trip/application/trip_service.dart';
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
///
/// Observes app lifecycle to persist in-progress trips when the user
/// swipes the app away or the OS reclaims memory.
class RoadGuardApp extends ConsumerStatefulWidget {
  const RoadGuardApp({super.key});

  @override
  ConsumerState<RoadGuardApp> createState() => _RoadGuardAppState();
}

class _RoadGuardAppState extends ConsumerState<RoadGuardApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Check for a recovered draft trip after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForRecoveredTrip();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // Flush in-progress trip data to Hive before the OS kills us
      ref.read(tripControllerProvider.notifier).onAppLifecyclePaused();
    }
  }

  void _checkForRecoveredTrip() async {
    final tripController = ref.read(tripControllerProvider.notifier);
    if (!tripController.hasDraftTrip) return;

    // Check if the background service is still running (survived app kill)
    final isServiceRunning =
        await FlutterBackgroundService().isRunning();

    if (isServiceRunning) {
      // Background service survived — seamlessly resume tracking + trip
      debugPrint('RoadGuardApp: Background service alive — resuming trip');
      await ref.read(speedTrackingProvider.notifier).startTracking();
      tripController.resumeTrip();
    } else {
      // Service was killed too — draft data is stale, discard it
      debugPrint('RoadGuardApp: Service dead — clearing stale draft');
      await tripController.discardDraftTrip();
    }
  }

  @override
  Widget build(BuildContext context) {
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
