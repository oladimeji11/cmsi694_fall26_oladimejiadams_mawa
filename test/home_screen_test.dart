import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mawa_app/models/user_profile.dart';
import 'package:mawa_app/screens/home_screen.dart';
import 'package:mawa_app/services/auth_service.dart';
import 'package:mawa_app/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeLocationService extends LocationService {
  LocationPermission currentStatus;
  LocationPermission requestStatus;
  bool openSettingsCalled = false;

  FakeLocationService({
    this.currentStatus = LocationPermission.denied,
    this.requestStatus = LocationPermission.whileInUse,
  });

  @override
  Future<LocationPermission> checkPermission() async => currentStatus;

  @override
  Future<LocationPermission> requestPermission() async => requestStatus;

  @override
  Future<bool> openAppSettings() async {
    openSettingsCalled = true;
    return true;
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

    await tester.pumpWidget(
      buildTestableWidget(
        HomeScreen(
          userProfile: testProfile,
          authService: authService,
          locationService: fakeLocationService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Greeting
    expect(find.text('Hello, Jane!'), findsOneWidget);
    expect(
      find.text('Your location-aware environmental safety dashboard.'),
      findsOneWidget,
    );

    // Verify Profile Details
    expect(find.text('Account Profile'), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('jane.doe@example.com'), findsOneWidget);
    expect(find.text('Los Angeles, California, US'), findsOneWidget);
  });

  testWidgets('HomeScreen shows success SnackBar when location permission is granted',
      (WidgetTester tester) async {
    final fakeLocationService = FakeLocationService(
      currentStatus: LocationPermission.denied,
      requestStatus: LocationPermission.whileInUse,
    );

    await tester.pumpWidget(
      buildTestableWidget(
        HomeScreen(
          userProfile: testProfile,
          authService: authService,
          locationService: fakeLocationService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Location permission granted.'), findsOneWidget);
  });

  testWidgets('HomeScreen shows explanatory SnackBar when location permission is denied',
      (WidgetTester tester) async {
    final fakeLocationService = FakeLocationService(
      currentStatus: LocationPermission.denied,
      requestStatus: LocationPermission.denied,
    );

    await tester.pumpWidget(
      buildTestableWidget(
        HomeScreen(
          userProfile: testProfile,
          authService: authService,
          locationService: fakeLocationService,
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

    await tester.pumpWidget(
      buildTestableWidget(
        HomeScreen(
          userProfile: testProfile,
          authService: authService,
          locationService: fakeLocationService,
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

    await tester.pumpWidget(
      buildTestableWidget(
        HomeScreen(
          userProfile: testProfile,
          authService: authService,
          locationService: fakeLocationService,
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
