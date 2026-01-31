import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// استيراد حزم اللغات الرسمية لدعم الـ Widgets الأساسية
import 'package:flutter_localizations/flutter_localizations.dart';

import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';
import 'l10n/app_localizations.dart'; // تأكد من المسار الصحيح لملفك
import 'screens/home_screen.dart';
import 'screens/patient_dashboard.dart';
import 'screens/doctor_dashboard.dart';
import 'screens/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); 
  
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider(prefs)),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // مراقبة LanguageProvider لتحديث التطبيق فور تغيير اللغة
    final langProvider = Provider.of<LanguageProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Medical App',

      // --- إعدادات اللغة والترجمة ---
      locale: langProvider.appLocale, // اللغة الحالية من الـ Provider
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
        Locale('ru'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate, // ملفك اليدوي
        GlobalMaterialLocalizations.delegate, // لترجمة نصوص Flutter الداخلية
        GlobalWidgetsLocalizations.delegate, // لدعم اتجاه النصوص RTL/LTR
        GlobalCupertinoLocalizations.delegate,
      ],
      // ------------------------------

      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          // 1. حالة التحميل عند تشغيل التطبيق أول مرة
          if (auth.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // 2. إذا لم يكن هناك مستخدم، التوجه لصفحة البداية
          if (auth.user == null) {
            return const HomeScreen();
          }

          // 3. التوجيه بناءً على الرتبة (Role) المخزنة في الـ AuthProvider
          switch (auth.userRole) {
            case 'admin':
              return const AdminDashboard();
            case 'doctor':
              return const DoctorDashboard();
            case 'patient':
              return const PatientDashboard();
            default:
              return const PatientDashboard();
          }
        },
      ),
    );
  }
}
}
