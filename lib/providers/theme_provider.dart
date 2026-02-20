import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';

/// مزود الثيمات - يدير الوضع الليلي/النهاري والإعدادات المحفوظة
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  final SharedPreferences _prefs;
  
  ThemeMode _themeMode = ThemeMode.system;
  bool _isInitialized = false;

  ThemeProvider(this._prefs) {
    // تحميل الإعدادات فوراً عند الإنشاء
    _loadTheme();
  }

  // Getters
  ThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;
  
  /// الثيم الحالي بناءً على الوضع المختار
  ThemeData get currentTheme {
    if (_themeMode == ThemeMode.dark) return AppTheme.darkTheme;
    if (_themeMode == ThemeMode.light) return AppTheme.lightTheme;
    
    // الوضع التلقائي - يتبع إعدادات النظام
    final platformBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return platformBrightness == Brightness.dark ? AppTheme.darkTheme : AppTheme.lightTheme;
  }

  /// هل الوضع الليلي مفعل حالياً؟
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  /// تحميل الإعدادات المحفوظة
  void _loadTheme() {
    try {
      final savedTheme = _prefs.getString(_themeKey);
      if (savedTheme != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (e) => e.toString() == savedTheme,
          orElse: () => ThemeMode.system,
        );
      }
    } catch (e) {
      debugPrint('Error loading theme: $e');
      _themeMode = ThemeMode.system;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// تهيئة إضافية (اختيارية) - إذا أردت استخدام await في main.dart
  Future<void> init() async {
    if (!_isInitialized) {
      _loadTheme();
    }
  }

  /// تغيير وضع الثيم
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    await _prefs.setString(_themeKey, mode.toString());
    notifyListeners();
  }

  /// التبديل بين الوضع الليلي والنهاري
  Future<void> toggleTheme() async {
    final modes = [ThemeMode.light, ThemeMode.dark, ThemeMode.system];
    final currentIndex = modes.indexOf(_themeMode);
    final nextIndex = (currentIndex + 1) % modes.length;
    await setThemeMode(modes[nextIndex]);
  }

  /// تفعيل الوضع الليلي مباشرة
  Future<void> setDarkMode() async {
    await setThemeMode(ThemeMode.dark);
  }

  /// تفعيل الوضع النهاري مباشرة
  Future<void> setLightMode() async {
    await setThemeMode(ThemeMode.light);
  }

  /// إعادة ضبط الثيم على الوضع التلقائي (يتبع النظام)
  Future<void> resetToSystem() async {
    await setThemeMode(ThemeMode.system);
  }
}
