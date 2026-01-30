import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Auth & Errors
      'userNotFound': 'User not found',
      'wrongPassword': 'Wrong password',
      'error': 'An error occurred',
      'cancel': 'Cancel',
      
      // Home & Navigation
      'scanQR': 'Scan QR Code',
      'specialistConsultations': 'Specialist Consultations',
      'myRecords': 'My Medical Records',
      'medicalTourism': 'Medical Tourism in Russia',
      
      // ... (أضف بقية المفاتيح السابقة هنا للتأكد من شمولية الملف)
      'pointCameraToQR': 'Point camera to QR',
      'scannedSuccessfully': 'Scanned successfully',
      'scanAgain': 'Scan again',
      'login': 'Login',
      'password': 'Password',
      'email': 'Email',
    },
    'ar': {
      // المصادقة والأخطاء
      'userNotFound': 'المستخدم غير موجود',
      'wrongPassword': 'كلمة المرور خاطئة',
      'error': 'حدث خطأ ما',
      'cancel': 'إلغاء',
      
      // الرئيسية والتنقل
      'scanQR': 'مسح رمز QR',
      'specialistConsultations': 'استشارات تخصصية',
      'myRecords': 'سجلاتي الطبية',
      'medicalTourism': 'السياحة العلاجية في روسيا',
      
      'pointCameraToQR': 'وجه الكاميرا نحو الرمز',
      'scannedSuccessfully': 'تم المسح بنجاح',
      'scanAgain': 'امسح مرة أخرى',
      'login': 'دخول',
      'password': 'كلمة المرور',
      'email': 'البريد الإلكتروني',
    }
  };

  String _get(String key) => _localizedValues[locale.languageCode]?[key] ?? _localizedValues['en']![key] ?? key;

  // --- القائمة الكاملة للـ Getters المطلوبة لإصلاح الأخطاء ---
  String get userNotFound => _get('userNotFound');
  String get wrongPassword => _get('wrongPassword');
  String get error => _get('error');
  String get cancel => _get('cancel');
  String get scanQR => _get('scanQR');
  String get specialistConsultations => _get('specialistConsultations');
  String get myRecords => _get('myRecords');
  String get medicalTourism => _get('medicalTourism');
  
  // تأكد من وجود Getters القديمة أيضاً
  String get pointCameraToQR => _get('pointCameraToQR');
  String get scannedSuccessfully => _get('scannedSuccessfully');
  String get scanAgain => _get('scanAgain');
  String get login => _get('login');
  String get email => _get('email');
  String get password => _get('password');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => ['en', 'ar', 'ru'].contains(locale.languageCode);
  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
