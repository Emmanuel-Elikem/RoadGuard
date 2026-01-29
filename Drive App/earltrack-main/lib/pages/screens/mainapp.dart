import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:earltrack/pages/screens/home.dart';
import 'package:earltrack/pages/screens/map.dart';
import 'package:earltrack/pages/screens/schedule.dart';
import 'package:earltrack/pages/screens/setting.dart';
import 'package:earltrack/pages/screens/trip.dart';
import 'package:earltrack/services/location_notification.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:shared_preferences/shared_preferences.dart';

final List<Map<String, String>> daysOfWeek = [
  {"short": "S", "long": "Sunday", 'selected': 'false'},
  {"short": "M", "long": "Monday", 'selected': 'false'},
  {"short": "T", "long": "Tuesday", 'selected': 'false'},
  {"short": "W", "long": "Wednesday", 'selected': 'false'},
  {"short": "T", "long": "Thursday", 'selected': 'false'},
  {"short": "F", "long": "Friday", 'selected': 'false'},
  {"short": "S", "long": "Saturday", 'selected': 'false'},
];

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

enum TtsState { playing, stopped, paused, continued }

class _MainAppState extends State<MainApp> {
  final PersistentTabController? _controller =
      PersistentTabController(initialIndex: 0);

  SharedPreferences? prefs; // sharedpreference
  bool isBackgroundMode = true;
  bool isSpeech = true;
  bool isSpeedAlarm = true;
  bool isSchedule = true;
  String? remindersString;
  String overSpeedDataString = '';
  List<dynamic>? reminders;
  List<dynamic>? overSpeedData;

  TimeOfDay? defaultTime;
  TimeOfDay? selectedTime;
  String selectedTimeMessage = '';
  final _FormKey = GlobalKey<FormState>();
  TextEditingController labelController = TextEditingController();
  bool isScheduleFormLoading = false;

  // text to speed variables
  late FlutterTts flutterTts;
  String? language;
  String? engine;
  double volume = 0.7;
  double pitch = 1.0;
  double rate = 0.5;
  bool isCurrentLanguageInstalled = false;
  String? _newVoiceText;
  int? _inputLength;
  LocationNotification locationNotification = LocationNotification();

  TtsState ttsState = TtsState.stopped;

  bool get isPlaying => ttsState == TtsState.playing;
  bool get isStopped => ttsState == TtsState.stopped;
  bool get isPaused => ttsState == TtsState.paused;
  bool get isContinued => ttsState == TtsState.continued;

  bool get isIOS => !kIsWeb && Platform.isIOS;
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isWindows => !kIsWeb && Platform.isWindows;
  bool get isWeb => kIsWeb;

