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
      'patientName': 'Patient Name', // مضاف
      'phone': 'Phone Number',
      'phoneOptional': 'Phone Number (optional)',
      'specialization': 'Specialization',
      'specializationOptional': 'Specialization (optional)',
      'patient': 'Patient',
      'doctor': 'Doctor',
      'logout': 'Logout',
      'patientDashboard': 'Patient Dashboard',
      'doctorDashboard': 'Doctor Dashboard',
      'myRecords': 'My Medical Records',
      'patientRecords': 'Patient Records',
      'scanQR': 'Scan QR Code',
      'generateQR': 'Generate QR Code',
      'newRecord': 'New Record',
      'diagnosis': 'Diagnosis',
      'prescription': 'Prescription',
      'notes': 'Notes',
      'notesOptional': 'Notes (optional)',
      'date': 'Date',
      'save': 'Save',
      'cancel': 'Cancel',
      'close': 'Close',
      'patientEmail': 'Patient Email',
      'recordDetails': 'Medical Record Details',
      'noRecordsYet': 'No medical records yet',
      'noRecords': 'No records yet',
      'error': 'Error',
      'success': 'Success',
      'loading': 'Loading...',
      'pleaseEnterEmail': 'Please enter email',
      'pleaseEnterPassword': 'Please enter password',
      'pleaseEnterName': 'Please enter name',
      'invalidEmail': 'Invalid email',
      'passwordTooShort': 'Password must be at least 6 characters',
      'noAccount': "Don't have an account? Sign up",
      'haveAccount': 'Have an account? Login',
      'userNotFound': 'No user found with this email',
      'wrongPassword': 'Wrong password',
      'weakPassword': 'Password is too weak',
      'emailInUse': 'Email is already in use',
      'recordAdded': 'Record added successfully',
      'patientNotFound': 'Patient not found',
      'qrScanned': 'QR Code scanned successfully!',
      'notScannedYet': 'Not scanned yet',
      'scannedSuccessfully': 'Scanned successfully!',
      'scanAgain': 'Scan again',
      'pointCameraToQR': 'Point camera at QR Code',
      'qrForRecord': 'QR Code for Medical Record',
      'shareQR': 'Share QR Code',
      'shareFeatureComingSoon': 'Save and share feature coming soon',
      'patientCanScan': 'Patient can scan this code to get medical record information',
      'settings': 'Settings',
      'language': 'Language',
      'selectLanguage': 'Select Language',
      'arabic': 'Arabic',
      'russian': 'Russian',
      'english': 'English',
      'languageChanged': 'Language changed successfully',
      'search': 'Search',
      'searchHint': 'Search by patient, diagnosis...',
      'medicalHistory': 'Medical History',
      'noMedicalHistory': 'No medical history yet',
      'medicationReminders': 'Reminders',
      'noReminders': 'No reminders set',
      'addReminder': 'Add Reminder',
      'medicationName': 'Medication Name',
      'dosage': 'Dosage',
      'reminderTime': 'Reminder Time',
      'repeatDays': 'Repeat on days',
      'reminderAdded': 'Reminder added',
      'deleteReminder': 'Delete Reminder',
      'deleteReminderConfirm': 'Are you sure you want to delete this?',
      'delete': 'Delete',
      'exportPdf': 'Export as PDF',
      'exportAll': 'Export All',
      'patientHistory': 'Patient History',
      'print': 'Print',
      'noMedicalRecords': 'No medical records found',
      'createPatientQuestion': 'Patient not found. Create new profile?',
      'create': 'Create',
      'pleaseEnterDiagnosis': 'Please enter diagnosis',
      'pleaseEnterPrescription': 'Please enter prescription',
      'dateRange': 'Date Range',
      'results': 'results',
    },
    'ar': {
      'appTitle': 'التطبيق الطبي',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'login': 'تسجيل الدخول',
      'signUp': 'إنشاء حساب',
      'fullName': 'الاسم الكامل',
      'patientName': 'اسم المريض', // مضاف
      'phone': 'رقم الهاتف',
      'phoneOptional': 'رقم الهاتف (اختياري)',
      'specialization': 'التخصص',
      'specializationOptional': 'التخصص (اختياري)',
      'patient': 'مريض',
      'doctor': 'طبيب',
      'logout': 'تسجيل الخروج',
      'patientDashboard': 'لوحة تحكم المريض',
      'doctorDashboard': 'لوحة تحكم الطبيب',
      'myRecords': 'سجلاتي الطبية',
      'patientRecords': 'سجلات المرضى',
      'scanQR': 'مسح QR Code',
      'generateQR': 'إنشاء QR Code',
      'newRecord': 'سجل جديد',
      'diagnosis': 'التشخيص',
      'prescription': 'الوصفة الطبية',
      'notes': 'ملاحظات',
      'notesOptional': 'ملاحظات (اختياري)',
      'date': 'التاريخ',
      'save': 'حفظ',
      'cancel': 'إلغاء',
      'close': 'إغلاق',
      'patientEmail': 'البريد الإلكتروني للمريض',
      'recordDetails': 'تفاصيل السجل الطبي',
      'noRecordsYet': 'لا توجد سجلات طبية حتى الآن',
      'noRecords': 'لا توجد سجلات حتى الآن',
      'error': 'خطأ',
      'success': 'نجاح',
      'loading': 'جاري التحميل...',
      'pleaseEnterEmail': 'الرجاء إدخال البريد الإلكتروني',
      'pleaseEnterPassword': 'الرجاء إدخال كلمة المرور',
      'pleaseEnterName': 'الرجاء إدخال الاسم',
      'invalidEmail': 'البريد الإلكتروني غير صالح',
      'passwordTooShort': 'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
      'noAccount': 'ليس لديك حساب؟ إنشاء حساب جديد',
      'haveAccount': 'لديك حساب؟ تسجيل الدخول',
      'userNotFound': 'لا يوجد مستخدم بهذا البريد الإلكتروني',
      'wrongPassword': 'كلمة المرور غير صحيحة',
      'weakPassword': 'كلمة المرور ضعيفة جداً',
      'emailInUse': 'البريد الإلكتروني مستخدم بالفعل',
      'recordAdded': 'تم إضافة السجل بنجاح',
      'patientNotFound': 'لم يتم العثور على المريض',
      'qrScanned': 'تم مسح QR Code بنجاح!',
      'notScannedYet': 'لم يتم المسح بعد',
      'scannedSuccessfully': 'تم المسح بنجاح!',
      'scanAgain': 'مسح مرة أخرى',
      'pointCameraToQR': 'وجّه الكاميرا نحو QR Code',
      'qrForRecord': 'QR Code للسجل الطبي',
      'shareQR': 'مشاركة QR Code',
      'shareFeatureComing Soon': 'ميزة الحفظ والمشاركة قيد التطوير',
      'patientCanScan': 'يمكن للمريض مسح هذا الكود للحصول على معلومات السجل الطبي',
      'settings': 'الإعدادات',
      'language': 'اللغة',
      'selectLanguage': 'اختر اللغة',
      'arabic': 'العربية',
      'russian': 'الروسية',
      'english': 'الإنجليزية',
      'languageChanged': 'تم تغيير اللغة بنجاح',
      'search': 'بحث',
      'searchHint': 'ابحث بالمريض، التشخيص...',
      'medicalHistory': 'السجل الطبي',
      'noMedicalHistory': 'لا يوجد سجل طبي حتى الآن',
      'medicationReminders': 'التنبيهات',
      'noReminders': 'لا توجد تنبيهات معدة',
      'addReminder': 'إضافة تنبيه',
      'medicationName': 'اسم الدواء',
      'dosage': 'الجرعة',
      'reminderTime': 'وقت التنبيه',
      'repeatDays': 'تكرار في أيام',
      'reminderAdded': 'تم إضافة التنبيه',
      'deleteReminder': 'حذف التنبيه',
      'deleteReminderConfirm': 'هل أنت متأكد من حذف هذا التنبيه؟',
      'delete': 'حذف',
      'exportPdf': 'تصدير PDF',
      'exportAll': 'تصدير الكل',
      'patientHistory': 'تاريخ المريض',
      'print': 'طباعة',
      'noMedicalRecords': 'لم يتم العثور على سجلات طبية',
      'createPatientQuestion': 'المريض غير موجود، هل تريد إنشاء ملف جديد؟',
      'create': 'إنشاء',
      'pleaseEnterDiagnosis': 'الرجاء إدخال التشخيص',
      'pleaseEnterPrescription': 'الرجاء إدخال الوصفة',
      'dateRange': 'الفترة الزمنية',
      'results': 'نتائج',
    },
    'ru': {
      'appTitle': 'Медицинское приложение',
      'email': 'Электронная почта',
      'password': 'Пароль',
      'login': 'Войти',
      'signUp': 'Регистрация',
      'fullName': 'Полное имя',
      'patientName': 'Имя пациента', // مضاف
      'phone': 'Номер телефона',
      'phoneOptional': 'Номер телефона (необязательно)',
      'specialization': 'Специализация',
      'specializationOptional': 'Специализация (необязательно)',
      'patient': 'Пациент',
      'doctor': 'Врач',
      'logout': 'Выйти',
      'patientDashboard': 'Панель пациента',
      'doctorDashboard': 'Панель врача',
      'myRecords': 'Мои медицинские записи',
      'patientRecords': 'Записи пациентов',
      'scanQR': 'Сканировать QR-код',
      'generateQR': 'Создать QR-код',
      'newRecord': 'Новая запись',
      'diagnosis': 'Диагноз',
      'prescription': 'Рецепт',
      'notes': 'Заметки',
      'notesOptional': 'Заметки (необязательно)',
      'date': 'Дата',
      'save': 'Сохранить',
      'cancel': 'Отмена',
      'close': 'Закрыть',
      'patientEmail': 'Email пациента',
      'recordDetails': 'Детали медицинской записи',
      'noRecordsYet': 'Пока нет медицинских записей',
      'noRecords': 'Пока нет записей',
      'error': 'Ошибка',
      'success': 'Успешно',
      'loading': 'Загрузка...',
      'pleaseEnterEmail': 'Введите email',
      'pleaseEnterPassword': 'Введите пароль',
      'pleaseEnterName': 'Введите имя',
      'invalidEmail': 'Неверный email',
      'passwordTooShort': 'Пароль должен быть не менее 6 символов',
      'noAccount': 'Нет аккаунта? Зарегистрируйтесь',
      'haveAccount': 'Есть аккаунт? Войдите',
      'userNotFound': 'Пользователь не найден',
      'wrongPassword': 'Неверный пароль',
      'weakPassword': 'Слишком слабый пароль',
      'emailInUse': 'Email уже используется',
      'recordAdded': 'Запись добавлена',
      'patientNotFound': 'Пациент не найден',
      'qrScanned': 'QR-код отсканирован!',
      'notScannedYet': 'Ещё не отсканировано',
      'scannedSuccessfully': 'Успешно отсканировано!',
      'scanAgain': 'Сканировать снова',
      'pointCameraToQR': 'Наведите камеру на QR-код',
      'qrForRecord': 'QR-код медицинской записи',
      'shareQR': 'Поделиться QR-кодом',
      'shareFeatureComingSoon': 'Функция скоро будет доступна',
      'patientCanScan': 'Пациент может отсканировать этот код',
      'settings': 'Настройки',
      'language': 'Язык',
      'selectLanguage': 'Выберите язык',
      'arabic': 'Арабский',
      'russian': 'Русский',
      'english': 'Английский',
      'languageChanged': 'Язык изменён',
      'search': 'Поиск',
      'searchHint': 'Поиск пациента...',
      'medicalHistory': 'История болезни',
      'noMedicalHistory': 'Истории болезни пока нет',
      'medicationReminders': 'Напоминания',
      'noReminders': 'Напоминаний нет',
      'addReminder': 'Добавить',
      'medicationName': 'Название лекарства',
      'dosage': 'Дозировка',
      'reminderTime': 'Время',
      'repeatDays': 'Повтор по дням',
      'reminderAdded': 'Напоминание добавлено',
      'deleteReminder': 'Удалить',
      'deleteReminderConfirm': 'Вы уверены?',
      'delete': 'Удалить',
      'exportPdf': 'Экспорт PDF',
      'exportAll': 'Экспорт всего',
      'patientHistory': 'История пациента',
      'print': 'Печать',
      'noMedicalRecords': 'Записей не найдено',
      'createPatientQuestion': 'Создать профиль?',
      'create': 'Создать',
      'pleaseEnterDiagnosis': 'Введите диагноз',
      'pleaseEnterPrescription': 'Введите рецепт',
      'dateRange': 'Период',
      'results': 'результаты',
    },
  };

  String _get(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']![key]!;
  }

  // Getters
  String get appTitle => _get('appTitle');
  String get email => _get('email');
  String get password => _get('password');
  String get login => _get('login');
  String get signUp => _get('signUp');
  String get fullName => _get('fullName');
  String get patientName => _get('patientName'); // مضاف
  String get phone => _get('phone');
  String get phoneOptional => _get('phoneOptional');
  String get specialization => _get('specialization');
  String get specializationOptional => _get('specializationOptional');
  String get patient => _get('patient');
  String get doctor => _get('doctor');
  String get logout => _get('logout');
  String get patientDashboard => _get('patientDashboard');
  String get doctorDashboard => _get('doctorDashboard');
  String get myRecords => _get('myRecords');
  String get patientRecords => _get('patientRecords');
  String get scanQR => _get('scanQR');
  String get generateQR => _get('generateQR');
  String get newRecord => _get('newRecord');
  String get diagnosis => _get('diagnosis');
  String get prescription => _get('prescription');
  String get notes => _get('notes');
  String get notesOptional => _get('notesOptional');
  String get date => _get('date');
  String get save => _get('save');
  String get cancel => _get('cancel');
  String get close => _get('close');
  String get patientEmail => _get('patientEmail');
  String get recordDetails => _get('recordDetails');
  String get noRecordsYet => _get('noRecordsYet');
  String get noRecords => _get('noRecords');
  String get error => _get('error');
  String get success => _get('success');
  String get loading => _get('loading');
  String get pleaseEnterEmail => _get('pleaseEnterEmail');
  String get pleaseEnterPassword => _get('pleaseEnterPassword');
  String get pleaseEnterName => _get('pleaseEnterName');
  String get invalidEmail => _get('invalidEmail');
  String get passwordTooShort => _get('passwordTooShort');
  String get noAccount => _get('noAccount');
  String get haveAccount => _get('haveAccount');
  String get userNotFound => _get('userNotFound');
  String get wrongPassword => _get('wrongPassword');
  String get weakPassword => _get('weakPassword');
  String get emailInUse => _get('emailInUse');
  String get recordAdded => _get('recordAdded');
  String get patientNotFound => _get('patientNotFound');
  String get qrScanned => _get('qrScanned');
  String get notScannedYet => _get('notScannedYet');
  String get scannedSuccessfully => _get('scannedSuccessfully');
  String get scanAgain => _get('scanAgain');
  String get pointCameraToQR => _get('pointCameraToQR');
  String get qrForRecord => _get('qrForRecord');
  String get shareQR => _get('shareQR');
  String get shareFeatureComingSoon => _get('shareFeatureComingSoon');
  String get patientCanScan => _get('patientCanScan');
  String get settings => _get('settings');
  String get language => _get('language');
  String get selectLanguage => _get('selectLanguage');
  String get arabic => _get('arabic');
  String get russian => _get('russian');
  String get english => _get('english');
  String get languageChanged => _get('languageChanged');
  String get search => _get('search');
  String get searchHint => _get('searchHint');
  String get medicalHistory => _get('medicalHistory');
  String get noMedicalHistory => _get('noMedicalHistory');
  String get medicationReminders => _get('medicationReminders');
  String get noReminders => _get('noReminders');
  String get addReminder => _get('addReminder');
  String get medicationName => _get('medicationName');
  String get dosage => _get('dosage');
  String get reminderTime => _get('reminderTime');
  String get repeatDays => _get('repeatDays');
  String get reminderAdded => _get('reminderAdded');
  String get deleteReminder => _get('deleteReminder');
  String get deleteReminderConfirm => _get('deleteReminderConfirm');
  String get delete => _get('delete');
  String get exportPdf => _get('exportPdf');
  String get exportAll => _get('exportAll');
  String get patientHistory => _get('patientHistory');
  String get print => _get('print');
  String get noMedicalRecords => _get('noMedicalRecords');
  String get createPatientQuestion => _get('createPatientQuestion');
  String get create => _get('create');
  String get pleaseEnterDiagnosis => _get('pleaseEnterDiagnosis');
  String get pleaseEnterPrescription => _get('pleaseEnterPrescription');
  String get dateRange => _get('dateRange');
  String get results => _get('results');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar', 'ru'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
