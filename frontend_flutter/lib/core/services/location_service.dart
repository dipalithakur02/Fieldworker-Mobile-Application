import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationDetails {
  final Position position;
  final String? address;

  const LocationDetails({
    required this.position,
    required this.address,
  });
}

class LocationService {
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  static Future<LocationDetails?> getCurrentLocationDetails() async {
    final position = await getCurrentLocation();
    if (position == null) {
      return null;
    }

    String? address;

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final addressParts = [
          placemark.street,
          placemark.subLocality,
          placemark.locality,
          placemark.administrativeArea,
          placemark.postalCode,
          placemark.country,
        ]
            .where((part) => part != null && part.trim().isNotEmpty)
            .cast<String>();

        address = addressParts.join(', ');
      }
    } catch (_) {
      address = null;
    }

    return LocationDetails(position: position, address: address);
  }

  static double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // in km
  }
}
