//lib/features/2_heatmap/screens/heatmap_screen.dart
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:trashtagger/core/models/report_pin_data.dart';
import 'package:trashtagger/core/services/firestore_service.dart';
import 'package:http/http.dart' as http;

class HeatmapScreen extends StatefulWidget {
  final LatLng userLocation;
  const HeatmapScreen(this.userLocation, {super.key});

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  Set<Marker> markers = {};
  final Map<String, BitmapDescriptor> _markerBitmapCache = {};

  // 3. INITIALIZE the camera position immediately
  //    using the 'widget.userLocation' passed in.
  late final CameraPosition _initialCameraPosition;

  @override
  void initState() {
    super.initState();

    // 4. SET the initial position right away
    _initialCameraPosition = CameraPosition(
      target: widget.userLocation,
      zoom: 14,
    );

    // Load just the pins, no need to get location here
    _loadReportPins();
  }

  // 5. RENAME and SIMPLIFY the load function
  void _loadReportPins() async {
    final FirestoreService firestoreService = FirestoreService();

    // Just get the pins
    final List<ReportPinData> allReportPins = await firestoreService
        .getReportPins();

    final List<ReportPinData> unresolvedPins = allReportPins
        .where((pin) => pin.status == 'pending')
        .toList();

    Set<Marker> newMarkers = {};
    for (final pin in unresolvedPins) {
      final marker = await _createMarker(pin);
      newMarkers.add(marker);
    }

    // 6. SET state for markers
    //    (No need to set camera, it's already done)
    setState(() {
      markers = newMarkers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Waste Hotspots')),
      // 7. REMOVE the loading spinner logic.
      //    The map can now be built immediately.
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _initialCameraPosition, // This is never null
        markers: markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      ),
    );
  }

  // New helper function to create a single marker from a pin
  Future<Marker> _createMarker(ReportPinData pin) async {
    BitmapDescriptor icon;
    final imageUrl = pin.beforeImageUrl; // Using the correct field name

    if (_markerBitmapCache.containsKey(imageUrl)) {
      // Use cached marker if available
      icon = _markerBitmapCache[imageUrl]!;
    } else {
      // Create a new marker and cache it
      try {
        icon = await _createImageMarkerBitmap(imageUrl);
        _markerBitmapCache[imageUrl] = icon; // Save to cache
      } catch (e) {
        if (kDebugMode) {
          print('Error creating image marker: $e');
        }
        // Use a fallback marker in case of error
        icon = await _getFallbackMarkerBitmap(75, text: "!");
      }
    }

    return Marker(
      markerId: MarkerId(pin.id),
      position: pin.location,
      icon: icon,
      onTap: () {
        if (kDebugMode) {
          print('Tapped on report: ${pin.id}');
        }
        // TODO: Show a dialog or navigate to a detail screen
        // _showReportDetails(pin);
      },
    );
  }

  // --- Marker Creation Functions ---

  // Function to create the "Snap Map" style image pin
  Future<BitmapDescriptor> _createImageMarkerBitmap(
    String imageUrl, {
    int size = 150,
  }) async {
    if (kIsWeb) size = (size / 2).floor();

    // 1. Download image bytes
    final http.Response response = await http.get(Uri.parse(imageUrl));
    final Uint8List imageBytes = response.bodyBytes;

    // 2. Decode the image
    final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ui.Image image = frame.image;

    // 3. Set up the canvas
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final double shadowBlur = kIsWeb ? 0 : 20.0; // No shadow on web
    final double borderWidth = kIsWeb ? 2 : 6.0;
    final double borderRadius = 12.0;
    final double imageSize = size.toDouble() - (shadowBlur * 2);
    final double finalSize = size.toDouble();

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // 4. Draw shadow
    if (!kIsWeb) {
      final Path shadowPath = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(shadowBlur, shadowBlur, imageSize, imageSize),
            Radius.circular(borderRadius),
          ),
        );
      canvas.drawShadow(shadowPath, Colors.black, shadowBlur / 2, false);
    }

    // 5. Create clipping path for the rounded square
    final RRect clipRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(shadowBlur, shadowBlur, imageSize, imageSize),
      Radius.circular(borderRadius),
    );
    canvas.clipRRect(clipRRect);

    // 6. Draw the image, scaled to fill the square (like BoxFit.cover)
    paintImage(
      canvas: canvas,
      rect: Rect.fromLTWH(shadowBlur, shadowBlur, imageSize, imageSize),
      image: image,
      fit: BoxFit.cover,
    );

    // 7. Draw the white border on top
    canvas.drawRRect(clipRRect, borderPaint);

    // 8. Convert to BitmapDescriptor
    final img = await pictureRecorder.endRecording().toImage(
      finalSize.toInt(),
      finalSize.toInt(),
    );
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  // Fallback marker (your original orange circle)
  Future<BitmapDescriptor> _getFallbackMarkerBitmap(
    int size, {
    String? text,
  }) async {
    if (kIsWeb) size = (size / 2).floor();

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint1 = Paint()..color = Colors.orange;
    final Paint paint2 = Paint()..color = Colors.white;

    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.0, paint1);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.2, paint2);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.8, paint1);

    if (text != null) {
      TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
      painter.text = TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size / 3,
          color: Colors.white,
          fontWeight: FontWeight.normal,
        ),
      );
      painter.layout();
      painter.paint(
        canvas,
        Offset(size / 2 - painter.width / 2, size / 2 - painter.height / 2),
      );
    }

    final img = await pictureRecorder.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }
}
