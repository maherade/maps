import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = 'home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentLocation();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    streamSubscription!.cancel();
  }

  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(30.4775881, 31.1797262),
    zoom: 14.4746,
  );

  Set<Marker> markers = {};
  int counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("GPS"),
      ),
      body: GoogleMap(
        onLongPress: (latlong) {
          Marker marker =
              Marker(markerId: MarkerId('marker$counter'), position: latlong);
          markers.add(marker);
          setState(() {
            counter++;
          });
        },
        mapType: MapType.hybrid,
        initialCameraPosition:
            myCurrentLocation == null ? _kGooglePlex : myCurrentLocation!,
        markers: markers,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      ),
    );
  }

  Location location = Location();
  PermissionStatus? permissionStatus;
  bool serviceEnabled = false;
  LocationData? locationData;
  CameraPosition? myCurrentLocation;
  StreamSubscription<LocationData>? streamSubscription;

  void getCurrentLocation() async {
    var permission = await isPermissionGranted();
    if (permission == false) return;
    var service = await isServiceEnabled();
    if (service == false) return;

    locationData = await location.getLocation();
    location.changeSettings(accuracy: LocationAccuracy.powerSave);
    streamSubscription = location.onLocationChanged.listen((event) {
      locationData = event;
      print(
          "My Location : lat${locationData?.latitude} long:${locationData?.longitude} ");
      updateUserLocation();
    });

    // Put a mark on current Location
    Marker userMarker = Marker(
        markerId: const MarkerId('userLocation'),
        position: LatLng(locationData!.latitude!, locationData!.longitude!));
    markers.add(userMarker);

    myCurrentLocation = CameraPosition(
      bearing: 190.8334901395799,
      target: LatLng(locationData!.latitude!, locationData!.longitude!),
      tilt: 40.440717697143555,
      zoom: 19.151926040649414,
    );
    final GoogleMapController controller = await _controller.future;
    controller
        .animateCamera(CameraUpdate.newCameraPosition(myCurrentLocation!));
    setState(() {});
  }

  void updateUserLocation() async {
    Marker userMarker = Marker(
        markerId: const MarkerId('userLocation'),
        position: LatLng(locationData!.latitude!, locationData!.longitude!));
    markers.add(userMarker);
    final GoogleMapController controller = await _controller.future;
    controller
        .animateCamera(CameraUpdate.newCameraPosition(myCurrentLocation!));
    setState(() {});
  }

  // AIzaSyBbD9dd4kO8uT1_LwzciMtiebWIquNUiwg
  Future<bool> isServiceEnabled() async {
    serviceEnabled = await location.serviceEnabled();
    if (serviceEnabled == false) {
      serviceEnabled = await location.requestService();
      return serviceEnabled;
    }
    return serviceEnabled;
  }

  Future<bool> isPermissionGranted() async {
    permissionStatus = await location.hasPermission();
    if (permissionStatus == PermissionStatus.denied) {
      permissionStatus = await location.requestPermission();
      return permissionStatus == PermissionStatus.granted;
    } else {
      return permissionStatus == PermissionStatus.granted;
    }
  }
}
