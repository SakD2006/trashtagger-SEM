import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart'; // Add uuid package for unique filenames

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // This is your existing function, unchanged.
  Future<String?> uploadReportImage(File imageFile) async {
    try {
      // 1. Generate a unique filename
      final String fileName = const Uuid().v4();
      final String fileExtension = imageFile.path.split('.').last;

      // 2. Compress the image
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/$fileName.$fileExtension';

      final XFile? compressedFile =
          await FlutterImageCompress.compressAndGetFile(
            imageFile.absolute.path,
            targetPath,
            quality: 70, // Adjust quality as needed
          );

      if (compressedFile == null) return null;

      // 3. Create a reference in Firebase Storage
      final Reference ref = _storage.ref().child(
        'reports/$fileName.$fileExtension',
      );

      // 4. Upload the compressed file
      final UploadTask uploadTask = ref.putFile(File(compressedFile.path));
      final TaskSnapshot snapshot = await uploadTask;

      // 5. Get the download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  // --- NEW FUNCTION ---
  // This is the new function for the "Complete Report" feature.
  // It specifically uploads an 'after.jpg' into the report's folder.
  Future<String?> uploadAfterImage(File imageFile, String reportId) async {
    try {
      // 1. Compress the image
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/$reportId-after.jpg';

      final XFile? compressedFile =
          await FlutterImageCompress.compressAndGetFile(
            imageFile.absolute.path,
            targetPath,
            quality: 70, // Adjust quality as needed
          );

      if (compressedFile == null) return null;

      // 2. Create a specific reference for the 'after' image
      //    e.g., /reports/{reportId}/after.jpg
      final Reference ref = _storage
          .ref()
          .child('reports')
          .child(reportId)
          .child('after.jpg');

      // 3. Upload the compressed file
      final UploadTask uploadTask = ref.putFile(File(compressedFile.path));
      final TaskSnapshot snapshot = await uploadTask;

      // 4. Get the download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading after image: $e");
      return null;
    }
  }
}
