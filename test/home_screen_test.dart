import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mawa_app/models/user_profile.dart';
import 'package:mawa_app/models/weather_alert.dart';
import 'package:mawa_app/models/weather_info.dart';
import 'package:mawa_app/screens/home_screen.dart';
import 'package:mawa_app/services/auth_service.dart';
import 'package:mawa_app/services/location_service.dart';
import 'package:mawa_app/services/weather_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeLocationService extends LocationService {
  LocationPermission currentStatus;
  LocationPermission requestStatus;
  bool gpsEnabled;
  bool openSettingsCalled = false;
  bool getCurrentPositionCalled = false;
  Placemark? mockPlacemark;

  FakeLocationService({
    this.currentStatus = LocationPermission.denied,
    this.requestStatus = LocationPermission.whileInUse,
    this.gpsEnabled = true,
    this.mockPlacemark,
  });

  @override
  Future<bool> isLocationServiceEnabled() async => gpsEnabled;

  @override
  Future<LocationPermission> checkPermission() async => currentStatus;

  @override
  Future<LocationPermission> requestPermission() async => requestStatus;

  @override
  Future<Position?> getCurrentPosition() async {
    getCurrentPositionCalled = true;
    if (!gpsEnabled || !isGranted(currentStatus)) {
      return null;
    }
    return Position(
      longitude: -118.2437,
      latitude: 34.0522,
      timestamp: DateTime.now(),
      accuracy: 10.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
  }

  @override
  Future<Placemark?> getPlacemarkFromCoordinates(
      double latitude, double longitude) async {
    return mockPlacemark;
  }

  @override
  Future<bool> openAppSettings() async {
    openSettingsCalled = true;
    return true;
  }
}

class FakeWeatherService extends WeatherService {
  final WeatherInfo? mockWeatherInfo;
  final List<WeatherAlert>? mockAlerts;
  final bool shouldFail;

  FakeWeatherService({
    this.mockWeatherInfo,
    this.mockAlerts,
    this.shouldFail = false,
  });

  @override
  Future<WeatherInfo> fetchCurrentWeather(double latitude, double longitude) async {
    if (shouldFail) {
      throw Exception('Unable to fetch weather');
    }
    return mockWeatherInfo ??
        const WeatherInfo(
          temperature: 72,
          temperatureUnit: 'F',
          shortForecast: 'Sunny',
          windSpeed: '7 mph',
          windDirection: 'SW',
          humidity: 45,
          precipitationChance: 20,
        );
  }

