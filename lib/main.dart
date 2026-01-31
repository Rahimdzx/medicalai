import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/patient_dashboard.dart';
import 'screens/doctor_dashboard.dart';
import 'screens/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // تأكد من وضع إعداداتك هنا إذا لزم الأمر
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          // 1. إذا كان التطبيق يحمل البيانات الأساسية
          if (auth.isLoading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          // 2. إذا لم يسجل دخول، نفتح شاشة الترحيب
          if (auth.user == null) {
            return const HomeScreen();
          }

          // 3. التوجيه الذكي بناءً على الدور
          switch (auth.userRole) {
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
  }
}
