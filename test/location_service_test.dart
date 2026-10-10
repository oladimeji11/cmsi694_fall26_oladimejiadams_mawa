import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mawa_app/services/location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocationService locationService;

  setUp(() {
    locationService = LocationService();
  });

  group('LocationService Logic Tests', () {
    test('isGranted returns true for whileInUse and always permissions', () {
      expect(locationService.isGranted(LocationPermission.whileInUse), true);
      expect(locationService.isGranted(LocationPermission.always), true);
      expect(locationService.isGranted(LocationPermission.denied), false);
      expect(locationService.isGranted(LocationPermission.deniedForever), false);
    });

    test('isDenied returns true for denied and deniedForever permissions', () {
      expect(locationService.isDenied(LocationPermission.denied), true);
      expect(locationService.isDenied(LocationPermission.deniedForever), true);
      expect(locationService.isDenied(LocationPermission.whileInUse), false);
      expect(locationService.isDenied(LocationPermission.always), false);
    });

    test('isPermanentlyDenied returns true only for deniedForever permission', () {
      expect(locationService.isPermanentlyDenied(LocationPermission.deniedForever), true);
      expect(locationService.isPermanentlyDenied(LocationPermission.denied), false);
      expect(locationService.isPermanentlyDenied(LocationPermission.whileInUse), false);
    });
  });
}
