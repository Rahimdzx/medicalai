import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  final SharedPreferences _prefs;
  
  LocaleProvider(this._prefs);
  
  Locale get locale => _locale;
  bool get isRTL => _locale.languageCode == 'ar';
  
  Future<void> init() async {
    final savedCode = _prefs.getString('locale_code');
    if (savedCode != null && ['en', 'ar', 'ru'].contains(savedCode)) {
      _locale = Locale(savedCode);
      notifyListeners();
    }
  }
  
  Future<void> setLocale(String languageCode) async {
    if (!['en', 'ru', 'ar'].contains(languageCode)) return;
    _locale = Locale(languageCode);
    await _prefs.setString('locale_code', languageCode);
    notifyListeners();
  }
}
