import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

  // تهيئة critical للتاريخ (للتقويم)
  await initializeDateFormatting('ru_RU', null);
  await initializeDateFormatting('ar', null);
  await initializeDateFormatting('en_US', null);

  final prefs = await SharedPreferences.getInstance();

  // تثبيت الوضع العمودي (اختياري لكن مفيد)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // تهيئة Providers قبل runApp
  final localeProvider = LocaleProvider(prefs);
  await localeProvider.init();
  
  final themeProvider = ThemeProvider(prefs);
  await themeProvider.init();

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
    // استخدام Selector بدلاً من Consumer للأداء الأفضل
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
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // Theme
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: data.themeMode,

          // RTL Support (من الخيار الأول)
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
