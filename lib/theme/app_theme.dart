import 'package:flutter/material.dart';

/// Central color palette. All colors are theme-aware: they return light-mode
/// values when [isDark] is false and dark-mode values when it is true.
/// Set [AppColors.isDark] from the theme toggle (ThemeService) before the
/// widget tree rebuilds.
class AppColors {
  static bool isDark = false;

  static Color get primaryGreen =>
      isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
  static Color get darkGreen =>
      isDark ? const Color(0xFFA5D6A7) : const Color(0xFF1B5E20);
  static Color get lightGreen =>
      isDark ? const Color(0xFF66BB6A) : const Color(0xFF4CAF50);
  static Color get accentGreen =>
      isDark ? const Color(0xFF4CAF50) : const Color(0xFF66BB6A);
  static Color get paleGreen =>
      isDark ? const Color(0xFF1E3325) : const Color(0xFFE8F5E9);
  static Color get mintBackground =>
      isDark ? const Color(0xFF111511) : const Color(0xFFF1F8F4);
  static Color get textPrimary =>
      isDark ? const Color(0xFFF1F8F4) : const Color(0xFF1A1A1A);
  static Color get textSecondary =>
      isDark ? const Color(0xFF9FB3A8) : const Color(0xFF616161);
  static Color get borderColor =>
      isDark ? const Color(0xFF2A3A30) : const Color(0xFFE0E0E0);
  static Color get cardColor =>
      isDark ? const Color(0xFF1B231E) : const Color(0xFFFFFFFF);
}

class AppTheme {
  static ThemeData get lightTheme => _buildTheme(dark: false);
  static ThemeData get darkTheme => _buildTheme(dark: true);

  /// The active theme, based on the current [AppColors.isDark] flag.
  static ThemeData get current => AppColors.isDark ? darkTheme : lightTheme;

  static ThemeData _buildTheme({required bool dark}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: dark ? const Color(0xFF81C784) : AppColors.primaryGreen,
      primary: AppColors.primaryGreen,
      secondary: AppColors.lightGreen,
      surface: AppColors.cardColor,
      brightness: dark ? Brightness.dark : Brightness.light,
    );

    final inputFill = dark ? AppColors.cardColor : Colors.white;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.mintBackground,
      canvasColor: AppColors.mintBackground,
      cardColor: AppColors.cardColor,
      dividerColor: AppColors.borderColor,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.mintBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.cardColor,
        indicatorColor: AppColors.paleGreen,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primaryGreen
                : AppColors.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.primaryGreen
                : AppColors.textSecondary,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primaryGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        hintStyle: TextStyle(color: AppColors.textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: dark ? const Color(0xFF111511) : Colors.white,
          elevation: 2,
          shadowColor: AppColors.primaryGreen.withOpacity(0.35),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryGreen;
          }
          return Colors.transparent;
        }),
        side: BorderSide(color: AppColors.borderColor, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardColor,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.cardColor,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.primaryGreen,
        textColor: AppColors.textPrimary,
      ),
    );
  }

  static BoxDecoration get screenGradient => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AppColors.isDark
              ? const [Color(0xFF16201A), Color(0xFF111511), Color(0xFF0E120E)]
              : const [Color(0xFFE8F5E9), Color(0xFFF1F8F4), Colors.white],
          stops: const [0.0, 0.35, 1.0],
        ),
      );
}
