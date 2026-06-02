import 'package:geocoding/geocoding.dart';

import 'package:geolocator/geolocator.dart';

class LocationService {

  Future<Position?> getCurrentLocation()
      async {

    bool serviceEnabled;

    LocationPermission permission;

    serviceEnabled =
        await Geolocator
            .isLocationServiceEnabled();

    if (!serviceEnabled) {

      return null;
    }

    permission =
        await Geolocator
            .checkPermission();

    if (permission ==
        LocationPermission.denied) {

      permission =
          await Geolocator
              .requestPermission();

      if (permission ==
          LocationPermission.denied) {

        return null;
      }
    }

    if (permission ==
        LocationPermission
            .deniedForever) {

      return null;
    }

    Position position =
        await Geolocator
            .getCurrentPosition(
      desiredAccuracy:
          LocationAccuracy.high,
    );

    return position;
  }

  Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {

    try {

      List<Placemark> placemarks =
          await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      Placemark place =
          placemarks.first;

      return
          '${place.street}, ${place.locality} - ${place.administrativeArea}';

    } catch (e) {

      return 'Endereço não encontrado';
    }
  }
}