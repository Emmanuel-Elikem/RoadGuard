import 'package:earltrack/main.dart';
import 'package:earltrack/pages/auth/email_verification.dart';
import 'package:earltrack/pages/auth/signin.dart';
import 'package:earltrack/services/authentication.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
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
  final confirmPasswordTextController = TextEditingController();
  final nameTextController = TextEditingController();
  final phoneTextController = TextEditingController();

  void dispose() {
    emailTextController.clear();
    passwordTextController.clear();
    confirmPasswordTextController.clear();
    nameTextController.clear();
    phoneTextController.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 6, 20),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 10,
          children: [
            Form(
                key: _FormKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 10,
                  children: [
                    TextFormField(
                      controller: nameTextController,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Full name is required';
                        }

                        if (value.trim().length < 2) {
                          return 'Full name should be three characters or more';
                        }

                        return null;
                      },
                      keyboardType: TextInputType.name,
                      autocorrect: false,
                      enableSuggestions: true,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Full name',
                        labelStyle: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                        hintText: 'Your name',
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
                    TextFormField(
                      controller: phoneTextController,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Phone number is required';
                        }

                        if (value.length < 10 || value.length > 10) {
                          return "Phone number should be 10 digit";
                        }

                        if (!RegExp(r'^0\d{9}$').hasMatch(value)) {
                          return "Enter a ten-digit number starting with 0";
                        }

                        return null;
                      },
                      keyboardType: TextInputType.phone,
                      autocorrect: false,
                      enableSuggestions: true,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Phone number',
                        labelStyle: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                        hintText: '050********',
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
                            borderSide: BorderSide(
                                color: const Color.fromARGB(255, 45, 74, 124))),
                      ),
                    ),
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
                    TextFormField(
                      controller: confirmPasswordTextController,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Confirm password is required';
                        }

                        if (value.length < 6) {
                          return "Confirm Password should be  six characters or more";
                        }

                        if (value != passwordTextController.value.text) {
                          return 'Passwords does not match';
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
                        labelText: 'Confirm password',
                        labelStyle: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                        hintText: 'confirm password',
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
                                // Navigator.of(context).pushReplacement(
                                //     MaterialPageRoute(
                                //         builder: (context) => MainApp()));
                                // print('Valid');

                                dynamic res = await Authentication()
                                    .createAccount(
                                        emailAddress:
                                            emailTextController.value.text,
                                        password:
                                            passwordTextController.value.text);

                                if (res == 'success') {
                                  navigatorKey.currentState!.pushReplacement(
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              EmailVerification()));
                                }

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
                                'Sign up',
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
                          'Already have account? ',
                          style: TextStyle(color: Colors.white70),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Signin()));
                          },
                          child: Text(
                            'Sign In',
                            style: TextStyle(color: Colors.blueAccent),
                          ),
                        )
                      ],
                    )
                  ],
                ))
          ],
        ),
      ),
    );
  }
}
