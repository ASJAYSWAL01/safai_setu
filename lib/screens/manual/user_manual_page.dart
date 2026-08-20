import 'package:flutter/material.dart';

import '../../l10n/manual_strings.dart';
import '../../models/user.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

/// Role-specific user manual shown from the Profile section. The content
/// follows the app language selected on the login screen.
class UserManualPage extends StatelessWidget {
  const UserManualPage({super.key, required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final strings = ManualStrings.of(context);
    final sections = strings.sectionsFor(role);

    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      appBar: AppBar(
        title: Text(
          strings.appBarTitle,
          style: TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RoleHeader(role: role, strings: strings),
              const SizedBox(height: 20),
              for (final section in sections) ...[
                _SectionCard(section: section),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleHeader extends StatelessWidget {
  const _RoleHeader({required this.role, required this.strings});

  final UserRole role;
  final ManualStrings strings;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = switch (role) {
      UserRole.citizen => (Icons.person_outline, AppColors.primaryGreen),
      UserRole.worker => (
          Icons.local_shipping_outlined,
          const Color(0xFF1565C0),
        ),
      UserRole.head => (
          Icons.admin_panel_settings_outlined,
          const Color(0xFF6A1B9A),
        ),
    };

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.manualTitleFor(role),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  strings.subtitle,
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});

  final ManualSection section;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.paleGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(section.icon,
                    color: AppColors.primaryGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  section.title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < section.steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      section.steps[i],
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
