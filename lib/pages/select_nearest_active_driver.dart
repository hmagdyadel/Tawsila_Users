import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:smooth_star_rating_nsafe/smooth_star_rating.dart';
import 'package:tawsila_user/assistants/assistant_methods.dart';
import 'package:tawsila_user/global/global.dart';

class SelectNearestActiveDriverScreen extends StatefulWidget {
  final DatabaseReference? referenceRideRequest;

  const SelectNearestActiveDriverScreen(
      {Key? key, required this.referenceRideRequest})
      : super(key: key);

  @override
  State<SelectNearestActiveDriverScreen> createState() =>
      _SelectNearestActiveDriverScreenState();
}

class _SelectNearestActiveDriverScreenState
    extends State<SelectNearestActiveDriverScreen> {
  String fareAmount = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.white54,
        title: const Text(
          'Nearest online drivers',
          style: TextStyle(fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.close,
            color: Colors.white,
          ),
          onPressed: () {
            // delete the ride request from database
            widget.referenceRideRequest!.remove();
            Fluttertoast.showToast(msg: 'You have cancelled the ride request');
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView.builder(
        itemCount: dList.length,
        itemBuilder: (BuildContext context, int index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                chosenDriverId = dList[index]['id'].toString();
              });
              Navigator.pop(context,'driverChosen');
            },
            child: Card(
              color: Colors.grey,
              elevation: 3,
              shadowColor: Colors.green,
              margin: const EdgeInsets.all(0),
              child: ListTile(
                leading: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Image.asset(
                      'assets/images/${dList[index]['car_details']['type']}.png'),
                ),
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      dList[index]['name'],
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    Text(
                      dList[index]['car_details']['car_model'],
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                    SmoothStarRating(
                      rating: 3.5,
                      color: Colors.black,
                      borderColor: Colors.black,
                      allowHalfRating: true,
                      size: 15,
                      starCount: 5,
                    )
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${getFareAmountAccordingToVehicleType(index)} EGP',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tripDirectionsDetailsInfo != null
                          ? tripDirectionsDetailsInfo!.durationText!
                          : '',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                          fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tripDirectionsDetailsInfo != null
                          ? tripDirectionsDetailsInfo!.distanceText!
                          : '',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  getFareAmountAccordingToVehicleType(int index) {
    if (dList[index]['car_details']['type'].toString() == 'Bike') {
      fareAmount = (AssistantMethods.calculateFareAmountFromOriginToDestination(
                  tripDirectionsDetailsInfo!) /
              2)
          .toStringAsFixed(1);
    } else if (dList[index]['car_details']['type'].toString() == 'Car-go') {
      fareAmount = (AssistantMethods.calculateFareAmountFromOriginToDestination(
              tripDirectionsDetailsInfo!))
          .toStringAsFixed(1);
    } else if (dList[index]['car_details']['type'].toString() == 'Car-X') {
      fareAmount = (AssistantMethods.calculateFareAmountFromOriginToDestination(
                  tripDirectionsDetailsInfo!) *
              1.5)
          .toStringAsFixed(1);
    }
    return fareAmount;
  }
}
