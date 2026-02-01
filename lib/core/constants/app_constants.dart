/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Medical App';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Supported Languages
  static const String defaultLanguage = 'en';
  static const List<String> supportedLanguages = ['en', 'ar', 'ru'];
  static const Map<String, String> languageNames = {
    'en': 'English',
    'ar': 'العربية',
    'ru': 'Русский',
  };
  static const Map<String, String> languageFlags = {
    'en': '🇺🇸',
    'ar': '🇸🇦',
    'ru': '🇷🇺',
  };

  // RTL Languages
  static const List<String> rtlLanguages = ['ar'];

  // User Roles
  static const String rolePatient = 'patient';
  static const String roleDoctor = 'doctor';
  static const String roleAdmin = 'admin';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String appointmentsCollection = 'appointments';
  static const String medicalRecordsCollection = 'medical_records';
  static const String notificationsCollection = 'notifications';
  static const String callsCollection = 'calls';

  // Firebase Storage Paths
  static const String userPhotosPath = 'user_photos';
  static const String chatMediaPath = 'chat_media';
  static const String medicalRecordsPath = 'medical_records';
  static const String voiceMessagesPath = 'voice_messages';

  // Message Types
  static const String messageTypeText = 'text';
  static const String messageTypeImage = 'image';
  static const String messageTypeFile = 'file';
  static const String messageTypeAudio = 'audio';
  static const String messageTypeLocation = 'location';

  // Message Status
  static const String messageStatusSent = 'sent';
  static const String messageStatusDelivered = 'delivered';
  static const String messageStatusRead = 'read';

  // Call Types
  static const String callTypeVideo = 'video';
  static const String callTypeAudio = 'audio';

  // Call Status
  static const String callStatusCalling = 'calling';
  static const String callStatusActive = 'active';
  static const String callStatusEnded = 'ended';
  static const String callStatusMissed = 'missed';
  static const String callStatusRejected = 'rejected';

  // Pagination
  static const int defaultPageSize = 20;
  static const int chatMessagesPageSize = 50;

  // Timeouts (in milliseconds)
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int callTimeout = 30000; // 30 seconds for call to be answered
  static const int sessionTimeout = 1800000; // 30 minutes

  // File Size Limits (in bytes)
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const int maxVoiceMessageDuration = 300; // 5 minutes in seconds

  // Image Compression
  static const int imageQuality = 70;
  static const int thumbnailSize = 200;

  // Validation
  static const int minPasswordLength = 6;
  static const int maxNameLength = 50;
  static const int maxBioLength = 500;

  // Animation Durations (in milliseconds)
  static const int shortAnimationDuration = 200;
  static const int mediumAnimationDuration = 300;
  static const int longAnimationDuration = 500;

  // SharedPreferences Keys
  static const String prefLanguageCode = 'language_code';
  static const String prefThemeMode = 'theme_mode';
  static const String prefFcmToken = 'fcm_token';
  static const String prefUserId = 'user_id';
  static const String prefOnboardingComplete = 'onboarding_complete';
  static const String prefBiometricEnabled = 'biometric_enabled';
}
