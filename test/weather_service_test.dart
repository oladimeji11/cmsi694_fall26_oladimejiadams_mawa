import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mawa_app/models/weather_alert.dart';
import 'package:mawa_app/models/weather_info.dart';
import 'package:mawa_app/services/weather_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WeatherInfo Model Tests', () {
    test('fromNwsJson parses all metrics correctly', () {
      final json = {
        'temperature': 72,
        'temperatureUnit': 'F',
        'shortForecast': 'Sunny',
        'windSpeed': '7 mph',
        'windDirection': 'SW',
        'relativeHumidity': {'value': 45},
        'probabilityOfPrecipitation': {'value': 20},
      };

      final info = WeatherInfo.fromNwsJson(json);

      expect(info.temperature, 72);
      expect(info.temperatureUnit, 'F');
      expect(info.shortForecast, 'Sunny');
      expect(info.windSpeed, '7 mph');
      expect(info.windDirection, 'SW');
      expect(info.humidity, 45);
      expect(info.precipitationChance, 20);
    });
  });

  group('WeatherAlert Model Tests', () {
    test('fromNwsJson parses alert properties correctly', () {
      final json = {
        'properties': {
          'event': 'Excessive Heat Warning',
          'severity': 'Extreme',
          'areaDesc': 'Los Angeles County Inland Coast',
          'expires': '2026-10-27T20:00:00-07:00',
          'headline': 'Excessive Heat Warning issued October 26...',
        }
      };

      final alert = WeatherAlert.fromNwsJson(json);

      expect(alert.event, 'Excessive Heat Warning');
      expect(alert.severity, 'Extreme');
      expect(alert.areaDesc, 'Los Angeles County Inland Coast');
      expect(alert.expires, isNotNull);
      expect(alert.headline, 'Excessive Heat Warning issued October 26...');
    });
  });

  group('WeatherService Pipeline Tests', () {
    test('fetchCurrentWeather executes 2-step NWS pipeline successfully', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('api.weather.gov/points')) {
          return http.Response(
            '{"properties": {"forecastHourly": "https://api.weather.gov/gridpoints/LOX/154,44/forecast/hourly"}}',
            200,
          );
        } else if (request.url.toString().contains('forecast/hourly')) {
          return http.Response(
            '{"properties": {"periods": [{"temperature": 75, "temperatureUnit": "F", "shortForecast": "Partly Cloudy", "windSpeed": "8 mph", "windDirection": "NW", "relativeHumidity": {"value": 50}, "probabilityOfPrecipitation": {"value": 10}}]}}',
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final weatherService = WeatherService(client: mockClient);
      final weather = await weatherService.fetchCurrentWeather(34.0522, -118.2437);

      expect(weather.temperature, 75);
      expect(weather.shortForecast, 'Partly Cloudy');
      expect(weather.windSpeed, '8 mph');
      expect(weather.humidity, 50);
      expect(weather.precipitationChance, 10);
    });

    test('fetchActiveAlerts parses active NWS alerts list correctly', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('api.weather.gov/alerts/active')) {
          return http.Response(
            '{"features": [{"properties": {"event": "Excessive Heat Warning", "severity": "Extreme", "areaDesc": "Los Angeles County Coast"}}]}',
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final weatherService = WeatherService(client: mockClient);
      final alerts = await weatherService.fetchActiveAlerts(34.0522, -118.2437);

      expect(alerts.length, 1);
      expect(alerts.first.event, 'Excessive Heat Warning');
      expect(alerts.first.severity, 'Extreme');
      expect(alerts.first.areaDesc, 'Los Angeles County Coast');
    });

    test('fetchActiveAlerts returns empty list when no alerts exist', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"features": []}', 200);
      });

      final weatherService = WeatherService(client: mockClient);
      final alerts = await weatherService.fetchActiveAlerts(34.0522, -118.2437);

      expect(alerts, isEmpty);
    });

    test('fetchCurrentWeather throws Exception on HTTP 404 or failure', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      final weatherService = WeatherService(client: mockClient);

      expect(
        () async => await weatherService.fetchCurrentWeather(0.0, 0.0),
        throwsA(isA<Exception>()),
      );
    });
  });
}
