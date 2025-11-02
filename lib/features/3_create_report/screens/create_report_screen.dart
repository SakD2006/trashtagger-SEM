import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:trashtagger/core/services/auth_service.dart';
import 'package:trashtagger/core/services/firestore_service.dart';
import 'package:trashtagger/core/services/location_service.dart';
import 'package:trashtagger/core/services/storage_service.dart';
import 'package:trashtagger/core/services/vision_llm_service.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  File? _image;
  bool _isUploading = false;
  String _statusMessage = 'Take a picture to start';

  final ImagePicker _picker = ImagePicker();
  final LocationService _locationService = LocationService();
  final StorageService _storageService = StorageService();
  final VisionLlmService _visionService = VisionLlmService();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  Future<void> _createReport() async {
    // 1. Check if image exists
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first!')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _statusMessage = 'Getting your location...';
    });

    // 2. Get location
    final LocationData? locationData = await _locationService
        .getCurrentLocation();
    if (locationData == null) {
      setState(() {
        _isUploading = false;
        _statusMessage = 'Failed to get location.';
      });
      return;
    }

    setState(() => _statusMessage = 'Analyzing image with AI...');

    // 3. Analyze with LLM (Gatekeeper)
    final String? description = await _visionService.analyzeInitialImage(
      _image!,
    );
    if (description == null) {
      setState(() {
        _isUploading = false;
        _statusMessage =
            'AI analysis rejected the image. No significant trash found.';
      });
      return;
    }

    setState(() => _statusMessage = 'Uploading image...');

    // 4. Upload image to Firebase Storage
    final String? imageUrl = await _storageService.uploadReportImage(_image!);
    if (imageUrl == null) {
      setState(() {
        _isUploading = false;
        _statusMessage = 'Failed to upload image.';
      });
      return;
    }

    setState(() => _statusMessage = 'Finalizing report...');

    // 5. Save report data to Firestore
    final user = _authService.currentUser;
    // You should fetch the user's username from your Firestore 'users' collection for better data
    final String username = user?.displayName ?? user?.email ?? 'Anonymous';

    await _firestoreService.createReport(
      reporterId: user!.uid,
      reporterUsername: username,
      beforeImageUrl: imageUrl,
      location: GeoPoint(locationData.latitude!, locationData.longitude!),
      llmDescription: description,
    );

    // 6. Finish
    if (mounted) {
      Navigator.of(context).pop(); // Go back to the feed screen
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _statusMessage = 'Image selected. Press upload to continue.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Report')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _image == null
                    ? const Center(child: Text('No image selected.'))
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_image!, fit: BoxFit.cover),
                      ),
              ),
              const SizedBox(height: 20),
              if (!_isUploading)
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Picture'),
                ),
              const SizedBox(height: 20),
              if (_isUploading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(_statusMessage, style: const TextStyle(fontSize: 16)),
              ] else if (_image != null)
                ElevatedButton.icon(
                  onPressed: _createReport,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Upload Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
