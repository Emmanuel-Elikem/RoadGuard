import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/rxdart.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocationNotification {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final onChangeNotification = BehaviorSubject<String>();

  static void onTapNotification(NotificationResponse notificationResponse) {
    if (notificationResponse.payload != null) {
      onChangeNotification.add(notificationResponse.payload!);
    } else {
      print('No payload in notification');
    }
  }

  static Future init() async {
// initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();
    final LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');
    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsDarwin,
            macOS: initializationSettingsDarwin,
            linux: initializationSettingsLinux);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: onTapNotification,
        onDidReceiveBackgroundNotificationResponse: onTapNotification);
  }

  static Future<void> showPersistentNotificationWithSound({
    required String title,
    required String body,
    required String payload,
    required int notificationId,
    String? soundFile,
    bool loopSound = false, // Enable sound looping
  }) async {
    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'persistent_channel_id',
      'Persistent Notifications',
      channelDescription: 'Notifications that stay until manually dismissed',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: soundFile != null
          ? RawResourceAndroidNotificationSound(soundFile)
          : null,
      ongoing: true,
      autoCancel: false,
      enableVibration: true,
      visibility: NotificationVisibility.public,
      timeoutAfter: null,
      category: AndroidNotificationCategory.status,
      additionalFlags:
          Int32List.fromList([1 << 2]), // FLAG_INSISTENT for repeating sound
      actions: [
        AndroidNotificationAction(
          'dismiss',
          'Dismiss',
          cancelNotification: true,
        ),
      ],
      channelShowBadge: true,
      showWhen: false,
      when: DateTime.now().millisecondsSinceEpoch,
    );

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      NotificationDetails(android: androidNotificationDetails),
      payload: payload,
    );
  }

  static Future simpleNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails('your channel id', 'your channel name',
            channelDescription: 'your channel description',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker');
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);
    await flutterLocalNotificationsPlugin
        .show(0, title, body, notificationDetails, payload: payload);
  }

  // showing perodic notifcation
  static Future showPeriodicNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails('second', 'your channel name',
            channelDescription: 'your channel description',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker');
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);
    await flutterLocalNotificationsPlugin.periodicallyShow(
        1, title, body, RepeatInterval.everyMinute, notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle);
  }

  // close a notifcation
  static Future cancelNotifcation(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    print("Reminder with ${id} has been cancelled");
  }

  // close all notification
  static Future cancelAllNotification() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  static Future<void> showScheduleNotification({
    required int
        id, // Unique ID for the notification (required for cancellation)
    required String title,
    required String body,
    required String payload,
    String? day, // Optional (null for one-time notifications)
    required int hour,
    required int minute,
  }) async {
    try {
      print(
          'Scheduling notification: ID=$id, $title, $body, $payload, $day, $hour:$minute');

      // Initialize time zones
      tz.initializeTimeZones();
      tz.setLocalLocation(
          tz.getLocation('Africa/Accra')); // Set time zone to Ghana

      // Get the current time in the local time zone
      tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate =
          tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

      // If a day is provided, find the next occurrence of that weekday
      if (day != null) {
        // Map days to weekday index (Monday = 1, Sunday = 7)
        Map<String, int> weekdayMap = {
          'Monday': DateTime.monday,
          'Tuesday': DateTime.tuesday,
          'Wednesday': DateTime.wednesday,
          'Thursday': DateTime.thursday,
          'Friday': DateTime.friday,
          'Saturday': DateTime.saturday,
          'Sunday': DateTime.sunday,
        };

        int dayOfWeek = weekdayMap[day] ?? DateTime.monday;

        // Find the next occurrence of the selected day
        while (
            scheduledDate.weekday != dayOfWeek || scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(Duration(days: 1));
        }

        print('Scheduled date for $day: $scheduledDate');
      } else {
        // One-time notification (no repeat days selected)
        if (scheduledDate.isBefore(now)) {
          scheduledDate =
              scheduledDate.add(Duration(days: 1)); // Ensure future time
        }

        print('Scheduled date for one-time notification: $scheduledDate');
      }

      // Schedule the notification
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id, // Use the provided ID
        title,
        body,
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'channel_3', // Channel ID
            'Alarm Channel', // Channel name
            channelDescription:
                'Channel for alarm notifications', // Channel description
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
            enableVibration: true, // Enable vibration
            vibrationPattern:
                Int64List.fromList([0, 1000, 500, 1000]), // Vibrate pattern
          ),
          // iOS: IOSNotificationDetails(
          //   sound: 'default', // Use the default sound on iOS
          //   presentAlert:
          //       true, // Show an alert when the notification is triggered
          //   presentBadge: true, // Update the app badge
          //   presentSound: true, // Play a sound
          // ),
        ),
        androidScheduleMode:
            AndroidScheduleMode.exactAllowWhileIdle, // Exact scheduling
        matchDateTimeComponents: day != null
            ? DateTimeComponents.dayOfWeekAndTime // Weekly repeat
            : DateTimeComponents.time, // One-time
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      print('Notification scheduled successfully');
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }
  // static Future<void> showScheduleNotification({
  //   required String title,
  //   required String body,
  //   required String payload,
  //   String? day, // Optional (null for one-time notifications)
  //   required int hour,
  //   required int minute,
  // }) async {
  //   try {
  //     // Initialize time zones
  //     tz.initializeTimeZones();
  //     tz.setLocalLocation(
  //         tz.getLocation('Africa/Accra')); // Set time zone to Ghana

  //     // Get the current time in the local time zone
  //     tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  //     tz.TZDateTime scheduledDate =
  //         tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

  //     // If a day is provided, find the next occurrence of that weekday
  //     if (day != null) {
  //       // Map days to weekday index (Monday = 1, Sunday = 7)
  //       Map<String, int> weekdayMap = {
  //         'Monday': DateTime.monday,
  //         'Tuesday': DateTime.tuesday,
  //         'Wednesday': DateTime.wednesday,
  //         'Thursday': DateTime.thursday,
  //         'Friday': DateTime.friday,
  //         'Saturday': DateTime.saturday,
  //         'Sunday': DateTime.sunday,
  //       };

  //       int dayOfWeek = weekdayMap[day] ?? DateTime.monday;

  //       // Find the next occurrence of the selected day
  //       while (
  //           scheduledDate.weekday != dayOfWeek || scheduledDate.isBefore(now)) {
  //         scheduledDate = scheduledDate.add(Duration(days: 1));
  //       }

  //       print('Scheduled date for $day: $scheduledDate');

  //       // Schedule the notification
  //       await flutterLocalNotificationsPlugin.zonedSchedule(
  //         dayOfWeek, // Unique ID per day (valid since dayOfWeek is 1-7)
  //         title,
  //         body,
  //         scheduledDate,
  //         NotificationDetails(
  //           android: AndroidNotificationDetails(
  //             'channel_3', // Channel ID
  //             'Alarm Channel', // Channel name
  //             channelDescription:
  //                 'Channel for alarm notifications', // Channel description
  //             importance: Importance.max,
  //             priority: Priority.high,
  //             ticker: 'ticker',
  //             enableVibration: true, // Enable vibration
  //             vibrationPattern:
  //                 Int64List.fromList([0, 1000, 500, 1000]), // Vibrate pattern
  //           ),
  //         ),
  //         androidScheduleMode:
  //             AndroidScheduleMode.exactAllowWhileIdle, // Exact scheduling
  //         matchDateTimeComponents:
  //             DateTimeComponents.dayOfWeekAndTime, // Weekly repeat
  //         uiLocalNotificationDateInterpretation:
  //             UILocalNotificationDateInterpretation.absoluteTime,
  //         payload: payload,
  //       );
  //     } else {
  //       // One-time notification (no repeat days selected)
  //       if (scheduledDate.isBefore(now)) {
  //         scheduledDate =
  //             scheduledDate.add(Duration(days: 1)); // Ensure future time
  //       }

  //       print('Scheduled date for one-time notification: $scheduledDate');

  //       // Generate a valid ID for one-time notifications
  //       int notificationId =
  //           Random().nextInt(2147483647); // Random ID within valid range

  //       // Schedule the notification
  //       await flutterLocalNotificationsPlugin.zonedSchedule(
  //         notificationId, // Unique ID for one-time
  //         title,
  //         body,
  //         scheduledDate,
  //         NotificationDetails(
  //           android: AndroidNotificationDetails(
  //             'channel_3', // Channel ID
  //             'Alarm Channel', // Channel name
  //             channelDescription:
  //                 'Channel for alarm notifications', // Channel description
  //             importance: Importance.max,
  //             priority: Priority.high,
  //             ticker: 'ticker',
  //             enableVibration: true, // Enable vibration
  //             vibrationPattern:
  //                 Int64List.fromList([0, 1000, 500, 1000]), // Vibrate pattern
  //           ),
  //         ),
  //         androidScheduleMode:
  //             AndroidScheduleMode.exactAllowWhileIdle, // Exact scheduling
  //         matchDateTimeComponents: DateTimeComponents.time, // One-time
  //         uiLocalNotificationDateInterpretation:
  //             UILocalNotificationDateInterpretation.absoluteTime,
  //         payload: payload,
  //       );
  //     }

  //     print('Notification scheduled successfully');
  //   } catch (e) {
  //     print('Error scheduling notification: $e');
  //   }
  // }
}
