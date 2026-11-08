import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mawa_app/models/earthquake.dart';
import 'package:mawa_app/services/earthquake_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const userLat = 34.0522;
  const userLong = -118.2437;

  group('Earthquake Model Ring Tagging Tests', () {
    test('fromUsgsJson classifies quake within 2.5 km as Here', () {
      // Coordinates ~1.5 km away from (34.0522, -118.2437)
      final json = {
        'properties': {
          'mag': 3.1,
          'place': '1 km E of Los Angeles, CA',
          'time': 1729800000000,
        },
        'geometry': {
          'coordinates': [-118.2300, 34.0522, 5.0],
        }
      };

      final quake = Earthquake.fromUsgsJson(json, userLat, userLong);

      expect(quake.magnitude, 3.1);
      expect(quake.ringTag, 'Here');
      expect(quake.distanceKm, lessThanOrEqualTo(2.5));
    });

    test('fromUsgsJson classifies quake between 2.5 km and 15 km as Nearby', () {
      // Coordinates ~8 km away from (34.0522, -118.2437)
      final json = {
        'properties': {
          'mag': 2.8,
          'place': '8 km NW of Los Angeles, CA',
          'time': 1729800000000,
        },
        'geometry': {
          'coordinates': [-118.3200, 34.1000, 7.0],
        }
      };

      final quake = Earthquake.fromUsgsJson(json, userLat, userLong);

      expect(quake.ringTag, 'Nearby');
      expect(quake.distanceKm, greaterThan(2.5));
      expect(quake.distanceKm, lessThanOrEqualTo(15.0));
    });

    test('fromUsgsJson classifies quake over 15 km as City-wide', () {
      // Coordinates ~30 km away from (34.0522, -118.2437)
      final json = {
        'properties': {
          'mag': 3.5,
          'place': '30 km S of Los Angeles, CA',
          'time': 1729800000000,
        },
        'geometry': {
          'coordinates': [-118.2437, 33.7800, 10.0],
        }
      };

      final quake = Earthquake.fromUsgsJson(json, userLat, userLong);

      expect(quake.ringTag, 'City-wide');
      expect(quake.distanceKm, greaterThan(15.0));
    });
  });

  group('EarthquakeService API Tests', () {
    test('fetchRecentEarthquakes parses and sorts quakes closest first', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('earthquake.usgs.gov')) {
          return http.Response(
            '''{
              "features": [
                {
                  "properties": {"mag": 4.0, "place": "Far Quake", "time": 1729800000000},
                  "geometry": {"coordinates": [-118.5000, 34.2000, 10.0]}
                },
                {
                  "properties": {"mag": 2.9, "place": "Close Quake", "time": 1729800000000},
                  "geometry": {"coordinates": [-118.2450, 34.0530, 2.0]}
                }
              ]
            }''',
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = EarthquakeService(client: mockClient);
      final quakes = await service.fetchRecentEarthquakes(userLat, userLong);

      expect(quakes.length, 2);
      expect(quakes.first.place, 'Close Quake');
      expect(quakes.last.place, 'Far Quake');
      expect(quakes.first.distanceKm, lessThan(quakes.last.distanceKm));
    });

    test('fetchRecentEarthquakes returns empty list when no quakes returned', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"features": []}', 200);
      });

      final service = EarthquakeService(client: mockClient);
      final quakes = await service.fetchRecentEarthquakes(userLat, userLong);

      expect(quakes, isEmpty);
    });

    test('fetchRecentEarthquakes throws Exception on HTTP 404 or failure', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = EarthquakeService(client: mockClient);

      expect(
        () async => await service.fetchRecentEarthquakes(userLat, userLong),
        throwsA(isA<Exception>()),
      );
    });
  });
}
