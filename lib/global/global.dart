import 'package:firebase_auth/firebase_auth.dart';
import 'package:tawsila_user/models/user_model.dart';

import '../models/direction_details_info.dart';

final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
User? currentFirebaseUser;
UserModel? userModelCurrentInfo;
List dList = []; //  online drivers info list
DirectionsDetailsInfo? tripDirectionsDetailsInfo;
String? chosenDriverId = '';
