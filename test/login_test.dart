import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mawa_app/models/user_profile.dart';
import 'package:mawa_app/screens/login_screen.dart';
import 'package:mawa_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthService authService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    authService = AuthService(prefs);

    // Seed a saved user profile
    await authService.signUp(const UserProfile(
      firstName: 'David',
      lastName: 'Miller',
      email: 'david@example.com',
      password: 'validPassword123',
    ));
    await authService.logout(); // End session to test login screen
  });

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  testWidgets('LoginScreen renders pre-filled email and password input',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(LoginScreen(authService: authService)),
    );

    expect(find.text('Welcome Back, David!'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Email Address'), findsOneWidget);
    expect(find.text('david@example.com'), findsOneWidget); // Pre-filled email
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Log In'), findsOneWidget);
  });

  testWidgets('LoginScreen displays error message on invalid email or password',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(LoginScreen(authService: authService)),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email Address'),
      'david@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'wrongPassword',
    );

    final loginButton = find.widgetWithText(ElevatedButton, 'Log In');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Invalid email or password. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('LoginScreen authenticates and navigates to HomeScreen on correct credentials',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(LoginScreen(authService: authService)),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email Address'),
      'david@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'validPassword123',
    );

    final loginButton = find.widgetWithText(ElevatedButton, 'Log In');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    expect(find.text('Hello, David!'), findsOneWidget);
    expect(find.text('david@example.com'), findsOneWidget);
    expect(authService.isSessionActive, true);
  });

  testWidgets('Tapping Sign Up navigates to SignUpScreen',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(LoginScreen(authService: authService)),
    );

    final signUpButton = find.widgetWithText(TextButton, 'Sign Up');
    await tester.ensureVisible(signUpButton);
    await tester.tap(signUpButton);
    await tester.pumpAndSettle();

    expect(find.text('Welcome to MAWA'), findsOneWidget);
  });
}
