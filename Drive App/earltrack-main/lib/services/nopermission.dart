import 'package:flutter/material.dart';

class NoPermissionApp extends StatefulWidget {
  final bool hasCheckedPermissions;
  const NoPermissionApp({super.key, required this.hasCheckedPermissions});

  @override
  State<NoPermissionApp> createState() => _NoPermissionAppState();
}

class _NoPermissionAppState extends State<NoPermissionApp> {
  @override
  Widget build(BuildContext context) {
    Widget outWidget;
    // Splash screen mode
    if (!widget.hasCheckedPermissions) {
      outWidget = const Image(
        image: AssetImage('assets/images/splash_image.png'),
        alignment: Alignment.center,
        fit: BoxFit.contain,
      );
    } else {
      outWidget = const Text(
        'Location permissions permanently denied!\n'
        'Please reinstall app and provide permissions!',
        style: TextStyle(
          color: Colors.red,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: outWidget),
      ),
    );
  }
}
