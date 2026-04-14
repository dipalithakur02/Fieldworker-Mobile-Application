import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

enum LocationFetchStatus {
  success,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

class LocationDetails {
  final LocationFetchStatus status;
  final Position position;
  final String? address;
  final String? village;
  final String? locality;
  final String? administrativeArea;
  final String? postalCode;
  final String? country;

  const LocationDetails({
    required this.status,
    required this.position,
    required this.address,
    this.village,
    this.locality,
    this.administrativeArea,
    this.postalCode,
    this.country,
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
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationDetails(
        status: LocationFetchStatus.serviceDisabled,
        position: _fallbackPosition,
        address: null,
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return LocationDetails(
        status: LocationFetchStatus.permissionDenied,
        position: _fallbackPosition,
        address: null,
      );
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationDetails(
        status: LocationFetchStatus.permissionDeniedForever,
        position: _fallbackPosition,
        address: null,
      );
    }

    final position = await Geolocator.getCurrentPosition();
    String? address;
    String? village;
    String? locality;
    String? administrativeArea;
    String? postalCode;
    String? country;

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        village = _firstNonEmpty([
          placemark.subLocality,
          placemark.locality,
          placemark.subAdministrativeArea,
        ]);
        locality = _firstNonEmpty([
          placemark.locality,
          placemark.subAdministrativeArea,
        ]);
        administrativeArea = placemark.administrativeArea;
        postalCode = placemark.postalCode;
        country = placemark.country;
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

    return LocationDetails(
      status: LocationFetchStatus.success,
      position: position,
      address: address,
      village: village,
      locality: locality,
      administrativeArea: administrativeArea,
      postalCode: postalCode,
      country: country,
    );
  }

  static double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // in km
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  static final Position _fallbackPosition = Position(
    longitude: 0,
    latitude: 0,
    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
    accuracy: 0,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}
