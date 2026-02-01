import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Permission management utilities
class PermissionsHelper {
  PermissionsHelper._();

  /// Request camera permission
  static Future<bool> requestCameraPermission(BuildContext context, {String locale = 'en'}) async {
    return _requestPermission(
      context,
      Permission.camera,
      locale: locale,
      permissionName: _getPermissionName('camera', locale),
      rationale: _getPermissionRationale('camera', locale),
    );
  }

  /// Request microphone permission
  static Future<bool> requestMicrophonePermission(BuildContext context, {String locale = 'en'}) async {
    return _requestPermission(
      context,
      Permission.microphone,
      locale: locale,
      permissionName: _getPermissionName('microphone', locale),
      rationale: _getPermissionRationale('microphone', locale),
    );
  }

  /// Request photo library permission
  static Future<bool> requestPhotosPermission(BuildContext context, {String locale = 'en'}) async {
    return _requestPermission(
      context,
      Permission.photos,
      locale: locale,
      permissionName: _getPermissionName('photos', locale),
      rationale: _getPermissionRationale('photos', locale),
    );
  }

  /// Request storage permission
  static Future<bool> requestStoragePermission(BuildContext context, {String locale = 'en'}) async {
    return _requestPermission(
      context,
      Permission.storage,
      locale: locale,
      permissionName: _getPermissionName('storage', locale),
      rationale: _getPermissionRationale('storage', locale),
    );
  }

  /// Request notification permission
  static Future<bool> requestNotificationPermission(BuildContext context, {String locale = 'en'}) async {
    return _requestPermission(
      context,
      Permission.notification,
      locale: locale,
      permissionName: _getPermissionName('notification', locale),
      rationale: _getPermissionRationale('notification', locale),
    );
  }

  /// Request location permission
  static Future<bool> requestLocationPermission(BuildContext context, {String locale = 'en'}) async {
    return _requestPermission(
      context,
      Permission.locationWhenInUse,
      locale: locale,
      permissionName: _getPermissionName('location', locale),
      rationale: _getPermissionRationale('location', locale),
    );
  }

  /// Request multiple permissions for video call
  static Future<bool> requestVideoCallPermissions(BuildContext context, {String locale = 'en'}) async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (cameraStatus.isDenied || micStatus.isDenied) {
      if (context.mounted) {
        await _showPermissionDeniedDialog(
          context,
          _getPermissionName('video_call', locale),
          _getPermissionRationale('video_call', locale),
          locale,
        );
      }
      return false;
    }

    if (cameraStatus.isPermanentlyDenied || micStatus.isPermanentlyDenied) {
      if (context.mounted) {
        await _showOpenSettingsDialog(context, locale);
      }
      return false;
    }

