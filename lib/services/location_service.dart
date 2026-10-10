import 'package:geolocator/geolocator.dart';

/// Service responsible for handling Android runtime location permissions via Geolocator.
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
