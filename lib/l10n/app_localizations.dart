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
    // ---------------- الإنجليزية (English) ----------------
    'en': {
      'appTitle': 'Medical App',
      'login': 'Login',
      'signUp': 'Sign Up',
      'email': 'Email',
      'password': 'Password',
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
      'weakPassword': 'Weak password',
      'emailInUse': 'Email already in use',
      'pleaseEnterName': 'Please enter name',
      'invalidEmail': 'Invalid email',
      'phoneOptional': 'Phone (Optional)',
      'patient': 'Patient',
      'doctor': 'Doctor',
      'haveAccount': 'Already have an account?',
      'specializationOptional': 'Specialization (Optional)',
      'languageChanged': 'Language changed',
      'recordAdded': 'Record added successfully',
      'patientNotFound': 'Patient not found',
      'patientEmail': 'Patient Email',
      'diagnosis': 'Diagnosis',
      'prescription': 'Prescription',
      'notesOptional': 'Notes (Optional)',
      'save': 'Save',
      'qrForRecord': 'QR for Record',
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
      'scannedSuccessfully': 'Scanned successfully',
      'scanAgain': 'Scan again',
      'checkUp': 'Check-up',
      'imagingReview': 'Imaging Review',
      'userNotFound': 'User not found',
      'wrongPassword': 'Wrong password',
      'error': 'Error',
      'cancel': 'Cancel',
      'scanQR': 'Scan QR Code',
      'specialistConsultations': 'Specialist Consultations',
      'myRecords': 'My Records',
      'medicalTourism': 'Medical Tourism in Russia',

      // Doctor Card & Specs
      'yearsExperience': 'Years Experience',
      'rating': 'Rating',
      'bookAppointment': 'Book Appointment',
      'viewProfile': 'View Profile',
      'specGeneral': 'General Practice',
      'specCardiology': 'Cardiology',
      'specDermatology': 'Dermatology',
      'specPediatrics': 'Pediatrics',
      'specOrthopedics': 'Orthopedics',
      'specNeurology': 'Neurology',
      'specPsychiatry': 'Psychiatry',
      'specDentistry': 'Dentistry',
      'specOphthalmology': 'Ophthalmology',
    },

    // ---------------- العربية (Arabic) ----------------
    'ar': {
      'appTitle': 'التطبيق الطبي',
      'login': 'دخول',
      'signUp': 'تسجيل جديد',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'fullName': 'الاسم الكامل',
      'pleaseEnterEmail': 'يرجى إدخال البريد',
      'pleaseEnterPassword': 'يرجى إدخال كلمة المرور',
      'passwordTooShort': 'كلمة المرور قصيرة',
      'noAccount': 'ليس لديك حساب؟',
      'patientDashboard': 'لوحة المريض',
      'doctorDashboard': 'لوحة الطبيب',
      'language': 'اللغة',
      'logout': 'خروج',
      'newRecord': 'سجل جديد',
      'weakPassword': 'كلمة المرور ضعيفة',
      'emailInUse': 'البريد مستخدم بالفعل',
      'pleaseEnterName': 'يرجى إدخال الاسم',
      'invalidEmail': 'بريد غير صالح',
      'phoneOptional': 'الهاتف (اختياري)',
      'patient': 'مريض',
      'doctor': 'طبيب',
      'haveAccount': 'لديك حساب بالفعل؟',
      'specializationOptional': 'التخصص (اختياري)',
      'languageChanged': 'تم تغيير اللغة',
      'recordAdded': 'تم إضافة السجل بنجاح',
      'patientNotFound': 'المريض غير موجود',
      'patientEmail': 'بريد المريض',
      'diagnosis': 'التشخيص',
      'prescription': 'الوصفة',
      'notesOptional': 'ملاحظات (اختياري)',
      'save': 'حفظ',
      'qrForRecord': 'رمز QR للسجل',
      'patientCanScan': 'يمكن للمريض مسح الرمز',
      'date': 'التاريخ',
      'notes': 'ملاحظات',
      'shareQR': 'مشاركة الرمز',
      'shareFeatureComingSoon': 'الميزة تتوفر قريباً',
      'search': 'بحث',
      'searchHint': 'بحث في السجلات...',
      'dateRange': 'النطاق الزمني',
      'results': 'نتائج',
      'pointCameraToQR': 'وجه الكاميرا نحو الرمز',
      'scannedSuccessfully': 'تم المسح بنجاح',
      'scanAgain': 'امسح مرة أخرى',
      'checkUp': 'فحص طبي',
      'imagingReview': 'مراجعة صور الأشعة',
      'userNotFound': 'المستخدم غير موجود',
      'wrongPassword': 'كلمة المرور خاطئة',
      'error': 'خطأ',
      'cancel': 'إلغاء',
      'scanQR': 'مسح رمز QR',
      'specialistConsultations': 'استشارات تخصصية',
      'myRecords': 'سجلاتي الطبية',
      'medicalTourism': 'السياحة العلاجية في روسيا',

      // بطاقة الطبيب والتخصصات
      'yearsExperience': 'سنوات خبرة',
      'rating': 'التقييم',
      'bookAppointment': 'حجز موعد',
      'viewProfile': 'عرض الملف',
      'specGeneral': 'ممارس عام',
      'specCardiology': 'طب القلب',
      'specDermatology': 'جلدية',
      'specPediatrics': 'طب أطفال',
      'specOrthopedics': 'عظام',
      'specNeurology': 'مخ وأعصاب',
      'specPsychiatry': 'طب نفسي',
      'specDentistry': 'طب أسنان',
      'specOphthalmology': 'عيون',
    },

    // ---------------- الروسية (Russian) ----------------
    'ru': {
      'appTitle': 'Медицинское приложение',
      'login': 'Вход',
      'signUp': 'Регистрация',
      'email': 'Электронная почта',
      'password': 'Пароль',
      'fullName': 'ФИО',
      'pleaseEnterEmail': 'Введите email',
      'pleaseEnterPassword': 'Введите пароль',
      'passwordTooShort': 'Пароль слишком короткий',
      'noAccount': 'Нет аккаунта?',
      'patientDashboard': 'Панель пациента',
      'doctorDashboard': 'Панель врача',
      'language': 'Язык',
      'logout': 'Выйти',
      'newRecord': 'Новая запись',
      'weakPassword': 'Слабый пароль',
      'emailInUse': 'Email уже используется',
      'pleaseEnterName': 'Введите имя',
      'invalidEmail': 'Неверный email',
      'phoneOptional': 'Телефон (необязательно)',
      'patient': 'Пациент',
      'doctor': 'Врач',
      'haveAccount': 'Уже есть аккаунт?',
      'specializationOptional': 'Специализация (необязательно)',
      'languageChanged': 'Язык изменен',
      'recordAdded': 'Запись успешно добавлена',
      'patientNotFound': 'Пациент не найден',
      'patientEmail': 'Email пациента',
      'diagnosis': 'Диагноз',
      'prescription': 'Назначение / Рецепт',
      'notesOptional': 'Заметки (необязательно)',
      'save': 'Сохранить',
      'qrForRecord': 'QR-код записи',
      'patientCanScan': 'Пациент может отсканировать',
      'date': 'Дата',
      'notes': 'Заметки',
      'shareQR': 'Поделиться QR',
      'shareFeatureComingSoon': 'Функция скоро будет доступна',
      'search': 'Поиск',
      'searchHint': 'Поиск записей...',
      'dateRange': 'Диапазон дат',
      'results': 'Результаты',
      'pointCameraToQR': 'Наведите камеру на QR',
      'scannedSuccessfully': 'Успешно отсканировано',
      'scanAgain': 'Сканировать снова',
      'checkUp': 'Осмотр',
      'imagingReview': 'Обзор снимков',
      'userNotFound': 'Пользователь не найден',
      'wrongPassword': 'Неверный пароль',
      'error': 'Ошибка',
      'cancel': 'Отмена',
      'scanQR': 'Сканировать QR',
      'specialistConsultations': 'Консультации специалистов',
      'myRecords': 'Мои медицинские записи',
      'medicalTourism': 'Медицинский туризм в России',

      // Doctor Card & Specs (Russian)
      'yearsExperience': 'Лет опыта',
      'rating': 'Рейтинг',
      'bookAppointment': 'Записаться',
      'viewProfile': 'Профиль',
      'specGeneral': 'Терапевт',
      'specCardiology': 'Кардиология',
      'specDermatology': 'Дерматология',
      'specPediatrics': 'Педиатрия',
      'specOrthopedics': 'Ортопедия',
      'specNeurology': 'Неврология',
      'specPsychiatry': 'Психиатрия',
      'specDentistry': 'Стоматология',
      'specOphthalmology': 'Офтальмология',
    }
  };

  String _get(String key) => _localizedValues[locale.languageCode]?[key] ?? _localizedValues['en']![key] ?? key;

  // --- Getters (لكل النصوص المستخدمة) ---
  String get appTitle => _get('appTitle');
  String get login => _get('login');
  String get signUp => _get('signUp');
  String get email => _get('email');
  String get password => _get('password');
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
  String get userNotFound => _get('userNotFound');
  String get wrongPassword => _get('wrongPassword');
  String get error => _get('error');
  String get cancel => _get('cancel');
  String get scanQR => _get('scanQR');
  String get specialistConsultations => _get('specialistConsultations');
  String get myRecords => _get('myRecords');
  String get medicalTourism => _get('medicalTourism');

  // --- Getters الجديدة (للبطاقة والتخصصات) ---
  String get yearsExperience => _get('yearsExperience');
  String get rating => _get('rating');
  String get bookAppointment => _get('bookAppointment');
  String get viewProfile => _get('viewProfile');

  String get specGeneral => _get('specGeneral');
  String get specCardiology => _get('specCardiology');
  String get specDermatology => _get('specDermatology');
  String get specPediatrics => _get('specPediatrics');
  String get specOrthopedics => _get('specOrthopedics');
  String get specNeurology => _get('specNeurology');
  String get specPsychiatry => _get('specPsychiatry');
  String get specDentistry => _get('specDentistry');
  String get specOphthalmology => _get('specOphthalmology');
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
