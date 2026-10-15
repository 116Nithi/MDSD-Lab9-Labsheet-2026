import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

class StorageService {
  StorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> uploadListingImage(File imageFile, String sellerId) async {
    if (!await imageFile.exists()) {
      throw FileSystemException('ไม่พบไฟล์รูปภาพสำหรับอัปโหลด', imageFile.path);
    }

    final extension = p.extension(imageFile.path).toLowerCase();
    final fileName = '${DateTime.now().microsecondsSinceEpoch}$extension';
    final reference = _storage.ref('listings/$sellerId/$fileName');
    final uploadTask = await reference.putFile(
      imageFile,
      SettableMetadata(contentType: _contentTypeFor(extension)),
    );
    return uploadTask.ref.getDownloadURL();
  }

  String _contentTypeFor(String extension) {
    return switch (extension) {
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      '.heic' => 'image/heic',
      '.gif' => 'image/gif',
      _ => 'image/jpeg',
    };
  }
}
