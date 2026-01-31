import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  final SharedPreferences prefs;
  Locale _appLocale = const Locale('en');

  LanguageProvider(this.prefs) {
    _fetchLocale();
  }

  // هذا هو الـ Getter الذي يطلبه الخطأ في الـ main.dart
  Locale get appLocale => _appLocale;

  void _fetchLocale() {
    String? langCode = prefs.getString('language_code');
    if (langCode == null) {
      _appLocale = const Locale('en');
    } else {
      _appLocale = Locale(langCode);
    }
    notifyListeners();
  }

  void changeLanguage(String languageCode) async {
    _appLocale = Locale(languageCode);
    await prefs.setString('language_code', languageCode);
    notifyListeners();
  }
}
