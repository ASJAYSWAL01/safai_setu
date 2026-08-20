import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app languages offered on the login screen.
enum AppLanguage {
  english('en', 'English'),
  hindi('hi', 'हिन्दी'),
  gujarati('gu', 'ગુજરાતી');

  const AppLanguage(this.code, this.nativeLabel);

  /// BCP-47 language code used for Flutter localization.
  final String code;

  /// The language name shown in its own script (used in the picker).
  final String nativeLabel;

  Locale get locale => Locale(code);
}

/// Current app language. The choice is applied instantly (whole app rebuilds)
/// and remembered on this device for the next launch.
class LanguageService {
  LanguageService._();
  static final LanguageService instance = LanguageService._();

  static const String _prefsKey = 'app_language';

  /// Currently selected language. Listen to this to rebuild the app on change.
  final ValueNotifier<AppLanguage> current =
      ValueNotifier<AppLanguage>(AppLanguage.english);

  Locale get locale => current.value.locale;

  /// Restores the saved language (called once at startup). Defaults to English.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefsKey);
      final saved = AppLanguage.values.firstWhere(
        (lang) => lang.code == code,
        orElse: () => AppLanguage.english,
      );
      current.value = saved;
    } on Object {
      // Default to English — persistence failure is non-fatal.
    }
  }

  /// Sets the language, applies it immediately and remembers the choice.
  Future<void> setLanguage(AppLanguage language) async {
    current.value = language;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, language.code);
    } on Object {
      // Persistence failure is non-fatal — the change still applies.
    }
  }
}
