import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../config/app_config.dart';

final uploadServiceProvider = Provider((ref) => UploadService());

/// Picks an image and uploads it to the backend `/api/uploads` endpoint,
/// returning the public URL. Used as our stand-in for Firebase Storage.
class UploadService {
  final _picker = ImagePicker();

  /// Opens the gallery; returns null if the user cancels.
  Future<XFile?> pickFromGallery() {
    return _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      imageQuality: 85,
    );
  }

  /// Uploads [file] to the backend and returns the hosted image URL.
  Future<String> uploadImage(XFile file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Not signed in');
    }
    // forceRefresh: always mint a fresh ID token so we never send a stale one.
    final token = await user.getIdToken(true);
    final bytes = await file.readAsBytes();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(AppConfig.uploadEndpoint),
    )
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(
        http.MultipartFile.fromBytes('image', bytes, filename: file.name),
      );

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('Upload failed (${res.statusCode}): ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['url'] as String;
  }
}
