// lib/core/models/report_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String reporterId;
  final String reporterUsername;
  final String beforeImageUrl;
  final String llmDescription;
  final String status;
  final GeoPoint location;
  final Timestamp createdAt;

  // --- ADD THESE FIELDS ---
  final String? afterImageUrl;
  final String? assignedNgoUid;
  final Timestamp? completedAt;
  final String? aiRating; // This will store the AI's rating

  ReportModel({
    required this.id,
    required this.reporterId,
    required this.reporterUsername,
    required this.beforeImageUrl,
    required this.llmDescription,
    required this.status,
    required this.location,
    required this.createdAt,
    // Add to constructor
    this.afterImageUrl,
    this.assignedNgoUid,
    this.completedAt,
    this.aiRating,
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      id: doc.id,
      reporterId: data['reporterId'] as String,
      reporterUsername: data['reporterUsername'] as String,
      beforeImageUrl: data['beforeImageUrl'] as String,
      llmDescription: data['llmDescription'] as String,
      status: data['status'] as String,
      location: data['location'] as GeoPoint,
      createdAt: data['createdAt'] as Timestamp,

      // --- MAP THE NEW FIELDS ---
      afterImageUrl: data['afterImageUrl'] as String?,
      assignedNgoUid: data['assignedNgoUid'] as String?,
      completedAt: data['completedAt'] as Timestamp?,
      aiRating: data['aiRating'] as String?, // Read the rating from Firestore
    );
  }
}
