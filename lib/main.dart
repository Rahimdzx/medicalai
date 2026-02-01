import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';
import 'providers/theme_provider.dart';
import 'l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'screens/home_screen.dart';
import 'screens/patient_dashboard.dart';
import 'screens/doctor_dashboard.dart';
import 'screens/admin_dashboard.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Get SharedPreferences instance
  final prefs = await SharedPreferences.getInstance();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        // Language Provider - must be first for localization
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(prefs),
        ),
        // Theme Provider
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(prefs),
        ),
        // Auth Provider
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
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
          // App configuration
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,

          // Localization
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

          // Theme
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,

          // Builder for RTL support and text direction
          builder: (context, child) {
            return Directionality(
              textDirection: languageProvider.textDirection,
              child: child ?? const SizedBox.shrink(),
            );
          },

          // Home screen with auth state handling
          home: const AuthWrapper(),
        );
      },
    );
  }
}

/// Wrapper widget that handles authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Show loading indicator while checking auth state
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            ),
          );
        }

        // User not logged in - show home/login screen
        if (auth.user == null) {
          return const HomeScreen();
        }

        // User logged in - route based on role
        return _buildDashboardForRole(auth.userRole);
      },
    );
  }

  Widget _buildDashboardForRole(String? role) {
    switch (role) {
      case AppConstants.roleAdmin:
        return const AdminDashboard();
      case AppConstants.roleDoctor:
        return const DoctorDashboard();
      case AppConstants.rolePatient:
      default:
        return const PatientDashboard();
    }
  }
}
