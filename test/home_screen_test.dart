import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mawa_app/models/user_profile.dart';
import 'package:mawa_app/screens/home_screen.dart';
import 'package:mawa_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    await tester.pumpWidget(
      buildTestableWidget(
        HomeScreen(userProfile: testProfile, authService: authService),
      ),
    );

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

    // Verify Placeholder Card is removed
    expect(find.text('Environmental Briefings & Hazards'), findsNothing);
  });

  testWidgets('Tapping Logout ends session and navigates to LoginScreen',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        HomeScreen(userProfile: testProfile, authService: authService),
      ),
    );

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
