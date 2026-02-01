/// API and external service configuration
class ApiConfig {
  ApiConfig._();

  // Agora Video Call Configuration
  // Note: In production, these should be loaded from environment variables
  static const String agoraAppId = '068164ddaed64ec482c4dcbb6329786e';

  // Video Call Settings
  static const int videoWidth = 1280;
  static const int videoHeight = 720;
  static const int videoFrameRate = 30;
  static const int videoBitrate = 2000;

  // Firebase Cloud Messaging
  static const String fcmServerKey = ''; // Set in production

  // API Base URL (if using custom backend)
  static const String apiBaseUrl = '';

  // Sentry DSN for crash reporting
  static const String sentryDsn = '';
}
