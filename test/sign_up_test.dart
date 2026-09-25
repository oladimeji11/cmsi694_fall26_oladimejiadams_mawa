import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mawa_app/screens/sign_up_screen.dart';
import 'package:mawa_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthService authService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    authService = AuthService(prefs);
  });

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  testWidgets('SignUpScreen renders header, input fields, and location dropdowns',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(SignUpScreen(authService: authService)),
    );

    expect(find.text('Welcome to MAWA'), findsOneWidget);
    expect(
      find.text('MAWA is a location-aware environmental intelligence app.'),
      findsOneWidget,
    );

    expect(find.widgetWithText(TextFormField, 'First Name'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Last Name'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Email Address'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);

    // Location dropdowns
    expect(find.text('United States (US)'), findsOneWidget);
    expect(find.text('California'), findsOneWidget);
    expect(find.text('Los Angeles'), findsOneWidget);
  });

  testWidgets('SignUpScreen shows validation errors when submitting empty form',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(SignUpScreen(authService: authService)),
    );

    final signUpButton = find.widgetWithText(ElevatedButton, 'Sign Up');

    // Tap the Sign Up button
    await tester.ensureVisible(signUpButton);
    await tester.tap(signUpButton);
    await tester.pumpAndSettle();

    // Verify inline errors appear
    expect(find.text('Please enter your first name'), findsOneWidget);
    expect(find.text('Please enter your last name'), findsOneWidget);
    expect(find.text('Please enter your email address'), findsOneWidget);
    expect(find.text('Please enter a password'), findsOneWidget);
  });

  testWidgets(
      'SignUpScreen creates user and navigates to HomeScreen on valid input',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(SignUpScreen(authService: authService)),
    );

    // Fill in valid details
    await tester.enterText(
        find.widgetWithText(TextFormField, 'First Name'), 'Alex');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Last Name'), 'Smith');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email Address'), 'alex@example.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'secure123');

    // Tap submit
    final signUpButton = find.widgetWithText(ElevatedButton, 'Sign Up');
    await tester.ensureVisible(signUpButton);
    await tester.tap(signUpButton);
    await tester.pumpAndSettle();

    // Verify user is navigated to HomeScreen with hello message and email displayed
    expect(find.text('Hello, Alex!'), findsOneWidget);
    expect(find.text('alex@example.com'), findsOneWidget);
    expect(find.text('Los Angeles, California, US'), findsOneWidget);
    expect(authService.hasSavedProfile, true);
    expect(authService.currentUser?.firstName, 'Alex');
    expect(authService.currentUser?.email, 'alex@example.com');
  });
}
