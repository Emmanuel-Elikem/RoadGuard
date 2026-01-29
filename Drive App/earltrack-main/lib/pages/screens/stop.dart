import 'dart:async';

import 'package:earltrack/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class Stop extends StatefulWidget {
  final List<Map<String, dynamic>>? locations;
  final double? topSpeed;
  final double? distanceCoverd;
  final double? averageSpeed;
  final String? duration;
  final String? unit;
  final List<LocationData>? overSpeedPointData;
  final List<LocationData>? theJourney;

  const Stop(
      {super.key,
      this.locations,
      this.topSpeed,
      this.distanceCoverd,
      this.averageSpeed,
      this.duration,
      this.unit,
      this.overSpeedPointData,
      this.theJourney});

  @override
  State<Stop> createState() => _StopState();
}

class _StopState extends State<Stop> {
  String? startLocation;
  String? endLocation;

  late double _rating;

  double _initialRating = 2.0;
  bool _isVertical = false;
  IconData? _selectedIcon;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final MapController mapController = MapController();

  Timer? _timer;

  // Async method to get the location data
  Future<String?> getActualData(latitude, longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      var output = 'No result found';
      if (placemarks.isNotEmpty) {
        Placemark currentLocation = placemarks[0];
        output = currentLocation.subLocality.toString() +
            " " +
            currentLocation.locality.toString() +
            ", " +
            currentLocation.country.toString(); // Get address
      }
      print(output);
      return output;
    } catch (e) {
      print("Error: $e");
      return '';
    }
  }

  @override
  void initState() {
    super.initState();
    print(widget.overSpeedPointData);
    // _timer = Timer(Duration(seconds: 5), () {
    //   //if (widget.averageSpeed! > 1) {
    //   _showRating();

    //   // }
    // });

    print(6666);
    print(widget.theJourney);
    print(777);
    _getLocationData();
  }

  Future<void> _showRating() async {
    if (mounted) {
      return showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Rate the drive'),
            content: _ratingBar(),
            actions: <Widget>[
              TextButton(
                child: const Text('Done'),
                onPressed: () {
                  Navigator.of(context).pop();
                  showCommentSheet();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> showCommentSheet() async {
    if (mounted) {
      return showDialog(
          context: context,
          builder: (context) {
            return SimpleDialog(
                contentPadding: EdgeInsets.all(20),
                title: Text('data'),
                children: [
                  Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            decoration: const InputDecoration(
                              hintText: 'Enter your email',
                            ),
                            validator: (String? value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter some text';
                              }
                              return null;
                            },
                          ),
                        ],
                      )),
                ]);
          });
    }
  }

  // Function to await the async method and set the location
  void _getLocationData() async {
    // Get latitude and longitude from widget
    double startLatitude =
        double.parse(widget.locations![0]['startJourney']![0].toString());
    double startLongitude =
        double.parse(widget.locations![0]['startJourney']![1].toString());

    double endLatitude =
        double.parse(widget.locations![1]['endJourney']![0].toString());
    double endLongitude =
        double.parse(widget.locations![1]['endJourney']![1].toString());

    // Fetch actual data
    String? fetchStartLocation =
        await getActualData(startLatitude, startLongitude);
    String? fetchEndLocation = await getActualData(endLatitude, endLongitude);

    // Update state with the result
    setState(() {
      startLocation = fetchStartLocation;
      endLocation = fetchEndLocation;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
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
            'Stop',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: const Text(
                'Journey detials',
                style: TextStyle(fontSize: 18, color: Colors.blueAccent),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                 

                  _buildInfoRow('Start location', startLocation ?? 'N/A'),
                  _buildInfoRow('End location', endLocation ?? 'N/A'),
                  _buildInfoRow(
                      'Top speed', "${widget.topSpeed?.toStringAsFixed(2)} ${widget.unit}"),
                  _buildInfoRow('Average speed',
                      "${widget.averageSpeed!.toStringAsFixed(2)} km/h"),
                  _buildInfoRow('Distance covered',
                      "${widget.distanceCoverd!.toStringAsFixed(2)} km"),
                  _buildInfoRow('Duration', widget.duration.toString()),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('OverSpeeding data',
                          style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.white)),
                      IconButton(
                          onPressed: overSpeedingMap,
                          icon: Icon(
                            CupertinoIcons.chevron_down,
                            color: Colors.white,
                          ))
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Traveling path',
                          style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.white)),
                      IconButton(
                          onPressed: travelPathMap,
                          icon: Icon(
                            CupertinoIcons.chevron_down,
                            color: Colors.white,
                          ))
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void overSpeedingMap() {
    showModalBottomSheet(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        backgroundColor: const Color.fromARGB(255, 0, 6, 20),
        builder: (BuildContext context) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * .75,
              child: Column(
                spacing: 15,
                children: [
                  Center(
                    child: const Text(
                      'Overspeeding point',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: mapController,
                          options: MapOptions(
                            initialCenter: widget.overSpeedPointData != null &&
                                    widget.overSpeedPointData!.isNotEmpty
                                ? LatLng(
                                    widget.overSpeedPointData!.first.latitude!,
                                    widget.overSpeedPointData!.first.longitude!)
                                : LatLng(51.509364,
                                    -0.128928), // Default center if overSpeedPointData is empty or null
                            initialZoom: 15,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.app',
                            ),
                            MarkerLayer(
                              markers: widget.overSpeedPointData
                                      ?.asMap()
                                      .map((index, data) {
                                        //                                             // Starting from the second element, increase the latitude and longitude
                                        //                                             double latOffset = 0.0;
                                        //                                             double longOffset = 0.0;

                                        //                                             // Apply offset only to subsequent points (starting from the second one)
                                        //                                             if (index > 0) {
                                        //                                               latOffset = index * 0.01;  // Increase latitude by a smaller offset
                                        // longOffset = index * 0.01; // Increase longitude by a smaller offset
                                        //                                             }

                                        //                                             print(2222);
                                        //                                             print(data.latitude! +
                                        //                                                 latOffset);

                                        //                                             print(data.longitude! +
                                        //                                                 longOffset);

                                        // Create the marker with the adjusted lat/long
                                        return MapEntry(
                                          index,
                                          Marker(
                                            width: 80.0,
                                            height: 80.0,
                                            point: LatLng(
                                              data.latitude!, // Adjusted latitude
                                              data.longitude!, // Adjusted longitude
                                            ),
                                            child: Container(
                                              alignment: Alignment.center,
                                              child: Icon(
                                                Icons.location_pin,
                                                color: Colors.red,
                                                size:
                                                    40.0, // Adjust the size of the marker icon
                                              ),
                                            ),
                                          ),
                                        );
                                      })
                                      .values
                                      .toList() ??
                                  [],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  void travelPathMap() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: const Color.fromARGB(255, 0, 6, 20),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * .75,
            child: Column(
              spacing: 15,
              children: [
                Center(
                  child: const Text(
                    'Traved path',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: mapController,
                        options: MapOptions(
                          initialCenter: widget.theJourney != null &&
                                  widget.theJourney!.isNotEmpty
                              ? LatLng(widget.theJourney!.first.latitude!,
                                  widget.theJourney!.first.longitude!)
                              : LatLng(51.509364, -0.128928),
                          initialZoom: 15,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.app',
                          ),
                          // Polyline Layer (Blue Path)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: widget.theJourney
                                        ?.asMap()
                                        .entries
                                        .map((entry) {
                                      // int index = entry.key;
                                      var data = entry.value;
                                      // double latOffset = index * 0.001;
                                      // double longOffset = index * 0.001;
                                      return LatLng(
                                          data.latitude!, data.longitude!);
                                    }).toList() ??
                                    [],
                                strokeWidth: 4.0,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                          // Marker Layer (First and Last Markers with Offset)
                          if (widget.theJourney != null &&
                              widget.theJourney!.isNotEmpty)
                            MarkerLayer(
                              markers: [
                                // First Marker (Green) with offset
                                Marker(
                                  width: 80.0,
                                  height: 80.0,
                                  point: LatLng(
                                    widget.theJourney!.first.latitude!,
                                    widget.theJourney!.first.longitude!,
                                  ),
                                  child: Icon(
                                    Icons.location_pin,
                                    color: Colors.green,
                                    size: 40.0,
                                  ),
                                ),
                                // Last Marker (Red) with offset - Only if more than one point
                                if (widget.theJourney!.length > 1)
                                  Marker(
                                    width: 80.0,
                                    height: 80.0,
                                    point: LatLng(
                                      widget.theJourney!.last.latitude! +
                                          ((widget.theJourney!.length - 1) *
                                              0.001), // Apply offset
                                      widget.theJourney!.last.longitude! +
                                          ((widget.theJourney!.length - 1) *
                                              0.001), // Apply offset
                                    ),
                                    child: Icon(
                                      Icons.location_pin,
                                      color: Colors.red,
                                      size: 40.0,
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: Colors.white)),
          Text(value, style: const TextStyle(color: Colors.grey, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _image(String asset) {
    return Image.asset(
      asset,
      height: 30.0,
      width: 30.0,
      color: Colors.amber,
    );
  }

  Widget _ratingBar() {
    return RatingBar.builder(
      initialRating: _initialRating,
      minRating: 1,
      direction: _isVertical ? Axis.vertical : Axis.horizontal,
      allowHalfRating: true,
      unratedColor: Colors.amber.withAlpha(50),
      itemCount: 5,
      itemSize: 35.0,
      itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
      itemBuilder: (context, _) => Icon(
        _selectedIcon ?? Icons.star,
        color: Colors.amber,
      ),
      onRatingUpdate: (rating) {
        setState(() {
          _rating = rating;
        });
      },
      updateOnDrag: true,
    );
  }
}
