import 'dart:async';
import 'dart:math';

//import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:earltrack/components/userLocation.dart';
import 'package:earltrack/main.dart';
import 'package:earltrack/pages/screens/analog.dart';
import 'package:earltrack/pages/screens/digital.dart';
import 'package:earltrack/pages/screens/map.dart';
import 'package:earltrack/pages/screens/schedule_trip.dart';
import 'package:earltrack/pages/screens/stop.dart';
import 'package:earltrack/services/location_notification.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart'
    show Placemark, placemarkFromCoordinates;
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';

final List<Map<String, String>> daysOfWeek = [
  {"short": "S", "long": "Sunday", 'selected': 'false'},
  {"short": "M", "long": "Monday", 'selected': 'false'},
  {"short": "T", "long": "Tuesday", 'selected': 'false'},
  {"short": "W", "long": "Wednesday", 'selected': 'false'},
  {"short": "T", "long": "Thursday", 'selected': 'false'},
  {"short": "F", "long": "Friday", 'selected': 'false'},
  {"short": "S", "long": "Saturday", 'selected': 'false'},
];

class Home extends StatefulWidget {
  final bool isBackgroundMode;
  final bool isSchedule;
  final Function setStartJourneyShared;
  final Function setEndJourneyShared;
  final Function setOverSpeedPoint;
  final Function getSharedPreference;
  final String unit;
  final List<dynamic>? overSpeedData;
  final Function speak;
  final Function saveReminder;
  final Function deleteReminder;
  final Function scheduleTripPopUpForm;
  final Function saveOverSpeedData;

  const Home({
    super.key,
    required this.isBackgroundMode,
    required this.setStartJourneyShared,
    required this.setEndJourneyShared,
    required this.setOverSpeedPoint,
    required this.getSharedPreference,
    required this.unit,
    required this.speak,
    required this.isSchedule,
    required this.saveReminder,
    required this.deleteReminder,
    required this.scheduleTripPopUpForm,
    this.overSpeedData,
    required this.saveOverSpeedData,
  });

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  final StreamController<LocationData> _locationStreamController =
      StreamController<LocationData>();
  double? velocity = 0.0;
  double? topVelocity = 0.0;
  double? heading = 0.0;
  late LocationData dataLocation;
  String groundLocation = "";
  Location location = Location();
  bool isInForeground = true;
  var random = Random();
  bool isRunning = false;
  bool isPause = false;
  bool isContinue = false;
  bool canStart = false;
  bool showTripPrompt = false;
  double totalDistance = 0.0;
  late SharedPreferences? prefs;
  double averageSpeed = 0.0;
  double totalTime = 0.0;
  LocationData? previousLocation;
  Timer? _overSpeedTimer;
  List<LocationData> overSpeedPointData = [];
  DateTime? _overSpeedStartTime;
  List<LocationData> theJourney = [];
  Timer? journeyTimer;
  DateTime? dateTime;
  TimeOfDay? defaultTime;
  TimeOfDay? selectedTime;
  String selectedTimeMessage = '';
  final _FormKey = GlobalKey<FormState>();
  TextEditingController labelController = TextEditingController();
  bool isScheduleFormLoading = false;
  bool hasTriggerOverSpeed = false;

  // duration variables
  Timer? _timer;
  int _seconds = 0;
  int _days = 0;
  String duration = '';
  double? smoothedSpeed = 0.0; // Smoothed value of the speed
  // double smoothingFactor =
  //     0.2; // Weight for the most recent speed (0.0 < smoothingFactor < 2.0)

  String currentView = 'analog';

