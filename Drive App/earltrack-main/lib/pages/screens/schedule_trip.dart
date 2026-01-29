import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ScheduleTrip extends StatefulWidget {
  const ScheduleTrip({super.key});

  @override
  State<ScheduleTrip> createState() => _ScheduleTripState();
}

class _ScheduleTripState extends State<ScheduleTrip> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: Icon(CupertinoIcons.xmark)),
        title: Text('Schdule trip'),
        centerTitle: true,
      ),
    );
  }
}