    return cameraStatus.isGranted && micStatus.isGranted;
  }

  /// Check if camera permission is granted
  static Future<bool> hasCameraPermission() async {
    return await Permission.camera.isGranted;
  }

  /// Check if microphone permission is granted
  static Future<bool> hasMicrophonePermission() async {
    return await Permission.microphone.isGranted;
  }

  /// Check if notification permission is granted
  static Future<bool> hasNotificationPermission() async {
    return await Permission.notification.isGranted;
  }

  static Future<bool> _requestPermission(
    BuildContext context,
    Permission permission, {
    required String locale,
    required String permissionName,
    required String rationale,
  }) async {
    final status = await permission.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await permission.request();
      if (result.isGranted) {
        return true;
      }
      if (context.mounted) {
        await _showPermissionDeniedDialog(context, permissionName, rationale, locale);
      }
      return false;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await _showOpenSettingsDialog(context, locale);
      }
      return false;
    }

    return false;
  }

  static Future<void> _showPermissionDeniedDialog(
    BuildContext context,
    String permissionName,
    String rationale,
    String locale,
  ) async {
    final titles = {
      'en': 'Permission Required',
      'ar': 'مطلوب إذن',
      'ru': 'Требуется разрешение',
    };

    final okTexts = {
      'en': 'OK',
      'ar': 'حسناً',
      'ru': 'ОК',
    };

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titles[locale] ?? titles['en']!),
        content: Text(rationale),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(okTexts[locale] ?? okTexts['en']!),
          ),
        ],
      ),
    );
  }

  static Future<void> _showOpenSettingsDialog(BuildContext context, String locale) async {
    final titles = {
      'en': 'Permission Denied',
      'ar': 'تم رفض الإذن',
      'ru': 'Разрешение отклонено',
    };

    final messages = {
      'en': 'This permission was permanently denied. Please enable it in app settings.',
      'ar': 'تم رفض هذا الإذن بشكل دائم. يرجى تمكينه في إعدادات التطبيق.',
      'ru': 'Разрешение было отклонено. Включите его в настройках приложения.',
    };

    final cancelTexts = {
      'en': 'Cancel',
      'ar': 'إلغاء',
      'ru': 'Отмена',
    };

    final settingsTexts = {
      'en': 'Open Settings',
      'ar': 'فتح الإعدادات',
      'ru': 'Открыть настройки',
    };

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titles[locale] ?? titles['en']!),
        content: Text(messages[locale] ?? messages['en']!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelTexts[locale] ?? cancelTexts['en']!),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(settingsTexts[locale] ?? settingsTexts['en']!),
          ),
        ],
      ),
    );

    if (result == true) {
      await openAppSettings();
    }
  }

  static String _getPermissionName(String permission, String locale) {
    final names = {
      'camera': {'en': 'Camera', 'ar': 'الكاميرا', 'ru': 'Камера'},
      'microphone': {'en': 'Microphone', 'ar': 'الميكروفون', 'ru': 'Микрофон'},
      'photos': {'en': 'Photos', 'ar': 'الصور', 'ru': 'Фото'},
      'storage': {'en': 'Storage', 'ar': 'التخزين', 'ru': 'Хранилище'},
      'notification': {'en': 'Notifications', 'ar': 'الإشعارات', 'ru': 'Уведомления'},
      'location': {'en': 'Location', 'ar': 'الموقع', 'ru': 'Местоположение'},
      'video_call': {'en': 'Camera & Microphone', 'ar': 'الكاميرا والميكروفون', 'ru': 'Камера и микрофон'},
    };
    return names[permission]?[locale] ?? names[permission]?['en'] ?? permission;
  }

  static String _getPermissionRationale(String permission, String locale) {
    final rationales = {
      'camera': {
        'en': 'Camera access is needed for video calls and scanning documents.',
        'ar': 'مطلوب الوصول إلى الكاميرا لإجراء مكالمات الفيديو ومسح المستندات.',
        'ru': 'Доступ к камере необходим для видеозвонков и сканирования документов.',
      },
      'microphone': {
        'en': 'Microphone access is needed for voice and video calls.',
        'ar': 'مطلوب الوصول إلى الميكروفون للمكالمات الصوتية والمرئية.',
        'ru': 'Доступ к микрофону необходим для голосовых и видеозвонков.',
      },
      'photos': {
        'en': 'Photo library access is needed to share medical images.',
        'ar': 'مطلوب الوصول إلى مكتبة الصور لمشاركة الصور الطبية.',
        'ru': 'Доступ к фото необходим для обмена медицинскими изображениями.',
      },
      'storage': {
        'en': 'Storage access is needed to save and share files.',
        'ar': 'مطلوب الوصول إلى التخزين لحفظ ومشاركة الملفات.',
        'ru': 'Доступ к хранилищу необходим для сохранения и обмена файлами.',
      },
      'notification': {
        'en': 'Notifications keep you updated on appointments and messages.',
        'ar': 'الإشعارات تبقيك على اطلاع بالمواعيد والرسائل.',
        'ru': 'Уведомления держат вас в курсе встреч и сообщений.',
      },
      'location': {
        'en': 'Location access helps find nearby clinics and doctors.',
        'ar': 'الوصول إلى الموقع يساعد في العثور على العيادات والأطباء القريبين.',
        'ru': 'Доступ к местоположению помогает найти ближайшие клиники.',
      },
      'video_call': {
        'en': 'Camera and microphone access are required for video consultations.',
        'ar': 'مطلوب الوصول إلى الكاميرا والميكروفون لإجراء الاستشارات المرئية.',
        'ru': 'Для видеоконсультаций необходим доступ к камере и микрофону.',
      },
    };
    return rationales[permission]?[locale] ?? rationales[permission]?['en'] ?? '';
  }
}
