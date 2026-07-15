import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/app_config.dart';
import '../models/outfit_analysis.dart';

final analysisServiceProvider = Provider((ref) => AnalysisService());

/// Sends an outfit photo to the backend `/api/analysis` (Groq vision) and
/// returns the parsed [OutfitAnalysis].
class AnalysisService {
  Future<OutfitAnalysis> analyze(XFile file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not signed in');
    final token = await user.getIdToken(true);
    final bytes = await file.readAsBytes();

    // Web camera captures can lack a proper name/mime — force a .jpg name and
    // an image content-type so the backend's filter accepts it.
    final request = http.MultipartRequest('POST', Uri.parse(AppConfig.analysisEndpoint))
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: 'outfit.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode != 200) {
      throw Exception('Analysis failed (${res.statusCode}): ${res.body}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>;
    return OutfitAnalysis.fromJson(data);
  }
}
