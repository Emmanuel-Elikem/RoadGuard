import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Editinfo extends StatefulWidget {
  const Editinfo({super.key});

  @override
  State<Editinfo> createState() => _EditinfoState();
}

class _EditinfoState extends State<Editinfo> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
        backgroundColor: const Color.fromARGB(255, 0, 6, 20),
        appBar: AppBar(
          leading: IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon(
                Icons.close,
                color: Colors.white,
              )),
          backgroundColor: const Color.fromARGB(255, 0, 6, 20),
          title: Text(
            'Edit Profile',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
        ),
        
    );
  }
}