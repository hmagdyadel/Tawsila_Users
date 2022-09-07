import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tawsila_user/assistants/request_assistant.dart';
import 'package:tawsila_user/global/map_key.dart';
import 'package:tawsila_user/info_handler/app_info.dart';
import 'package:tawsila_user/models/directions.dart';
import 'package:tawsila_user/widgets/progress_dialog.dart';

import '../models/predicted_places.dart';

class PlacePredictionTileDesign extends StatelessWidget {
  final PredictedPlaces predictedPlaces;

  const PlacePredictionTileDesign({Key? key, required this.predictedPlaces})
      : super(key: key);

  getPlaceDirectionDetails(String placeID, context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) => const ProgressDialog(
        message: 'Setting pick up place..',
      ),
    );
    String placeDirectionDetailsUrl =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeID&key=$mapKey';
    var responseAPI =
        await RequestAssistant.receiveRequest(placeDirectionDetailsUrl);
    Navigator.pop(context);
    if (responseAPI == 'Error occurred, no response.') {
      return;
    }
    if (responseAPI['status'] == 'OK') {
      Directions directions = Directions();
      directions.locationName = responseAPI['result']['name'];
      directions.locationLatitude =
          responseAPI['result']['geometry']['location']['lat'];
      directions.locationLongitude =
          responseAPI['result']['geometry']['location']['lng'];
      directions.locationId = placeID;
      Provider.of<AppInfo>(context, listen: false)
          .updateDropOffLocationAddress(directions);
      Navigator.pop(context, 'obtainedDropOff');

    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(primary: Colors.white10),
        onPressed: () {
          getPlaceDirectionDetails(predictedPlaces.placeId!, context);
        },
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Row(
            children: [
              const Icon(
                Icons.add_location,
                color: Colors.grey,
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    predictedPlaces.mainText!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, color: Colors.white54),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    predictedPlaces.secondaryText!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                  const SizedBox(height: 8),
                ],
              ))
            ],
          ),
        ));
  }
}
