import 'package:cloud_firestore/cloud_firestore.dart';

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
        'createdAt':
            FieldValue.serverTimestamp(), // Good practice to have a timestamp
      });
    } catch (e) {
      print("Error saving user: $e");
      // Optionally, rethrow the error to handle it in the UI
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

  // --- Report Operations (You will use these later) ---

  /// Fetches a real-time stream of all reports for the main feed.
  /// Reports are ordered by creation date, with the newest first.
  Stream<QuerySnapshot> getReportsStream() {
    return _db
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots();
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
      // Use .add() to let Firestore automatically generate a unique document ID
      await _db.collection('reports').add({
        'reporterId': reporterId,
        'reporterUsername': reporterUsername,
        'beforeImageUrl': beforeImageUrl,
        'location': location,
        'llmDescription': llmDescription,
        'status': 'pending', // The initial status of every new report
        'createdAt':
            FieldValue.serverTimestamp(), // Use the server's time for accuracy
        'afterImageUrl': null, // This will be added later by an NGO
        'cleanedBy': null, // This will be added later by an NGO
      });
    } catch (e) {
      print("Error creating report: $e");
      // Optionally rethrow the error to be handled by the UI
      rethrow;
    }
  }

  /// Fetches ONLY the location data for all reports to build the heatmap.
  Future<List<GeoPoint>> getReportLocations() async {
    try {
      final snapshot = await _db.collection('reports').get();
      if (snapshot.docs.isEmpty) {
        return [];
      }
      return snapshot.docs
          .map((doc) => doc.data()['location'] as GeoPoint)
          .toList();
    } catch (e) {
      print("Error fetching report locations: $e");
      return [];
    }
  }
}
