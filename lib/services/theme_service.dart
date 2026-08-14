import 'package:flutter/foundation.dart';

/// In-memory theme preference. The chosen mode is applied immediately and
/// remembered for the current app session.
class ThemeService {
  ThemeService._();

  static final ThemeService instance = ThemeService._();

  /// True when dark mode is active.
  final ValueNotifier<bool> isDark = ValueNotifier<bool>(false);

  bool get darkMode => isDark.value;

  void toggle() {
    isDark.value = !isDark.value;
  }

  void setDark(bool dark) {
    isDark.value = dark;
  }
}
