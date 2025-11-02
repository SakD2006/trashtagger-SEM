import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String reporterId;
  final String reporterUsername;
  final String beforeImageUrl;
  final String? afterImageUrl; // Nullable, as it might not exist yet
  final GeoPoint location;
  final String llmDescription;
  final String status; // e.g., 'pending', 'completed'
  final Timestamp createdAt;
  final String? cleanedBy; // Nullable NGO name

  ReportModel({
    required this.id,
    required this.reporterId,
    required this.reporterUsername,
    required this.beforeImageUrl,
    this.afterImageUrl,
    required this.location,
    required this.llmDescription,
    required this.status,
    required this.createdAt,
    this.cleanedBy,
  });

  // Factory constructor to create a ReportModel from a Firestore document
  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      id: doc.id,
      reporterId: data['reporterId'] ?? '',
      reporterUsername: data['reporterUsername'] ?? 'Anonymous',
      beforeImageUrl: data['beforeImageUrl'] ?? '',
      afterImageUrl: data['afterImageUrl'],
      location: data['location'] ?? const GeoPoint(0, 0),
      llmDescription: data['llmDescription'] ?? 'No description available.',
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      cleanedBy: data['cleanedBy'],
    );
  }
}
