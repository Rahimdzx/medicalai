import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'providers/language_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/patient_dashboard.dart';
import 'screens/doctor_dashboard.dart';
import 'screens/admin_dashboard.dart'; // تأكد من إنشاء هذا الملف
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
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
            
            // تعريف المسارات (Routes)
            routes: {
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
            },

            localizationsDelegates: const [
              AppLocalizations.delegate,
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
            ),

            // مراقب حالة تسجيل الدخول والأدوار
            home: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                // 1. حالة التحميل
                if (authProvider.isLoading) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                // 2. إذا لم يسجل دخول بعد، نعرض شاشة الترحيب
                if (authProvider.user == null) {
                  return const HomeScreen();
                }

                // 3. توجيه المستخدم بناءً على دوره (Role)
                final String role = authProvider.userRole;

                switch (role) {
                  case 'admin':
                    return const AdminDashboard();
                  case 'doctor':
                    return const DoctorDashboard();
                  case 'patient':
                  default:
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
