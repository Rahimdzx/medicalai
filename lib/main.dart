import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';

// Theme & Constants
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';

// Screens
import 'screens/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // تهيئة تنسيق التاريخ للغات المختلفة
  await initializeDateFormatting('ru_RU', null);
  await initializeDateFormatting('ar', null);
  await initializeDateFormatting('en_US', null);

  final prefs = await SharedPreferences.getInstance();

  // تثبيت الوضع العمودي فقط
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // تهيئة Providers
  final localeProvider = LocaleProvider(prefs);
  await localeProvider.init();
  
  final themeProvider = ThemeProvider(prefs);
  await themeProvider.init(); // يضمن التهيئة الكاملة قبل تشغيل التطبيق

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: themeProvider),
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
    return Selector2<LocaleProvider, ThemeProvider, _AppConfig>(
      selector: (_, locale, theme) => _AppConfig(
        locale: locale.locale, 
        themeMode: theme.themeMode,
        isRTL: locale.isRTL,
      ),
      builder: (context, config, child) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          
          // Localization
          locale: config.locale,
          supportedLocales: const [
            Locale('en'),
            Locale('ar'),
            Locale('ru'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // Theme
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: config.themeMode,

          // RTL Support
          builder: (context, child) {
            return Directionality(
              textDirection: config.isRTL ? TextDirection.rtl : TextDirection.ltr,
              child: child!,
            );
          },

          home: const AuthWrapper(),
        );
      },
    );
  }
}

// كلاس مساعد لتنظيم بيانات Selector
class _AppConfig {
  final Locale locale;
  final ThemeMode themeMode;
  final bool isRTL;

  const _AppConfig({
    required this.locale,
    required this.themeMode,
    required this.isRTL,
  });
}
