import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'Medical App',
      'email': 'Email',
      'password': 'Password',
      'login': 'Login',
      'signUp': 'Sign Up',
      'fullName': 'Full Name',
      'patientName': 'Patient Name',
      'phone': 'Phone Number',
      'specialization': 'Specialization',
      'patient': 'Patient',
      'doctor': 'Doctor',
      'logout': 'Logout',
      'myRecords': 'My Medical Records',
      'scanQR': 'Scan QR Code',
      'specialistConsultations': 'Specialist Consultations', // مضاف
      'medicalTourism': 'Medical Tourism', // مضاف
      'error': 'Error',
      'cancel': 'Cancel',
      'save': 'Save',
      // ... بقية كلماتك الإنجليزية السابقة ...
    },
    'ar': {
      'appTitle': 'التطبيق الطبي',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'login': 'تسجيل الدخول',
      'signUp': 'إنشاء حساب',
      'fullName': 'الاسم الكامل',
      'patientName': 'اسم المريض',
      'phone': 'رقم الهاتف',
      'specialization': 'التخصص',
      'patient': 'مريض',
      'doctor': 'طبيب',
      'logout': 'تسجيل الخروج',
      'myRecords': 'سجلاتي الطبية',
      'scanQR': 'مسح رمز QR',
      'specialistConsultations': 'استشارات تخصصية', // مضاف
      'medicalTourism': 'السياحة العلاجية', // مضاف
      'error': 'خطأ',
      'cancel': 'إلغاء',
      'save': 'حفظ',
      // ... بقية كلماتك العربية السابقة ...
    },
    'ru': {
      'appTitle': 'Медицинское приложение',
      'email': 'Электронная почта',
      'password': 'Пароль',
      'login': 'Войти',
      'signUp': 'Регистрация',
      'fullName': 'Полное имя',
      'patientName': 'Имя пациента',
      'phone': 'Номер телефона',
      'specialization': 'Специализация',
      'patient': 'Пациент',
      'doctor': 'Врач',
      'logout': 'Выйти',
      'myRecords': 'Мои записи',
      'scanQR': 'Сканировать QR',
      'specialistConsultations': 'Консультации специалистов', // مضاف
      'medicalTourism': 'Медицинский туризм', // مضاف
      'error': 'Ошибка',
      'cancel': 'Отмена',
      'save': 'Сохранить',
      // ... بقية كلماتك الروسية السابقة ...
    },
  };

  String _get(String key) {
    // تصحيح: التأكد من عدم حدوث تعطل إذا كان المفتاح غير موجود نهائياً
    return _localizedValues[locale.languageCode]?[key] ??
           _localizedValues['en']?[key] ?? 
           key; // إرجاع اسم المفتاح نفسه كحل أخير بدلاً من الانهيار
  }

  // Getters - تأكد من إضافة الـ Getters للقيم الجديدة
  String get appTitle => _get('appTitle');
  String get scanQR => _get('scanQR');
  String get specialistConsultations => _get('specialistConsultations');
  String get medicalTourism => _get('medicalTourism');
  String get myRecords => _get('myRecords');
  String get login => _get('login');
  String get error => _get('error');
  String get cancel => _get('cancel');
  // ... أضف بقية الـ Getters هنا بنفس الطريقة ...
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
