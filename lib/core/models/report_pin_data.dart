// lib/core/models/report_pin_data.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ReportPinData {
  final String id;
  final GeoPoint geoPoint;
  final String beforeImageUrl;
  final String? afterImageUrl;
  final String status; // 'pending', 'in_progress', 'completed'
  final String reporterUid;
  final String? assignedNgoUid;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? description;

  ReportPinData({
    required this.id,
    required this.geoPoint,
    required this.beforeImageUrl,
    required this.reporterUid,
    required this.status,
    required this.createdAt,
    this.afterImageUrl,
    this.assignedNgoUid,
    this.completedAt,
    this.description,
  });

  LatLng get location => LatLng(geoPoint.latitude, geoPoint.longitude);

  factory ReportPinData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportPinData(
      id: doc.id,
      geoPoint: data['geoPoint'] as GeoPoint,
      beforeImageUrl: data['beforeImageUrl'] as String,
      afterImageUrl: data['afterImageUrl'] as String?,
      status: data['status'] as String,
      reporterUid: data['reporterUid'] as String,
      assignedNgoUid: data['assignedNgoUid'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      description: data['description'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'geoPoint': geoPoint,
      'beforeImageUrl': beforeImageUrl,
      'afterImageUrl': afterImageUrl,
      'status': status,
      'reporterUid': reporterUid,
      'assignedNgoUid': assignedNgoUid,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'description': description,
    };
  }
}
