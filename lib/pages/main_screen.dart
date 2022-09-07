import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:tawsila_user/assistants/assistant_methods.dart';
import 'package:tawsila_user/assistants/geofire_assistant.dart';

import 'package:tawsila_user/assistants/request_assistant.dart';
import 'package:tawsila_user/info_handler/app_info.dart';
import 'package:tawsila_user/main.dart';
import 'package:tawsila_user/models/active_nearby_available_drivers.dart';
import 'package:tawsila_user/pages/search_places_screen.dart';
import 'package:tawsila_user/pages/select_nearest_active_driver.dart';
import 'package:tawsila_user/splash/splash_screen.dart';
import 'package:tawsila_user/widgets/progress_dialog.dart';
import '../global/global.dart';
import '../widgets/my_drawer.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? googleMapController;
  GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState>();
  double searchLocationContainerHeight = 220;
  Position? userCurrentPosition;
  var geoLocator = Geolocator();
  LocationPermission? _locationPermission;
  double bottomPadding = 0;
  List<LatLng> pLineCoordinatesList = [];
  Set<Polyline> polyLineSet = {};
  Set<Marker> markerSet = {};
  Set<Circle> circleSet = {};
  String username = '';
  String userEmail = '';
  bool openNavigationDrawer = true;
  bool activeNearByDriverKeysLoaded = false;
  BitmapDescriptor? activeNearByIcon;
  List<ActiveNearByAvailableDrivers> onlineNearByAvailableDriverList = [];
  static const CameraPosition _kLake = CameraPosition(
    target: LatLng(29.9406967, 31.2806411),
    zoom: 14,
  );
  DatabaseReference? referenceRideRequest;

  blackThemeGoogleMap() {
    googleMapController?.setMapStyle('''
                    [
                      {
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#242f3e"
                          }
                        ]
                      },
                      {
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#746855"
                          }
                        ]
                      },
                      {
                        "elementType": "labels.text.stroke",
                        "stylers": [
                          {
                            "color": "#242f3e"
                          }
                        ]
                      },
                      {
                        "featureType": "administrative.locality",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#d59563"
                          }
                        ]
                      },
                      {
                        "featureType": "poi",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#d59563"
                          }
                        ]
                      },
                      {
                        "featureType": "poi.park",
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#263c3f"
                          }
                        ]
                      },
                      {
                        "featureType": "poi.park",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#6b9a76"
                          }
                        ]
                      },
                      {
                        "featureType": "road",
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#38414e"
                          }
                        ]
                      },
                      {
                        "featureType": "road",
                        "elementType": "geometry.stroke",
                        "stylers": [
                          {
                            "color": "#212a37"
                          }
                        ]
                      },
                      {
                        "featureType": "road",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#9ca5b3"
                          }
                        ]
                      },
                      {
                        "featureType": "road.highway",
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#746855"
                          }
                        ]
                      },
                      {
                        "featureType": "road.highway",
                        "elementType": "geometry.stroke",
                        "stylers": [
                          {
                            "color": "#1f2835"
                          }
                        ]
                      },
                      {
                        "featureType": "road.highway",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#f3d19c"
                          }
                        ]
                      },
                      {
                        "featureType": "transit",
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#2f3948"
                          }
                        ]
                      },
                      {
                        "featureType": "transit.station",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#d59563"
                          }
                        ]
                      },
                      {
                        "featureType": "water",
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#17263c"
                          }
                        ]
                      },
                      {
                        "featureType": "water",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#515c6d"
                          }
                        ]
                      },
                      {
                        "featureType": "water",
                        "elementType": "labels.text.stroke",
                        "stylers": [
                          {
                            "color": "#17263c"
                          }
                        ]
                      }
                    ]
                ''');
  }

  checkIfLocationPermissionAllowed() async {
    _locationPermission = await Geolocator.requestPermission();
    if (_locationPermission == LocationPermission.denied) {
      _locationPermission = await Geolocator.requestPermission();
    }
  }

  locateUserPosition() async {
    Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    userCurrentPosition = currentPosition;
    LatLng latLngPosition =
        LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);
    CameraPosition cameraPosition =
        CameraPosition(target: latLngPosition, zoom: 14);
    googleMapController!
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    print(userCurrentPosition!.latitude);
    print(userCurrentPosition!.longitude);
    String humanReadableAddress =
        await RequestAssistant.searchAddressForGeographicCoordinates(
            userCurrentPosition!, returnContext());
    print('this is your address: $humanReadableAddress');
    username = userModelCurrentInfo!.name!;
    userEmail = userModelCurrentInfo!.email!;
    initializeGeoFireListener();
  }

  @override
  void initState() {
    super.initState();
    checkIfLocationPermissionAllowed();
  }

  BuildContext returnContext() {
    return context;
  }

  saveRideRequestInformation() {
    //save the ride request information
    // .push() generate automatic unique id
    referenceRideRequest =
        FirebaseDatabase.instance.ref().child('All Ride Requests').push();
    var originLocation =
        Provider.of<AppInfo>(context, listen: false).userPickupLocation;
    var destinationLocation =
        Provider.of<AppInfo>(context, listen: false).userDropOffLocation;
    Map originLocationMap = {
      'latitude': originLocation!.locationLatitude.toString(),
      'longitude': originLocation.locationLongitude.toString(),
    };
    Map destinationLocationMap = {
      'latitude': destinationLocation!.locationLatitude.toString(),
      'longitude': destinationLocation.locationLongitude.toString(),
    };
    Map userInformationMap = {
      'origin': originLocationMap,
      'destination': destinationLocationMap,
      'time': DateTime.now().toString(),
      'username': userModelCurrentInfo!.name,
      'userPhone': userModelCurrentInfo!.phone,
      'originAddress': originLocation.locationName,
      'destinationAddress': destinationLocation.locationName,
      'driverId': 'matting',
    };
    referenceRideRequest!.set(userInformationMap);

    onlineNearByAvailableDriverList =
        GeoFireAssistant.activeNearByAvailableDrivers;
    searchNearestOnlineDrivers();
  }

  searchNearestOnlineDrivers() async {
    //when no active drivers available
    if (onlineNearByAvailableDriverList.isEmpty) {
      //cancel ride request;
      referenceRideRequest!.remove();
      setState(() {
        polyLineSet.clear();
        markerSet.clear();
        circleSet.clear();
        pLineCoordinatesList.clear();
      });
      Fluttertoast.showToast(
          msg:
              'No online nearest driver available, Search again for ride after some time');

      Future.delayed(const Duration(milliseconds: 4000), () {
        MyApp.restartApp(context);
      });
      return;
    }
    // active drivers available
    await retrieveOnlineDriversInformation(onlineNearByAvailableDriverList);
    var response = await Navigator.push(
        returnContext(),
        MaterialPageRoute(
            builder: (c) => SelectNearestActiveDriverScreen(
                referenceRideRequest: referenceRideRequest)));
    if (response == 'driverChosen') {
      FirebaseDatabase.instance
          .ref()
          .child('drivers')
          .child(chosenDriverId!)
          .once()
          .then((snap) {
        if (snap.snapshot.value != null) {
          // send notification to that specific driver
          sendNotificationToDriverNow(chosenDriverId!);
        } else {
          Fluttertoast.showToast(msg: 'This driver do not exist');
        }
      });
    }
  }

  sendNotificationToDriverNow(String chosenDriverId) {
// assign/set ride request to new ride status in drivers parent node for that specific chosen driver
    FirebaseDatabase.instance
        .ref()
        .child('drivers')
        .child(chosenDriverId)
        .child('newRideStatus')
        .set(referenceRideRequest!.key);
    // automate the push notification
  }

  retrieveOnlineDriversInformation(List onlineNearestDriverList) async {
    DatabaseReference reference =
        FirebaseDatabase.instance.ref().child('drivers');
    for (int i = 0; i < onlineNearestDriverList.length; i++) {
      await reference
          .child(onlineNearestDriverList[i].driverId.toString())
          .once()
          .then((dataSnapshot) {
        var driverKeyInfo = dataSnapshot.snapshot.value;
        dList.add(driverKeyInfo);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    createActiveNearByDriverIconMarker();
    return Scaffold(
      key: sKey,
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width / 1.4,
        child: Theme(
          data: Theme.of(context).copyWith(canvasColor: Colors.black),
          child: MyDrawer(
            name: username,
            email: userEmail,
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: bottomPadding),
            mapType: MapType.normal,
            myLocationEnabled: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
            polylines: polyLineSet,
            markers: markerSet,
            circles: circleSet,
            initialCameraPosition: _kLake,
            onMapCreated: (GoogleMapController controller) {
              _controllerGoogleMap.complete(controller);
              googleMapController = controller;
              blackThemeGoogleMap();
              setState(() {
                bottomPadding = 230;
              });
              // for black theme google  map
              locateUserPosition();
            },
          ),
          // custom Drawer
          Positioned(
            top: 36,
            left: 14,
            child: GestureDetector(
              onTap: () {
                if (openNavigationDrawer) {
                  sKey.currentState!.openDrawer();
                } else {
                  //refresh app automatic
                  //  Navigator.popUntil(context, ModalRoute.withName(Navigator.defaultRouteName));
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (c) => const SplashView()));
                }
              },
              child: CircleAvatar(
                backgroundColor: Colors.grey,
                child: Icon(
                  openNavigationDrawer ? Icons.menu : Icons.close,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
          // UI for searching location
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedSize(
              curve: Curves.easeIn,
              duration: const Duration(milliseconds: 120),
              child: Container(
                height: searchLocationContainerHeight,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 18),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.add_location_alt_outlined,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'From',
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              Text(
                                Provider.of<AppInfo>(context)
                                            .userPickupLocation !=
                                        null
                                    ? (Provider.of<AppInfo>(context)
                                        .userPickupLocation!
                                        .locationName!)
                                    : 'Your current location',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(
                          height: 1, thickness: 1, color: Colors.grey),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () async {
                          // go to search places screen
                          var responseFromSearchScreen = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (c) => const SearchPlacesScreen()));

                          if (responseFromSearchScreen == 'obtainedDropOff') {
                            setState(() {
                              openNavigationDrawer = false;
                            });
                            //draw routes draw polyline
                            await drawPolylineFromOriginToDestination();
                          }
                        },
                        child: Row(
                          children: [
                            const Icon(
                              Icons.add_location_alt_outlined,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'To',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                ),
                                Text(
                                  Provider.of<AppInfo>(context)
                                              .userDropOffLocation !=
                                          null
                                      ? (Provider.of<AppInfo>(context)
                                          .userDropOffLocation!
                                          .locationName!)
                                      : 'Where to go?',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Divider(
                          height: 1, thickness: 1, color: Colors.grey),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (Provider.of<AppInfo>(context, listen: false)
                                  .userDropOffLocation !=
                              null) {
                            saveRideRequestInformation();
                          } else {
                            Fluttertoast.showToast(
                                msg: 'Please select destination location');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            primary: Colors.green,
                            textStyle: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        child: const Text('Request a Ride'),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> drawPolylineFromOriginToDestination() async {
    var originPosition =
        Provider.of<AppInfo>(context, listen: false).userPickupLocation;
    var destinationPosition =
        Provider.of<AppInfo>(context, listen: false).userDropOffLocation;
    var originLatLng = LatLng(
        originPosition!.locationLatitude!, originPosition.locationLongitude!);
    var destinationLatLng = LatLng(destinationPosition!.locationLatitude!,
        destinationPosition.locationLongitude!);
    showDialog(
        context: context,
        builder: (BuildContext context) => const ProgressDialog(
              message: 'Please wait...',
            ));

    var directionDetailsInfo =
        await AssistantMethods.obtainOriginToDestinationDirectionDetails(
            originLatLng, destinationLatLng);
    setState(() {
      tripDirectionsDetailsInfo = directionDetailsInfo;
    });
    Navigator.pop(returnContext());
    PolylinePoints pPoints = PolylinePoints();
    List<PointLatLng> decodedPolylinePointsList =
        pPoints.decodePolyline(directionDetailsInfo!.ePoints!);
    pLineCoordinatesList.clear();
    if (decodedPolylinePointsList.isNotEmpty) {
      for (var pointLatLng in decodedPolylinePointsList) {
        pLineCoordinatesList
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      }
    }
    polyLineSet.clear();
    setState(() {
      Polyline polyline = Polyline(
        color: Colors.teal,
        polylineId: const PolylineId('PolylineId'),
        jointType: JointType.round,
        points: pLineCoordinatesList,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );
      polyLineSet.add(polyline);
    });
    LatLngBounds boundsLatLng;
    if (originLatLng.latitude > destinationLatLng.latitude &&
        originLatLng.longitude > destinationLatLng.longitude) {
      boundsLatLng =
          LatLngBounds(southwest: destinationLatLng, northeast: originLatLng);
    } else if (originLatLng.longitude > destinationLatLng.longitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(originLatLng.latitude, destinationLatLng.longitude),
        northeast: LatLng(destinationLatLng.latitude, originLatLng.longitude),
      );
    } else if (originLatLng.latitude > destinationLatLng.latitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(destinationLatLng.latitude, originLatLng.longitude),
        northeast: LatLng(originLatLng.latitude, destinationLatLng.longitude),
      );
    } else {
      boundsLatLng = LatLngBounds(
        southwest: originLatLng,
        northeast: destinationLatLng,
      );
    }
    googleMapController!
        .animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 65));
    Marker originMarker = Marker(
      markerId: const MarkerId('originId'),
      infoWindow:
          InfoWindow(title: originPosition.locationName, snippet: 'Origin'),
      position: originLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
    );

    Marker destinationMarker = Marker(
      markerId: const MarkerId('destinationId'),
      infoWindow: InfoWindow(
          title: destinationPosition.locationName, snippet: 'Destination'),
      position: destinationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    );
    setState(() {
      markerSet.add(originMarker);
      markerSet.add(destinationMarker);
    });
    Circle originCircle = Circle(
      circleId: const CircleId('originId'),
      fillColor: Colors.green,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: originLatLng,
    );

    Circle destinationCircle = Circle(
      circleId: const CircleId('destinationId'),
      fillColor: Colors.red,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: destinationLatLng,
    );
    setState(() {
      circleSet.add(originCircle);
      circleSet.add(destinationCircle);
    });
  }

  initializeGeoFireListener() {
    Geofire.initialize('activeDrivers');
    Geofire.queryAtLocation(
            userCurrentPosition!.latitude, userCurrentPosition!.longitude, 7)!
        .listen((map) {
      if (map != null) {
        var callBack = map['callBack'];
        //latitude will be retrieved from map['latitude']
        //longitude will be retrieved from map['longitude']
        switch (callBack) {
          //whenever any driver become active / online
          case Geofire.onKeyEntered:
            ActiveNearByAvailableDrivers activeNearByAvailableDriver =
                ActiveNearByAvailableDrivers();
            activeNearByAvailableDriver.locationLatitude = map['latitude'];
            activeNearByAvailableDriver.locationLongitude = map['longitude'];
            activeNearByAvailableDriver.driverId = map['key'];
            GeoFireAssistant.activeNearByAvailableDrivers
                .add(activeNearByAvailableDriver);
            if (activeNearByDriverKeysLoaded) {
              displayActiveDriversOnUsersMap();
            }
            break;
          //whenever any driver become nonactive / offline
          case Geofire.onKeyExited:
            GeoFireAssistant.deleteOfflineDriverFromList(map['key']);
            displayActiveDriversOnUsersMap();
            break;
          //whenever driver moves  update driver location
          case Geofire.onKeyMoved:
            ActiveNearByAvailableDrivers activeNearByAvailableDrivers =
                ActiveNearByAvailableDrivers();
            activeNearByAvailableDrivers.locationLatitude = map['latitude'];
            activeNearByAvailableDrivers.locationLongitude = map['longitude'];
            activeNearByAvailableDrivers.driverId = map['key'];
            GeoFireAssistant.updateActiveNearbyAvailableDriverLocation(
                activeNearByAvailableDrivers);
            displayActiveDriversOnUsersMap();
            break;
          // display those online drivers on users map
          case Geofire.onGeoQueryReady:
            activeNearByDriverKeysLoaded = true;
            displayActiveDriversOnUsersMap();
            break;
        }
      }

      setState(() {});
    });
  }

  displayActiveDriversOnUsersMap() {
    setState(() {
      markerSet.clear();
      circleSet.clear();
      Set<Marker> driverMarkerSet = <Marker>{};
      for (ActiveNearByAvailableDrivers eachDriver
          in GeoFireAssistant.activeNearByAvailableDrivers) {
        LatLng eachDriverActivePosition =
            LatLng(eachDriver.locationLatitude!, eachDriver.locationLongitude!);
        Marker marker = Marker(
          markerId: MarkerId(eachDriver.driverId!),
          position: eachDriverActivePosition,
          icon: activeNearByIcon!,
          rotation: 360,
        );
        driverMarkerSet.add(marker);
      }
      setState(() {
        markerSet = driverMarkerSet;
      });
    });
  }

  createActiveNearByDriverIconMarker() {
    if (activeNearByIcon == null) {
      ImageConfiguration imageConfiguration =
          createLocalImageConfiguration(context, size: const Size(2, 2));
      BitmapDescriptor.fromAssetImage(
              imageConfiguration, 'assets/images/car.png')
          .then((value) {
        activeNearByIcon = value;
      });
    }
  }
}
