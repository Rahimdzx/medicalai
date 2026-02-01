import 'package:intl/intl.dart';

/// Date, time, and number formatting utilities
class Formatters {
  Formatters._();

  // Date Formats
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _dateFormatAr = DateFormat('yyyy/MM/dd', 'ar');
  static final DateFormat _dateFormatRu = DateFormat('dd.MM.yyyy', 'ru');

  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _time12Format = DateFormat('h:mm a');

  static final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');
  static final DateFormat _fullDateFormat = DateFormat('EEEE, MMMM d, y');

  /// Format date based on locale
  static String formatDate(DateTime date, {String locale = 'en'}) {
    switch (locale) {
      case 'ar':
        return _dateFormatAr.format(date);
      case 'ru':
        return _dateFormatRu.format(date);
      default:
        return _dateFormat.format(date);
    }
  }

  /// Format time (24-hour)
  static String formatTime(DateTime time) {
    return _timeFormat.format(time);
  }

  /// Format time (12-hour with AM/PM)
  static String formatTime12(DateTime time) {
    return _time12Format.format(time);
  }

  /// Format date and time
  static String formatDateTime(DateTime dateTime, {String locale = 'en'}) {
    return '${formatDate(dateTime, locale: locale)} ${formatTime(dateTime)}';
  }

  /// Format full date (e.g., "Monday, January 1, 2024")
  static String formatFullDate(DateTime date, {String locale = 'en'}) {
    return DateFormat('EEEE, MMMM d, y', locale).format(date);
  }

  /// Format relative time (e.g., "5 minutes ago", "yesterday")
  static String formatRelativeTime(DateTime dateTime, {String locale = 'en'}) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return _getRelativeText('just_now', locale);
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return _getRelativeText('minutes_ago', locale, count: minutes);
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return _getRelativeText('hours_ago', locale, count: hours);
    } else if (difference.inDays == 1) {
      return _getRelativeText('yesterday', locale);
    } else if (difference.inDays < 7) {
      return _getRelativeText('days_ago', locale, count: difference.inDays);
    } else {
      return formatDate(dateTime, locale: locale);
    }
  }

  static String _getRelativeText(String key, String locale, {int count = 0}) {
    final Map<String, Map<String, String>> texts = {
      'just_now': {'en': 'Just now', 'ar': 'الآن', 'ru': 'Только что'},
      'minutes_ago': {'en': '$count min ago', 'ar': 'منذ $count د', 'ru': '$count мин назад'},
      'hours_ago': {'en': '$count h ago', 'ar': 'منذ $count س', 'ru': '$count ч назад'},
      'yesterday': {'en': 'Yesterday', 'ar': 'أمس', 'ru': 'Вчера'},
      'days_ago': {'en': '$count days ago', 'ar': 'منذ $count أيام', 'ru': '$count дн назад'},
    };
    return texts[key]?[locale] ?? texts[key]?['en'] ?? key;
  }

  /// Format chat timestamp (time if today, date if older)
  static String formatChatTimestamp(DateTime dateTime, {String locale = 'en'}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return formatTime(dateTime);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return _getRelativeText('yesterday', locale);
    } else {
      return formatDate(dateTime, locale: locale);
    }
  }

  /// Format call duration (e.g., "05:23" or "1:23:45")
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString()}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format file size (bytes to human readable)
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Format currency
  static String formatCurrency(double amount, {String currency = 'USD', String locale = 'en'}) {
    final format = NumberFormat.currency(locale: locale, symbol: _getCurrencySymbol(currency));
    return format.format(amount);
  }

  static String _getCurrencySymbol(String currency) {
    const symbols = {
      'USD': '\$',
      'EUR': '\u20AC',
      'RUB': '\u20BD',
      'SAR': 'SAR',
      'AED': 'AED',
    };
    return symbols[currency] ?? currency;
  }

  /// Format number with thousands separator
  static String formatNumber(num number, {String locale = 'en'}) {
    return NumberFormat('#,###', locale).format(number);
  }

  /// Format percentage
  static String formatPercentage(double value, {int decimals = 0}) {
    return '${(value * 100).toStringAsFixed(decimals)}%';
  }

  /// Format phone number for display
  static String formatPhoneNumber(String phone) {
    // Remove non-digits
    final digits = phone.replaceAll(RegExp(r'\D'), '');

    if (digits.length == 10) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    } else if (digits.length == 11) {
      return '+${digits[0]} (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7)}';
    }

    return phone;
  }

  /// Truncate text with ellipsis
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  /// Format name (capitalize first letter of each word)
  static String formatName(String name) {
    return name.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
