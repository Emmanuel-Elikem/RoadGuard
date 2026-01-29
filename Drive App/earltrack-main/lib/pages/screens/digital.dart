import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

class Digital extends StatefulWidget {
  final double? value;
  final String unit;
  const Digital({super.key, this.value, required this.unit});

  @override
  State<Digital> createState() => _DigitalState();
}

class _DigitalState extends State<Digital> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * .45,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedFlipCounter(
            duration: Duration(milliseconds: 500),
            value: widget.value!.toInt(), // pass in a value like 2014
            textStyle: GoogleFonts.quantico(
                fontSize: 150,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          SizedBox(width: 5),
          Text(
            widget.unit.toUpperCase(),
            style: TextStyle(
                fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
