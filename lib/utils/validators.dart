class Validators {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _mobileRegex = RegExp(r'^[6-9]\d{9}$');

  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? email(String? value) {
    final requiredError = required(value, fieldName: 'Email');
    if (requiredError != null) return requiredError;

    if (!_emailRegex.hasMatch(value!.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? mobile(String? value) {
    final requiredError = required(value, fieldName: 'Mobile number');
    if (requiredError != null) return requiredError;

    final cleaned = value!.replaceAll(RegExp(r'\s+'), '');
    if (!_mobileRegex.hasMatch(cleaned)) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  static String? emailOrMobile(String? value) {
    final requiredError = required(value, fieldName: 'Email or mobile number');
    if (requiredError != null) return requiredError;

    final trimmed = value!.trim();
    if (_emailRegex.hasMatch(trimmed)) return null;

    final cleaned = trimmed.replaceAll(RegExp(r'\s+'), '');
    if (_mobileRegex.hasMatch(cleaned)) return null;

    return 'Enter a valid email or 10-digit mobile number';
  }

  static String? password(String? value, {int minLength = 6}) {
    final requiredError = required(value, fieldName: 'Password');
    if (requiredError != null) return requiredError;

    if (value!.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    final requiredError = required(value, fieldName: 'Confirm password');
    if (requiredError != null) return requiredError;

    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }
}
