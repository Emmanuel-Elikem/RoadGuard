import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class Analog extends StatefulWidget {
  final double? value;
  final double? heading;
  final String unit;
  const Analog({super.key, this.value, required this.unit, this.heading});

  @override
  State<Analog> createState() => _AnalogState();
}

class _AnalogState extends State<Analog> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * .45,
      decoration: ShapeDecoration(shadows: [
        BoxShadow(
          color: Color.fromARGB(255, 1, 11, 36)
              .withOpacity(0.5), // Adjust opacity if needed
          blurRadius: 10, // Controls the blur effect
          spreadRadius: 2, // Controls how far the shadow spreads
          offset: Offset(4, 4), // Adjusts the shadow position
        )
      ], shape: CircleBorder(side: BorderSide())),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Center(
          child: SfRadialGauge(
            axes: <RadialAxis>[
              RadialAxis(
                  startAngle: 270,
                  endAngle: 270,
                  minimum: 0,
                  maximum: 360,
                  interval: 90,
                  radiusFactor: 0.4,
                  showAxisLine: false,
                  showLastLabel: false, // Hide the last label
                  minorTicksPerInterval: 4,
                  majorTickStyle: MajorTickStyle(
                    length: 8,
                    thickness: 3,
                    color: Colors.white,
                  ),
                  minorTickStyle: MinorTickStyle(
                    length: 3,
                    thickness: 1.5,
                    color: Colors.white,
                  ),
                  axisLabelStyle: GaugeTextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  pointers: <GaugePointer>[
                    // Pointer showing the current heading
                    NeedlePointer(
                      value: widget.heading ??
                          0.0, // Update the pointer value with the heading
                      needleColor: Colors.grey,
                      knobStyle: KnobStyle(
                        color: Colors.red,
                      ),
                      needleLength: 0.8,
                    ),
                  ],
                  onLabelCreated: (AxisLabelCreatedArgs args) {
                    if (args.text == '0') {
                      args.text = 'N';
                      args.labelStyle = GaugeTextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white);
                    } else if (args.text == '90') {
                      args.text = 'E';
                      args.labelStyle = GaugeTextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white);
                    } else if (args.text == '180') {
                      args.text = 'S';
                      args.labelStyle = GaugeTextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white);
                    } else if (args.text == '270') {
                      args.text = 'W';
                      args.labelStyle = GaugeTextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white);
                    }
                  }),
              RadialAxis(
                minimum: 0,
                maximum: 200,
                labelOffset: 15,
                showLastLabel: true,
                axisLineStyle: AxisLineStyle(
                  thicknessUnit: GaugeSizeUnit.factor,
                  thickness: 0.03,
                ),
                majorTickStyle: MajorTickStyle(
                  length: 6,
                  thickness: 4,
                  color: Colors.white,
                ),
                minorTickStyle: MinorTickStyle(
                  length: 3,
                  thickness: 3,
                  color: Colors.white,
                ),
                axisLabelStyle: GaugeTextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                ranges: <GaugeRange>[
                  GaugeRange(
                    startValue: 0,
                    endValue: 200,
                    sizeUnit: GaugeSizeUnit.factor,
                    startWidth: 0.03,
                    endWidth: 0.03,
                    gradient: SweepGradient(
                      colors: const <Color>[
                        Colors.green,
                        Colors.yellow,
                        Colors.red,
                      ],
                      stops: const <double>[0.0, 0.5, 1],
                    ),
                  ),
                ],
                pointers: <GaugePointer>[
                  NeedlePointer(
                    value: widget.value ?? 0,
                    needleLength: 0.9,
                    enableAnimation: true,
                    animationType: AnimationType.ease,
                    needleStartWidth: 2,
                    needleEndWidth: 14,
                    needleColor: Colors.grey,
                    knobStyle: KnobStyle(knobRadius: 0.09),
                  ),
                ],
                annotations: <GaugeAnnotation>[
                  GaugeAnnotation(
                    horizontalAlignment: GaugeAlignment.center,
                    verticalAlignment: GaugeAlignment.near,
                    widget: Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            widget.value!.toStringAsFixed(2),
                            style: GoogleFonts.quantico(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          Text(
                            widget.unit.toUpperCase(),
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    angle: 90,
                    positionFactor: 0.75,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
