import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/language_service.dart';
import '../theme/app_theme.dart';

/// Opens the language picker bottom sheet (English / हिन्दी / ગુજરાતી).
/// Selecting a language applies it to the whole app instantly and remembers
/// it for the next launch. Shared by the login screen and profile pages.
Future<void> showLanguagePicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      final strings = AppStrings.of(sheetContext);
      final current = LanguageService.instance.current.value;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.chooseLanguage,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                strings.selectLanguageHint,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              for (final lang in AppLanguage.values)
                _LanguageTile(
                  language: lang,
                  selected: current == lang,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    LanguageService.instance.setLanguage(lang);
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}

/// "App Language" tile shown on every profile page — opens [showLanguagePicker]
/// and shows the currently active language.
class LanguageTile extends StatelessWidget {
  const LanguageTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: LanguageService.instance.current,
      builder: (context, lang, _) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderColor.withOpacity(0.7)),
          ),
          child: ListTile(
            onTap: () => showLanguagePicker(context),
            leading: Icon(
              Icons.language,
              color: AppColors.primaryGreen,
            ),
            title: const Text(
              'App Language',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            ),
            subtitle: Text(
              lang.nativeLabel,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      },
    );
  }
}

/// One option in the language picker sheet — shows the language in its own
/// script with a green check when it is the active one.
class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: selected ? AppColors.paleGreen : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    language.nativeLabel,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_circle,
                    color: AppColors.primaryGreen,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
