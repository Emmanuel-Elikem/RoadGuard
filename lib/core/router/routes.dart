/// Route path constants for the application.
///
/// Centralizing routes prevents typos and makes refactoring easier.
abstract final class Routes {
  // Shell routes (bottom nav destinations)
  static const String home = '/';
  static const String stats = '/stats';
  static const String search = '/search';
  static const String settings = '/settings';

  // Auth routes
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';

  // Feature routes
  static const String tracking = '/tracking';
  static const String rateDriver = '/rate-driver';
  static const String vehicleDetails = '/vehicle/:plateNumber';

  // Helper for vehicle details with plate number
  static String vehicleDetailsPath(String plateNumber) =>
      '/vehicle/$plateNumber';
}

/// Route names for named navigation.
abstract final class RouteNames {
  static const String home = 'home';
  static const String stats = 'stats';
  static const String search = 'search';
  static const String settings = 'settings';
  static const String splash = 'splash';
  static const String onboarding = 'onboarding';
  static const String auth = 'auth';
  static const String tracking = 'tracking';
  static const String rateDriver = 'rateDriver';
  static const String vehicleDetails = 'vehicleDetails';
}
