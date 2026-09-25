import 'package:flutter_test/flutter_test.dart';
import 'package:mawa_app/main.dart';
import 'package:mawa_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MyApp smoke test launches SignUpScreen when unauthenticated',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final authService = AuthService(prefs);

    await tester.pumpWidget(MyApp(authService: authService));

    expect(find.text('Welcome to MAWA'), findsOneWidget);
    expect(
        find.text('MAWA is a location-aware environmental intelligence app.'),
        findsOneWidget);
  });
}
