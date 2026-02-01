import '../constants/app_constants.dart';

/// Input validation utilities
class Validators {
  Validators._();

  /// Validates email format
  static String? validateEmail(String? value, {String? emptyMessage, String? invalidMessage}) {
    if (value == null || value.trim().isEmpty) {
      return emptyMessage ?? 'Please enter email';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return invalidMessage ?? 'Invalid email format';
    }

    return null;
  }

  /// Validates password strength
  static String? validatePassword(String? value, {
    String? emptyMessage,
    String? shortMessage,
    int minLength = AppConstants.minPasswordLength,
  }) {
    if (value == null || value.isEmpty) {
      return emptyMessage ?? 'Please enter password';
    }

    if (value.length < minLength) {
      return shortMessage ?? 'Password must be at least $minLength characters';
    }

    return null;
  }

  /// Validates password confirmation matches
  static String? validateConfirmPassword(String? value, String password, {
    String? emptyMessage,
    String? mismatchMessage,
  }) {
    if (value == null || value.isEmpty) {
      return emptyMessage ?? 'Please confirm password';
    }

    if (value != password) {
      return mismatchMessage ?? 'Passwords do not match';
    }

    return null;
  }

  /// Validates required field is not empty
  static String? validateRequired(String? value, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? 'This field is required';
    }
    return null;
  }

  /// Validates name (letters, spaces, and common characters)
  static String? validateName(String? value, {
    String? emptyMessage,
    String? invalidMessage,
    int maxLength = AppConstants.maxNameLength,
  }) {
    if (value == null || value.trim().isEmpty) {
      return emptyMessage ?? 'Please enter name';
    }

    if (value.length > maxLength) {
      return 'Name must be less than $maxLength characters';
    }

    // Allow letters (including Arabic, Russian), spaces, hyphens, and apostrophes
    final nameRegex = RegExp(r"^[\p{L}\s\-']+$", unicode: true);

    if (!nameRegex.hasMatch(value.trim())) {
      return invalidMessage ?? 'Name contains invalid characters';
    }

    return null;
  }

  /// Validates phone number format
  static String? validatePhone(String? value, {
    String? invalidMessage,
    bool required = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Please enter phone number' : null;
    }

    // Remove common formatting characters
    final cleanPhone = value.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');

    // Check if it contains only digits
    if (!RegExp(r'^\d{7,15}$').hasMatch(cleanPhone)) {
      return invalidMessage ?? 'Invalid phone number';
    }

    return null;
  }

  /// Validates numeric input
  static String? validateNumber(String? value, {
    String? emptyMessage,
    String? invalidMessage,
    double? min,
    double? max,
  }) {
    if (value == null || value.trim().isEmpty) {
      return emptyMessage ?? 'Please enter a number';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return invalidMessage ?? 'Invalid number';
    }

    if (min != null && number < min) {
      return 'Value must be at least $min';
    }

    if (max != null && number > max) {
      return 'Value must be at most $max';
    }

    return null;
  }

  /// Validates price/currency input
  static String? validatePrice(String? value, {
    String? emptyMessage,
    bool required = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      return required ? (emptyMessage ?? 'Please enter price') : null;
    }

    final price = double.tryParse(value);
    if (price == null || price < 0) {
      return 'Invalid price';
    }

    return null;
  }

  /// Validates URL format
  static String? validateUrl(String? value, {
    bool required = false,
    String? invalidMessage,
  }) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Please enter URL' : null;
    }

    try {
      final uri = Uri.parse(value);
      if (!uri.hasScheme || (!uri.isScheme('http') && !uri.isScheme('https'))) {
        return invalidMessage ?? 'Invalid URL format';
      }
    } catch (_) {
      return invalidMessage ?? 'Invalid URL format';
    }

    return null;
  }

  /// Validates date is not in the past
  static String? validateFutureDate(DateTime? value, {
    String? emptyMessage,
    String? pastMessage,
  }) {
    if (value == null) {
      return emptyMessage ?? 'Please select a date';
    }

    if (value.isBefore(DateTime.now())) {
      return pastMessage ?? 'Date cannot be in the past';
    }

    return null;
  }

  /// Validates text length
  static String? validateLength(String? value, {
    int? minLength,
    int? maxLength,
    String? tooShortMessage,
    String? tooLongMessage,
  }) {
    if (value == null) return null;

    if (minLength != null && value.length < minLength) {
      return tooShortMessage ?? 'Must be at least $minLength characters';
    }

    if (maxLength != null && value.length > maxLength) {
      return tooLongMessage ?? 'Must be at most $maxLength characters';
    }

    return null;
  }
}
