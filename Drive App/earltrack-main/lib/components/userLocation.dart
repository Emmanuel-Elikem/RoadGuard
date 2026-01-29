import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart';

class Userlocation extends StatefulWidget {
  final String userLocaation;
  const Userlocation({super.key, required this.userLocaation});

  @override
  State<Userlocation> createState() => _UserlocationState();
}

class _UserlocationState extends State<Userlocation> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 2,
        children: [
          if (widget.userLocaation != '')
            Icon(
              CupertinoIcons.location_circle,
              color: Colors.white,
              size: 20,
            ),
          if (widget.userLocaation != '') Text(widget.userLocaation, style: TextStyle(color: Colors.white),),
        ],
      ),
    );
  }
}
