import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Thin helper for authenticated JSON calls to the Savarun Node backend.
///
/// Every backend route sits behind `requireAuth`, so each call carries the
/// user's Firebase ID token as a bearer token.
class ApiClient {
  const ApiClient();

  Future<Map<String, dynamic>> get(String url) async {
    final res = await http.get(Uri.parse(url), headers: await _headers());
    return _decode(res);
  }

  Future<Map<String, dynamic>> post(String url, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse(url),
      headers: {...await _headers(), 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  Future<Map<String, String>> _headers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not signed in');
    return {'Authorization': 'Bearer ${await user.getIdToken()}'};
  }

  Map<String, dynamic> _decode(http.Response res) {
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || json['ok'] != true) {
      throw Exception(json['error'] ?? 'Request failed (${res.statusCode})');
    }
    return json;
  }
}
