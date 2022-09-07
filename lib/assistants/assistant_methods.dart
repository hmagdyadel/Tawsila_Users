import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tawsila_user/assistants/request_assistant.dart';
import 'package:tawsila_user/models/direction_details_info.dart';

import '../global/global.dart';
import '../global/map_key.dart';
import '../models/user_model.dart';

class AssistantMethods {
  static void readCurrentOnlineUserInfo() async {
    currentFirebaseUser = firebaseAuth.currentUser;
    DatabaseReference userRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(currentFirebaseUser!.uid);
    userRef.once().then((snap) {
      if (snap.snapshot.value != null) {
        userModelCurrentInfo = UserModel.fromSnapshot(snap.snapshot);
        print('name =${userModelCurrentInfo!.name}');
        print('email =${userModelCurrentInfo!.email}');
      }
    });
  }

  static Future<DirectionsDetailsInfo?>
  obtainOriginToDestinationDirectionDetails(LatLng originPosition,
      LatLng destinationPosition) async {
    String urlOriginToDestinationDirectionDetails =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${originPosition
        .latitude},${originPosition.longitude}&destination=${destinationPosition
        .latitude},${destinationPosition.longitude}&key=$mapKey';
    var responseDirectionAPI = await RequestAssistant.receiveRequest(
        urlOriginToDestinationDirectionDetails);
    if (responseDirectionAPI == 'Error occurred, no response.') {
      return null;
    }
    DirectionsDetailsInfo directionsDetailsInfo = DirectionsDetailsInfo();
    directionsDetailsInfo.ePoints =
    responseDirectionAPI['routes'][0]['overview_polyline']['points'];

    directionsDetailsInfo.distanceText =
    responseDirectionAPI['routes'][0]['legs'][0]['distance']['text'];
    directionsDetailsInfo.distanceValue =
    responseDirectionAPI['routes'][0]['legs'][0]['distance']['value'];

    directionsDetailsInfo.durationText =
    responseDirectionAPI['routes'][0]['legs'][0]['duration']['text'];
    directionsDetailsInfo.durationValue =
    responseDirectionAPI['routes'][0]['legs'][0]['duration']['value'];
    return directionsDetailsInfo;
  }

  static double calculateFareAmountFromOriginToDestination(
      DirectionsDetailsInfo directionsDetailsInfo) {
    double timeTravelFareAmountPerMinute =
        (directionsDetailsInfo.durationValue! / 60) * 0.1;
    double distanceTravelFareAmountPerKilometer =
        (directionsDetailsInfo.durationValue! / 1000) * 0.2;
    double totalAmount =
        timeTravelFareAmountPerMinute + distanceTravelFareAmountPerKilometer;
    // 1 USD = 19.20 EGP
    double localCurrencyTotalFare = totalAmount * 19.2;
    return double.parse(localCurrencyTotalFare.toStringAsFixed(1));
  }
}
