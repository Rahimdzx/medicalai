import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Centralized error handling utilities
class ErrorHandler {
  ErrorHandler._();

  /// Convert Firebase Auth errors to user-friendly messages
  static String getFirebaseAuthErrorMessage(FirebaseAuthException error, {String locale = 'en'}) {
    final messages = _firebaseAuthMessages[error.code];
    return messages?[locale] ?? messages?['en'] ?? error.message ?? _getDefaultError(locale);
  }

  /// Convert general exceptions to user-friendly messages
  static String getErrorMessage(dynamic error, {String locale = 'en'}) {
    if (error is FirebaseAuthException) {
      return getFirebaseAuthErrorMessage(error, locale: locale);
    }

    if (error is FirebaseException) {
      return _getFirebaseErrorMessage(error.code, locale);
    }

    // Network errors
    if (error.toString().contains('SocketException') ||
        error.toString().contains('network') ||
        error.toString().contains('connection')) {
      return _getNetworkError(locale);
    }

    // Timeout errors
    if (error.toString().contains('timeout') || error.toString().contains('TimeoutException')) {
      return _getTimeoutError(locale);
    }

    return _getDefaultError(locale);
  }

  /// Show error snackbar
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show info snackbar
  static void showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show error dialog
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? buttonText,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(buttonText ?? 'OK'),
          ),
        ],
      ),
    );
  }

  /// Show confirmation dialog
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDangerous
                ? TextButton.styleFrom(foregroundColor: Colors.red)
                : null,
            child: Text(confirmText ?? 'Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // Firebase Auth error messages
  static const Map<String, Map<String, String>> _firebaseAuthMessages = {
    'user-not-found': {
      'en': 'No account found with this email',
      'ar': 'لا يوجد حساب بهذا البريد الإلكتروني',
      'ru': 'Аккаунт с этим email не найден',
    },
    'wrong-password': {
      'en': 'Incorrect password',
      'ar': 'كلمة المرور غير صحيحة',
      'ru': 'Неверный пароль',
    },
    'email-already-in-use': {
      'en': 'This email is already registered',
      'ar': 'هذا البريد الإلكتروني مسجل بالفعل',
      'ru': 'Этот email уже зарегистрирован',
    },
    'weak-password': {
      'en': 'Password is too weak',
      'ar': 'كلمة المرور ضعيفة جداً',
      'ru': 'Слишком слабый пароль',
    },
    'invalid-email': {
      'en': 'Invalid email address',
      'ar': 'عنوان البريد الإلكتروني غير صالح',
      'ru': 'Недействительный email адрес',
    },
    'user-disabled': {
      'en': 'This account has been disabled',
      'ar': 'تم تعطيل هذا الحساب',
      'ru': 'Этот аккаунт отключен',
    },
    'too-many-requests': {
      'en': 'Too many attempts. Please try again later',
      'ar': 'محاولات كثيرة جداً. حاول مرة أخرى لاحقاً',
      'ru': 'Слишком много попыток. Попробуйте позже',
    },
    'operation-not-allowed': {
      'en': 'This operation is not allowed',
      'ar': 'هذه العملية غير مسموح بها',
      'ru': 'Эта операция не разрешена',
    },
    'requires-recent-login': {
      'en': 'Please log in again to continue',
      'ar': 'يرجى تسجيل الدخول مرة أخرى للمتابعة',
      'ru': 'Пожалуйста, войдите снова для продолжения',
    },
    'network-request-failed': {
      'en': 'Network error. Please check your connection',
      'ar': 'خطأ في الشبكة. يرجى التحقق من اتصالك',
      'ru': 'Ошибка сети. Проверьте подключение',
    },
  };

  static String _getFirebaseErrorMessage(String code, String locale) {
    final messages = {
      'permission-denied': {
        'en': 'You do not have permission to perform this action',
        'ar': 'ليس لديك إذن للقيام بهذا الإجراء',
        'ru': 'У вас нет разрешения на это действие',
      },
      'unavailable': {
        'en': 'Service temporarily unavailable. Please try again',
        'ar': 'الخدمة غير متاحة مؤقتاً. حاول مرة أخرى',
        'ru': 'Сервис временно недоступен. Попробуйте снова',
      },
      'cancelled': {
        'en': 'Operation was cancelled',
        'ar': 'تم إلغاء العملية',
        'ru': 'Операция отменена',
      },
    };
    return messages[code]?[locale] ?? messages[code]?['en'] ?? _getDefaultError(locale);
  }

  static String _getNetworkError(String locale) {
    const messages = {
      'en': 'No internet connection. Please check your network',
      'ar': 'لا يوجد اتصال بالإنترنت. يرجى التحقق من شبكتك',
      'ru': 'Нет подключения к интернету. Проверьте сеть',
    };
    return messages[locale] ?? messages['en']!;
  }

  static String _getTimeoutError(String locale) {
    const messages = {
      'en': 'Request timed out. Please try again',
      'ar': 'انتهت مهلة الطلب. حاول مرة أخرى',
      'ru': 'Время ожидания истекло. Попробуйте снова',
    };
    return messages[locale] ?? messages['en']!;
  }

  static String _getDefaultError(String locale) {
    const messages = {
      'en': 'Something went wrong. Please try again',
      'ar': 'حدث خطأ ما. حاول مرة أخرى',
      'ru': 'Что-то пошло не так. Попробуйте снова',
    };
    return messages[locale] ?? messages['en']!;
  }
}
