import '../models/active_nearby_available_drivers.dart';

class GeoFireAssistant {
  static List<ActiveNearByAvailableDrivers> activeNearByAvailableDrivers = [];

  static void deleteOfflineDriverFromList(String driverId) {
    int indexNumber = activeNearByAvailableDrivers
        .indexWhere((element) => element.driverId == driverId);
    activeNearByAvailableDrivers.removeAt(indexNumber);
  }

  static void updateActiveNearbyAvailableDriverLocation(
      ActiveNearByAvailableDrivers driverWhoMove) {
    int indexNumber = activeNearByAvailableDrivers
        .indexWhere((element) => element.driverId == driverWhoMove.driverId);
    activeNearByAvailableDrivers[indexNumber].locationLatitude =
        driverWhoMove.locationLatitude;
    activeNearByAvailableDrivers[indexNumber].locationLongitude =
        driverWhoMove.locationLongitude;
  }
}
