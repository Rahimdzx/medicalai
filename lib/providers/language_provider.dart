import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  final SharedPreferences prefs;
  Locale _appLocale = const Locale('en');

  static const String _languageKey = 'language_code';
  static const List<String> supportedLanguages = ['en', 'ar', 'ru'];

  LanguageProvider(this.prefs) {
    _fetchLocale();
  }

  // Getters for both naming conventions to ensure compatibility
  Locale get appLocale => _appLocale;
  Locale get locale => _appLocale;

  // Check if current language is RTL
  bool get isRTL => _appLocale.languageCode == 'ar';

  // Get current language code
  String get languageCode => _appLocale.languageCode;

  void _fetchLocale() {
    final String? langCode = prefs.getString(_languageKey);
    if (langCode != null && supportedLanguages.contains(langCode)) {
      _appLocale = Locale(langCode);
    } else {
      _appLocale = const Locale('en');
    }
    notifyListeners();
  }

  // Primary method for changing language
  Future<void> changeLanguage(String languageCode) async {
    if (!supportedLanguages.contains(languageCode)) return;
    if (_appLocale.languageCode == languageCode) return;

    _appLocale = Locale(languageCode);
    await prefs.setString(_languageKey, languageCode);
    notifyListeners();
  }

  // Alias for setLocale to support existing code
  Future<void> setLocale(Locale locale) async {
    await changeLanguage(locale.languageCode);
  }

  // Get language display name
  String getLanguageDisplayName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      case 'ru':
        return 'Русский';
      default:
        return code;
    }
  }

  // Get language flag emoji
  String getLanguageFlag(String code) {
    switch (code) {
      case 'en':
        return '🇺🇸';
      case 'ar':
        return '🇸🇦';
      case 'ru':
        return '🇷🇺';
      default:
        return '🌐';
    }
  }
}