  double updateSmoothedSpeed(double newSpeed) {
    double dynamicFactor =
        newSpeed > 10 ? 0.1 : 0.3; // Less smoothing at high speeds
    smoothedSpeed = smoothedSpeed == null
        ? newSpeed
        : (dynamicFactor * newSpeed) + ((1 - dynamicFactor) * smoothedSpeed!);

    return smoothedSpeed!;
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double radius = 6371; // Radius of Earth in km
    double lat1Rad = _degToRad(lat1);
    double lon1Rad = _degToRad(lon1);
    double lat2Rad = _degToRad(lat2);
    double lon2Rad = _degToRad(lon2);
    double deltaLat = lat2Rad - lat1Rad;
    double deltaLon = lon2Rad - lon1Rad;

    double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLon / 2) * sin(deltaLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distanceKm = radius * c; // Distance in km

    if (distanceKm * 1000 < 5) return 0; // Ignore noise below 5 meters

    if (widget.unit == 'm/s') {
      return distanceKm * 1000; // Return in meters
    } else if (widget.unit == 'km/h') {
      return distanceKm; // Return in kilometers
    } else if (widget.unit == 'miles/h') {
      return distanceKm * 0.621371; // Convert to miles
    }

    return distanceKm; // Default to kilometers
  }

  // Helper function to convert degrees to radians
  double _degToRad(double deg) {
    return deg * (pi / 180);
  }

  /// Velocity in m/s to km/hr converter
  double mpstokmph(double mps) => mps * 18 / 5;

  /// Velocity in m/s to miles per hour converter
  double mpstomilesph(double mps) => mps * 85 / 38;

  double? convertedVelocity(double? newVelocity) {
    newVelocity = newVelocity ?? velocity;

    if (widget.unit == 'm/s') {
      return newVelocity;
    } else if (widget.unit == 'km/h') {
      return mpstokmph(newVelocity!);
    } else if (widget.unit == 'miles/h') {
      return mpstomilesph(newVelocity!);
    }
    return newVelocity;
  }

