import 'package:flutter_test/flutter_test.dart';
import 'package:mawa_app/models/user_profile.dart';
import 'package:mawa_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService Tests', () {
    late AuthService authService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      authService = AuthService(prefs);
    });

    test('Initial auth state should be unauthenticated and session inactive', () {
      expect(authService.hasSavedProfile, false);
      expect(authService.isSessionActive, false);
      expect(authService.currentUser, isNull);
    });

    test('signUp should save profile, activate session, and set current user', () async {
      const profile = UserProfile(
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'jane@example.com',
        password: 'password123',
      );

      final result = await authService.signUp(profile);

      expect(result, true);
      expect(authService.hasSavedProfile, true);
      expect(authService.isSessionActive, true);
      expect(authService.currentUser?.firstName, 'Jane');
      expect(authService.currentUser?.email, 'jane@example.com');
      expect(authService.currentUser?.city, 'Los Angeles');
    });

    test('login should succeed for correct credentials and fail for wrong password/email', () async {
      const profile = UserProfile(
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'jane@example.com',
        password: 'correctPassword',
      );

      await authService.signUp(profile);
      await authService.logout(); // End active session
      expect(authService.isSessionActive, false);

      // Wrong email
      final wrongEmailLogin = await authService.login(
        email: 'wrong@example.com',
        password: 'correctPassword',
      );
      expect(wrongEmailLogin, false);

      // Wrong password
      final wrongPasswordLogin = await authService.login(
        email: 'jane@example.com',
        password: 'wrongPassword',
      );
      expect(wrongPasswordLogin, false);

      // Correct email and password
      final correctLogin = await authService.login(
        email: 'jane@example.com',
        password: 'correctPassword',
      );
      expect(correctLogin, true);
      expect(authService.isSessionActive, true);
    });

    test('logout should deactivate session while retaining saved profile', () async {
      const profile = UserProfile(
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'jane@example.com',
        password: 'password123',
      );

      await authService.signUp(profile);
      expect(authService.isSessionActive, true);

      final logoutResult = await authService.logout();
      expect(logoutResult, true);
      expect(authService.isSessionActive, false);
      expect(authService.hasSavedProfile, true);
    });

    test('deleteAccount should clear saved profile and session completely', () async {
      const profile = UserProfile(
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'jane@example.com',
        password: 'password123',
      );

      await authService.signUp(profile);
      final deleteResult = await authService.deleteAccount();

      expect(deleteResult, true);
      expect(authService.hasSavedProfile, false);
      expect(authService.isSessionActive, false);
      expect(authService.currentUser, isNull);
    });
  });
}
