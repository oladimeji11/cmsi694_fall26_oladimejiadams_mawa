import 'package:geolocator/geolocator.dart';

/// Represents a seismic earthquake event returned by the USGS API.
class Earthquake {
  final double magnitude;
  final String place;
  final DateTime time;
  final double latitude;
  final double longitude;
  final double depth;
  final double distanceKm;
  final String ringTag;

  const Earthquake({
    required this.magnitude,
    required this.place,
    required this.time,
    required this.latitude,
    required this.longitude,
    required this.depth,
    required this.distanceKm,
    required this.ringTag,
  });

  /// Factory constructor to parse USGS GeoJSON feature item and calculate distance from user coordinates.
  factory Earthquake.fromUsgsJson(
      Map<String, dynamic> json, double userLat, double userLong) {
    final properties = json['properties'] as Map<String, dynamic>? ?? {};
    final geometry = json['geometry'] as Map<String, dynamic>? ?? {};
    final coordinates = geometry['coordinates'] as List<dynamic>? ?? [0.0, 0.0, 0.0];

    final quakeLong = (coordinates.isNotEmpty) ? (coordinates[0] as num).toDouble() : 0.0;
    final quakeLat = (coordinates.length > 1) ? (coordinates[1] as num).toDouble() : 0.0;
    final depth = (coordinates.length > 2) ? (coordinates[2] as num).toDouble() : 0.0;

    final distanceMeters = Geolocator.distanceBetween(userLat, userLong, quakeLat, quakeLong);
    final distanceKm = distanceMeters / 1000.0;

    String ringTag;
    if (distanceKm <= 2.5) {
      ringTag = 'Here';
    } else if (distanceKm <= 15.0) {
      ringTag = 'Nearby';
    } else {
      ringTag = 'City-wide';
    }

    final rawTime = properties['time'] as num?;
    final time = rawTime != null
        ? DateTime.fromMillisecondsSinceEpoch(rawTime.toInt(), isUtc: true).toLocal()
        : DateTime.now();

    return Earthquake(
      magnitude: (properties['mag'] as num?)?.toDouble() ?? 0.0,
      place: (properties['place'] as String?) ?? 'Unknown Location',
      time: time,
      latitude: quakeLat,
      longitude: quakeLong,
      depth: depth,
      distanceKm: distanceKm,
      ringTag: ringTag,
    );
  }
}
