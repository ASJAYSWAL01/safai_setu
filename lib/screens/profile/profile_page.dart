import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/complaint_service.dart';
import '../../services/theme_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/complete_profile_dialog.dart';
import '../../widgets/language_picker.dart';
import '../../widgets/theme_switch_tile.dart';
import '../about/about_page.dart';
import '../auth/auth_gate.dart';
import '../manual/user_manual_page.dart';
import '../support/call_assistant_page.dart';
import '../support/development_team_page.dart';
import '../notifications/notifications_page.dart';
import '../support/help_support_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  ComplaintStats? _stats;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
    AuthService.instance.currentUser.addListener(_onUserChanged);
  }

  @override
  void dispose() {
    AuthService.instance.currentUser.removeListener(_onUserChanged);
    super.dispose();
  }

  void _onUserChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _editProfile() async {
    final user = AuthService.instance.user;
    if (user == null) return;
    final saved = await showCompleteProfileDialog(
      context,
      initialPhone: user.phone,
      isEditing: true,
    );
    if (saved) {
      await AuthService.instance.refreshCurrentUser();
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await ComplaintService.instance.fetchMyStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _loadingStats = false;
        });
      }
    } on Object {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Rebuild instantly when the theme toggles (works whether this page is
    // the Profile tab or pushed from the home screen).
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService.instance.isDark,
      builder: (context, _, __) => Scaffold(
        backgroundColor: AppColors.mintBackground,
        appBar: AppBar(
          title: Text(
            'Profile',
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
              _Avatar(
                name: user.name,
                photoUrl: user.photoUrl,
                isChampion: (_stats?.resolved ?? 0) > 10,
              ),
              const SizedBox(height: 14),
              Text(
                user.name,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              if ((_stats?.resolved ?? 0) > 10) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Safai Champion',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                'Citizen Account',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              if (user.phone != null && user.phone!.trim().isNotEmpty)
                Text(
                  user.phone!,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              Text(
                user.email,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      label: 'Total Complaints',
                      value: _loadingStats ? '…' : '${_stats?.total ?? 0}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatBox(
                      label: 'Resolved',
                      value: _loadingStats ? '…' : '${_stats?.resolved ?? 0}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _MenuTile(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                onTap: _editProfile,
              ),
              _MenuTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const NotificationsPage()),
                  );
                },
              ),
              _MenuTile(
                icon: Icons.menu_book_outlined,
                title: 'User Manual',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) =>
                            const UserManualPage(role: UserRole.citizen)),
                  );
                },
              ),
              const ThemeSwitchTile(),
              const LanguageTile(),
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => performLogout(context),
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                        color: Colors.redAccent, fontWeight: FontWeight.w600),
                  ),
                  style:              OutlinedButton.styleFrom(
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
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.photoUrl, this.isChampion = false});

  final String name;
  final String? photoUrl;
  final bool isChampion;

  @override
  Widget build(BuildContext context) {
    final border = isChampion
        ? const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
            ),
          )
        : null;

    final child = CircleAvatar(
      radius: isChampion ? 48 : 44,
      backgroundColor: AppColors.paleGreen,
      backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
          ? NetworkImage(photoUrl!)
          : null,
      onBackgroundImageError: (_, __) {},
      child: (photoUrl == null || photoUrl!.isEmpty)
          ? Text(
              name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: isChampion ? 30 : 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            )
          : null,
    );

    if (!isChampion) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: border,
          child: child,
        ),
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFFFFB300),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star, color: Colors.white, size: 14),
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
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
