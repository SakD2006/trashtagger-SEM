import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart'; // Add uuid package for unique filenames

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
}
