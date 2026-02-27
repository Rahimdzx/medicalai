/// API and external service configuration
class ApiConfig {
  ApiConfig._();

  // Agora Video Call Configuration
  // ⚠️ IMPORTANT: Replace with your own App ID from https://console.agora.io/
  // To get your App ID:
  // 1. Sign up at https://console.agora.io/
  // 2. Create a new project
  // 3. Copy the App ID and paste it below
  static const String agoraAppId = '068164ddaed64ec482c4dcbb6329786e';  // ← Replace this!

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
