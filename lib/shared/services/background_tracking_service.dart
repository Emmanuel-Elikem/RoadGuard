import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

/// Service that manages the background isolate for persistent tracking.
@pragma('vm:entry-point')
class BackgroundTrackingService {
  static const String notificationChannelId = 'road_guard_tracking';
  static const int notificationId = 888;

  /// Initialize the background service (called from main).
  Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    // Notification setup for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      'RoadGuard Tracking',
      description: 'Monitoring your speed for safety',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        // This will be executed in the separate isolate
        onStart: onStart,

        // auto start false so we control when it starts
        autoStart: false,
        isForegroundMode: true,

        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'RoadGuard Service',
        initialNotificationContent: 'Initializing...',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  /// Entry point for the background isolate.
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    // Only available for flutter 3.0.0 and later
    DartPluginRegistrant.ensureInitialized();

    // Listen for stop event from UI
    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Android-specific: set as foreground
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
      service.setForegroundNotificationInfo(
        title: "RoadGuard Tracking",
        content: "Starting GPS...",
      );
    }

    // Settings for high accuracy
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0, 
    );
    
    // Stream position updates
    Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        final speedKmh = (position.speed * 3.6).abs();
        
        // Update notification with speed and accuracy
        if (service is AndroidServiceInstance) {
           service.setForegroundNotificationInfo(
            title: "RoadGuard Tracking",
            content: "Speed: ${speedKmh.toStringAsFixed(0)} km/h | ±${position.accuracy.toStringAsFixed(0)}m",
          );
        }

        // Send data to UI
        service.invoke(
          'update',
          {
            'lat': position.latitude,
            'lng': position.longitude,
            'speed': position.speed,
            'accuracy': position.accuracy,
            'altitude': position.altitude,
            'heading': position.heading,
            'time': position.timestamp.toIso8601String(),
            'speed_accuracy': position.speedAccuracy,
          },
        );
      },
      onError: (e) {
        debugPrint('BackgroundTrackingService: GPS error: $e');
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: "RoadGuard Error",
            content: "GPS Error: $e",
          );
        }
        service.invoke('error', {'message': e.toString()});
      },
    );
  }

  @pragma('vm:entry-point')
  static bool onIosBackground(ServiceInstance service) {
    WidgetsFlutterBinding.ensureInitialized();
    return true;
  }
}
