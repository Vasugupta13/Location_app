import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

double? lat;
double? long;

class GetLocation extends StatefulWidget {
  const GetLocation({super.key});

  @override
  State<GetLocation> createState() => _GetLocationState();
}

class _GetLocationState extends State<GetLocation> {
  //Google maps controller-->
  final Completer<GoogleMapController> _controller = Completer();
  static CameraPosition initialPosition =
      const CameraPosition(target: LatLng(27.5664, 76.1490), zoom: 15);

  Set<Marker> markers = {};

  //------>

  //showLocation function
  Future<void> showLocation() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(
          target: LatLng(lat!, long!), zoom: 16, bearing: 192.0, tilt: 45)),
    );
    markers.clear();
    markers.add(
      Marker(
        markerId: const MarkerId('currentLocation'),
        position: LatLng(lat!, long!),
        infoWindow: const InfoWindow(title: 'Your location'),
      ),
    );
  }
  //store at fireBase-->
  Future addLocation(double Latitude, double Longitude) async {
    await FirebaseFirestore.instance
        .collection("latlong")
        .add({'Latitude': Latitude, 'Longitude': Longitude});
  }
  //------>

//Geolocator for latitude and longitude-->
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }
  //------>



  //get data and show it-->
  getLatLong() async {
    Future<Position> data = _determinePosition();
    data.then(
      (value) {
        if (kDebugMode) {
          print("value $value");
        }
        setState(
          () {
            lat = value.latitude;
            long = value.longitude;
            showLocation().then(
              (value) {
                setState(
                  () {
                    addLocation(lat!, long!);
                  },
                );
              },
            );
          },
        );
      },
    ).catchError(
      (error) {
        if (kDebugMode) {
          print("Error $error");
        }
      },
    );
  }
  //------>

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple[300],
        title: const Text(
          'Location',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: MediaQuery.of(context).size.height * 0.005,
            child: Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(40),
                  topLeft: Radius.circular(40),
                ),
              ),
              child: GoogleMap(
                markers: markers,
                initialCameraPosition: initialPosition,
                mapType: MapType.normal,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.75,
            child: Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  topLeft: Radius.circular(20),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.77,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () async {
                    getLatLong();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[400],
                    elevation: 5,
                    shadowColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.all(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Your current location',
                        style: TextStyle(
                          fontSize: 17,
                        ),
                      ),
                      Icon(
                        Icons.location_on_outlined,
                        size: 18,
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
