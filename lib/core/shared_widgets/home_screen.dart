import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // 1. ADD THIS
import 'package:location/location.dart'; // 2. ADD THIS
import 'package:trashtagger/core/services/location_service.dart'; // 3. ADD THIS
import 'package:trashtagger/features/1_reports_feed/screens/reports_feed_screen.dart';
import 'package:trashtagger/features/2_heatmap/screens/heatmap_screen.dart';
import 'package:trashtagger/features/4_profile/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // 4. ADD fields to hold location state
  LatLng? _userLocation;
  bool _isLocationLoading = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    // 5. FETCH location when this screen first loads
    _fetchUserLocation();
  }

  Future<void> _fetchUserLocation() async {
    final LocationService locationService = LocationService();
    try {
      final LocationData? userLocationData = await locationService
          .getCurrentLocation();

      if (userLocationData != null &&
          userLocationData.latitude != null &&
          userLocationData.longitude != null) {
        setState(() {
          _userLocation = LatLng(
            userLocationData.latitude!,
            userLocationData.longitude!,
          );
          _isLocationLoading = false;
        });
      } else {
        throw Exception('Could not retrieve location.');
      }
    } catch (e) {
      // Handle errors (e.g., permissions denied)
      setState(() {
        _isLocationLoading = false;
        _locationError =
            'Could not get location. Please enable permissions and try again.';
      });
    }
  }

  // 6. This is no longer 'const'
  Widget _buildHeatmapScreen() {
    if (_isLocationLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_locationError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _locationError!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLocationLoading = true;
                    _locationError = null;
                  });
                  _fetchUserLocation();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_userLocation != null) {
      // 7. PASS the location to the HeatmapScreen
      return HeatmapScreen(_userLocation!);
    }
    // Fallback, though this state should ideally not be reached
    return const Center(child: Text('An unexpected error occurred.'));
  }

  @override
  Widget build(BuildContext context) {
    // 8. DEFINE the screens list inside 'build'
    final List<Widget> screens = [
      const ReportsFeedScreen(),
      _buildHeatmapScreen(), // Use our new helper function
      const ProfileScreen(),
    ];

    return Scaffold(
      // 9. USE the list defined above
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Heatmap'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
