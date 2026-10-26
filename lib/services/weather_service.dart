import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/weather_info.dart';

/// Service responsible for fetching weather metrics from the National Weather Service (NWS) API.
class WeatherService {
  static const Map<String, String> _headers = {
    'User-Agent': '(MAWA Environmental App, contact@mawa.edu)',
    'Accept': 'application/geo+json',
  };

  final http.Client _client;

  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches current weather information for the given GPS latitude and longitude via the NWS 2-step pipeline.
  Future<WeatherInfo> fetchCurrentWeather(double latitude, double longitude) async {
    try {
      // Step 1: Query NWS Points endpoint to retrieve location metadata and forecast URLs
      final pointsUrl = Uri.parse(
        'https://api.weather.gov/points/${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}',
      );
      
      final pointsResponse = await _client.get(pointsUrl, headers: _headers).timeout(
            const Duration(seconds: 10),
          );

      if (pointsResponse.statusCode != 200) {
        throw const FormatException('Unable to fetch weather');
      }

      final pointsJson = json.decode(pointsResponse.body) as Map<String, dynamic>;
      final forecastHourlyUrl = pointsJson['properties']?['forecastHourly'] as String?;

      if (forecastHourlyUrl == null || forecastHourlyUrl.isEmpty) {
        throw const FormatException('Unable to fetch weather');
      }

      // Step 2: Query the forecastHourly endpoint to retrieve current period weather metrics
      final forecastUrl = Uri.parse(forecastHourlyUrl);
      final forecastResponse = await _client.get(forecastUrl, headers: _headers).timeout(
            const Duration(seconds: 10),
          );

      if (forecastResponse.statusCode != 200) {
        throw const FormatException('Unable to fetch weather');
      }

      final forecastJson = json.decode(forecastResponse.body) as Map<String, dynamic>;
      final periods = forecastJson['properties']?['periods'] as List<dynamic>?;

      if (periods == null || periods.isEmpty) {
        throw const FormatException('Unable to fetch weather');
      }

      return WeatherInfo.fromNwsJson(periods[0] as Map<String, dynamic>);
    } on SocketException catch (_) {
      throw Exception('Unable to fetch weather');
    } on http.ClientException catch (_) {
      throw Exception('Unable to fetch weather');
    } catch (e) {
      debugPrint('MAWA NWS Weather API Error: $e');
      throw Exception('Unable to fetch weather');
    }
  }
}
