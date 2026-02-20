import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

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

  // تهيئة التاريخ
  await initializeDateFormatting('ru_RU', null);
  await initializeDateFormatting('ar', null);
  await initializeDateFormatting('en_US', null);

  final prefs = await SharedPreferences.getInstance();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final localeProvider = LocaleProvider(prefs);
  await localeProvider.init();
  
  final themeProvider = ThemeProvider(prefs);
  //themeProvider.init(); // <-- تم التعليق عليه إذا لم تكن موجودة

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
    return Selector2<LocaleProvider, ThemeProvider, ({Locale locale, ThemeMode themeMode, bool isRTL})>(
      selector: (_, locale, theme) => (
        locale: locale.locale, 
        themeMode: theme.themeMode,
        isRTL: locale.isRTL,
      ),
      builder: (context, data, child) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          
          // Localization
          locale: data.locale,
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
          themeMode: data.themeMode,

          // RTL Support
          builder: (context, child) {
            return Directionality(
              textDirection: data.isRTL ? TextDirection.rtl : TextDirection.ltr,
              child: child!,
            );
          },

          home: const AuthWrapper(),
        );
      },
    );
  }
}
