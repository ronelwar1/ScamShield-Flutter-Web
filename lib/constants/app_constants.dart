/// App-wide constants. Never store secret API credentials here.
class AppConstants {
  AppConstants._();

  /// Change this one value to rename the app everywhere.
  static const String appName = 'SafeScan';
  static const String appTagline = 'Check any message before you trust it';

  /// Planned REST API base URL. Not used until the backend exists.
  static const String apiBaseUrl = 'http://localhost:8000';

  static const int maxMessageLength = 2000;
  static const int minPasswordLength = 8;
}
