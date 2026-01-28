import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// يجب إضافة هذا السطر لكي تعمل الـ Localizations
import 'package:flutter_localizations/flutter_localizations.dart'; 

import 'l10n/app_localizations.dart';
import 'providers/language_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/patient_dashboard.dart';
import 'screens/doctor_dashboard.dart';
import 'firebase_options.dart'; // تأكد أن هذا الملف موجود في مجلد lib

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // الطريقة الصحيحة باستخدام الملف المولد من FlutterFire CLI
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Firebase initialization error: $e");
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider(prefs)),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: 'Medical App',
            debugShowCheckedModeBanner: false,
            // تحديث اللغة ديناميكياً بناءً على البروفايدر
            locale: languageProvider.locale, 
            supportedLocales: const [
              Locale('en'),
              Locale('ar'),
              Locale('ru'),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              useMaterial3: true,
            ),
            // منطق التوجيه (Routing Logic)
            home: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                // 1. حالة التحميل (مثلاً عند فتح التطبيق والتحقق من التوكن)
                if (authProvider.isLoading) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                // 2. المستخدم غير مسجل دخول
                if (authProvider.user == null) {
                  return const LoginScreen();
                }

                // 3. المستخدم مسجل دخول - توجيه حسب الصلاحية
                if (authProvider.userRole == 'doctor') {
                  return const DoctorDashboard();
                }

                // الافتراضي للمريض
                return const PatientDashboard();
              },
            ),
          );
        },
      ),
    );
  }
}
