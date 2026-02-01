import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

/// Provider for managing application language and locale settings
class LanguageProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  Locale _appLocale;
  bool _isLoading = false;

  LanguageProvider(this._prefs) : _appLocale = const Locale('en') {
    _loadSavedLocale();
  }

  /// Current application locale
  Locale get appLocale => _appLocale;

  /// Current language code (e.g., 'en', 'ar', 'ru')
  String get languageCode => _appLocale.languageCode;

  /// Whether the current language is RTL
  bool get isRTL => AppConstants.rtlLanguages.contains(_appLocale.languageCode);

  /// Text direction based on current language
  TextDirection get textDirection => isRTL ? TextDirection.rtl : TextDirection.ltr;

  /// Loading state
  bool get isLoading => _isLoading;

  /// Get language display name
  String get currentLanguageName =>
      AppConstants.languageNames[_appLocale.languageCode] ?? 'English';

  /// Get language flag emoji
  String get currentLanguageFlag =>
      AppConstants.languageFlags[_appLocale.languageCode] ?? '🇺🇸';

  /// List of supported locales
  List<Locale> get supportedLocales =>
      AppConstants.supportedLanguages.map((code) => Locale(code)).toList();

  /// Load saved locale from preferences
  void _loadSavedLocale() {
    final savedLanguageCode = _prefs.getString(AppConstants.prefLanguageCode);
    if (savedLanguageCode != null &&
        AppConstants.supportedLanguages.contains(savedLanguageCode)) {
      _appLocale = Locale(savedLanguageCode);
    } else {
      // Default to English if no saved preference
      _appLocale = const Locale('en');
    }
    notifyListeners();
  }

  /// Change application language
  Future<void> changeLanguage(String languageCode) async {
    if (!AppConstants.supportedLanguages.contains(languageCode)) {
      debugPrint('Unsupported language code: $languageCode');
      return;
    }

    if (_appLocale.languageCode == languageCode) {
      return; // No change needed
    }

    _isLoading = true;
    notifyListeners();

    try {
      _appLocale = Locale(languageCode);
      await _prefs.setString(AppConstants.prefLanguageCode, languageCode);
    } catch (e) {
      debugPrint('Error saving language preference: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Change language using Locale object
  Future<void> setLocale(Locale locale) async {
    await changeLanguage(locale.languageCode);
  }

  /// Get language name by code
  String getLanguageName(String code) {
    return AppConstants.languageNames[code] ?? code;
  }

  /// Get language flag by code
  String getLanguageFlag(String code) {
    return AppConstants.languageFlags[code] ?? '🏳️';
  }

  /// Check if a language code is RTL
  bool isLanguageRTL(String code) {
    return AppConstants.rtlLanguages.contains(code);
  }

  /// Get all available languages with their details
  List<LanguageOption> get availableLanguages {
    return AppConstants.supportedLanguages.map((code) {
      return LanguageOption(
        code: code,
        name: AppConstants.languageNames[code] ?? code,
        flag: AppConstants.languageFlags[code] ?? '🏳️',
        isRTL: AppConstants.rtlLanguages.contains(code),
        isSelected: _appLocale.languageCode == code,
      );
    }).toList();
  }

  /// Reset to default language (English)
  Future<void> resetToDefault() async {
    await changeLanguage(AppConstants.defaultLanguage);
  }
}

/// Model for language option
class LanguageOption {
  final String code;
  final String name;
  final String flag;
  final bool isRTL;
  final bool isSelected;

  const LanguageOption({
    required this.code,
    required this.name,
    required this.flag,
    required this.isRTL,
    required this.isSelected,
  });

  /// Display string combining flag and name
  String get displayName => '$flag $name';
}
