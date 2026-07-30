import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/app_config.dart';

/// AI-detected tags for one clothing photo (Module 2 auto-tagging).
class ItemTags {
  const ItemTags({
    required this.name,
    required this.category,
    required this.colorName,
    required this.colorHex,
    required this.fabric,
    required this.season,
    required this.formality,
  });

  final String name;
  final String category;
  final String colorName;
  final String colorHex;
  final String fabric;
  final String season;
  final String formality;

  factory ItemTags.fromJson(Map<String, dynamic> d) => ItemTags(
        name: d['name'] ?? '',
        category: d['category'] ?? 'Tops',
        colorName: d['colorName'] ?? '',
        colorHex: d['colorHex'] ?? '#9E9E9E',
        fabric: d['fabric'] ?? 'Cotton',
        season: d['season'] ?? 'All-season',
        formality: d['formality'] ?? 'Casual',
      );
}

final autotagServiceProvider = Provider((ref) => const AutotagService());

/// Calls the backend `/api/wardrobe/autotag` (Groq vision) for one image.
class AutotagService {
  const AutotagService();

  Future<ItemTags> tag(XFile file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not signed in');
    final token = await user.getIdToken(true);
    final bytes = await file.readAsBytes();

    final request =
        http.MultipartRequest('POST', Uri.parse(AppConfig.wardrobeAutotagEndpoint))
          ..headers['Authorization'] = 'Bearer $token'
          ..files.add(http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: 'item.jpg',
            contentType: MediaType('image', 'jpeg'),
          ));

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 200) {
      throw Exception('Auto-tag failed (${res.statusCode})');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return ItemTags.fromJson(json['data'] as Map<String, dynamic>);
  }
}
