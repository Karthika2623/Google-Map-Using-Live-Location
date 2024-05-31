import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyMapScreen(),
    );
  }
}

class MyMapScreen extends StatefulWidget {
  const MyMapScreen({Key? key}) : super(key: key);

  @override
  _MyMapScreenState createState() => _MyMapScreenState();
}

class _MyMapScreenState extends State<MyMapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  String? _currentAddress;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      List<Placemark> placemarks =
      await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];

      setState(() {
        _currentPosition = position;
        _currentAddress =
        "${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}";
      });

      _moveCameraToCurrentLocation();

      // Continuously listen for location changes
      Geolocator.getPositionStream(
        desiredAccuracy: LocationAccuracy.best,
        distanceFilter: 10, // Update every 10 meters
      ).listen((newPosition) {
        setState(() {
          _currentPosition = newPosition;
        });

        // Reverse geocode the new position to get the address
        placemarkFromCoordinates(
          newPosition.latitude,
          newPosition.longitude,
        ).then((newPlace) {
          setState(() {
            _currentAddress =
            "${newPlace[0].street}, ${newPlace[0].locality}, ${newPlace[0].postalCode}, ${newPlace[0].country}";
          });
        });
      });
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  void _moveCameraToCurrentLocation() {
    if (_mapController != null && _currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            zoom: 15.0,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Location Example'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              setState(() {
                _mapController = controller;
              });
            },
            initialCameraPosition: const CameraPosition(
              target: LatLng(0.0, 0.0),
              zoom: 10.0,
            ),
            myLocationEnabled: true,
          ),
          Positioned(
            bottom: 16.0,
            left: 16.0,
            child: Card(
              elevation: 4.0,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_currentPosition != null)
                      Text(
                        'Location: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
                        style: const TextStyle(fontSize: 16.0),
                      )
                    else
                      const Text('Location not available'),
                    const SizedBox(height: 7.0),
                    Text(
                      'Address: ${_currentAddress ?? "Loading..."}',
                      style: const TextStyle(fontSize: 16.0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
