class UserModel {
  final String uid;
  final String username;
  final String email;
  final String role; // 'public' or 'ngo'

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    required this.role,
  });

  // A factory constructor for creating a new UserModel instance from a map
  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'public',
    );
  }

  // A method for converting a UserModel instance to a map
  Map<String, dynamic> toMap() {
    return {'username': username, 'email': email, 'role': role};
  }
}
