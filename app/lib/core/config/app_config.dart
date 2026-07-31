import 'package:flutter/foundation.dart';

/// App-wide configuration.
class AppConfig {
  AppConfig._();

  /// Explicit override, e.g. to point a debug build at the deployed server:
  ///   flutter run --dart-define=BACKEND_URL=https://savarun-api.onrender.com
  static const String _override = String.fromEnvironment('BACKEND_URL');

  /// The deployed backend, used by release builds.
  static const String _prodUrl = 'https://savarun-app.onrender.com';

  /// Base URL of the Savarun Node/Express backend.
  ///
  /// Debug builds talk to the local server by default, so `flutter run` works
  /// without extra flags; release builds go to the deployed one. Either can be
  /// overridden with `--dart-define=BACKEND_URL=...`.
  ///
  /// NOTE: on a physical Android/iOS device `localhost` means the phone
  /// itself — pass your machine's LAN IP (e.g. http://192.168.1.5:4000).
  static const String backendBaseUrl = _override != ''
      ? _override
      : (kReleaseMode ? _prodUrl : 'http://localhost:4000');

  static const String uploadEndpoint = '$backendBaseUrl/api/uploads';
  static const String uploadBulkEndpoint = '$backendBaseUrl/api/uploads/bulk';
  static const String analysisEndpoint = '$backendBaseUrl/api/analysis';
  static const String wardrobeAnalyticsEndpoint =
      '$backendBaseUrl/api/wardrobe/analytics';
  static const String wardrobeAutotagEndpoint =
      '$backendBaseUrl/api/wardrobe/autotag';
  static const String affiliateProductsEndpoint =
      '$backendBaseUrl/api/affiliate/products';
  static const String affiliateTrendingEndpoint =
      '$backendBaseUrl/api/affiliate/trending';
  static const String affiliateFeaturedEndpoint =
      '$backendBaseUrl/api/affiliate/featured';
  static const String affiliateClickEndpoint =
      '$backendBaseUrl/api/affiliate/click';
  static const String brandsEndpoint = '$backendBaseUrl/api/affiliate/brands';
  static const String myBrandsEndpoint =
      '$backendBaseUrl/api/affiliate/my-brands';
  static const String brandProductsEndpoint =
      '$backendBaseUrl/api/affiliate/products';
}
