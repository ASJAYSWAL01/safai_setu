import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/language_picker.dart';
import '../../widgets/theme_switch_tile.dart';
import '../about/about_page.dart';
import '../auth/auth_gate.dart';
import '../manual/user_manual_page.dart';
import '../support/call_assistant_page.dart';
import '../support/development_team_page.dart';
import '../support/help_support_page.dart';

class WorkerProfilePage extends StatelessWidget {
  const WorkerProfilePage({super.key});

  Future<void> _logout(BuildContext context) => performLogout(context);

  @override
  Widget build(BuildContext context) {
    final AppUser worker = AuthService.instance.user!;

    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      appBar: AppBar(
        title: Text(
          'Worker Profile',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _Avatar(worker: worker),
              const SizedBox(height: 14),
              Text(
                worker.name,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Pickup Truck Worker',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              AppCard(
                child: Column(
                  children: [
                    _InfoRow(label: 'Worker ID', value: worker.workerId ?? '—'),
                    const Divider(height: 20),
                    _InfoRow(
                        label: 'Vehicle Number',
                        value: worker.vehicleNumber ?? '—'),
                    const Divider(height: 20),
                    _InfoRow(label: 'Mobile', value: worker.phone ?? '—'),
                    const Divider(height: 20),
                    _InfoRow(label: 'Email', value: worker.email),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How it works',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Worker ID is issued by your department Head.\n'
                      '• Collection tasks are assigned by the Head.\n'
                      '• After collecting waste, take a proof photo — it is sent to the citizen and the Head.',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const ThemeSwitchTile(),
              const LanguageTile(),
              _MenuTile(
                icon: Icons.menu_book_outlined,
                title: 'User Manual',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) =>
                            const UserManualPage(role: UserRole.worker)),
                  );
                },
              ),
              _MenuTile(
                icon: Icons.support_agent,
                title: 'Call Our Assistant',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const CallAssistantPage()),
                  );
                },
              ),
              _MenuTile(
                icon: Icons.engineering_outlined,
                title: 'Development Team',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const DevelopmentTeamPage()),
                  );
                },
              ),
              _MenuTile(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const HelpSupportPage()),
                  );
                },
              ),
              _MenuTile(
                icon: Icons.info_outline,
                title: 'About Safai Setu',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const AboutPage()),
                  );
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                        color: Colors.redAccent, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.worker});

  final AppUser worker;

  @override
  Widget build(BuildContext context) {
    final photo = worker.photoUrl;
    if (photo != null && photo.isNotEmpty) {
      return CircleAvatar(
        radius: 44,
        backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
        backgroundImage: NetworkImage(photo),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: 44,
      backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
      child: const Icon(Icons.local_shipping_rounded,
          size: 44, color: Color(0xFF1565C0)),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.7)),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryGreen),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
