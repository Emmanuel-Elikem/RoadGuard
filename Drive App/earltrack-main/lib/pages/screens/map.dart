import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class MapScreen extends StatefulWidget {
  final LocationData? dataLocation;

  const MapScreen({super.key, required this.dataLocation});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController mapController = MapController();
  LatLng? startLocation; // First recorded location
  LatLng? currentLocation; // Most recent location
  List<LatLng> routePath = []; // Stores the route
  bool isMapReady = false; // Ensure map is ready before moving it

  @override
  void initState() {
    super.initState();

    if (widget.dataLocation != null) {
      LatLng initialLocation = LatLng(
          widget.dataLocation!.latitude!, widget.dataLocation!.longitude!);
      startLocation = initialLocation; // First recorded location
      currentLocation = initialLocation;
      routePath.add(initialLocation);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        isMapReady = true;
      });

      if (currentLocation != null) {
        moveToCurrentLocation();
      }
    });
  }

  void updateLocation(LocationData? newLocation) {
    if (newLocation?.latitude != null && newLocation?.longitude != null) {
      LatLng updatedLocation =
          LatLng(newLocation!.latitude!, newLocation.longitude!);

      setState(() {
        startLocation ??= updatedLocation;
        currentLocation = updatedLocation; // Update to latest location
        routePath.add(updatedLocation);
      });

      if (isMapReady) {
        mapController.move(updatedLocation, 18);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * .45,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Stack(
          children: [
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: startLocation ??
                    const LatLng(51.509364, -0.128928), // Default center
                initialZoom: 20,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                if (routePath.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePath,
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    ],
                  ),
                // Red marker for the first location
                if (startLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: startLocation!,
                        width: 50,
                        height: 50,
                        child: const Icon(
                          CupertinoIcons.location_solid,
                          color: Colors.red,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                // Blue marker for the latest location
                if (currentLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: currentLocation!,
                        width: 50,
                        height: 50,
                        child: const Icon(
                          CupertinoIcons.location_solid,
                          color: Colors.blue,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Move the map to the current location
  void moveToCurrentLocation() {
    if (currentLocation != null && isMapReady) {
      mapController.move(currentLocation!, 18);
    }
  }
}

/**
 * floatingActionButton: FloatingActionButton(
        onPressed: moveToCurrentLocation, // Move to current location on click
        child: const Icon(Icons.my_location),
      ),
 */



  // Function to get and update the user's location
  // void initLocation() async {
  //   bool _serviceEnabled;
  //   PermissionStatus _permissionGranted;

  //   // Check if location service is enabled
  //   _serviceEnabled = await location.serviceEnabled();
  //   if (!_serviceEnabled) {
  //     _serviceEnabled = await location.requestService();
  //     if (!_serviceEnabled) return;
  //   }

  //   // Check location permissions
  //   _permissionGranted = await location.hasPermission();
  //   if (_permissionGranted == PermissionStatus.denied) {
  //     _permissionGranted = await location.requestPermission();
  //     if (_permissionGranted != PermissionStatus.granted) return;
  //   }

  //   // Get initial location
  //   LocationData locationData = await location.getLocation();
  //   setState(() {
  //     startLocation =
  //         LatLng(locationData.latitude ?? 0.0, locationData.longitude ?? 0.0);
  //     currentLocation = startLocation;
  //     routePath.add(startLocation!);
  //     mapController.move(currentLocation!, 18);
  //   });

  //   // Listen for location updates
  //   location.onLocationChanged.listen((LocationData newLocation) {
  //     if (newLocation.latitude != null && newLocation.longitude != null) {
  //       setState(() {
  //         currentLocation =
  //             LatLng(newLocation.latitude!, newLocation.longitude!);
  //         routePath.add(currentLocation!); // Add new location to the path
  //       });
  //     }
  //   });

  //   location.changeSettings(distanceFilter: 100);
  // }
