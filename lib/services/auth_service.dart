import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

/// Service responsible for managing user account persistence, email & password authentication, and active session state.
class AuthService {
  static const String _userProfileKey = 'mawa_user_profile';
  static const String _sessionActiveKey = 'mawa_session_active';

  final SharedPreferences _prefs;
  UserProfile? _currentUser;

  AuthService(this._prefs) {
    _loadProfileFromStorage();
  }

  /// Returns the currently saved user profile, if available.
  UserProfile? get currentUser => _currentUser;

  /// Loads any previously saved profile from SharedPreferences.
  void _loadProfileFromStorage() {
    final jsonString = _prefs.getString(_userProfileKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        _currentUser = UserProfile.fromJson(jsonString);
      } catch (_) {
        _currentUser = null;
      }
    }
  }

  /// Checks if a saved user profile exists locally on the device.
  bool get hasSavedProfile => _currentUser != null;

  /// Checks if the user has an active logged-in session.
  bool get isSessionActive {
    final isActive = _prefs.getBool(_sessionActiveKey) ?? false;
    return hasSavedProfile && isActive;
  }

  /// Signs up a new user, persisting their profile to SharedPreferences and activating the session.
  Future<bool> signUp(UserProfile profile) async {
    final success = await _prefs.setString(_userProfileKey, profile.toJson());
    if (success) {
      _currentUser = profile;
      await _prefs.setBool(_sessionActiveKey, true);
    }
    return success;
  }

  /// Logs in a returning user by verifying their email and password against the saved profile.
  Future<bool> login({required String email, required String password}) async {
    if (_currentUser == null) {
      _loadProfileFromStorage();
    }

    if (_currentUser != null) {
      final emailMatches =
          _currentUser!.email.trim().toLowerCase() == email.trim().toLowerCase();
      final passwordMatches = _currentUser!.password == password;

      if (emailMatches && passwordMatches) {
        await _prefs.setBool(_sessionActiveKey, true);
        return true;
      }
    }
    return false;
  }

  /// Logs out the user by ending the active session while retaining their saved profile for future logins.
  Future<bool> logout() async {
    final success = await _prefs.setBool(_sessionActiveKey, false);
    return success;
  }

  /// Deletes the saved user profile and ends the session completely.
  Future<bool> deleteAccount() async {
    await _prefs.remove(_sessionActiveKey);
    final success = await _prefs.remove(_userProfileKey);
    if (success) {
      _currentUser = null;
    }
    return success;
  }

  /// Completely clears all saved local storage keys (profiles and session state).
  Future<bool> clearAllData() async {
    _currentUser = null;
    return await _prefs.clear();
  }
}
