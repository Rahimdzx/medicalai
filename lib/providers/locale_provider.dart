import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('en');
  
  Locale get locale => _locale;
  bool get isRTL => _locale.languageCode == 'ar';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString('locale');
    if (savedLocale != null) {
      _locale = Locale(savedLocale);
      notifyListeners();
    }
  }

  void setLocale(String languageCode) {
    if (!['en', 'ru', 'ar'].contains(languageCode)) return;
    _locale = Locale(languageCode);
    notifyListeners();
    _saveLocale(languageCode);
  }

  Future<void> _saveLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', languageCode);
  }
}
