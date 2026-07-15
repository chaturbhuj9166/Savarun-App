/// App-wide configuration.
class AppConfig {
  AppConfig._();

  /// Base URL of the Savarun Node/Express backend.
  ///
  /// Works for web + desktop dev. NOTE: on a real Android/iOS device,
  /// `localhost` points to the phone itself — replace with your machine's
  /// LAN IP (e.g. http://192.168.1.5:4000) when testing on device.
  static const String backendBaseUrl = 'http://localhost:4000';

  static const String uploadEndpoint = '$backendBaseUrl/api/uploads';
  static const String analysisEndpoint = '$backendBaseUrl/api/analysis';
}