  // init flutter text to speed
  dynamic initTts() {
    flutterTts = FlutterTts();

    _setAwaitOptions();

    if (isAndroid) {
      _getDefaultEngine();
      _getDefaultVoice();
    }

    flutterTts.setStartHandler(() {
      setState(() {
        print("Playing");
        ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        print("Complete");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setCancelHandler(() {
      setState(() {
        print("Cancel");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setPauseHandler(() {
      setState(() {
        print("Paused");
        ttsState = TtsState.paused;
      });
    });

    flutterTts.setContinueHandler(() {
      setState(() {
        print("Continued");
        ttsState = TtsState.continued;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        print("error: $msg");
        ttsState = TtsState.stopped;
      });
    });
  }

  Future<void> _speak(String text) async {
    if (!isSpeech || text.isEmpty)
      return; // Exit early if speech is disabled or text is empty

    try {
      await flutterTts.setVolume(volume);
      await flutterTts.setSpeechRate(rate);
      await flutterTts.setPitch(pitch);

      setState(() {
        _newVoiceText = text;
      });

      await flutterTts.speak(text);
    } catch (e) {
      debugPrint("Error in text-to-speech: $e");
    }
  }

  Future<void> _setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
  }

  void _stop() async {
    var result = await flutterTts.stop();
    if (result == 1) setState(() => ttsState = TtsState.stopped);
  }

  Future<void> _pause() async {
    var result = await flutterTts.pause();
    if (result == 1) setState(() => ttsState = TtsState.paused);
  }

  Future<void> _getDefaultEngine() async {
    var engine = await flutterTts.getDefaultEngine;
    if (engine != null) {
      print(engine);
    }
  }

  Future<void> _getDefaultVoice() async {
    var voice = await flutterTts.getDefaultVoice;
    if (voice != null) {
      print(voice);
    }
  }

  void _onChange(String text) {
    setState(() {
      _newVoiceText = text;
    });
  }

  // end flutter text to speed logic

  // unit for spped
  final List<String> units = const <String>['m/s', 'km/h', 'miles/h'];
  String currentSelectedUnit = 'km/h';

  // background mode
  void toggleBackgroundMode() {
    if (prefs != null) {
      prefs?.setBool('isBackgroundMode', !isBackgroundMode);
    }
    setState(() {
      isBackgroundMode = !isBackgroundMode;
    });
  }

  // toggle allow text to speech
  void toggleSpeech() {
    if (prefs != null) {
      prefs?.setBool('isSpeech', !isSpeech);
    }
    setState(() {
      isSpeech = !isSpeech;
    });
  }

  // toggle speed alarm
  void toggleSpeedAlarm() {
    if (prefs != null) {
      prefs?.setBool('isSpeedAlarm', !isSpeedAlarm);
    }
    setState(() {
      isSpeedAlarm = !isSpeedAlarm;
    });
  }

  // toggle schedule pop up
  void toggleScheduleNoti() {
    if (prefs != null) {
      print(isSchedule);
      prefs?.setBool('isSchedule', !isSchedule);
    }
    setState(() {
      isSchedule = !isSchedule;
    });

    print(isSchedule);
  }

  // start shared preferences
  void startSharedPreference() async {
    prefs = await SharedPreferences.getInstance();

    setState(() {
      currentSelectedUnit = prefs?.getString('unit') ?? 'km/h';
      isSpeech = prefs?.getBool('isSpeech') ?? true;
      isBackgroundMode = prefs?.getBool('isBackgroundMode') ?? true;
      isSpeedAlarm = prefs?.getBool('isSpeedAlarm') ?? true;
      isSchedule = prefs?.getBool('isSchedule') ?? true;
      remindersString = prefs?.getString('reminders') ?? '';
      reminders = remindersString != '' ? jsonDecode(remindersString!) : [];
      overSpeedDataString = prefs?.getString('overSpeedData') ?? '';
      overSpeedData =
          overSpeedDataString != '' ? jsonDecode(overSpeedDataString) : [];
    });

    if (reminders != []) {
      reminders?.forEach((reminder) => print(reminder));
    }

  }

  // save reminder
  void saveReminder(Map<String, dynamic> data) async {
    dynamic updateReminders = reminders;
    updateReminders!.add(data);
    await prefs!
        .setString('reminders', jsonEncode(updateReminders)); // reminders
    setState(() {
      reminders = updateReminders;
    });
  }

  void saveOverSpeedData(String data) async {
    List<dynamic>? updateOverSpeedData = overSpeedData;
    updateOverSpeedData!.add(data);
    await prefs!.setString('overSpeedData', jsonEncode(updateOverSpeedData));
    setState(() {
      overSpeedData = updateOverSpeedData;
    });
  }

  // fetch all reminder
  Future<List<Map<String, dynamic>>> loadReminders() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? remindersString = prefs.getString('reminders');

    if (remindersString != null) {
      List<dynamic> reminders = jsonDecode(remindersString);

      // Ensure the data is properly cast into a List<Map<String, dynamic>>
      return List<Map<String, dynamic>>.from(reminders);
    }

    return [];
  }

  // delete reminder
  void deleteReminder(String reminderId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? remindersString = prefs.getString('reminders');

    if (remindersString != null) {
      List<dynamic> updateReminders = jsonDecode(remindersString);

      // Remove the reminder with matching ID

      updateReminders.removeWhere((reminder) => reminder['id'] == reminderId);

      LocationNotification.cancelNotifcation(int.parse(reminderId));

      // Save updated list
      await prefs.setString('reminders', jsonEncode(updateReminders));

      setState(() {
        reminders = updateReminders;
      });
    }
  }

  // update reminder
  void updateReminder(String reminderId, String type, dynamic data) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? remindersString = prefs.getString('reminders');

    if (remindersString != null) {
      List<dynamic> updatedReminders = jsonDecode(remindersString);

      if (type == 'toggleStatus') {
        // Update the status in the existing list
        for (var i = 0; i < updatedReminders.length; i++) {
          if (updatedReminders[i]['id'] == reminderId) {
            updatedReminders[i]['status'] =
                (updatedReminders[i]['status'] == 'on') ? 'off' : 'on';

            Timer(Duration(seconds: 1), () {
              if (updatedReminders[i]['status'] == 'on') {
                if (updatedReminders[i]['repeatDays'].isEmpty) {
                  // If no repeat days selected, schedule a one-time notification
                  LocationNotification.showScheduleNotification(
                    id: int.parse(updatedReminders[i]['id']),
                    title: 'Reminder',
                    body: updatedReminders[i]['label'] != ''
                        ? updatedReminders[i]['label']
                        : 'Scheduled Notification',
                    payload: 'Reminder ID: ${updatedReminders[i]['id']}',
                    hour: updatedReminders[i]['hour'],
                    minute: updatedReminders[i]['minute'],
                  );
                } else {
                  // Schedule notifications for each selected repeat day
                  for (String day in updatedReminders[i]['repeatDays']) {
                    LocationNotification.showScheduleNotification(
                      id: int.parse(updatedReminders[i]['id']),
                      title: 'Reminder',
                      body: updatedReminders[i]['label'] != ''
                          ? updatedReminders[i]['label']
                          : 'Scheduled Notification',
                      payload: 'Reminder ID: ${updatedReminders[i]['id']}',
                      day: day, // Pass repeat day
                      hour: updatedReminders[i]['hour'],
                      minute: updatedReminders[i]['minute'],
                    );
                  }
                }
              } else {
                LocationNotification.cancelNotifcation(
                    int.parse(updatedReminders[i]['id']));
              }
              ;
            });
          }
        }
        await prefs.setString('reminders', jsonEncode(updatedReminders));

        // Update the state
        setState(() {
          reminders = updatedReminders;
        });
      }

      if (type == 'updateData') {
        updatedReminders.removeWhere((element) => element['id'] == reminderId);
        updatedReminders.add(data);

        await prefs.setString('reminders', jsonEncode(updatedReminders));

        setState(() {
          reminders = updatedReminders;
        });
      }
    }
  }

  // unit selection func
  void unitSelection(String newUnit) {
    print(newUnit);
    if (prefs != null) {
      prefs!.setString('unit', newUnit);
    }

    print(prefs?.getString('unit'));
    setState(() {
      currentSelectedUnit = newUnit;
    });
  }

  // shared preference for start journey, end journey and to monitor overspeed
  void setStartJourneyShared(data) {
    prefs?.remove('startJourney');
    prefs?.setStringList('startJourney', data);
  }

  void setEndJourneyShared(data) {
    print(data);
    prefs?.remove('endJourney');
    prefs?.setStringList('endJourney', data);
  }

  void setOverSpeedPoint(data) {
    prefs?.remove('overSpeedPoint');
    prefs?.setStringList('overSpeedPoint', data);
  }

  List<Map<String, dynamic>> getSharedPreference() {
    List<String>? startJourney = prefs?.getStringList('startJourney');
    List<String>? endJourney = prefs?.getStringList('endJourney');

    return [
      {'startJourney': startJourney ?? []},
      {'endJourney': endJourney ?? []},
    ];
  }

  void notificationsetMessage(String message, String type) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: type == 'error'
            ? Colors.redAccent
            : const Color.fromARGB(255, 0, 6, 20),
        duration: const Duration(milliseconds: 1500),
        content: ListTile(
          dense: true,
          leading: Icon(
            type == 'error' ? Icons.warning : Icons.message,
            color: Colors.white,
          ),
          title: Text(
            message,
            style: TextStyle(color: Colors.white),
          ),
        )));
  }

  Future<void> _selectTime(BuildContext context) async {
    final now = TimeOfDay.now();
    defaultTime ??= now; // Ensure defaultTime is initialized

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: defaultTime!,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (pickedTime != null && pickedTime != selectedTime) {
      final nowMinutes = now.hour * 60 + now.minute;
      final pickedMinutes = pickedTime.hour * 60 + pickedTime.minute;

      int difference = pickedMinutes - nowMinutes;

      // If the picked time is earlier than now, assume it's the next day
      if (difference < 0) difference += 1440;

      String message;
      if (difference == 0) {
        message = "Notification is set for 1 day from now.";
      } else if (difference < 60) {
        message = "Notification is set for $difference minutes from now.";
      } else if (difference < 1440) {
        message = "Notification is set for ${difference ~/ 60} hours from now.";
      } else {
        message =
            "Notification is set for ${difference ~/ 1440} day(s) from now.";
      }

      print(pickedTime);
      setState(() {
        selectedTimeMessage = message;
        selectedTime = pickedTime;
      });
      print(selectedTime);
    }
  }

  void scheduleTripPopUp() {
    showModalBottomSheet(
        context: context,
        showDragHandle: true,
        backgroundColor: const Color.fromARGB(255, 0, 6, 20),
        builder: (context) {
          return Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                height: 300,
                child: Column(spacing: 10, children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Trip now or schedule?',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                      IconButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: Icon(
                            CupertinoIcons.xmark,
                            size: 25,
                            color: Colors.white,
                          ))
                    ],
                  ),
                  ListTile(
                    onTap: () {
                      // Navigator.of(context).push(MaterialPageRoute(
                      //     builder: (context) => ScheduleTrip()));
                      Navigator.of(context).pop();
                      scheduleTripPopUpForm();
                    },
                    shape: BeveledRectangleBorder(
                        side: BorderSide(width: 0.1, color: Colors.grey),
                        borderRadius: BorderRadius.circular(5)),
                    title: Text(
                      'Schedule trip',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Pick a date and time',
                      style: TextStyle(color: Colors.white70),
                    ), // Add your desired subtitle
                    leading: Icon(
                      Icons.schedule,
                      size: 35,
                      color: Colors.white,
                    ),

                    trailing: Icon(
                      CupertinoIcons.arrow_up_right,
                      size: 25,
                      color: Colors.white,
                    ),
                  ),
                  ListTile(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    shape: BeveledRectangleBorder(
                      side: BorderSide(width: 0.1, color: Colors.grey),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    title: Text(
                      'Continue Without Scheduling',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Proceed without selecting a date',
                      style: TextStyle(color: Colors.white70),
                    ),
                    leading: Icon(
                      Icons.play_arrow,
                      size: 35,
                      color: Colors.white,
                    ),
                    trailing: Icon(
                      CupertinoIcons.arrow_up_right,
                      size: 25,
                      color: Colors.white,
                    ),
                  )
                ]),
              ));
        });
  }

  void scheduleTripPopUpForm() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color.fromARGB(255, 0, 6, 20),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // This is the key change
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Form(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'Add schedule',
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      ),
                      Divider(),
                      SizedBox(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 5,
                          children: [
                            ListTile(
                              onTap: () async {
                                await _selectTime(context);
                                setState(() {}); // Forces rebuild
                              },
                              shape: BeveledRectangleBorder(
                                  side: BorderSide(
                                      width: 0.1, color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5)),
                              title: Text(
                                'Pick time',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white),
                              ),
                              subtitle: Text(
                                selectedTime != null
                                    ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                                    : 'No time selected',
                                style: TextStyle(color: Colors.white),
                              ),
                              trailing: Icon(
                                CupertinoIcons.clock,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Repeat',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children:
                                    daysOfWeek.asMap().entries.map((entry) {
                                  int index = entry.key;
                                  Map<String, String> day = entry.value;

                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        // This updates state inside the modal
                                        if (daysOfWeek[index]['selected'] ==
                                            'false') {
                                          daysOfWeek[index]['selected'] =
                                              'true';
                                        } else {
                                          daysOfWeek[index]['selected'] =
                                              'false';
                                        }
                                      });
                                      print(
                                          "Selected index: $index, Day: ${day['long']}");
                                    },
                                    child: Container(
                                      height: 40,
                                      width: 40,
                                      decoration: ShapeDecoration(
                                        color: day['selected'] == 'true'
                                            ? Colors.white
                                            : Colors.transparent,
                                        shape: CircleBorder(
                                          side: BorderSide(
                                              width: 0.5, color: Colors.grey),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          day['short']!,
                                          style: TextStyle(
                                              fontSize: 20,
                                              color: day['selected'] == 'true'
                                                  ? Color.fromARGB(
                                                      255, 45, 74, 124)
                                                  : Colors.white),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            Text(
                              'Label',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                            TextFormField(
                              controller: labelController,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Add a label...',
                                hintStyle: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                                fillColor: const Color.fromARGB(255, 7, 16, 37),
                                filled: true,
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                      color: const Color.fromARGB(
                                          255, 45, 74, 124)),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                      color: const Color.fromARGB(
                                          255, 45, 74, 124)),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      for (var days in daysOfWeek) {
                                        days['selected'] = 'false';
                                        print(days.toString());
                                      }

                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor:
                                            Color.fromARGB(255, 45, 74, 124),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                            side: BorderSide(
                                              color: const Color.fromARGB(
                                                  255, 0, 6, 20),
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        fixedSize: Size.fromWidth(
                                            MediaQuery.of(context).size.width *
                                                .45)),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10.0, vertical: 13),
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(fontSize: 20),
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                      onPressed: isScheduleFormLoading
                                          ? () {}
                                          : () {
                                              isScheduleFormLoading = true;
                                              if (selectedTime != null) {
                                                notificationsetMessage(
                                                    selectedTimeMessage,
                                                    'message');

                                                // Get selected repeat days
                                                List<String> selectedDays =
                                                    daysOfWeek
                                                        .where((day) =>
                                                            day['selected'] ==
                                                            'true')
                                                        .map((day) =>
                                                            day['long']!)
                                                        .toList();

                                                Map<String, dynamic>
                                                    newReminder = {
                                                  'id': DateTime.now()
                                                      .microsecond
                                                      .toString(),
                                                  'hour': selectedTime!.hour,
                                                  'minute':
                                                      selectedTime!.minute,
                                                  'repeatDays': selectedDays,
                                                  'label': labelController.text
                                                      .trim(),
                                                  'status': 'on'
                                                };

                                                saveReminder(newReminder);

                                                if (selectedDays.isEmpty) {
                                                  // If no repeat days selected, schedule a one-time notification
                                                  LocationNotification
                                                      .showScheduleNotification(
                                                    id: int.parse(
                                                        newReminder['id']),
                                                    title: 'Reminder',
                                                    body: labelController
                                                            .text.isNotEmpty
                                                        ? labelController.text
                                                        : 'Scheduled Notification',
                                                    payload:
                                                        'Reminder ID: ${newReminder['id']}',
                                                    hour: selectedTime!.hour,
                                                    minute:
                                                        selectedTime!.minute,
                                                  );
                                                } else {
                                                  // Schedule notifications for each selected repeat day
                                                  for (String day
                                                      in selectedDays) {
                                                    LocationNotification
                                                        .showScheduleNotification(
                                                      id: int.parse(
                                                          newReminder['id']),
                                                      title: 'Reminder',
                                                      body: labelController
                                                              .text.isNotEmpty
                                                          ? labelController.text
                                                          : 'Scheduled Notification',
                                                      payload:
                                                          'Reminder ID: ${newReminder['id']}',
                                                      day:
                                                          day, // Pass repeat day
                                                      hour: selectedTime!.hour,
                                                      minute:
                                                          selectedTime!.minute,
                                                    );
                                                  }
                                                }
                                                for (var days in daysOfWeek) {
                                                  days['selected'] = 'false';
                                                }

                                                selectedTime = null;
                                                labelController.text = '';

                                                Navigator.pop(context);
                                              } else {
                                                notificationsetMessage(
                                                    'Please pick a time',
                                                    'error');
                                              }

                                              isScheduleFormLoading = false;
                                            },
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color.fromARGB(
                                              255, 45, 74, 124),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                          fixedSize: Size.fromWidth(
                                              MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  .45)),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10.0, vertical: 13),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            if (isScheduleFormLoading)
                                              CupertinoActivityIndicator(
                                                  radius: 12.0,
                                                  color: CupertinoColors.white),
                                            if (!isScheduleFormLoading)
                                              Text(
                                                'Save',
                                                style: TextStyle(fontSize: 20),
                                              ),
                                          ],
                                        ),
                                      ))
                                ],
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    startSharedPreference();
    initTts();
  }

  @override
  void dispose() {
    super.dispose();
    flutterTts.stop();
  }

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      tabs: [
        PersistentTabConfig(
            screen: Home(
              isBackgroundMode: isBackgroundMode,
              setStartJourneyShared: setStartJourneyShared,
              setEndJourneyShared: setEndJourneyShared,
              setOverSpeedPoint: setOverSpeedPoint,
              getSharedPreference: getSharedPreference,
              unit: currentSelectedUnit,
              speak: _speak,
              isSchedule: isSchedule,
              saveReminder: saveReminder,
              deleteReminder: deleteReminder,
              scheduleTripPopUpForm: scheduleTripPopUpForm,
              saveOverSpeedData: saveOverSpeedData,
              overSpeedData: overSpeedData,
            ),
            item: ItemConfig(
              icon: Icon(CupertinoIcons.speedometer),
              activeForegroundColor: const Color.fromARGB(255, 45, 74, 124),
              title: "Speed",
            )),
        PersistentTabConfig(
            screen: Schedule(
              loadReminders: loadReminders,
              updateReminder: updateReminder,
              reminders: reminders,
              saveReminder: saveReminder,
              deleteReminder: deleteReminder,
              scheduleTripPopUpForm: scheduleTripPopUpForm,
            ),
            item: ItemConfig(
              icon: Icon(Icons.schedule),
              activeForegroundColor: const Color.fromARGB(255, 45, 74, 124),
              title: "Schedule",
            )),
        PersistentTabConfig(
            screen: Trip(),
            item: ItemConfig(
              icon: Icon(CupertinoIcons.square_stack),
              activeForegroundColor: const Color.fromARGB(255, 45, 74, 124),
              title: "Trip",
            )),
        PersistentTabConfig(
            screen: Setting(
              isBackgroundMode: isBackgroundMode,
              toggleBackgroundMode: toggleBackgroundMode,
              unitSelection: unitSelection,
              isSpeech: isSpeech,
              toggleSpeech: toggleSpeech,
              isSpeedAlarm: isSpeedAlarm,
              toggleSpeedAlarm: toggleSpeedAlarm,
              unit: currentSelectedUnit,
              isSchedule: isSchedule,
              toggleScheduleNoti: toggleScheduleNoti,
            ),
            item: ItemConfig(
              icon: Icon(CupertinoIcons.settings),
              activeForegroundColor: const Color.fromARGB(255, 45, 74, 124),
              title: "Settings",
            ))
      ],
      navBarBuilder: (navBarConfig) => Style1BottomNavBar(
        navBarConfig: navBarConfig,
        navBarDecoration: NavBarDecoration(color: Colors.black87),
      ),
    );
  }
}
