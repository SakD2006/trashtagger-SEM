import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:trashtagger/core/models/report_pin_data.dart';

class ReportDetailsWidget extends StatelessWidget {
  final ReportPinData report;
  final bool isNgo;
  final Function(String) onStatusUpdate;
  final Function(String) onAfterImageUpload;

  const ReportDetailsWidget({
    super.key,
    required this.report,
    required this.isNgo,
    required this.onStatusUpdate,
    required this.onAfterImageUpload,
  });

  Future<void> _uploadAfterImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1800,
      maxHeight: 1800,
    );

    if (image == null) return;

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('report_images')
        .child('${report.id}_after.jpg');

    try {
      await storageRef.putFile(File(image.path));
      final imageUrl = await storageRef.getDownloadURL();
      onAfterImageUpload(imageUrl);
    } catch (e) {
      print('Error uploading after image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Report Details',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _buildImageSection(),
          const SizedBox(height: 16),
          _buildStatusSection(context),
          if (report.description != null) ...[
            const SizedBox(height: 16),
            Text(
              'Description:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(report.description!),
          ],
          const SizedBox(height: 16),
          _buildTimestampSection(),
          if (isNgo && report.status != 'completed') _buildNgoActions(context),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Before:'),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  report.beforeImageUrl,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        if (report.afterImageUrl != null)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('After:'),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    report.afterImageUrl!,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatusSection(BuildContext context) {
    return Row(
      children: [
        const Text('Status: '),
        Chip(
          label: Text(
            report.status.replaceAll('_', ' ').toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: _getStatusColor(),
        ),
      ],
    );
  }

  Widget _buildTimestampSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reported on: ${_formatDate(report.createdAt)}',
          style: const TextStyle(color: Colors.grey),
        ),
        if (report.completedAt != null)
          Text(
            'Completed on: ${_formatDate(report.completedAt!)}',
            style: const TextStyle(color: Colors.grey),
          ),
      ],
    );
  }

  Widget _buildNgoActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        if (report.status == 'pending')
          ElevatedButton(
            onPressed: () => onStatusUpdate('in_progress'),
            child: const Text('Start Cleaning'),
          ),
        if (report.status == 'in_progress')
          ElevatedButton(
            onPressed: _uploadAfterImage,
            child: const Text('Upload After Image'),
          ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (report.status) {
      case 'pending':
        return Colors.red;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
