import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Service for requesting location permission, reading GPS coordinates,
/// and reverse-geocoding coordinates to street addresses.
class LocationService {
  /// Checks the current location permission status without prompting.
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Prompts the Android OS system location consent dialog.
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Opens the device App Settings screen for the MAWA application.
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Checks if system location services (GPS hardware) are enabled on the device.
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Reads current GPS latitude and longitude coordinates if permission is granted and location services are enabled.
  Future<Position?> getCurrentPosition() async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    final permission = await checkPermission();
    if (!isGranted(permission)) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Reverse-geocodes GPS coordinates into a human-readable Placemark (street, city, state, postal code).
  Future<Placemark?> getPlacemarkFromCoordinates(
      double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        return placemarks.first;
      }
      return null;
    } catch (_) {
      return null; // Graceful fallback on network/geocoding error
    }
  }

  /// Returns true if the user granted location permission (while in use or always).
  bool isGranted(LocationPermission status) {
    return status == LocationPermission.whileInUse ||
        status == LocationPermission.always;
  }

  /// Returns true if location permission was denied (temporarily or permanently).
  bool isDenied(LocationPermission status) {
    return status == LocationPermission.denied ||
        status == LocationPermission.deniedForever;
  }

  /// Returns true if location permission was permanently denied by the user.
  bool isPermanentlyDenied(LocationPermission status) {
    return status == LocationPermission.deniedForever;
  }
}
