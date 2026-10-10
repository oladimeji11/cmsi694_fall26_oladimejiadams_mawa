import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import 'login_screen.dart';

/// The Home landing screen dashboard displaying user greeting, account profile details,
/// and managing location permission requests and system settings redirection.
class HomeScreen extends StatefulWidget {
  final UserProfile userProfile;
  final AuthService authService;
  final LocationService? locationService;

  const HomeScreen({
    super.key,
    required this.userProfile,
    required this.authService,
    this.locationService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final LocationService _locationService;
  bool _isPermanentlyDenied = false;

  @override
  void initState() {
    super.initState();
    _locationService = widget.locationService ?? LocationService();

    // Register lifecycle observer to listen for app resume events
    WidgetsBinding.instance.addObserver(this);

    // Trigger location permission check after the first frame renders
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

  Future<void> _checkAndRequestLocationPermission() async {
    try {
      final currentStatus = await _locationService.checkPermission();

      // If permission is already granted, clear permanently denied banner and return
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
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your location-aware environmental safety dashboard.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),

            // Location Access Blocked Banner (Displayed when permanently denied)
            if (_isPermanentlyDenied) ...[
              Card(
                color: Colors.orange.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.orange.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_off_outlined,
                              color: Colors.orange.shade800),
                          const SizedBox(width: 8),
                          Text(
                            'Location Access Blocked',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Location access is blocked. Please enable location permissions in system settings.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.orange.shade900,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await _locationService.openAppSettings();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.settings_outlined, size: 18),
                        label: const Text('Open App Settings'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Profile Info Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_outline, color: Colors.deepPurple),
                        const SizedBox(width: 8),
                        Text(
                          'Account Profile',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.badge_outlined, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${widget.userProfile.firstName} ${widget.userProfile.lastName}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined, size: 18, color: Colors.grey),
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
                        const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
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
