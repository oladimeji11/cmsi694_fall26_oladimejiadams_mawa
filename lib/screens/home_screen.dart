import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_profile.dart';
import '../models/weather_info.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';
import 'login_screen.dart';

/// The Home landing screen dashboard displaying user greeting, current weather metrics,
/// account profile details, and location permission management.
class HomeScreen extends StatefulWidget {
  final UserProfile userProfile;
  final AuthService authService;
  final LocationService? locationService;
  final WeatherService? weatherService;

  const HomeScreen({
    super.key,
    required this.userProfile,
    required this.authService,
    this.locationService,
    this.weatherService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final LocationService _locationService;
  late final WeatherService _weatherService;

  bool _isPermanentlyDenied = false;
  String? _geocodedAddress;

  WeatherInfo? _weatherInfo;
  bool _isWeatherLoading = false;
  String? _weatherError;

  @override
  void initState() {
    super.initState();
    _locationService = widget.locationService ?? LocationService();
    _weatherService = widget.weatherService ?? WeatherService();

    // Register lifecycle observer to listen for app resume events
    WidgetsBinding.instance.addObserver(this);

    // Trigger location permission check and weather fetch after the first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRequestLocationPermission();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check location permission when returning from System Settings to the app foreground
    if (state == AppLifecycleState.resumed) {
      _checkAndRequestLocationPermission();
    }
  }

  Future<void> _fetchWeather(double latitude, double longitude) async {
    setState(() {
      _isWeatherLoading = true;
      _weatherError = null;
    });

    try {
      final info = await _weatherService.fetchCurrentWeather(latitude, longitude);
      if (mounted) {
        setState(() {
          _weatherInfo = info;
          _isWeatherLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _weatherError = 'Unable to fetch weather';
          _isWeatherLoading = false;
        });
      }
    }
  }

  Future<void> _fetchAndReverseGeocodeLocation(Position position) async {
    debugPrint(
      'MAWA GPS Location: Latitude ${position.latitude}, Longitude ${position.longitude}',
    );

    // Trigger NWS 2-Step Weather API fetch
    _fetchWeather(position.latitude, position.longitude);

    try {
      final placemark = await _locationService.getPlacemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (mounted && placemark != null) {
        final subThoroughfare = placemark.subThoroughfare ?? '';
        final thoroughfare = placemark.thoroughfare ?? placemark.street ?? '';
        final name = (placemark.name != null &&
                placemark.name != placemark.locality &&
                placemark.name != placemark.subAdministrativeArea &&
                placemark.name != placemark.country)
            ? placemark.name!
            : '';

        String street = (subThoroughfare.isNotEmpty &&
                !thoroughfare.contains(subThoroughfare))
            ? '$subThoroughfare $thoroughfare'
            : thoroughfare;

        if (street.isEmpty && name.isNotEmpty) {
          street = name;
        }

        final subLocality = (placemark.subLocality != null &&
                placemark.subLocality != placemark.locality)
            ? placemark.subLocality!
            : '';
        final city = placemark.locality ??
            placemark.subAdministrativeArea ??
            widget.userProfile.city;
        final state = placemark.administrativeArea ?? widget.userProfile.state;
        final postalCode = placemark.postalCode ?? '';

        final formattedParts = [
          if (street.isNotEmpty) street,
          if (subLocality.isNotEmpty) subLocality,
          if (city.isNotEmpty) city,
          if (state.isNotEmpty) state,
          if (postalCode.isNotEmpty) postalCode,
        ];

        if (formattedParts.isNotEmpty) {
          final exactAddress = formattedParts.join(', ');
          debugPrint('MAWA Exact Address Obtained: $exactAddress');
          setState(() {
            _geocodedAddress = exactAddress;
          });
        }
      }
    } catch (e) {
      debugPrint('MAWA Reverse Geocoding Exception: $e');
    }
  }

  Future<void> _checkAndRequestLocationPermission() async {
    try {
      // 1. Check if location services (GPS hardware) are enabled on the device
      final isGpsEnabled = await _locationService.isLocationServiceEnabled();
      if (!isGpsEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location services are disabled. Please enable GPS in device settings.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // 2. Check current location permission status
      final currentStatus = await _locationService.checkPermission();

      // If permission is already granted, clear permanently denied banner and read GPS
      if (_locationService.isGranted(currentStatus)) {
        if (mounted && _isPermanentlyDenied) {
          setState(() {
            _isPermanentlyDenied = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission granted.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          setState(() {
            _isPermanentlyDenied = false;
          });
        }

        // Read GPS coordinates and fetch weather/address
        final position = await _locationService.getCurrentPosition();
        if (position != null) {
          await _fetchAndReverseGeocodeLocation(position);
        }
        return;
      }

      // If permission is permanently denied, update UI state to show blocked banner
      if (_locationService.isPermanentlyDenied(currentStatus)) {
        if (mounted) {
          setState(() {
            _isPermanentlyDenied = true;
          });
        }
        return;
      }

      // Prompt system location permission dialog for unrequested / denied status
      final requestedStatus = await _locationService.requestPermission();

      if (!mounted) return;

      if (_locationService.isGranted(requestedStatus)) {
        setState(() {
          _isPermanentlyDenied = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission granted.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Read GPS coordinates and fetch weather/address
        final position = await _locationService.getCurrentPosition();
        if (position != null) {
          await _fetchAndReverseGeocodeLocation(position);
        }
      } else if (_locationService.isPermanentlyDenied(requestedStatus)) {
        setState(() {
          _isPermanentlyDenied = true;
        });
      } else if (_locationService.isDenied(requestedStatus)) {
        setState(() {
          _isPermanentlyDenied = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permission is needed to show local hazard briefings for your area.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (_) {
      // Gracefully handle any platform permission errors without crashing the app
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MAWA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log Out',
            onPressed: () async {
              await widget.authService.logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LoginScreen(authService: widget.authService),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Header
            Text(
              'Hello, ${widget.userProfile.firstName}!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Dashboard',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),

            // Location Access Blocked Banner (Displayed when permanently denied)
            if (_isPermanentlyDenied) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_off_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Location Access Blocked',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Location access is blocked. Please enable location permissions in system settings.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          await _locationService.openAppSettings();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.settings_outlined, size: 18),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Open App Settings',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Current Weather Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.thermostat_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Current Weather',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        if (_isWeatherLoading)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const Divider(height: 20),
                    if (_isWeatherLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_weatherError != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          _weatherError!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.orange.shade800,
                              ),
                        ),
                      )
                    else if (_weatherInfo != null) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${_weatherInfo!.temperature}°${_weatherInfo!.temperatureUnit}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _weatherInfo!.shortForecast,
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.air_outlined,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                '${_weatherInfo!.windSpeed} ${_weatherInfo!.windDirection}'
                                    .trim(),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          if (_weatherInfo!.humidity != null)
                            Row(
                              children: [
                                const Icon(Icons.water_drop_outlined,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  '${_weatherInfo!.humidity}%',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          if (_weatherInfo!.precipitationChance != null)
                            Row(
                              children: [
                                const Icon(Icons.umbrella_outlined,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  '${_weatherInfo!.precipitationChance}%',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Profile Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Account Profile',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.badge_outlined,
                            size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${widget.userProfile.firstName} ${widget.userProfile.lastName}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined,
                            size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.userProfile.email,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _geocodedAddress ??
                                '${widget.userProfile.city}, ${widget.userProfile.state}, ${widget.userProfile.country}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
