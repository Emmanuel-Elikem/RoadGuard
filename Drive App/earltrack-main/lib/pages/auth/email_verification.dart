import 'dart:async';

import 'package:earltrack/main.dart';
import 'package:earltrack/pages/screens/mainapp.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:earltrack/pages/auth/welcome.dart';

class EmailVerification extends StatefulWidget {
  const EmailVerification({super.key});

  @override
  State<EmailVerification> createState() => _EmailVerificationState();
}

class _EmailVerificationState extends State<EmailVerification> {
  bool isEmailVerified = false;
  Timer? timer;
  Timer? checkTimer;
  int _resendTimeout = 60; // 1 minute
  // ignore: unused_field
  bool _codeSent = false;

  @override
  void initState() {
    isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;
    checkingEmailVerificationState();
  }

  @override
  void dispose() {
    timer?.cancel();
    checkTimer?.cancel();

    super.dispose();
  }

  void checkingEmailVerificationState() {
    if (!isEmailVerified) {
      //print("email is not verified");
      sendVerification();

      checkTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        checkEmailVerified();
      });
    }
  }

  Future checkEmailVerified() async {
    await FirebaseAuth.instance.currentUser!.reload();
    setState(() {
      isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;
    });

    if (isEmailVerified) {
      //widget.updateEmailVerification(isEmailVerified);
      checkTimer?.cancel();
      timer?.cancel();
      // ignore: use_build_context_synchronously
      navigatorKey.currentState!
          .pushReplacement(MaterialPageRoute(builder: (context) => MainApp()));
    }
  }

  Future sendVerification() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.sendEmailVerification();

      _codeSent = true;
      _resendTimeout = 60; // Reset the countdown timer
      checkTimer?.cancel();
      checkTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        checkEmailVerified();
      });

      timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_resendTimeout > 0) {
          setState(() {
            _resendTimeout--;
          });
        } else {
          setState(() {
            _codeSent = false;
          });
          timer.cancel();
        }
      });
    } catch (e) {
      //print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Center(
            child: Text(
              'Email Verification',
              style: TextStyle(color: Colors.blue, fontSize: 18),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_resendTimeout == 0) {
                sendVerification();
                _resendTimeout = 60; // Reset the countdown timer
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
                side: const BorderSide(width: 0.5, color: Colors.grey)),
            child: Text(
              _resendTimeout > 0
                  ? 'Resend Code ($_resendTimeout)'
                  : 'Resend Code',
              style: const TextStyle(color: Colors.black),
            ),
          ),
          ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.currentUser!.reload();
                User? user = FirebaseAuth.instance.currentUser;
                user?.delete();
                navigatorKey.currentState!.pushReplacement(
                    MaterialPageRoute(builder: (context) => Welcome() ));
              },
              child: Text('Home'))
        ],
      ),
    );
  }
}