  @override
  Future<List<WeatherAlert>> fetchActiveAlerts(
      double latitude, double longitude) async {
    if (shouldFail) {
      throw Exception('Unable to fetch active alerts');
    }
    return mockAlerts ?? [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthService authService;
  const testProfile = UserProfile(
    firstName: 'Jane',
    lastName: 'Doe',
    email: 'jane.doe@example.com',
    password: 'password123',
    country: 'US',
    state: 'California',
    city: 'Los Angeles',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    authService = AuthService(prefs);
    await authService.signUp(testProfile);
  });

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  testWidgets('HomeScreen renders Hello greeting and Account Profile details',
      (WidgetTester tester) async {
    final fakeLocationService = FakeLocationService(
      currentStatus: LocationPermission.whileInUse,
    );
    final fakeWeatherService = FakeWeatherService();

    await tester.pumpWidget(
      buildTestableWidget(
        HomeScreen(
          userProfile: testProfile,
          authService: authService,
          locationService: fakeLocationService,
          weatherService: fakeWeatherService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Greeting
    expect(find.text('Hello, Jane!'), findsOneWidget);
    expect(
      find.text('Dashboard'),
      findsOneWidget,
    );

    // Verify Profile Details
    expect(find.text('Account Profile'), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('jane.doe@example.com'), findsOneWidget);
    expect(find.text('Los Angeles, California, US'), findsOneWidget);
    expect(fakeLocationService.getCurrentPositionCalled, true);
  });

  testWidgets('HomeScreen renders Weather Card with temperature, condition, wind, humidity, precipitation',
      (WidgetTester tester) async {
    final fakeLocationService = FakeLocationService(
      currentStatus: LocationPermission.whileInUse,
    );
    final fakeWeatherService = FakeWeatherService(
      mockWeatherInfo: const WeatherInfo(
        temperature: 75,
        temperatureUnit: 'F',
        shortForecast: 'Partly Cloudy',
        windSpeed: '8 mph',
        windDirection: 'NW',
        humidity: 50,
        precipitationChance: 10,
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        HomeScreen(
          userProfile: testProfile,
          authService: authService,
          locationService: fakeLocationService,
          weatherService: fakeWeatherService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Current Weather'), findsOneWidget);
    expect(find.text('75°F'), findsOneWidget);
    expect(find.text('Partly Cloudy'), findsOneWidget);
    expect(find.text('8 mph NW'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('10%'), findsOneWidget);
  });

  testWidgets('HomeScreen renders Active Weather Alerts Card with No active alerts message when empty',
      (WidgetTester tester) async {
    final fakeLocationService = FakeLocationService(
      currentStatus: LocationPermission.whileInUse,
    );
    final fakeWeatherService = FakeWeatherService(mockAlerts: []);

    await tester.pumpWidget(
      buildTestableWidget(
        HomeScreen(
          userProfile: testProfile,
          authService: authService,
          locationService: fakeLocationService,
          weatherService: fakeWeatherService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Active Weather Alerts'), findsOneWidget);
    expect(find.text('No active alerts for your area'), findsOneWidget);
  });

  testWidgets('HomeScreen renders Active Weather Alerts Card with City-wide and for your information badges when alerts exist',
      (WidgetTester tester) async {
    final fakeLocationService = FakeLocationService(
      currentStatus: LocationPermission.whileInUse,
    );
    final fakeWeatherService = FakeWeatherService(
      mockAlerts: [
        const WeatherAlert(
          event: 'Excessive Heat Warning',
          severity: 'Extreme',
          areaDesc: 'Los Angeles County Coast',
        ),
      ],
    );

    await tester.pumpWidget(
      buildTestableWidget(
        HomeScreen(
          userProfile: testProfile,
          authService: authService,
          locationService: fakeLocationService,
          weatherService: fakeWeatherService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Active Weather Alerts'), findsOneWidget);
    expect(find.text('City-wide'), findsOneWidget);
    expect(find.text('for your information'), findsOneWidget);
    expect(find.text('Excessive Heat Warning'), findsOneWidget);
    expect(find.text('Extreme'), findsOneWidget);
    expect(find.text('Area: Los Angeles County Coast'), findsOneWidget);
  });

  testWidgets('HomeScreen renders error message when weather API fails',
      (WidgetTester tester) async {
    final fakeLocationService = FakeLocationService(
      currentStatus: LocationPermission.whileInUse,
    );
    final fakeWeatherService = FakeWeatherService(shouldFail: true);

    await tester.pumpWidget(
      buildTestableWidget(
        HomeScreen(
          userProfile: testProfile,
          authService: authService,
          locationService: fakeLocationService,
          weatherService: fakeWeatherService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to fetch weather'), findsOneWidget);
    expect(find.text('Unable to fetch active alerts'), findsOneWidget);
  });

  testWidgets('HomeScreen displays exact street address, city, state, and zip code from reverse-geocoding',
      (WidgetTester tester) async {
    final fakeLocationService = FakeLocationService(
      currentStatus: LocationPermission.whileInUse,
      mockPlacemark: Placemark(
        street: '1 LMU Drive',
        locality: 'Los Angeles',
        administrativeArea: 'CA',
        postalCode: '90045',
      ),
    );
    final fakeWeatherService = FakeWeatherService();

    await tester.pumpWidget(
      buildTestableWidget(
        HomeScreen(
          userProfile: testProfile,
          authService: authService,
          locationService: fakeLocationService,
          weatherService: fakeWeatherService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 LMU Drive, Los Angeles, CA, 90045'), findsOneWidget);
  });

  testWidgets('HomeScreen shows SnackBar when location services are disabled on device',
      (WidgetTester tester) async {
    final fakeLocationService = FakeLocationService(
      gpsEnabled: false,
    );
    final fakeWeatherService = FakeWeatherService();

    await tester.pumpWidget(
      buildTestableWidget(
        HomeScreen(
          userProfile: testProfile,
          authService: authService,
          locationService: fakeLocationService,
          weatherService: fakeWeatherService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Location services are disabled. Please enable GPS in device settings.'),
      findsOneWidget,
    );
    expect(fakeLocationService.getCurrentPositionCalled, false);
  });

  testWidgets('HomeScreen shows success SnackBar when location permission is granted',
      (WidgetTester tester) async {
    final fakeLocationService = FakeLocationService(
      currentStatus: LocationPermission.denied,
      requestStatus: LocationPermission.whileInUse,
    );
    final fakeWeatherService = FakeWeatherService();

    await tester.pumpWidget(
      buildTestableWidget(
        HomeScreen(
          userProfile: testProfile,
          authService: authService,
          locationService: fakeLocationService,
          weatherService: fakeWeatherService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Location permission granted.'), findsOneWidget);
    expect(fakeLocationService.getCurrentPositionCalled, true);
  });

  testWidgets('HomeScreen shows explanatory SnackBar when location permission is denied',
      (WidgetTester tester) async {
    final fakeLocationService = FakeLocationService(
      currentStatus: LocationPermission.denied,
      requestStatus: LocationPermission.denied,
    );
    final fakeWeatherService = FakeWeatherService();

    await tester.pumpWidget(
      buildTestableWidget(
        HomeScreen(
          userProfile: testProfile,
          authService: authService,
          locationService: fakeLocationService,
          weatherService: fakeWeatherService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Location permission is needed to show local hazard briefings for your area.'),
      findsOneWidget,
    );
  });

  testWidgets('HomeScreen shows Blocked Banner and Open App Settings button when permanently denied',
      (WidgetTester tester) async {
    final fakeLocationService = FakeLocationService(
      currentStatus: LocationPermission.deniedForever,
    );
    final fakeWeatherService = FakeWeatherService();

    await tester.pumpWidget(
      buildTestableWidget(
        HomeScreen(
          userProfile: testProfile,
          authService: authService,
          locationService: fakeLocationService,
          weatherService: fakeWeatherService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Location Access Blocked banner and button
    expect(find.text('Location Access Blocked'), findsOneWidget);
    expect(
      find.text('Location access is blocked. Please enable location permissions in system settings.'),
      findsOneWidget,
    );
    final settingsButton = find.widgetWithText(ElevatedButton, 'Open App Settings');
    expect(settingsButton, findsOneWidget);

    // Tap button to verify openAppSettings is invoked
    await tester.tap(settingsButton);
    await tester.pumpAndSettle();
    expect(fakeLocationService.openSettingsCalled, true);
  });

  testWidgets('Tapping Logout ends session and navigates to LoginScreen',
      (WidgetTester tester) async {
    final fakeLocationService = FakeLocationService(
      currentStatus: LocationPermission.whileInUse,
    );
    final fakeWeatherService = FakeWeatherService();

    await tester.pumpWidget(
      buildTestableWidget(
        HomeScreen(
          userProfile: testProfile,
          authService: authService,
          locationService: fakeLocationService,
          weatherService: fakeWeatherService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(authService.isSessionActive, true);

    // Tap Logout button
    final logoutButton = find.byIcon(Icons.logout);
    await tester.tap(logoutButton);
    await tester.pumpAndSettle();

    // Verify session is ended and LoginScreen is shown
    expect(authService.isSessionActive, false);
    expect(find.text('Welcome Back, Jane!'), findsOneWidget);
  });
}
