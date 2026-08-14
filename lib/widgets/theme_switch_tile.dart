import 'package:flutter/material.dart';

import '../services/theme_service.dart';
import '../theme/app_theme.dart';

/// Dark / light theme toggle shown on every profile page. Bound to the
/// shared [ThemeService] so the whole app switches instantly.
class ThemeSwitchTile extends StatelessWidget {
  const ThemeSwitchTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService.instance.isDark,
      builder: (context, isDark, _) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderColor.withOpacity(0.7)),
          ),
          child: SwitchListTile(
            value: isDark,
            onChanged: (_) => ThemeService.instance.toggle(),
            secondary: Icon(
              isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              color: isDark ? const Color(0xFF90A4AE) : Colors.orange,
            ),
            title: Text(
              isDark ? 'Dark Theme' : 'Light Theme',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            ),
            subtitle: Text(
              isDark ? 'Dark mode is ON' : 'Switch to dark mode',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            activeTrackColor: AppColors.primaryGreen,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      },
    );
  }
}
