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
      'appTitle': 'Medical App',
      'email': 'Email',
      'password': 'Password',
      'login': 'Login',
      'signUp': 'Sign Up',
      'fullName': 'Full Name',
      'pleaseEnterEmail': 'Please enter email',
      'pleaseEnterPassword': 'Please enter password',
      'passwordTooShort': 'Password too short',
      'noAccount': "Don't have an account?",
      'patientDashboard': 'Patient Dashboard',
      'doctorDashboard': 'Doctor Dashboard',
      'language': 'Language',
      'logout': 'Logout',
      'newRecord': 'New Record',
      'weakPassword': 'Password is weak',
      'emailInUse': 'Email already in use',
      'pleaseEnterName': 'Please enter name',
      'invalidEmail': 'Invalid email',
      'phoneOptional': 'Phone (Optional)',
      'patient': 'Patient',
      'doctor': 'Doctor',
      'haveAccount': 'Already have an account?',
      'specializationOptional': 'Specialization (Optional)',
      'languageChanged': 'Language Changed',
      'recordAdded': 'Record Added',
      'patientNotFound': 'Patient Not Found',
      'patientEmail': 'Patient Email',
      'diagnosis': 'Diagnosis',
      'prescription': 'Prescription',
      'notesOptional': 'Notes (Optional)',
      'save': 'Save',
      'qrForRecord': 'QR for Medical Record',
      'patientCanScan': 'Patient can scan this',
      'date': 'Date',
      'notes': 'Notes',
      'shareQR': 'Share QR',
      'shareFeatureComingSoon': 'Feature coming soon',
      'search': 'Search',
      'searchHint': 'Search records...',
      'dateRange': 'Date Range',
      'results': 'Results',
      'pointCameraToQR': 'Point camera to QR',
      'scannedSuccessfully': 'Scanned!',
      'scanAgain': 'Scan Again',
      'checkUp': 'Medical Check-up',
      'imagingReview': 'Imaging Review',
    },
    'ar': {
      'appTitle': 'التطبيق الطبي',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'login': 'دخول',
      'signUp': 'تسجيل جديد',
      'fullName': 'الاسم الكامل',
      'pleaseEnterEmail': 'يرجى إدخال البريد',
      'pleaseEnterPassword': 'يرجى إدخال كلمة المرور',
      'passwordTooShort': 'كلمة المرور قصيرة',
      'noAccount': 'ليس لديك حساب؟',
      'patientDashboard': 'واجهة المريض',
      'doctorDashboard': 'واجهة الطبيب',
      'language': 'اللغة',
      'logout': 'خروج',
      'newRecord': 'سجل جديد',
      'weakPassword': 'كلمة المرور ضعيفة',
      'emailInUse': 'البريد مستخدم مسبقاً',
      'pleaseEnterName': 'يرجى إدخال الاسم',
      'invalidEmail': 'بريد غير صالح',
      'phoneOptional': 'الهاتف (اختياري)',
      'patient': 'مريض',
      'doctor': 'طبيب',
      'haveAccount': 'لديك حساب بالفعل؟',
      'specializationOptional': 'التخصص (اختياري)',
      'languageChanged': 'تم تغيير اللغة',
      'recordAdded': 'تم إضافة السجل',
      'patientNotFound': 'المريض غير موجود',
      'patientEmail': 'بريد المريض',
      'diagnosis': 'التشخيص',
      'prescription': 'الوصفة',
      'notesOptional': 'ملاحظات (اختياري)',
      'save': 'حفظ',
      'qrForRecord': 'رمز QR للسجل',
      'patientCanScan': 'يمكن للمريض مسح الرمز',
      'date': 'التاريخ',
      'notes': 'الملاحظات',
      'shareQR': 'مشاركة الرمز',
      'shareFeatureComingSoon': 'الميزة ستتوفر قريباً',
      'search': 'بحث',
      'searchHint': 'ابحث في السجلات...',
      'dateRange': 'النطاق الزمني',
      'results': 'نتائج',
      'pointCameraToQR': 'وجه الكاميرا نحو الرمز',
      'scannedSuccessfully': 'تم المسح بنجاح',
      'scanAgain': 'امسح مرة أخرى',
      'checkUp': 'فحص طبي',
      'imagingReview': 'مراجعة الصور الطبية',
    }
  };

  String _get(String key) => _localizedValues[locale.languageCode]?[key] ?? _localizedValues['en']![key] ?? key;

  // Getters (يجب أن تتطابق الأسماء تماماً مع ما تستدعيه في الشاشات)
  String get appTitle => _get('appTitle');
  String get email => _get('email');
  String get password => _get('password');
  String get login => _get('login');
  String get signUp => _get('signUp');
  String get fullName => _get('fullName');
  String get pleaseEnterEmail => _get('pleaseEnterEmail');
  String get pleaseEnterPassword => _get('pleaseEnterPassword');
  String get passwordTooShort => _get('passwordTooShort');
  String get noAccount => _get('noAccount');
  String get patientDashboard => _get('patientDashboard');
  String get doctorDashboard => _get('doctorDashboard');
  String get language => _get('language');
  String get logout => _get('logout');
  String get newRecord => _get('newRecord');
  String get weakPassword => _get('weakPassword');
  String get emailInUse => _get('emailInUse');
  String get pleaseEnterName => _get('pleaseEnterName');
  String get invalidEmail => _get('invalidEmail');
  String get phoneOptional => _get('phoneOptional');
  String get patient => _get('patient');
  String get doctor => _get('doctor');
  String get haveAccount => _get('haveAccount');
  String get specializationOptional => _get('specializationOptional');
  String get languageChanged => _get('languageChanged');
  String get recordAdded => _get('recordAdded');
  String get patientNotFound => _get('patientNotFound');
  String get patientEmail => _get('patientEmail');
  String get diagnosis => _get('diagnosis');
  String get prescription => _get('prescription');
  String get notesOptional => _get('notesOptional');
  String get save => _get('save');
  String get qrForRecord => _get('qrForRecord');
  String get patientCanScan => _get('patientCanScan');
  String get date => _get('date');
  String get notes => _get('notes');
  String get shareQR => _get('shareQR');
  String get shareFeatureComingSoon => _get('shareFeatureComingSoon');
  String get search => _get('search');
  String get searchHint => _get('searchHint');
  String get dateRange => _get('dateRange');
  String get results => _get('results');
  String get pointCameraToQR => _get('pointCameraToQR');
  String get scannedSuccessfully => _get('scannedSuccessfully');
  String get scanAgain => _get('scanAgain');
  String get checkUp => _get('checkUp');
  String get imagingReview => _get('imagingReview');
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
