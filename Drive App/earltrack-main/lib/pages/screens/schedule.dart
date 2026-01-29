import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Schedule extends StatefulWidget {
  final Function loadReminders;
  final Function updateReminder;
  final List<dynamic>? reminders;
  final Function saveReminder;
  final Function deleteReminder;
  final Function scheduleTripPopUpForm;
  const Schedule(
      {super.key,
      required this.loadReminders,
      required this.updateReminder,
      required this.reminders,
      required this.saveReminder,
      required this.deleteReminder,
      required this.scheduleTripPopUpForm});

  @override
  State<Schedule> createState() => _ScheduleState();
}

final List<Map<String, String>> daysOfWeek = [
  {"short": "S", "long": "Sunday", 'selected': 'false'},
  {"short": "M", "long": "Monday", 'selected': 'false'},
  {"short": "T", "long": "Tuesday", 'selected': 'false'},
  {"short": "W", "long": "Wednesday", 'selected': 'false'},
  {"short": "T", "long": "Thursday", 'selected': 'false'},
  {"short": "F", "long": "Friday", 'selected': 'false'},
  {"short": "S", "long": "Saturday", 'selected': 'false'},
];

class _ScheduleState extends State<Schedule> {
  TimeOfDay? defaultTime;
  TimeOfDay? selectedTime;
  String selectedTimeMessage = '';
  final _FormKey = GlobalKey<FormState>();
  TextEditingController labelController = TextEditingController();
  bool isScheduleFormLoading = false;

  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    List? reminders = widget.reminders;
    
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 0, 6, 20),
        appBar: AppBar(
          title: Text(
            "Scheduled Reminders",
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: const Color.fromARGB(255, 0, 6, 20),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            widget.scheduleTripPopUpForm();
          },
          backgroundColor: const Color.fromARGB(255, 45, 74, 124),
          foregroundColor: Colors.white,
          child: Icon(CupertinoIcons.add),
        ),
        body: reminders!.isEmpty
            ? Center(
                child: Text(
                  "No trip schedule reminders set.",
                  style: TextStyle(color: Colors.white),
                ),
              )
            : ListView.builder(
                itemCount: reminders.length,
                itemBuilder: (context, index) {
                  final reminder = reminders[index];
                  var repeat = reminder['repeatDays'];
                  var repeatTextArr = [];
                  var repeatText = '';
                  var notificationText = '';

                  DateTime now = DateTime.now();
                  int reminderHour = reminder['hour'];
                  int reminderMinute = reminder['minute'];
                  DateTime reminderTime = DateTime(now.year, now.month, now.day,
                      reminderHour, reminderMinute);

                  if (reminderTime.isBefore(now)) {
                    reminderTime = reminderTime.add(Duration(days: 1));
                  }

                  int difference = reminderTime.difference(now).inMinutes;

                  if (repeat != []) {
                    if (repeat.length == 7) {
                      repeatText = 'Everyday';
                    } else if (repeat.isNotEmpty) {
                      for (var element in repeat) {
                        repeatTextArr.add(element.toString().substring(0, 3));
                      }
                      repeatText = repeatTextArr.join(', ');
                    } else {
                      // DateTime nowWithoutSeconds = DateTime(
                      //     now.year, now.month, now.day, now.hour, now.minute);

                      // if (reminderTime.isAfter(nowWithoutSeconds)) {
                      //   repeatText = 'Today';
                      // } else {
                      //   repeatText = 'Tomorrow';
                      // }
                      repeatText =
                          reminderTime.day == now.day ? 'Today' : 'Tomorrow';
                    }
                  }

                  // Determine notification text
                  if (difference < 60) {
                    notificationText =
                        "Notification is set for $difference minutes from now.";
                  } else if (difference < 1440) {
                    int hours = difference ~/ 60;
                    int minutes = difference % 60;
                    if (minutes == 0) {
                      notificationText =
                          "Notification is set for $hours hours from now.";
                    } else {
                      notificationText =
                          "Notification is set for $hours hours and $minutes minutes from now.";
                    }
                  } else {
                    int days = difference ~/ 1440;
                    notificationText =
                        "Notification is set for $days day(s) from now.";
                  }

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListTile(
                      onTap: () {
                        setState(() {
                          selectedTimeMessage = '';
                          selectedTime = TimeOfDay(
                              hour: reminder['hour'],
                              minute: reminder['minute']);
                        });

                        labelController = TextEditingController(
                            text: reminder['label'] ?? '');
                        for (var days in daysOfWeek) {
                          days['selected'] = 'false';
                        }

                        for (var element in reminder['repeatDays']) {
                          for (var i = 0; i < daysOfWeek.length; i++) {
                            if (daysOfWeek[i]['long'] == element) {
                              daysOfWeek[i]['selected'] = 'true';
                            }
                          }
                        }
                        scheduleTripPopUpUpdateForm(reminder);
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                        side: BorderSide(color: Colors.grey, width: 0.5),
                      ),
                      leading: Text(
                        "${reminder['hour'].toString().padLeft(2, '0')}:${reminder['minute'].toString().padLeft(2, '0')}",
                        style: TextStyle(fontSize: 25, color: Colors.white),
                      ),
                      title: Text(
                        repeatText,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: Colors.white),
                        overflow:
                            TextOverflow.ellipsis, // Truncate text with "..."
                        maxLines: 1, // Ensure it's a single line
                      ),
                      subtitle: Text(
                        notificationText,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        overflow:
                            TextOverflow.ellipsis, // Truncate text with "..."
                        maxLines: 1, // Ensure it's a single line
                      ),
                      trailing: CupertinoSwitch(
                        // This bool value toggles the switch.
                        value: reminder['status'] == 'on',
                        activeTrackColor: CupertinoColors.activeBlue,
                        onChanged: (bool? value) {
                          widget.updateReminder(
                              reminder['id'], 'toggleStatus', '');
                        },
                      ),
                    ),
                  );
                },
              ));
  }

  void notificationsetMessageUpdate(String message, String type) {
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

  Future<void> _selectTimeUpdate(BuildContext context, dynamic remaider) async {
    defaultTime = TimeOfDay(hour: remaider['hour'], minute: remaider['minute']);
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
      final now = TimeOfDay.now();
      final nowMinutes = now.hour * 60 + now.minute;
      final pickedMinutes = pickedTime.hour * 60 + pickedTime.minute;
      var difference = pickedMinutes - nowMinutes;
      // If the picked time is earlier than the current time, set it for the next day
      if (difference < 0) {
        difference +=
            1440; // Add 24 hours (1440 minutes) to move to the next day
      }

      if (difference == 0) {
        setState(() {
          selectedTimeMessage = "Notification is set for 1 day from now.";
        });
      } else if (difference > 0 && difference < 60) {
        setState(() {
          selectedTimeMessage =
              "Notification is set for $difference minutes from now.";
        });
      } else if (difference >= 60 && difference < 1440) {
        int hours = difference ~/ 60;
        setState(() {
          selectedTimeMessage =
              "Notification is set for $hours hours from now.";
        });
      } else {
        int days = difference ~/ 1440;
        setState(() {
          selectedTimeMessage =
              "Notification is set for $days day(s) from now.";
        });
      }

      print(selectedTimeMessage);

      setState(() {
        selectedTime = pickedTime;
      });
    } else {
      print(22222);
    }
  }

  void scheduleTripPopUpUpdateForm(reminder) {
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
                          'Edit schedule',
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
                              onTap: () => _selectTimeUpdate(context, reminder),
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
                                    : '${reminder['hour'].toString().padLeft(2, '0')}:${reminder['minute'].toString().padLeft(2, '0')}',
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

                                  // bool isSelected =
                                  //     daysOfWeek[index]['selected'] == 'true' ||
                                  //         (reminder['repeatedDays'] != null &&
                                  //             reminder['repeatedDays']
                                  //                 .contains(day['long']));
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

                                      widget.deleteReminder(reminder['id']);
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
                                        'Delete',
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
                                                if (selectedTimeMessage != '') {
                                                  notificationsetMessageUpdate(
                                                      selectedTimeMessage,
                                                      'message');
                                                }

                                                
                                                Map<String, dynamic>
                                                    updatedRemainder = {
                                                  'id': reminder['id'],
                                                  'hour': selectedTime!.hour,
                                                  'minute':
                                                      selectedTime!.minute,
                                                  'repeatDays': daysOfWeek
                                                      .where((day) =>
                                                          day['selected'] ==
                                                          'true')
                                                      .map((day) => day['long'])
                                                      .toList(),
                                                  'label': labelController.text
                                                      .trim(),
                                                  'status': 'on'
                                                };

                                                print(updatedRemainder);

                                                widget.updateReminder(
                                                    reminder['id'],
                                                    'updateData',
                                                    updatedRemainder);
                                                for (var days in daysOfWeek) {
                                                  days['selected'] = 'false';
                                                }

                                                selectedTime = null;
                                                labelController.text = '';

                                                Navigator.pop(context);
                                              } else {
                                                notificationsetMessageUpdate(
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
}
