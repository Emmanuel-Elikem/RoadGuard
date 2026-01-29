import 'package:earltrack/main.dart';
import 'package:earltrack/pages/auth/email_verification.dart';
import 'package:earltrack/pages/screens/mainapp.dart';
import 'package:earltrack/pages/auth/welcome.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final User? user = context.watch<User?>();

    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (user == null) {
      return Welcome();
    } else {
      if (!user.emailVerified) {
        return EmailVerification();
      }
      return MainApp();
    }
  }
}
