import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trashtagger/core/models/report_pin_data.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- User Operations ---

  /// Saves a new user to the `users` collection in Firestore.
  /// The document ID is set to the user's UID from Firebase Auth.
  Future<void> saveUser({
    required String uid,
    required String username,
    required String email,
    required String role,
  }) async {
    try {
      await _db.collection('users').doc(uid).set({
        'username': username,
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error saving user: $e");
      rethrow;
    }
  }

  /// Fetches a user's data from Firestore using their UID.
  Future<Map<String, dynamic>?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("Error fetching user: $e");
      return null;
    }
  }

  // --- Report Operations ---

  /// Fetches a real-time stream of all reports for the main feed.
  /// Reports are ordered by creation date, with the newest first.
  Stream<QuerySnapshot> getReportsStream() {
    return _db
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots();
    // Your ReportsFeedScreen will map these docs to ReportModel
  }

  /// Creates a new report document in the `reports` collection.
  Future<void> createReport({
    required String reporterId,
    required String reporterUsername,
    required String beforeImageUrl,
    required GeoPoint location,
    required String llmDescription,
  }) async {
    try {
      await _db.collection('reports').add({
        'reporterId': reporterId,
        'reporterUsername': reporterUsername,
        'beforeImageUrl': beforeImageUrl,
        'location': location, // Storing location
        'llmDescription': llmDescription,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'afterImageUrl': null,
        'assignedNgoUid': null, // Standardized field name
        'completedAt': null, // Standardized field name
      });
    } catch (e) {
      print("Error creating report: $e");
      rethrow;
    }
  }

  /// Fetches data needed for the map pins.
  Future<List<ReportPinData>> getReportPins() async {
    try {
      final snapshot = await _db
          .collection('reports')
          .where('beforeImageUrl', isNotEqualTo: null)
          .get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      // Manually map the Firestore doc to your ReportPinData model
      // This ensures all fields are correctly populated
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ReportPinData(
          id: doc.id,
          // Read from 'location' key (from createReport)
          geoPoint: data['location'] as GeoPoint,
          beforeImageUrl: data['beforeImageUrl'] as String,
          reporterUid: data['reporterId'] as String,
          status: data['status'] as String,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          // Ensure optional fields are mapped
          afterImageUrl: data['afterImageUrl'] as String?,
          assignedNgoUid: data['assignedNgoUid'] as String?,
          completedAt: data['completedAt'] != null
              ? (data['completedAt'] as Timestamp).toDate()
              : null,
          description: data['llmDescription'] as String?,
        );
      }).toList();
    } catch (e) {
      print("Error fetching report pins: $e");
      return [];
    }
  }

  // --- NEW FUNCTION ---
  /// Atomically updates a report to 'completed' status.
  /// This single function is used by CompleteReportScreen.

  Future<void> completeReport({
    required String reportId,
    required String afterImageUrl,
    required String ngoId,
    required String? aiRating, // 1. ADD THIS PARAMETER
  }) async {
    try {
      await _db.collection('reports').doc(reportId).update({
        'status': 'completed',
        'afterImageUrl': afterImageUrl,
        'assignedNgoUid': ngoId,
        'completedAt': FieldValue.serverTimestamp(),
        'aiRating': aiRating, // 2. SAVE THE RATING
      });
    } catch (e) {
      print('Error completing report: $e');
      rethrow;
    }
  }

  //
  // --- DEPRECATED FUNCTIONS ---
  // The functions below are no longer needed as their logic is
  // combined into the `completeReport` function above.
  //
  // Future<void> updateReportStatus(String reportId, String newStatus) async { ... }
  // Future<void> updateReportCompletedAt(String reportId, Timestamp completedAt) async { ... }
  // Future<void> updateReportAfterImage(String reportId, String imageUrl) async { ... }
  //
}
