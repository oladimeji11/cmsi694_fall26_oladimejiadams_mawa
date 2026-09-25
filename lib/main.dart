import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/sign_up_screen.dart';
import 'services/auth_service.dart';

void main() async {
  // Ensure Flutter engine bindings are initialized before calling async platform channels.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences for local storage persistence.
  final prefs = await SharedPreferences.getInstance();
  final authService = AuthService(prefs);

  runApp(MyApp(authService: authService));
}

class MyApp extends StatelessWidget {
  final AuthService authService;

  const MyApp({super.key, required this.authService});

  Widget _getInitialHomeScreen() {
    if (authService.isSessionActive && authService.currentUser != null) {
      return HomeScreen(
        userProfile: authService.currentUser!,
        authService: authService,
      );
    } else if (authService.hasSavedProfile) {
      return LoginScreen(authService: authService);
    } else {
      return SignUpScreen(authService: authService);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MAWA - Environmental Intelligence',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: _getInitialHomeScreen(),
    );
  }
}
