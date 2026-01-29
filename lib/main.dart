import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; 

// ملاحظة: قمت بحذف استيراد AppLocalizations لأنه يسبب الشاشة الرمادية إذا لم تكن الملفات موجودة
import 'providers/language_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/patient_dashboard.dart';
import 'screens/doctor_dashboard.dart';

void main() async {
  // ضمان تهيئة الأدوات قبل أي عمليات أخرى
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // إعداد Firebase يدوياً
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBgyD_eY_ESnhPV8YC91a3O88exvnHJgbA",
        appId: "1:831395986138:android:efaa3b497df3f0594f03e3",
        messagingSenderId: "831395986138",
        projectId: "medical-app-eb53e",
        storageBucket: "medical-app-eb53e.firebasestorage.app",
      ),
    );
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
    // حتى لو فشل Firebase، سنحاول تشغيل التطبيق لعرض شاشة الخطأ بدلاً من الشاشة الرمادية
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
            locale: languageProvider.locale,
            
            // تم تعديل هذا الجزء ليتناسب مع ترجمتك اليدوية (بدون AppLocalizations.delegate)
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('ar'),
              Locale('ru'),
            ],
            
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              useMaterial3: true,
              // حماية إضافية: إذا لم يجد التطبيق الخط الافتراضي لا ينهار
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),

            // استخدام ErrorWidget مخصص لمنع الشاشة الرمادية تماماً أثناء التطوير
            builder: (context, widget) {
              ErrorWidget.builder = (FlutterErrorDetails details) {
                return Scaffold(
                  body: Center(
                    child: Text(
                      "حدث خطأ في الواجهة: ${details.exception}",
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              };
              return widget!;
            },

            home: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                // شاشة التحميل
                if (authProvider.isLoading) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                // إذا لم يسجل الدخول
                if (authProvider.user == null) {
                  return const LoginScreen();
                }

                // توجيه المستخدم حسب الرتبة
                // قمت بإضافة فحص إضافي هنا لمنع الانهيار إذا كان Role فارغاً
                if (authProvider.userRole == 'doctor') {
                  return const DoctorDashboard();
                } else {
                  return const PatientDashboard();
                }
              },
            ),
          );
        },
      ),
    );
  }
}
