import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

// استيراد المزودين (Providers)
import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';
import 'providers/theme_provider.dart';

// استيراد ملفات الترجمة والثيم
import 'l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';

// استيراد الشاشات
import 'screens/home_screen.dart';
import 'screens/patient_dashboard.dart';
import 'screens/admin_dashboard.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart'; // تأكد من إنشاء هذا الملف
import 'screens/dashboard/doctor_dashboard.dart';
import 'screens/payment/payment_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // تهيئة تنسيق التاريخ للغات المختلفة
  await initializeDateFormatting('ru_RU', null);
  await initializeDateFormatting('ar', null);
  await initializeDateFormatting('en_US', null);

  final prefs = await SharedPreferences.getInstance();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider(prefs)),
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MedicalApp(),
    ),
  );
}

class MedicalApp extends StatelessWidget {
  const MedicalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageProvider, ThemeProvider>(
      builder: (context, languageProvider, themeProvider, _) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          
          // إعدادات اللغة
          locale: languageProvider.appLocale,
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

          // إعدادات الثيم
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,

          // إدارة المسارات
          onGenerateRoute: AppRoutes.generateRoute,

          builder: (context, child) {
            return Directionality(
              textDirection: languageProvider.textDirection,
              child: child!,
            );
          },

          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (auth.user == null) {
          return const HomeScreen();
        }
        return _buildDashboardForRole(auth.userRole);
      },
    );
  }

  Widget _buildDashboardForRole(String? role) {
    switch (role) {
      case AppConstants.roleAdmin:
        return const AdminDashboard();
      case AppConstants.roleDoctor:
        return const DoctorDashboardScreen();
      case AppConstants.rolePatient:
      default:
        return const PatientDashboard();
    }
  }
}

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/signup':
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case '/payment':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => PaymentScreen(
            appointmentId: args['appointmentId'],
            doctorId: args['doctorId'],
            doctorName: args['doctorName'],
            consultationFee: args['consultationFee'],
          ),
        );
      default:
        return MaterialPageRoute(builder: (_) => const AuthWrapper());
    }
  }
}
