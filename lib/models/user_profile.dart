import 'dart:convert';

/// Represents a user profile in MAWA.
/// Location fields default to US / California / Los Angeles for Sprint 1.
class UserProfile {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String country;
  final String state;
  final String city;

  const UserProfile({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    this.country = 'US',
    this.state = 'California',
    this.city = 'Los Angeles',
  });

  /// Converts the [UserProfile] instance to a Map for JSON serialization.
  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
      'country': country,
      'state': state,
      'city': city,
    };
  }

  /// Creates a [UserProfile] instance from a Map.
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      country: map['country'] ?? 'US',
      state: map['state'] ?? 'California',
      city: map['city'] ?? 'Los Angeles',
    );
  }

  /// Converts the [UserProfile] instance to a JSON string.
  String toJson() => json.encode(toMap());

  /// Creates a [UserProfile] instance from a JSON string.
  factory UserProfile.fromJson(String source) =>
      UserProfile.fromMap(json.decode(source));
}
