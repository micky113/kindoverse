import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'file_picker_registrar.dart';

/// Service for picking and uploading campaign cover images, gallery photos,
/// and geo-tagged milestone proof media to Firebase Cloud Storage.
class ImpactStorageService {
  final FirebaseStorage? _customStorage;

  ImpactStorageService({FirebaseStorage? storage}) : _customStorage = storage;

  FirebaseStorage get _storage => _customStorage ?? FirebaseStorage.instance;

  /// Opens the native/web file picker for an image and uploads it to Firebase Storage.
  /// Returns the public download URL, or `null` if the user cancelled.
  Future<String?> pickAndUploadImage({
    required String folderPath,
    Map<String, String>? customMetadata,
  }) async {
    final picker = ensureFilePickerInitialized();
    final result = await picker.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return null;

    final ext = (file.extension ?? 'jpg').toLowerCase();
    final contentType =
        ext == 'png'
            ? 'image/png'
            : ext == 'webp'
            ? 'image/webp'
            : 'image/jpeg';

    return uploadBytes(
      folderPath: folderPath,
      fileName: file.name,
      bytes: bytes,
      contentType: contentType,
      customMetadata: customMetadata,
    );
  }

  /// Uploads raw image bytes to Firebase Storage with audit metadata tags
  /// and returns the public download URL. Falls back to a data URI if
  /// Firebase Storage bucket/CORS is unavailable.
  Future<String> uploadBytes({
    required String folderPath,
    required String fileName,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
    Map<String, String>? customMetadata,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitizedName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final storagePath = '$folderPath/${timestamp}_$sanitizedName';

    try {
      final ref = _storage.ref().child(storagePath);
      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          ...?customMetadata,
        },
      );

      final snapshot = await ref
          .putData(bytes, metadata)
          .timeout(const Duration(seconds: 15));
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint(
        'Firebase Storage upload warning ($e) — using inline data URL fallback.',
      );
      return 'data:$contentType;base64,${base64Encode(bytes)}';
    }
  }
}

final impactStorageServiceProvider = Provider<ImpactStorageService>((ref) {
  return ImpactStorageService();
});
