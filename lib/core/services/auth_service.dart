import 'package:firebase_auth/firebase_auth.dart';
import 'package:trashtagger/core/services/firestore_service.dart'; // We will create this next

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // GET the current user
  User? get currentUser => _auth.currentUser;

  // STREAM to listen for auth changes (the best way to manage login state)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // SIGN UP with email and password
  Future<User?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    required String role,
  }) async {
    try {
      // 1. Create the user in Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      User? newUser = userCredential.user;

      // 2. IMPORTANT: Save user data (with role) to Firestore
      if (newUser != null) {
        await _firestoreService.saveUser(
          uid: newUser.uid,
          username: username,
          email: email,
          role: role, // Default role for new signups
        );
      }
      return newUser;
    } on FirebaseAuthException catch (e) {
      // Handle errors like 'email-already-in-use'
      print("Firebase Auth Error: ${e.message}");
      return null;
    }
  }

  // SIGN IN with email and password
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Error: ${e.message}");
      return null;
    }
  }

  // SIGN OUT
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
