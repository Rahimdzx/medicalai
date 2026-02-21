import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  // Check if current locale is RTL
  bool get isRTL => locale.languageCode == 'ar';

  static final Map<String, Map<String, String>> _localizedValues = {
    // ---------------- English ----------------
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
      'adminDashboard': 'Admin Dashboard',
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
      'admin': 'Admin',
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
      'noMessages': 'No messages yet',
      'typeMessage': 'Type a message...',
      'consultationPrice': 'Consultation Price',
      'uploading': 'Uploading...',
      // New extended keys
      'welcome': 'Welcome',
      'welcomeBack': 'Welcome Back',
      'settings': 'Settings',
      'profile': 'Profile',
      'editProfile': 'Edit Profile',
      'appointments': 'Appointments',
      'myAppointments': 'My Appointments',
      'upcomingAppointments': 'Upcoming Appointments',
      'pastAppointments': 'Past Appointments',
      'noAppointments': 'No appointments',
      'scheduleAppointment': 'Schedule Appointment',
      'confirmAppointment': 'Confirm Appointment',
      'cancelAppointment': 'Cancel Appointment',
      'appointmentConfirmed': 'Appointment confirmed',
      'appointmentCancelled': 'Appointment cancelled',
      'medicalHistory': 'Medical History',
      'medications': 'Medications',
      'medicationReminders': 'Medication Reminders',
      'addMedication': 'Add Medication',
      'dosage': 'Dosage',
      'frequency': 'Frequency',
      'startDate': 'Start Date',
      'endDate': 'End Date',
      'timesPerDay': 'Times per day',
      'morning': 'Morning',
      'afternoon': 'Afternoon',
      'evening': 'Evening',
      'night': 'Night',
      'findDoctor': 'Find Doctor',
      'findSpecialist': 'Find Specialist',
      'nearbyDoctors': 'Nearby Doctors',
      'topRated': 'Top Rated',
      'available': 'Available',
      'unavailable': 'Unavailable',
      'online': 'Online',
      'offline': 'Offline',
      'experience': 'Experience',
      'reviews': 'Reviews',
      'patients': 'Patients',
      'consultations': 'Consultations',
      'chat': 'Chat',
      'startChat': 'Start Chat',
      'sendMessage': 'Send Message',
      'videoCall': 'Video Call',
      'startVideoCall': 'Start Video Call',
      'endCall': 'End Call',
      'calling': 'Calling...',
      'inCall': 'In Call',
      'callEnded': 'Call Ended',
      'camera': 'Camera',
      'microphone': 'Microphone',
      'speaker': 'Speaker',
      'switchCamera': 'Switch Camera',
      'muteAudio': 'Mute Audio',
      'unmuteAudio': 'Unmute Audio',
      'uploadFile': 'Upload File',
      'uploadImage': 'Upload Image',
      'uploadDocument': 'Upload Document',
      'selectFile': 'Select File',
      'selectImage': 'Select Image',
      'takePhoto': 'Take Photo',
      'gallery': 'Gallery',
      'fileUploaded': 'File uploaded',
      'uploadFailed': 'Upload failed',
      'downloading': 'Downloading...',
      'downloadComplete': 'Download complete',
      'notifications': 'Notifications',
      'enableNotifications': 'Enable Notifications',
      'disableNotifications': 'Disable Notifications',
      'noNotifications': 'No notifications',
      'markAsRead': 'Mark as read',
      'clearAll': 'Clear all',
      'generateQR': 'Generate QR Code',
      'scanDoctorCode': 'Scan Doctor Code',
      'shareProfile': 'Share Profile',
      'copyLink': 'Copy Link',
      'linkCopied': 'Link copied',
      'pdfExport': 'Export PDF',
      'exportRecords': 'Export Records',
      'printRecords': 'Print Records',
      'shareRecords': 'Share Records',
      'noRecords': 'No medical records yet',
      'uploadFirstRecord': 'Upload your first medical record',
      'doctorName': 'Doctor Name',
      'prescriptionAndTreatment': 'Prescription and Treatment',
      'selectLanguage': 'Select Language',
      'changeLanguage': 'Change Language',
      'english': 'English',
      'arabic': 'Arabic',
      'russian': 'Russian',
      'darkMode': 'Dark Mode',
      'lightMode': 'Light Mode',
      'systemTheme': 'System Theme',
      'about': 'About',
      'version': 'Version',
      'termsOfService': 'Terms of Service',
      'privacyPolicy': 'Privacy Policy',
      'contactUs': 'Contact Us',
      'support': 'Support',
      'help': 'Help',
      'faq': 'FAQ',
      'success': 'Success',
      'failed': 'Failed',
      'loading': 'Loading...',
      'pleaseWait': 'Please wait...',
      'tryAgain': 'Try again',
      'retry': 'Retry',
      'confirm': 'Confirm',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'update': 'Update',
      'submit': 'Submit',
      'close': 'Close',
      'back': 'Back',
      'next': 'Next',
      'previous': 'Previous',
      'done': 'Done',
      'ok': 'OK',
      'yes': 'Yes',
      'no': 'No',
      'connectionError': 'Connection error',
      'noInternet': 'No internet connection',
      'serverError': 'Server error',
      'somethingWentWrong': 'Something went wrong',
      'sessionExpired': 'Session expired',
      'unauthorized': 'Unauthorized',
      'accessDenied': 'Access denied',
      'price': 'Price',
      'total': 'Total',
      'currency': '\$',
      'payment': 'Payment',
      'payNow': 'Pay Now',
      'paymentSuccessful': 'Payment successful',
      'paymentFailed': 'Payment failed',
      'age': 'Age',
      'gender': 'Gender',
      'male': 'Male',
      'female': 'Female',
      'bloodType': 'Blood Type',
      'height': 'Height',
      'weight': 'Weight',
      'allergies': 'Allergies',
      'chronicDiseases': 'Chronic Diseases',
      'russiaPrograms': 'Russia Medical Programs',
      'medicalTourismDesc': 'Discover the best medical centers in Russia',
      'viewPrograms': 'View Programs',
      'bookNow': 'Book Now',
      'doctorManagement': 'Doctor Management',
      'addDoctor': 'Add Doctor',
      'removeDoctor': 'Remove Doctor',
      'verifyDoctor': 'Verify Doctor',
      'doctorVerified': 'Doctor Verified',
      'pendingVerification': 'Pending Verification',
      // Login & Auth Extended
      'welcomeToMedical': 'Welcome to Medical Portal',
      'signInToContinue': 'Sign in to continue',
      'forgotPassword': 'Forgot Password?',
      'rememberMe': 'Remember me',
      'orSignInWith': 'Or sign in with',
      'secureLogin': 'Secure Login',
      'enterCredentials': 'Enter your credentials',
      // Doctor Dashboard Extended
      'dailyPatients': 'Daily Patients',
      'pendingConsultations': 'Pending Consultations',
      'completedToday': 'Completed Today',
      'totalEarnings': 'Total Earnings',
      'todaySchedule': 'Today\'s Schedule',
      'noScheduledAppointments': 'No scheduled appointments',
      'viewAllAppointments': 'View All Appointments',
      'quickActions': 'Quick Actions',
      'startConsultation': 'Start Consultation',
      'viewPatientRecords': 'View Patient Records',
      'manageSchedule': 'Manage Schedule',
      'appointmentWith': 'Appointment with',
      'scheduledFor': 'Scheduled for',
      'consultationType': 'Consultation type',
      'videoConsultation': 'Video Consultation',
      'inPersonVisit': 'In-person Visit',
      'chatConsultation': 'Chat Consultation',
      // Payment Extended
      'paymentProcessing': 'Processing Payment',
      'paymentAmount': 'Payment Amount',
      'consultationFee': 'Consultation Fee',
      'serviceFee': 'Service Fee',
      'totalAmount': 'Total Amount',
      'paymentMethod': 'Payment Method',
      'bankCard': 'Bank Card',
      'onlinePayment': 'Online Payment',
      'confirmPayment': 'Confirm Payment',
      'paymentPending': 'Payment Pending',
      'paymentCompleted': 'Payment Completed',
      'paymentCancelled': 'Payment Cancelled',
      'paymentError': 'Payment Error',
      'tryPaymentAgain': 'Try Payment Again',
      'backToConsultation': 'Back to Consultation',
      'receiptSent': 'Receipt sent to your email',
      'transactionId': 'Transaction ID',
      // Time & Scheduling
      'moscowTime': 'Moscow Time (MSK)',
      'localTime': 'Local Time',
      'selectTime': 'Select Time',
      'selectDate': 'Select Date',
      'timeSlot': 'Time Slot',
      'duration': 'Duration',
      'minutes': 'minutes',
      // Currency
      'rubles': 'Rubles',
      'rub': 'RUB',
    },

    // ---------------- Arabic ----------------
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
      'adminDashboard': 'لوحة الإدارة',
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
      'admin': 'مدير',
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
      'noMessages': 'لا توجد رسائل بعد',
      'typeMessage': 'اكتب رسالة...',
      'consultationPrice': 'سعر الكشف',
      'uploading': 'جاري الرفع...',
      // New extended keys
      'welcome': 'مرحباً',
      'welcomeBack': 'مرحباً بعودتك',
      'settings': 'الإعدادات',
      'profile': 'الملف الشخصي',
      'editProfile': 'تعديل الملف',
      'appointments': 'المواعيد',
      'myAppointments': 'مواعيدي',
      'upcomingAppointments': 'المواعيد القادمة',
      'pastAppointments': 'المواعيد السابقة',
      'noAppointments': 'لا توجد مواعيد',
      'scheduleAppointment': 'حجز موعد',
      'confirmAppointment': 'تأكيد الموعد',
      'cancelAppointment': 'إلغاء الموعد',
      'appointmentConfirmed': 'تم تأكيد الموعد',
      'appointmentCancelled': 'تم إلغاء الموعد',
      'medicalHistory': 'التاريخ الطبي',
      'medications': 'الأدوية',
      'medicationReminders': 'تذكيرات الأدوية',
      'addMedication': 'إضافة دواء',
      'dosage': 'الجرعة',
      'frequency': 'التكرار',
      'startDate': 'تاريخ البدء',
      'endDate': 'تاريخ الانتهاء',
      'timesPerDay': 'مرات في اليوم',
      'morning': 'صباحاً',
      'afternoon': 'ظهراً',
      'evening': 'مساءً',
      'night': 'ليلاً',
      'findDoctor': 'البحث عن طبيب',
      'findSpecialist': 'البحث عن متخصص',
      'nearbyDoctors': 'أطباء قريبون',
      'topRated': 'الأعلى تقييماً',
      'available': 'متاح',
      'unavailable': 'غير متاح',
      'online': 'متصل',
      'offline': 'غير متصل',
      'experience': 'الخبرة',
      'reviews': 'التقييمات',
      'patients': 'المرضى',
      'consultations': 'الاستشارات',
      'chat': 'المحادثة',
      'startChat': 'بدء محادثة',
      'sendMessage': 'إرسال رسالة',
      'videoCall': 'مكالمة فيديو',
      'startVideoCall': 'بدء مكالمة فيديو',
      'endCall': 'إنهاء المكالمة',
      'calling': 'جاري الاتصال...',
      'inCall': 'في مكالمة',
      'callEnded': 'انتهت المكالمة',
      'camera': 'الكاميرا',
      'microphone': 'الميكروفون',
      'speaker': 'مكبر الصوت',
      'switchCamera': 'تبديل الكاميرا',
      'muteAudio': 'كتم الصوت',
      'unmuteAudio': 'إلغاء كتم الصوت',
      'uploadFile': 'رفع ملف',
      'uploadImage': 'رفع صورة',
      'uploadDocument': 'رفع مستند',
      'selectFile': 'اختر ملف',
      'selectImage': 'اختر صورة',
      'takePhoto': 'التقاط صورة',
      'gallery': 'المعرض',
      'fileUploaded': 'تم رفع الملف',
      'uploadFailed': 'فشل الرفع',
      'downloading': 'جاري التحميل...',
      'downloadComplete': 'اكتمل التحميل',
      'notifications': 'الإشعارات',
      'enableNotifications': 'تفعيل الإشعارات',
      'disableNotifications': 'تعطيل الإشعارات',
      'noNotifications': 'لا توجد إشعارات',
      'markAsRead': 'تحديد كمقروء',
      'clearAll': 'مسح الكل',
      'generateQR': 'إنشاء رمز QR',
      'scanDoctorCode': 'مسح كود الطبيب',
      'shareProfile': 'مشاركة الملف',
      'copyLink': 'نسخ الرابط',
      'linkCopied': 'تم نسخ الرابط',
      'pdfExport': 'تصدير PDF',
      'exportRecords': 'تصدير السجلات',
      'printRecords': 'طباعة السجلات',
      'shareRecords': 'مشاركة السجلات',
      'noRecords': 'لا توجد سجلات طبية حتى الآن',
      'uploadFirstRecord': 'رفع أول تحليل طبي لك',
      'doctorName': 'اسم الطبيب',
      'prescriptionAndTreatment': 'الروشتة والعلاج',
      'selectLanguage': 'اختر اللغة',
      'changeLanguage': 'تغيير اللغة',
      'english': 'الإنجليزية',
      'arabic': 'العربية',
      'russian': 'الروسية',
      'darkMode': 'الوضع الداكن',
      'lightMode': 'الوضع الفاتح',
      'systemTheme': 'سمة النظام',
      'about': 'حول التطبيق',
      'version': 'الإصدار',
      'termsOfService': 'شروط الخدمة',
      'privacyPolicy': 'سياسة الخصوصية',
      'contactUs': 'اتصل بنا',
      'support': 'الدعم',
      'help': 'المساعدة',
      'faq': 'الأسئلة الشائعة',
      'success': 'نجاح',
      'failed': 'فشل',
      'loading': 'جاري التحميل...',
      'pleaseWait': 'يرجى الانتظار...',
      'tryAgain': 'حاول مرة أخرى',
      'retry': 'إعادة المحاولة',
      'confirm': 'تأكيد',
      'delete': 'حذف',
      'edit': 'تعديل',
      'add': 'إضافة',
      'update': 'تحديث',
      'submit': 'إرسال',
      'close': 'إغلاق',
      'back': 'رجوع',
      'next': 'التالي',
      'previous': 'السابق',
      'done': 'تم',
      'ok': 'موافق',
      'yes': 'نعم',
      'no': 'لا',
      'connectionError': 'خطأ في الاتصال',
      'noInternet': 'لا يوجد اتصال بالإنترنت',
      'serverError': 'خطأ في الخادم',
      'somethingWentWrong': 'حدث خطأ ما',
      'sessionExpired': 'انتهت الجلسة',
      'unauthorized': 'غير مصرح',
      'accessDenied': 'تم رفض الوصول',
      'price': 'السعر',
      'total': 'الإجمالي',
      'currency': 'ر.س',
      'payment': 'الدفع',
      'payNow': 'ادفع الآن',
      'paymentSuccessful': 'تم الدفع بنجاح',
      'paymentFailed': 'فشل الدفع',
      'age': 'العمر',
      'gender': 'الجنس',
      'male': 'ذكر',
      'female': 'أنثى',
      'bloodType': 'فصيلة الدم',
      'height': 'الطول',
      'weight': 'الوزن',
      'allergies': 'الحساسية',
      'chronicDiseases': 'الأمراض المزمنة',
      'russiaPrograms': 'برامج روسيا الطبية',
      'medicalTourismDesc': 'اكتشف أفضل المراكز الطبية في روسيا',
      'viewPrograms': 'عرض البرامج',
      'bookNow': 'احجز الآن',
      'doctorManagement': 'إدارة الأطباء',
      'addDoctor': 'إضافة طبيب',
      'removeDoctor': 'إزالة طبيب',
      'verifyDoctor': 'تحقق من الطبيب',
      'doctorVerified': 'طبيب موثق',
      'pendingVerification': 'في انتظار التحقق',
      // Login & Auth Extended
      'welcomeToMedical': 'مرحباً بك في البوابة الطبية',
      'signInToContinue': 'سجل الدخول للمتابعة',
      'forgotPassword': 'نسيت كلمة المرور؟',
      'rememberMe': 'تذكرني',
      'orSignInWith': 'أو سجل الدخول باستخدام',
      'secureLogin': 'تسجيل دخول آمن',
      'enterCredentials': 'أدخل بيانات الاعتماد',
      // Doctor Dashboard Extended
      'dailyPatients': 'المرضى اليوم',
      'pendingConsultations': 'الاستشارات المعلقة',
      'completedToday': 'مكتملة اليوم',
      'totalEarnings': 'إجمالي الأرباح',
      'todaySchedule': 'جدول اليوم',
      'noScheduledAppointments': 'لا توجد مواعيد مجدولة',
      'viewAllAppointments': 'عرض جميع المواعيد',
      'quickActions': 'إجراءات سريعة',
      'startConsultation': 'بدء الاستشارة',
      'viewPatientRecords': 'عرض سجلات المرضى',
      'manageSchedule': 'إدارة الجدول',
      'appointmentWith': 'موعد مع',
      'scheduledFor': 'مجدول لـ',
      'consultationType': 'نوع الاستشارة',
      'videoConsultation': 'استشارة فيديو',
      'inPersonVisit': 'زيارة شخصية',
      'chatConsultation': 'استشارة محادثة',
      // Payment Extended
      'paymentProcessing': 'جاري معالجة الدفع',
      'paymentAmount': 'مبلغ الدفع',
      'consultationFee': 'رسوم الاستشارة',
      'serviceFee': 'رسوم الخدمة',
      'totalAmount': 'المبلغ الإجمالي',
      'paymentMethod': 'طريقة الدفع',
      'bankCard': 'بطاقة بنكية',
      'onlinePayment': 'الدفع الإلكتروني',
      'confirmPayment': 'تأكيد الدفع',
      'paymentPending': 'الدفع معلق',
      'paymentCompleted': 'تم الدفع',
      'paymentCancelled': 'تم إلغاء الدفع',
      'paymentError': 'خطأ في الدفع',
      'tryPaymentAgain': 'حاول الدفع مرة أخرى',
      'backToConsultation': 'العودة للاستشارة',
      'receiptSent': 'تم إرسال الإيصال إلى بريدك',
      'transactionId': 'رقم المعاملة',
      // Time & Scheduling
      'moscowTime': 'توقيت موسكو (MSK)',
      'localTime': 'التوقيت المحلي',
      'selectTime': 'اختر الوقت',
      'selectDate': 'اختر التاريخ',
      'timeSlot': 'الفترة الزمنية',
      'duration': 'المدة',
      'minutes': 'دقائق',
      // Currency
      'rubles': 'روبل',
      'rub': 'RUB',
    },

    // ---------------- Russian ----------------
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
      'adminDashboard': 'Панель администратора',
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
      'admin': 'Администратор',
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
      'noMessages': 'Сообщений пока нет',
      'typeMessage': 'Введите сообщение...',
      'consultationPrice': 'Цена консультации',
      'uploading': 'Загрузка...',
      // New extended keys
      'welcome': 'Добро пожаловать',
      'welcomeBack': 'С возвращением',
      'settings': 'Настройки',
      'profile': 'Профиль',
      'editProfile': 'Редактировать профиль',
      'appointments': 'Записи',
      'myAppointments': 'Мои записи',
      'upcomingAppointments': 'Предстоящие записи',
      'pastAppointments': 'Прошедшие записи',
      'noAppointments': 'Нет записей',
      'scheduleAppointment': 'Записаться на прием',
      'confirmAppointment': 'Подтвердить запись',
      'cancelAppointment': 'Отменить запись',
      'appointmentConfirmed': 'Запись подтверждена',
      'appointmentCancelled': 'Запись отменена',
      'medicalHistory': 'Медицинская история',
      'medications': 'Лекарства',
      'medicationReminders': 'Напоминания о лекарствах',
      'addMedication': 'Добавить лекарство',
      'dosage': 'Дозировка',
      'frequency': 'Частота',
      'startDate': 'Дата начала',
      'endDate': 'Дата окончания',
      'timesPerDay': 'Раз в день',
      'morning': 'Утро',
      'afternoon': 'День',
      'evening': 'Вечер',
      'night': 'Ночь',
      'findDoctor': 'Найти врача',
      'findSpecialist': 'Найти специалиста',
      'nearbyDoctors': 'Ближайшие врачи',
      'topRated': 'Лучшие по рейтингу',
      'available': 'Доступен',
      'unavailable': 'Недоступен',
      'online': 'Онлайн',
      'offline': 'Офлайн',
      'experience': 'Опыт',
      'reviews': 'Отзывы',
      'patients': 'Пациенты',
      'consultations': 'Консультации',
      'chat': 'Чат',
      'startChat': 'Начать чат',
      'sendMessage': 'Отправить сообщение',
      'videoCall': 'Видеозвонок',
      'startVideoCall': 'Начать видеозвонок',
      'endCall': 'Завершить звонок',
      'calling': 'Вызов...',
      'inCall': 'В звонке',
      'callEnded': 'Звонок завершен',
      'camera': 'Камера',
      'microphone': 'Микрофон',
      'speaker': 'Динамик',
      'switchCamera': 'Переключить камеру',
      'muteAudio': 'Выключить звук',
      'unmuteAudio': 'Включить звук',
      'uploadFile': 'Загрузить файл',
      'uploadImage': 'Загрузить изображение',
      'uploadDocument': 'Загрузить документ',
      'selectFile': 'Выбрать файл',
      'selectImage': 'Выбрать изображение',
      'takePhoto': 'Сделать фото',
      'gallery': 'Галерея',
      'fileUploaded': 'Файл загружен',
      'uploadFailed': 'Ошибка загрузки',
      'downloading': 'Загрузка...',
      'downloadComplete': 'Загрузка завершена',
      'notifications': 'Уведомления',
      'enableNotifications': 'Включить уведомления',
      'disableNotifications': 'Отключить уведомления',
      'noNotifications': 'Нет уведомлений',
      'markAsRead': 'Отметить как прочитанное',
      'clearAll': 'Очистить все',
      'generateQR': 'Создать QR-код',
      'scanDoctorCode': 'Сканировать код врача',
      'shareProfile': 'Поделиться профилем',
      'copyLink': 'Копировать ссылку',
      'linkCopied': 'Ссылка скопирована',
      'pdfExport': 'Экспорт PDF',
      'exportRecords': 'Экспорт записей',
      'printRecords': 'Печать записей',
      'shareRecords': 'Поделиться записями',
      'noRecords': 'Медицинских записей пока нет',
      'uploadFirstRecord': 'Загрузите свою первую медицинскую запись',
      'doctorName': 'Имя врача',
      'prescriptionAndTreatment': 'Назначения и лечение',
      'selectLanguage': 'Выберите язык',
      'changeLanguage': 'Изменить язык',
      'english': 'Английский',
      'arabic': 'Арабский',
      'russian': 'Русский',
      'darkMode': 'Темная тема',
      'lightMode': 'Светлая тема',
      'systemTheme': 'Системная тема',
      'about': 'О приложении',
      'version': 'Версия',
      'termsOfService': 'Условия использования',
      'privacyPolicy': 'Политика конфиденциальности',
      'contactUs': 'Связаться с нами',
      'support': 'Поддержка',
      'help': 'Помощь',
      'faq': 'Частые вопросы',
      'success': 'Успешно',
      'failed': 'Ошибка',
      'loading': 'Загрузка...',
      'pleaseWait': 'Пожалуйста, подождите...',
      'tryAgain': 'Попробуйте снова',
      'retry': 'Повторить',
      'confirm': 'Подтвердить',
      'delete': 'Удалить',
      'edit': 'Редактировать',
      'add': 'Добавить',
      'update': 'Обновить',
      'submit': 'Отправить',
      'close': 'Закрыть',
      'back': 'Назад',
      'next': 'Далее',
      'previous': 'Назад',
      'done': 'Готово',
      'ok': 'ОК',
      'yes': 'Да',
      'no': 'Нет',
      'connectionError': 'Ошибка соединения',
      'noInternet': 'Нет подключения к интернету',
      'serverError': 'Ошибка сервера',
      'somethingWentWrong': 'Что-то пошло не так',
      'sessionExpired': 'Сессия истекла',
      'unauthorized': 'Не авторизован',
      'accessDenied': 'Доступ запрещен',
      'price': 'Цена',
      'total': 'Итого',
      'currency': '₽',
      'payment': 'Оплата',
      'payNow': 'Оплатить',
      'paymentSuccessful': 'Оплата успешна',
      'paymentFailed': 'Ошибка оплаты',
      'age': 'Возраст',
      'gender': 'Пол',
      'male': 'Мужской',
      'female': 'Женский',
      'bloodType': 'Группа крови',
      'height': 'Рост',
      'weight': 'Вес',
      'allergies': 'Аллергии',
      'chronicDiseases': 'Хронические заболевания',
      'russiaPrograms': 'Медицинские программы России',
      'medicalTourismDesc': 'Откройте для себя лучшие медицинские центры России',
      'viewPrograms': 'Посмотреть программы',
      'bookNow': 'Забронировать',
      'doctorManagement': 'Управление врачами',
      'addDoctor': 'Добавить врача',
      'removeDoctor': 'Удалить врача',
      'verifyDoctor': 'Верифицировать врача',
      'doctorVerified': 'Врач верифицирован',
      'pendingVerification': 'Ожидает верификации',
      // Login & Auth Extended
      'welcomeToMedical': 'Добро пожаловать в Медицинский портал',
      'signInToContinue': 'Войдите для продолжения',
      'forgotPassword': 'Забыли пароль?',
      'rememberMe': 'Запомнить меня',
      'orSignInWith': 'Или войдите через',
      'secureLogin': 'Безопасный вход',
      'enterCredentials': 'Введите данные для входа',
      // Doctor Dashboard Extended
      'dailyPatients': 'Пациентов сегодня',
      'pendingConsultations': 'Ожидающие консультации',
      'completedToday': 'Завершено сегодня',
      'totalEarnings': 'Общий доход',
      'todaySchedule': 'Расписание на сегодня',
      'noScheduledAppointments': 'Нет запланированных приёмов',
      'viewAllAppointments': 'Все приёмы',
      'quickActions': 'Быстрые действия',
      'startConsultation': 'Начать консультацию',
      'viewPatientRecords': 'Записи пациентов',
      'manageSchedule': 'Управление расписанием',
      'appointmentWith': 'Приём с',
      'scheduledFor': 'Назначен на',
      'consultationType': 'Тип консультации',
      'videoConsultation': 'Видеоконсультация',
      'inPersonVisit': 'Очный приём',
      'chatConsultation': 'Чат-консультация',
      // Payment Extended
      'paymentProcessing': 'Обработка платежа',
      'paymentAmount': 'Сумма платежа',
      'consultationFee': 'Стоимость консультации',
      'serviceFee': 'Сервисный сбор',
      'totalAmount': 'Итоговая сумма',
      'paymentMethod': 'Способ оплаты',
      'bankCard': 'Банковская карта',
      'onlinePayment': 'Онлайн-оплата',
      'confirmPayment': 'Подтвердить оплату',
      'paymentPending': 'Ожидание оплаты',
      'paymentCompleted': 'Оплата завершена',
      'paymentCancelled': 'Оплата отменена',
      'paymentError': 'Ошибка оплаты',
      'tryPaymentAgain': 'Повторить оплату',
      'backToConsultation': 'Вернуться к консультации',
      'receiptSent': 'Чек отправлен на ваш email',
      'transactionId': 'Номер транзакции',
      // Time & Scheduling
      'moscowTime': 'Московское время (MSK)',
      'localTime': 'Местное время',
      'selectTime': 'Выберите время',
      'selectDate': 'Выберите дату',
      'timeSlot': 'Временной слот',
      'duration': 'Длительность',
      'minutes': 'минут',
      // Currency
      'rubles': 'Рублей',
      'rub': 'RUB',
    }
  };

  String _get(String key) => _localizedValues[locale.languageCode]?[key] ?? _localizedValues['en']![key] ?? key;

  // --- Original Getters ---
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
  String get adminDashboard => _get('adminDashboard');
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
  String get admin => _get('admin');
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
  String get noMessages => _get('noMessages');
  String get typeMessage => _get('typeMessage');
  String get consultationPrice => _get('consultationPrice');
  String get uploading => _get('uploading');

  // --- New Extended Getters ---
  String get welcome => _get('welcome');
  String get welcomeBack => _get('welcomeBack');
  String get settings => _get('settings');
  String get profile => _get('profile');
  String get editProfile => _get('editProfile');
  String get appointments => _get('appointments');
  String get myAppointments => _get('myAppointments');
  String get upcomingAppointments => _get('upcomingAppointments');
  String get pastAppointments => _get('pastAppointments');
  String get noAppointments => _get('noAppointments');
  String get scheduleAppointment => _get('scheduleAppointment');
  String get confirmAppointment => _get('confirmAppointment');
  String get cancelAppointment => _get('cancelAppointment');
  String get appointmentConfirmed => _get('appointmentConfirmed');
  String get appointmentCancelled => _get('appointmentCancelled');
  String get medicalHistory => _get('medicalHistory');
  String get medications => _get('medications');
  String get medicationReminders => _get('medicationReminders');
  String get addMedication => _get('addMedication');
  String get dosage => _get('dosage');
  String get frequency => _get('frequency');
  String get startDate => _get('startDate');
  String get endDate => _get('endDate');
  String get timesPerDay => _get('timesPerDay');
  String get morning => _get('morning');
  String get afternoon => _get('afternoon');
  String get evening => _get('evening');
  String get night => _get('night');
  String get findDoctor => _get('findDoctor');
  String get findSpecialist => _get('findSpecialist');
  String get nearbyDoctors => _get('nearbyDoctors');
  String get topRated => _get('topRated');
  String get available => _get('available');
  String get unavailable => _get('unavailable');
  String get online => _get('online');
  String get offline => _get('offline');
  String get experience => _get('experience');
  String get reviews => _get('reviews');
  String get patients => _get('patients');
  String get consultations => _get('consultations');
  String get chat => _get('chat');
  String get startChat => _get('startChat');
  String get sendMessage => _get('sendMessage');
  String get videoCall => _get('videoCall');
  String get startVideoCall => _get('startVideoCall');
  String get endCall => _get('endCall');
  String get calling => _get('calling');
  String get inCall => _get('inCall');
  String get callEnded => _get('callEnded');
  String get camera => _get('camera');
  String get microphone => _get('microphone');
  String get speaker => _get('speaker');
  String get switchCamera => _get('switchCamera');
  String get muteAudio => _get('muteAudio');
  String get unmuteAudio => _get('unmuteAudio');
  String get uploadFile => _get('uploadFile');
  String get uploadImage => _get('uploadImage');
  String get uploadDocument => _get('uploadDocument');
  String get selectFile => _get('selectFile');
  String get selectImage => _get('selectImage');
  String get takePhoto => _get('takePhoto');
  String get gallery => _get('gallery');
  String get fileUploaded => _get('fileUploaded');
  String get uploadFailed => _get('uploadFailed');
  String get downloading => _get('downloading');
  String get downloadComplete => _get('downloadComplete');
  String get notifications => _get('notifications');
  String get enableNotifications => _get('enableNotifications');
  String get disableNotifications => _get('disableNotifications');
  String get noNotifications => _get('noNotifications');
  String get markAsRead => _get('markAsRead');
  String get clearAll => _get('clearAll');
  String get generateQR => _get('generateQR');
  String get scanDoctorCode => _get('scanDoctorCode');
  String get shareProfile => _get('shareProfile');
  String get copyLink => _get('copyLink');
  String get linkCopied => _get('linkCopied');
  String get pdfExport => _get('pdfExport');
  String get exportRecords => _get('exportRecords');
  String get printRecords => _get('printRecords');
  String get shareRecords => _get('shareRecords');
  String get noRecords => _get('noRecords');
  String get uploadFirstRecord => _get('uploadFirstRecord');
  String get doctorName => _get('doctorName');
  String get prescriptionAndTreatment => _get('prescriptionAndTreatment');
  String get selectLanguage => _get('selectLanguage');
  String get changeLanguage => _get('changeLanguage');
  String get english => _get('english');
  String get arabic => _get('arabic');
  String get russian => _get('russian');
  String get darkMode => _get('darkMode');
  String get lightMode => _get('lightMode');
  String get systemTheme => _get('systemTheme');
  String get about => _get('about');
  String get version => _get('version');
  String get termsOfService => _get('termsOfService');
  String get privacyPolicy => _get('privacyPolicy');
  String get contactUs => _get('contactUs');
  String get support => _get('support');
  String get help => _get('help');
  String get faq => _get('faq');
  String get success => _get('success');
  String get failed => _get('failed');
  String get loading => _get('loading');
  String get pleaseWait => _get('pleaseWait');
  String get tryAgain => _get('tryAgain');
  String get retry => _get('retry');
  String get confirm => _get('confirm');
  String get delete => _get('delete');
  String get edit => _get('edit');
  String get add => _get('add');
  String get update => _get('update');
  String get submit => _get('submit');
  String get close => _get('close');
  String get back => _get('back');
  String get next => _get('next');
  String get previous => _get('previous');
  String get done => _get('done');
  String get ok => _get('ok');
  String get yes => _get('yes');
  String get no => _get('no');
  String get connectionError => _get('connectionError');
  String get noInternet => _get('noInternet');
  String get serverError => _get('serverError');
  String get somethingWentWrong => _get('somethingWentWrong');
  String get sessionExpired => _get('sessionExpired');
  String get unauthorized => _get('unauthorized');
  String get accessDenied => _get('accessDenied');
  String get price => _get('price');
  String get total => _get('total');
  String get currency => _get('currency');
  String get payment => _get('payment');
  String get payNow => _get('payNow');
  String get paymentSuccessful => _get('paymentSuccessful');
  String get paymentFailed => _get('paymentFailed');
  String get age => _get('age');
  String get gender => _get('gender');
  String get male => _get('male');
  String get female => _get('female');
  String get bloodType => _get('bloodType');
  String get height => _get('height');
  String get weight => _get('weight');
  String get allergies => _get('allergies');
  String get chronicDiseases => _get('chronicDiseases');
  String get russiaPrograms => _get('russiaPrograms');
  String get medicalTourismDesc => _get('medicalTourismDesc');
  String get viewPrograms => _get('viewPrograms');
  String get bookNow => _get('bookNow');
  String get doctorManagement => _get('doctorManagement');
  String get addDoctor => _get('addDoctor');
  String get removeDoctor => _get('removeDoctor');
  String get verifyDoctor => _get('verifyDoctor');
  String get doctorVerified => _get('doctorVerified');
  String get pendingVerification => _get('pendingVerification');

  // --- New Extended Getters for Russian Market ---
  // Login & Auth
  String get welcomeToMedical => _get('welcomeToMedical');
  String get signInToContinue => _get('signInToContinue');
  String get forgotPassword => _get('forgotPassword');
  String get rememberMe => _get('rememberMe');
  String get orSignInWith => _get('orSignInWith');
  String get secureLogin => _get('secureLogin');
  String get enterCredentials => _get('enterCredentials');

  // Doctor Dashboard
  String get dailyPatients => _get('dailyPatients');
  String get pendingConsultations => _get('pendingConsultations');
  String get completedToday => _get('completedToday');
  String get totalEarnings => _get('totalEarnings');
  String get todaySchedule => _get('todaySchedule');
  String get noScheduledAppointments => _get('noScheduledAppointments');
  String get viewAllAppointments => _get('viewAllAppointments');
  String get quickActions => _get('quickActions');
  String get startConsultation => _get('startConsultation');
  String get viewPatientRecords => _get('viewPatientRecords');
  String get manageSchedule => _get('manageSchedule');
  String get appointmentWith => _get('appointmentWith');
  String get scheduledFor => _get('scheduledFor');
  String get consultationType => _get('consultationType');
  String get videoConsultation => _get('videoConsultation');
  String get inPersonVisit => _get('inPersonVisit');
  String get chatConsultation => _get('chatConsultation');

  // Payment
  String get paymentProcessing => _get('paymentProcessing');
  String get paymentAmount => _get('paymentAmount');
  String get consultationFee => _get('consultationFee');
  String get serviceFee => _get('serviceFee');
  String get totalAmount => _get('totalAmount');
  String get paymentMethod => _get('paymentMethod');
  String get bankCard => _get('bankCard');
  String get onlinePayment => _get('onlinePayment');
  String get confirmPayment => _get('confirmPayment');
  String get paymentPending => _get('paymentPending');
  String get paymentCompleted => _get('paymentCompleted');
  String get paymentCancelled => _get('paymentCancelled');
  String get paymentError => _get('paymentError');
  String get tryPaymentAgain => _get('tryPaymentAgain');
  String get backToConsultation => _get('backToConsultation');
  String get receiptSent => _get('receiptSent');
  String get transactionId => _get('transactionId');

  // Time & Scheduling
  String get moscowTime => _get('moscowTime');
  String get localTime => _get('localTime');
  String get selectTime => _get('selectTime');
  String get selectDate => _get('selectDate');
  String get timeSlot => _get('timeSlot');
  String get duration => _get('duration');
  String get minutes => _get('minutes');

  // Currency
  String get rubles => _get('rubles');
  String get rub => _get('rub');

  // ARB File Additional Keys
  String get completeBooking => _get('completeBooking');
  String get consultationFormat => _get('consultationFormat');
  String get audioConsultation => _get('audioConsultation');
  String get today => _get('today');
  String get tomorrow => _get('tomorrow');
  String get urgent => _get('urgent');
  String get scheduled => _get('scheduled');
  String get confirmAndPay => _get('confirmAndPay');
  String get pay => _get('pay');
  String get bookingConfirmed => _get('bookingConfirmed');
  String get paymentConfirmed => _get('paymentConfirmed');
  String get paymentConsentPrefix => _get('paymentConsentPrefix');
  String get serviceAgreement => _get('serviceAgreement');
  String get dataConsent => _get('dataConsent');
  String get and => _get('and');
  String get registrationRequired => _get('registrationRequired');
  String get loginRequiredMessage => _get('loginRequiredMessage');
  String get fileUploaded => _get('fileUploaded');
  String get uploadFailed => _get('uploadFailed');
  String get retry => _get('retry');
  String get patientManagement => _get('patientManagement');
  String get manageDoctorsDesc => _get('manageDoctorsDesc');
  String get managePatientsDesc => _get('managePatientsDesc');
  String get legalDocuments => _get('legalDocuments');
  String get editLegalDocs => _get('editLegalDocs');
  String get overview => _get('overview');
  String get totalUsers => _get('totalUsers');
  String get welcomeBack => _get('welcomeBack');
  String get myQrCode => _get('myQrCode');
  String get mySchedule => _get('mySchedule');
  String get consultationSystemMessage => _get('consultationSystemMessage');
  String get radiologyInstructions => _get('radiologyInstructions');
  String get enterDoctorId => _get('enterDoctorId');
  String get scanQr => _get('scanQr');
  String get myDoctors => _get('myDoctors');
  String get noConsultationsYet => _get('noConsultationsYet');
  String get onlineConsultation => _get('onlineConsultation');
  String get paymentConsent => _get('paymentConsent');
  String get uploadPhoto => _get('uploadPhoto');
  String get uploadDocument => _get('uploadDocument');
  String get uploadFile => _get('uploadFile');
  String get schedule => _get('schedule');
  String get services => _get('services');
  String get addTimeSlot => _get('addTimeSlot');
  String get startTime => _get('startTime');
  String get endTime => _get('endTime');
  String get booked => _get('booked');
  String get acceptingBookings => _get('acceptingBookings');
  String get specialty => _get('specialty');
  String get system => _get('system');
  String get doctorNotFound => _get('doctorNotFound');
  String get signup => _get('signup');
  String get phoneNumber => _get('phoneNumber');
  String get confirmPassword => _get('confirmPassword');
  String get availability => _get('availability');
  String get all => _get('all');
  String get chooseTime => _get('chooseTime');
  String get chat => _get('chat');
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
