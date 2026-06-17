import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {

  Future<Position?> getCurrentLocation() async {

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return null;
    }

    permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {

      permission =
          await Geolocator.requestPermission();

      if (permission ==
          LocationPermission.denied) {
        return null;
      }
    }

    if (permission ==
        LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy:
          LocationAccuracy.high,
    );
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

    if (placemarks.isNotEmpty) {
      final place = placemarks.first;

      final rua = place.street ?? '';
      final bairro = place.subLocality ?? '';
      final cidade = place.locality ?? '';
      final estado = place.administrativeArea ?? '';

      final endereco = [
        rua,
        bairro,
        cidade,
        estado,
      ]
          .where((item) => item.isNotEmpty)
          .join(', ');

      return endereco.isNotEmpty
          ? endereco
          : 'Endereço não encontrado';
    }

    return 'Endereço não encontrado';
  } catch (e) {
    print('ERRO CODING: $e');

    return '${latitude.toStringAsFixed(6)}, '
           '${longitude.toStringAsFixed(6)}';
  }
}
}