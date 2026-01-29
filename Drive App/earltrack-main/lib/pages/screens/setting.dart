import 'package:earltrack/main.dart';
import 'package:earltrack/pages/auth/welcome.dart';
import 'package:earltrack/pages/screens/accountinfo.dart';
import 'package:earltrack/pages/screens/editinfo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

final List<String> units = const <String>['m/s', 'km/h', 'miles/h'];

class Setting extends StatefulWidget {
  final bool isBackgroundMode;
  final bool isSpeech;
  final bool isSpeedAlarm;
  final bool isSchedule;
  final String unit;
  final Function toggleBackgroundMode;
  final Function toggleSpeech;
  final Function toggleSpeedAlarm;
  final Function toggleScheduleNoti;
  final Function unitSelection;
  const Setting(
      {super.key,
      required this.isBackgroundMode,
      required this.toggleBackgroundMode,
      required this.unitSelection,
      required this.isSpeech,
      required this.toggleSpeech,
      required this.isSpeedAlarm,
      required this.toggleSpeedAlarm,
      required this.unit,
      required this.isSchedule,
      required this.toggleScheduleNoti});

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  String currentSpeedOption = '';
  bool switchValue = true;
  bool light = true;

  @override
  void initState() {
    super.initState();
    currentSpeedOption = widget.unit;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 6, 20),
      appBar: AppBar(
        title: Text(
          "Settings",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 6, 20),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: IconButton(
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.signOut();
                    navigatorKey.currentState!.pushReplacement(
                        MaterialPageRoute(builder: (context) => Welcome()));
                  } catch (e) {
                    print(e);
                  }
                },
                icon: Icon(
                  Icons.logout,
                  color: Colors.white,
                )),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              SizedBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account settings',
                      style: TextStyle(fontSize: 18, color: Colors.blueAccent),
                    ),
                    _buildRowWidget('Account information',
                        Icon(CupertinoIcons.chevron_right), () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => Accountinfo()));
                    }),
                    _buildRowWidget('Edit account',
                        Icon(CupertinoIcons.chevron_right), () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (context) => Editinfo()));
                        }),
                    _buildRowWidget('Report an issue',
                        Icon(CupertinoIcons.chevron_right), () {}),
                    _buildRowWidget('Contact support',
                        Icon(CupertinoIcons.chevron_right), () {}),
                    _buildRowWidget('Privacy policy',
                        Icon(CupertinoIcons.chevron_right), () {}),
                  ],
                ),
              ),
              SizedBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Speedometer settings',
                      style: TextStyle(fontSize: 18, color: Colors.blueAccent),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Speed unit',
                      style: TextStyle(color: Colors.white, fontSize: 17),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Flex(
                            direction: Axis.horizontal,
                            children: [
                              Radio(
                                value: units[0],
                                groupValue: currentSpeedOption,
                                onChanged: (value) {
                                  widget.unitSelection(value.toString());
                                  setState(() {
                                    currentSpeedOption = value.toString();
                                  });
                                },
                              ),
                              Text(
                                'm/s',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 17),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: Flex(
                            direction: Axis.horizontal,
                            children: [
                              Radio(
                                value: units[1],
                                groupValue: currentSpeedOption,
                                onChanged: (value) {
                                  widget.unitSelection(value.toString());
                                  setState(() {
                                    currentSpeedOption = value.toString();
                                  });
                                },
                              ),
                              Text(
                                'km/h',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 17),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Speed Alarm',
                          style: TextStyle(color: Colors.white, fontSize: 17),
                        ),
                        CupertinoSwitch(
                          // This bool value toggles the switch.
                          value: widget.isSpeedAlarm,
                          activeTrackColor: CupertinoColors.activeBlue,
                          onChanged: (bool? value) {
                            // This is called when the user toggles the switch.
                            widget.toggleSpeedAlarm();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'General settings',
                      style: TextStyle(fontSize: 18, color: Colors.blueAccent),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Background mode',
                          style: TextStyle(color: Colors.white, fontSize: 17),
                        ),
                        CupertinoSwitch(
                          // This bool value toggles the switch.
                          value: widget.isBackgroundMode,
                          activeTrackColor: CupertinoColors.activeBlue,
                          onChanged: (bool? value) {
                            // This is called when the user toggles the switch.
                            widget.toggleBackgroundMode();
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Show schedule trip popup',
                          style: TextStyle(color: Colors.white, fontSize: 17),
                        ),
                        CupertinoSwitch(
                          // This bool value toggles the switch.
                          value: widget.isSchedule,
                          activeTrackColor: CupertinoColors.activeBlue,
                          onChanged: (bool? value) {
                            // This is called when the user toggles the switch.
                            widget.toggleScheduleNoti();
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Voice location update',
                          style: TextStyle(color: Colors.white, fontSize: 17),
                        ),
                        CupertinoSwitch(
                          // This bool value toggles the switch.
                          value: widget.isSpeech,
                          activeTrackColor: CupertinoColors.activeBlue,
                          onChanged: (bool? value) {
                            // This is called when the user toggles the switch.
                            widget.toggleSpeech();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRowWidget(
    String info,
    Icon icon,
    VoidCallback callBack,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          info,
          style: TextStyle(color: Colors.white, fontSize: 17),
        ),
        IconButton(onPressed: callBack, icon: icon)
      ],
    );
  }
}
