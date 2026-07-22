/// App-wide configuration.
class AppConfig {
  AppConfig._();

  /// Base URL of the Savarun Node/Express backend.
  ///
  /// Override at build/run time without touching code:
  ///   flutter run   --dart-define=BACKEND_URL=http://localhost:4000
  ///   flutter build --dart-define=BACKEND_URL=https://savarun-api.onrender.com
  ///
  /// The default points at the deployed backend so release builds and any
  /// device (where `localhost` would mean the phone itself) work out of the box.
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://savarun-api.onrender.com',
  );

  static const String uploadEndpoint = '$backendBaseUrl/api/uploads';
  static const String analysisEndpoint = '$backendBaseUrl/api/analysis';
  static const String wardrobeAnalyticsEndpoint =
      '$backendBaseUrl/api/wardrobe/analytics';
  static const String affiliateProductsEndpoint =
      '$backendBaseUrl/api/affiliate/products';
  static const String affiliateTrendingEndpoint =
      '$backendBaseUrl/api/affiliate/trending';
  static const String affiliateClickEndpoint =
      '$backendBaseUrl/api/affiliate/click';
}
