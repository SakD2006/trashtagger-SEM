import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:trashtagger/core/services/firestore_service.dart';

class HeatmapScreen extends StatefulWidget {
  const HeatmapScreen({super.key});

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  Set<Heatmap> _heatmaps = {};
  bool _isLoading = true;

  // Initial camera position over India
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(20.5937, 78.9629), // Center of India
    zoom: 5,
  );

  @override
  void initState() {
    super.initState();
    _generateHeatmapData();
  }

  void _generateHeatmapData() async {
    // Fetch the raw GeoPoint data from Firestore
    List<GeoPoint> locations = await _firestoreService.getReportLocations();

    // --- CHANGE 1: Convert GeoPoints to WeightedLatLng ---
    // We now create a list of WeightedLatLng, giving each point a default weight of 1.
    final List<WeightedLatLng> weightedLatLngList = locations.map((point) {
      return WeightedLatLng(LatLng(point.latitude, point.longitude), weight: 1);
    }).toList();

    if (weightedLatLngList.isNotEmpty) {
      setState(() {
        _heatmaps = {
          Heatmap(
            heatmapId: const HeatmapId('reports_heatmap'),
            // --- CHANGE 2: Use the 'data' parameter ---
            data: weightedLatLngList,
            radius: HeatmapRadius.fromPixels(30), // Use the HeatmapRadius class
            opacity: 0.8,
          ),
        };
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Waste Hotspots')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: _initialPosition,
              heatmaps: _heatmaps,
              mapType: MapType.normal,
            ),
    );
  }
}
