import 'dart:async';
//import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:earltrack/pages/screens/mainapp.dart';
import 'package:earltrack/pages/screens/tts.dart';
import 'package:earltrack/services/authentication.dart';
import 'package:earltrack/services/location_notification.dart';
import 'package:earltrack/services/nopermission.dart';
import 'package:earltrack/services/wrapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// This function will be used by the WorkManager to handle background tasks
void backgroundTask() async {
  // Get the shared preferences to store the counter value
  final prefs = await SharedPreferences.getInstance();
  int counter =
      prefs.getInt('counter') ?? 0; // Default counter is 0 if not found

  // Increment the counter
  counter++;

  // Save the new counter value back to shared preferences
  prefs.setInt('counter', counter);

  // Show a notification with the incremented counter
  // AwesomeNotifications().createNotification(
  //   content: NotificationContent(
  //     id: 10,
  //     channelKey: 'basic_channel',
  //     title: 'Current Speed',
  //     body: 'Hello $counter', // Show the incremented counter
  //   ),
  // );
}

// This function will initialize WorkManager and register the periodic task
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) {
    // If the task is triggered, we call backgroundTask
    if (task == 'location_update_task') {
      print(
          'WorkManager task started!'); // Prints to the console (in debug mode)
      backgroundTask(); // Handle the background task
    }

    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
   tz.initializeTimeZones();
  await LocationNotification.init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const NoPermissionApp(hasCheckedPermissions: false));

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.unableToDetermine) {
    permission = await GeolocatorPlatform.instance.requestPermission();
  }

  switch (permission) {
    case LocationPermission.deniedForever:
      runApp(const NoPermissionApp(hasCheckedPermissions: true));
      break;

    case LocationPermission.always:
    case LocationPermission.whileInUse:
      runApp(const MainApp());
      break;

    case LocationPermission.denied:
    case LocationPermission.unableToDetermine:
      runApp(const NoPermissionApp(hasCheckedPermissions: false));
  }


  await _ensureLocationPermissions();

  runApp(MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: true,
      home: StreamProvider<User?>.value(
        value: Authentication().authStateChanges,
        initialData: null,
        child: Wrapper(),
      )));
}

Future<void> _ensureLocationPermissions() async {
  final location = Location();

  location.enableBackgroundMode(enable: true);
}