  @override
  void initState() {
    super.initState();
    listenToNotifications();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer(Duration(seconds: 5), () {
        widget.isSchedule && widget.scheduleTripPopUpForm();
      });
    });
    // Check if notifications are allowed
    // AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    //   if (!isAllowed) {
    //     AwesomeNotifications().requestPermissionToSendNotifications();
    //   }
    // });

    // Set notification listeners for handling action buttons
    // AwesomeNotifications()
    //     .setListeners(onActionReceivedMethod: onActionReceivedMethod);

    // Get initialize location
    location.getLocation().then((value) {
      previousLocation = value;
    });

    updateJourney();
    dateTime = DateTime.now();

    // Listen to location changes
    location.onLocationChanged.listen((LocationData currentLocation) {
      if (currentLocation.accuracy == null || currentLocation.speed == null) {
        return;
      }

      _locationStreamController.add(currentLocation);
      setState(() {
        dataLocation = currentLocation;
        velocity = updateSmoothedSpeed(currentLocation.speed!);
        heading = (currentLocation.heading ?? 0) / 2;

        if (velocity! > topVelocity!) {
          topVelocity = velocity;
        }
      });

      if (isRunning) {
        checkOverSpeed(convertedVelocity(velocity) ?? 0.0, currentLocation);
        updateDistanceAndSpeed(currentLocation);
        getGroundLocation(currentLocation.latitude, currentLocation.longitude);
      }

      // Update the notification when speed changes
      if (isRunning && widget.isBackgroundMode && !isInForeground) {
        updateSpeedNotification();
      }
    });

    startSharedPreference();

    // Set location settings
    location.changeSettings(
      accuracy: LocationAccuracy.high, // High accuracy
    );
  }

  void updateSpeedNotification() {
    LocationNotification.simpleNotification(
        body:
            'Speed: ${convertedVelocity(velocity!)?.toStringAsFixed(2)} ${widget.unit} '
            'Average Speed: ${averageSpeed.toStringAsFixed(2)} ${widget.unit}',
        title: 'Current Speed',
        payload: 'stop');
  }

  listenToNotifications() {
    LocationNotification.onChangeNotification.stream.listen((event) {
      print(event);
    });
  }

  void checkOverSpeed(double velocity, LocationData currentLocation) {
    // Define speed limits based on the unit
    const double speedLimitKph = 0; // 50.0; // Speed limit in km/h
    const double speedLimitMps =
        0; //13.89; // Speed limit in m/s (50 km/h converted to m/s)
    const double speedLimitMph = 0;
    //31.07; // Speed limit in miles/h (50 km/h converted to miles/h)

    // Check the unit and compare the speed with the correct limit
    double speed =
        velocity; // The speed is already in the correct unit, no need to convert.

    if (isRunning) {
      final storedId = '214623';

      if (widget.unit == 'm/s' && speed >= speedLimitMps) {
        // Overspeeding in m/s
        _handleOverspeed(currentLocation);
        if (!hasTriggerOverSpeed) {
          widget.saveOverSpeedData(storedId);
          LocationNotification.showPersistentNotificationWithSound(
              body:
                  'You have been driving above the speed limit for over a minute!',
              title: 'Overspeed Alert!',
              payload: 'overspeed',
              notificationId: int.parse(storedId));
          setState(() {
            hasTriggerOverSpeed = true;
          });
        }
      } else if (widget.unit == 'km/h' && speed >= speedLimitKph) {
        // Overspeeding in km/h
        print(3333333333);
        _handleOverspeed(currentLocation);
        if (!hasTriggerOverSpeed) {
          widget.saveOverSpeedData(storedId);
          LocationNotification.showPersistentNotificationWithSound(
              body:
                  'You have been driving above the speed limit for over a minute!',
              title: 'Overspeed Alert!',
              payload: 'overspeed',
              notificationId: int.parse(storedId));
          setState(() {
            hasTriggerOverSpeed = true;
          });
        } else {
          print("ggggg ${hasTriggerOverSpeed} ");
        }
      } else if (widget.unit == 'miles/h' && speed >= speedLimitMph) {
        // Overspeeding in miles/h

        _handleOverspeed(currentLocation);
        if (!hasTriggerOverSpeed) {
          widget.saveOverSpeedData(storedId);
          LocationNotification.showPersistentNotificationWithSound(
              body:
                  'You have been driving above the speed limit for over a minute!',
              title: 'Overspeed Alert!',
              payload: 'overspeed',
              notificationId: int.parse(storedId));

          setState(() {
            hasTriggerOverSpeed = true;
          });
        }
      } else {
        // If speed is below the threshold, reset the overspeed tracking
        _overSpeedStartTime = null;
        _overSpeedTimer?.cancel();
        _overSpeedTimer = null;
        setState(() {
          hasTriggerOverSpeed = false;
        });
        widget.overSpeedData?.forEach((element) =>
            LocationNotification.cancelNotifcation(int.parse(element)));
      }
    }
  }

  void _handleOverspeed(LocationData currentLocation) {
    _overSpeedStartTime ??= DateTime.now();
    // Calculate the overspeed duration
    Duration overspeedDuration =
        DateTime.now().difference(_overSpeedStartTime!);
    int minutes = overspeedDuration.inSeconds;
    // Trigger notification after 1 minute of overspeeding
    if (minutes >= 0 && _overSpeedTimer == null && isRunning) {
      _overSpeedTimer = Timer(Duration(seconds: 10), () async {
        if ((widget.unit == 'm/s' && velocity! >= 0) || //13.89
            (widget.unit == 'km/h' && velocity! >= 0) || //50.0
            (widget.unit == 'miles/h' && velocity! >= 0)) {
          overSpeedPointData.add(currentLocation);

          // if (!hasTriggerOverSpeed) {
          //   print('hello');
          //   LocationNotification.simpleNotification(
          //       body:
          //           'You have been driving above the speed limit for over a minute!',
          //       title: 'Overspeed Alert!',
          //       payload: 'overspeed');
          //   hasTriggerOverSpeed = true;
          // }
        }
        _overSpeedTimer = null; // Reset timer
      });
    }
  }

  void updateJourney() {
    journeyTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      setState(() {
        location.getLocation().then((value) {
          theJourney.add(value);
        });
      });
    });
  }

  void updateDistanceAndSpeed(LocationData currentLocation) {
    if (previousLocation == null || currentLocation.time == null) return;

    double speed = convertedVelocity(velocity) ?? 0.0;
    double timeDifference =
        (currentLocation.time! - previousLocation!.time!).abs() /
            1000; // in seconds

    if (speed > 1 && timeDifference > 0) {
      // Ignore small fluctuations
      double distanceCovered = calculateDistance(
        previousLocation!.latitude!,
        previousLocation!.longitude!,
        currentLocation.latitude!,
        currentLocation.longitude!,
      );

      totalDistance += distanceCovered;
      totalTime += timeDifference;

      if (totalTime > 0) {
        setState(() {
          averageSpeed = widget.unit == 'm/s'
              ? totalDistance / totalTime
              : widget.unit == 'km/h'
                  ? (totalDistance / totalTime) * 3.6
                  : (totalDistance / totalTime) * 2.23694; // miles/h
        });
      }
    }

    previousLocation = currentLocation;
  }

  void showSpeed() {
    // LocationNotification.showScheduleNotification(
    //   id: 2,
    //   title: 'Reminder',
    //   body: 'Take a break!',
    //   payload: 'reminder_1',
    //   hour: 20, // 3:00 PM
    //   minute: 14,
    // );

    setState(() {
      isRunning = true;
      topVelocity = 0.0;
      totalDistance = 0.0;
      averageSpeed = 0.0;
      overSpeedPointData = [];
      theJourney = [];
      heading = 0.0;
      velocity = 0.0;
      groundLocation = '';
    });

    location.getLocation().then((value) {
      widget.setStartJourneyShared([
        value.latitude.toString(),
        value.longitude.toString(),
        value.speed.toString(),
        value.time.toString(),
        value.heading.toString(),
      ]);
    }).catchError((error) {
      widget.setStartJourneyShared(['0', '0', '0', '0', '0']);
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
        if (_seconds >= 86400) {
          _seconds = 0; // Reset seconds
          _days++; // Increment days
        }
      });
    });
  }

  void stopSpeed() {
    setState(() {
      isRunning = false;
      journeyTimer?.cancel();
      journeyTimer = null;
      hasTriggerOverSpeed = false;
    });

    widget.overSpeedData?.forEach((element) =>
        LocationNotification.cancelNotifcation(int.parse(element)));

    location.getLocation().then((value) {
      widget.setEndJourneyShared([
        value.latitude.toString(),
        value.longitude.toString(),
        value.speed.toString(),
        value.time.toString(),
        value.heading.toString(),
      ]);
    }).catchError((error) {
      widget.setEndJourneyShared(['0', '0', '0', '0', '0']);
    });

    _seconds = 0;
    _days = 0;
    _timer?.cancel();
    List<Map<String, dynamic>> data = widget.getSharedPreference();

    navigatorKey.currentState!.push(MaterialPageRoute(
      builder: (context) => Stop(
        locations: data,
        topSpeed: convertedVelocity(topVelocity!),
        distanceCoverd: totalDistance,
        averageSpeed: averageSpeed,
        duration: duration,
        unit: widget.unit,
        overSpeedPointData: overSpeedPointData,
        theJourney: theJourney,
      ),
    ));
  }

  void startSharedPreference() async {
    prefs = await SharedPreferences.getInstance();
  }

  void getGroundLocation(double? lat, double? long) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(lat ?? 0.0, long ?? 0.0);
      var output = 'No result found';
      if (placemarks.isNotEmpty) {
        Placemark currentLocation = placemarks[0];
        output = currentLocation.locality.toString() +
            ", " +
            currentLocation.country.toString(); // Get address
      }
      setState(() {
        groundLocation = output;
      });
    } catch (e) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app state changes
    if (state == AppLifecycleState.resumed) {
      // App is in the foreground
      setState(() {
        isInForeground = true;
      });
      print("App is in Foreground");
    } else if (state == AppLifecycleState.paused) {
      // App is in the background
      setState(() {
        isInForeground = false;
      });
      print("App is in Background");
    }
  }

  void triggerNotification() {}

  void overSpeedingNotification() {}

  // format the seconds
  String _formatTime() {
    int hours = _seconds ~/ 3600;
    int minutes = (_seconds % 3600) ~/ 60;
    int seconds = _seconds % 60;
    String duration = '00:00:00';
    if (isRunning) {
      duration =
          '${_days > 0 ? "$_days day " : ""}${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    // return '${_days > 0 ? "$_days day " : ""}${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    return duration;
  }

  @override
  void dispose() {
    _locationStreamController.close(); // Clean up the StreamController
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    journeyTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 6, 20),
      floatingActionButton: currentView == 'map'
          ? FloatingActionButton(
              backgroundColor: const Color.fromARGB(255, 45, 74, 124),
              onPressed: () {},
              child: const Icon(
                Icons.my_location,
                color: Colors.white,
              ),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              /**View Buttons */
              Card(
                margin: EdgeInsets.symmetric(vertical: 5, horizontal: 35),
                color: const Color.fromARGB(255, 7, 16, 37),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              fixedSize: Size.fromWidth(
                                  MediaQuery.of(context).size.width * 0.25),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                              backgroundColor: currentView == 'analog'
                                  ? const Color.fromARGB(255, 45, 74, 124)
                                  : Colors.transparent,
                              foregroundColor: Colors.white),
                          onPressed: () {
                            if (currentView != 'analog') {
                              setState(() {
                                currentView = 'analog';
                              });
                            }
                          },
                          child: Text('Analog')),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              fixedSize: Size.fromWidth(
                                  MediaQuery.of(context).size.width * 0.25),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                              backgroundColor: currentView == 'digital'
                                  ? const Color.fromARGB(255, 45, 74, 124)
                                  : Colors.transparent,
                              foregroundColor: Colors.white),
                          onPressed: () {
                            if (currentView != 'digital') {
                              setState(() {
                                currentView = 'digital';
                                LocationNotification.cancelAllNotification();
                                // LocationNotification
                                //     .showPersistentNotificationWithSound(
                                //   body: 'Take a break',
                                //   title: 'Reminder33333333',
                                //   payload: 'reminder_!',
                                //   notificationId: 45654534,
                                // );
                              });
                            }
                          },
                          child: Text('Digital')),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              fixedSize: Size.fromWidth(
                                  MediaQuery.of(context).size.width * 0.25),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                              backgroundColor: currentView == 'map'
                                  ? const Color.fromARGB(255, 45, 74, 124)
                                  : Colors.transparent,
                              foregroundColor: Colors.white),
                          onPressed: () {
                            if (currentView != 'map') {
                              setState(() {
                                currentView = 'map';
                              });
                            }
                          },
                          child: Text('Map')),
                    ],
                  ),
                ),
              ),

              /**Speedometer or counter */
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.65,
                child: Center(
                  child: StreamBuilder<LocationData>(
                    stream: _locationStreamController.stream,
                    builder: (BuildContext context,
                        AsyncSnapshot<LocationData> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text(
                          'Waiting for location...',
                          style: TextStyle(color: Colors.white),
                        );
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (snapshot.hasData) {
                        // debugPrint(snapshot.data.toString());
                        //double? speed = snapshot.data!.speed!;
                        // double randomNumber = random.nextDouble() * 100;
                        //print(snapshot.data);
                        //dynamic dataLocation = snapshot.data;
                        canStart = true;
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            hasTriggerOverSpeed
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    spacing: 5,
                                    children: [
                                      Icon(
                                        Icons.warning_amber,
                                        color: Colors.redAccent,
                                      ),
                                      Text(
                                        'Overspeed!!!',
                                        style:
                                            TextStyle(color: Colors.redAccent),
                                      ),
                                    ],
                                  )
                                : Userlocation(
                                    userLocaation: groundLocation,
                                  ),
                            Center(
                                child: Card(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    color: const Color.fromARGB(255, 7, 16, 37),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text.rich(TextSpan(
                                          text: //isRunning ?
                                              _formatTime(),
                                          // : '00:00:00',
                                          style: TextStyle(
                                              fontSize: 24,
                                              color: Colors.white),
                                          children: [
                                            TextSpan(
                                              text: 's',
                                              style: TextStyle(fontSize: 14),
                                            )
                                          ])),
                                    ))),
                            currentView == 'analog'
                                ? Analog(
                                    value: isRunning
                                        ? convertedVelocity(velocity!)
                                        : 0.0,
                                    unit: widget.unit,
                                    heading: isRunning ? heading : 0.0,
                                  )
                                : currentView == 'digital'
                                    ? Digital(
                                        value: isRunning
                                            ? convertedVelocity(velocity!)
                                            : 0.0,
                                        unit: widget.unit,
                                      )
                                    : MapScreen(
                                        dataLocation: snapshot.data,
                                      ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Card(
                                    color: const Color.fromARGB(255, 7, 16, 37),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Text.rich(
                                        textAlign: TextAlign.center,
                                        TextSpan(
                                          text: 'Distance',
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.white),
                                          children: [
                                            TextSpan(
                                                text:
                                                    "\n${totalDistance.toStringAsFixed(1)}", // New line before the label
                                                style: TextStyle(
                                                  fontSize: 24,
                                                ), // Style for label
                                                children: [
                                                  TextSpan(
                                                    text: widget.unit == 'm/s'
                                                        ? 'm'
                                                        : widget.unit == 'km/h'
                                                            ? 'km'
                                                            : 'miles', // New line before the label
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  )
                                                ]),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Card(
                                    color: const Color.fromARGB(255, 7, 16, 37),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Text.rich(
                                        textAlign: TextAlign.center,
                                        TextSpan(
                                          text: 'Avg Speed',
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.white),
                                          children: [
                                            TextSpan(
                                                text:
                                                    "\n${averageSpeed.toStringAsFixed(1)}", // New line before the label
                                                style: TextStyle(
                                                  fontSize: 24,
                                                ), // Style for label
                                                children: [
                                                  TextSpan(
                                                    text: widget
                                                        .unit, // New line before the label
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  )
                                                ]),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Card(
                                    color: const Color.fromARGB(255, 7, 16, 37),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Text.rich(
                                        textAlign: TextAlign.center,
                                        TextSpan(
                                          text: 'Top Speed',
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.white),
                                          children: [
                                            TextSpan(
                                                text:
                                                    "\n${convertedVelocity(topVelocity!)?.toStringAsFixed(1)}", // New line before the label
                                                style: TextStyle(
                                                  fontSize: 24,
                                                ), // Style for label
                                                children: [
                                                  TextSpan(
                                                    text: widget
                                                        .unit, // New line before the label
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  )
                                                ]),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Text('No data');
                      }
                    },
                  ),
                ),
              ),
              if (!isRunning && !isPause)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 10,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 45, 74, 124),
                            foregroundColor: Colors.white,
                            fixedSize: Size.fromWidth(
                                MediaQuery.of(context).size.width * .8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        onPressed: () {
                          if (!isRunning && canStart) {
                            showSpeed();
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            'Start',
                            style: TextStyle(
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              if (isRunning && !isPause)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 10,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 45, 74, 124),
                          foregroundColor: Colors.white,
                          fixedSize: Size.fromWidth(
                              MediaQuery.of(context).size.width * .4),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      onPressed: () {
                        if (isRunning) {
                          setState(() {
                            isPause = true;
                            isRunning = true; //
                            hasTriggerOverSpeed = true;
                          });

                          widget.overSpeedData?.forEach((element) =>
                              LocationNotification.cancelNotifcation(
                                  int.parse(element)));
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 5),
                        child: Text(
                          'Pause',
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          fixedSize: Size.fromWidth(
                              MediaQuery.of(context).size.width * .4),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      onPressed: () {
                        if (isRunning) {
                          stopSpeed();
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 10),
                        child: Text(
                          'Stop Trip',
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              if (isPause)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 10,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 45, 74, 124),
                            foregroundColor: Colors.white,
                            fixedSize: Size.fromWidth(
                                MediaQuery.of(context).size.width * .8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        onPressed: () {
                          if (isPause) {
                            setState(() {
                              isRunning = true;
                              isPause = false;
                              hasTriggerOverSpeed = false;
                            });
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              // Text(
              //   _formatTime(),
              // )
            ],
          ),
        ),
      ),
    );
  }
}
