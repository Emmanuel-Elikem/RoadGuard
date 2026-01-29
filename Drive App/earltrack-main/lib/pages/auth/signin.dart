import 'package:earltrack/main.dart';
import 'package:earltrack/pages/auth/email_verification.dart';
import 'package:earltrack/pages/auth/signup.dart';
import 'package:earltrack/pages/screens/mainapp.dart';
import 'package:earltrack/services/authentication.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Signin extends StatefulWidget {
  const Signin({super.key});

  @override
  State<Signin> createState() => _SigninState();
}

class _SigninState extends State<Signin> {
  final _FormKey = GlobalKey<FormState>();
  var isObscure = true;
  bool isLoading = false;
  void toggleEye() {
    setState(() {
      isObscure = !isObscure;
    });
  }

  final emailTextController = TextEditingController();
  final passwordTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  void dispose() {
    emailTextController.clear();
    passwordTextController.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 6, 20),
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 10,
          children: [
            ElevatedButton(
              onPressed: () async {
                dynamic res = await Authentication().signWithGoogle();

                if (res) {
                  navigatorKey.currentState!.pushReplacement(MaterialPageRoute(
                      builder: (context) => EmailVerification()));
                } else {
                  // Handle the error or show a message indicating the failure
                  print("Google sign-in failed");
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 17, horizontal: 17),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: Image(
                  image: AssetImage('assets/images/google.png'),
                  alignment: Alignment.center,
                  fit: BoxFit.contain,
                  width: 40,
                  height: 40),
            ),
            Row(
              children: [
                Expanded(child: Divider(thickness: 1)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    "or",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                Expanded(child: Divider(thickness: 1)),
              ],
            ),
            Form(
                key: _FormKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 10,
                  children: [
                    TextFormField(
                      controller: emailTextController,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Email is required';
                        }

                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return "Enter valid email address";
                        }
                        return null;
                      },
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      enableSuggestions: true,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                          hintText: 'example@gmail.com',
                          hintStyle:
                              TextStyle(fontSize: 16, color: Colors.white),
                          fillColor: const Color.fromARGB(255, 7, 16, 37),
                          filled: true,
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.redAccent),
                          ),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color:
                                      const Color.fromARGB(255, 45, 74, 124))),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color:
                                      const Color.fromARGB(255, 45, 74, 124)))),
                    ),
                    TextFormField(
                      controller: passwordTextController,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Password is required';
                        }

                        if (value.length < 6) {
                          return "Password should be six characters or more";
                        }
                        return null;
                      },
                      keyboardType: TextInputType.visiblePassword,
                      autocorrect: false,
                      enableSuggestions: false,
                      obscureText: isObscure,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        suffixIcon: IconButton(
                          onPressed: toggleEye,
                          icon: isObscure
                              ? Icon(CupertinoIcons.eye)
                              : Icon(CupertinoIcons.eye_slash), // Example icon
                        ),
                        labelText: 'Password',
                        labelStyle: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                        hintText: 'enter password',
                        hintStyle: TextStyle(fontSize: 16, color: Colors.white),
                        fillColor: const Color.fromARGB(255, 7, 16, 37),
                        filled: true,
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.redAccent),
                        ),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: const Color.fromARGB(255, 45, 74, 124))),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: const Color.fromARGB(255, 45, 74, 124))),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: isLoading
                          ? () {}
                          : () async {
                              if (_FormKey.currentState!.validate()) {
                                setState(() {
                                  isLoading = true;
                                });

                                String res = await Authentication().signInUser(
                                    emailAddress:
                                        emailTextController.value.text,
                                    password:
                                        passwordTextController.value.text);

                                if (res == 'success') {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                        builder: (context) => MainApp()),
                                  );
                                }
                                print(res);
                                setState(() {
                                  isLoading = false;
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 45, 74, 124),
                          foregroundColor: Colors.white,
                          fixedSize:
                              Size.fromWidth(MediaQuery.of(context).size.width),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 13),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isLoading)
                              CupertinoActivityIndicator(
                                  radius: 12.0, color: CupertinoColors.white),
                            if (!isLoading)
                              Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Not having account? ',
                          style: TextStyle(color: Colors.white70),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Signup()));
                          },
                          child: Text(
                            'Sign up',
                            style: TextStyle(color: Colors.blueAccent),
                          ),
                        )
                      ],
                    )
                  ],
                ))
          ],
        ),
      )),
    );
  }
}
