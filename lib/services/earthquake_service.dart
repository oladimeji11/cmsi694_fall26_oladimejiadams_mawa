import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/earthquake.dart';

/// Service responsible for fetching seismic earthquake data from the USGS API.
class EarthquakeService {
  final http.Client _client;

  EarthquakeService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches recent earthquakes within 50 km, in the last 7 days, with magnitude >= 2.5, sorted closest first.
  Future<List<Earthquake>> fetchRecentEarthquakes(
      double latitude, double longitude) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
      final url = Uri.parse(
        'https://earthquake.usgs.gov/fdsnws/event/1/query?format=geojson&latitude=${latitude.toStringAsFixed(4)}&longitude=${longitude.toStringAsFixed(4)}&maxradiuskm=50&minmagnitude=2.5&starttime=$sevenDaysAgo',
      );

      final response = await _client.get(url, headers: {
        'Accept': 'application/json',
      }).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode != 200) {
        throw const FormatException('Unable to fetch earthquake data');
      }

      final jsonMap = json.decode(response.body) as Map<String, dynamic>;
      final features = jsonMap['features'] as List<dynamic>?;

      if (features == null || features.isEmpty) {
        return [];
      }

      final earthquakes = features
          .map((f) => Earthquake.fromUsgsJson(f as Map<String, dynamic>, latitude, longitude))
          .toList();

      // Sort earthquakes by distance ascending (closest first)
      earthquakes.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      return earthquakes;
    } on SocketException catch (_) {
      throw Exception('Unable to fetch earthquake data');
    } on http.ClientException catch (_) {
      throw Exception('Unable to fetch earthquake data');
    } catch (e) {
      debugPrint('MAWA USGS Earthquake API Error: $e');
      throw Exception('Unable to fetch earthquake data');
    }
  }
}
