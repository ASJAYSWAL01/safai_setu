import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import '../../utils/call_utils.dart';

/// "Development Team" — the people behind Safai Setu with one-tap contact
/// links (GitHub, LinkedIn, WhatsApp, phone).
class DevelopmentTeamPage extends StatelessWidget {
  const DevelopmentTeamPage({super.key});

  static const _members = <_TeamMember>[
    _TeamMember(
      name: 'Ashish Jayswal',
      role: 'Team Lead',
      photo: 'assets/images/assistant_ashish.png',
      github: 'https://github.com/ASJAYSWAL01',
      linkedin: 'https://www.linkedin.com/in/ashishjayswal01/',
      whatsapp:
          'https://wa.me/917283881430?text=Hello%20sir%21%20I%20want%20to%20talk%20regarding%20the%20Safai%20Setu%20app%2C%20which%20is%20developed%20by%20your%20team%2C%20Diplomax.',
      phone: '+91-7283881430',
    ),
    _TeamMember(
      name: 'Het Suthar',
      role: 'Co-Lead',
      photo: 'assets/images/assistant_het.jpg',
      github: 'https://github.com/Het-Suthar1809',
      linkedin: 'https://www.linkedin.com/in/het1809',
      whatsapp:
          'https://wa.me/916355413255?text=Hello%20sir%21%20I%20want%20to%20talk%20regarding%20the%20Safai%20Setu%20app%2C%20which%20is%20developed%20by%20your%20team%2C%20Diplomax.',
      phone: '+91-6355413255',
    ),
    _TeamMember(
      name: 'Hrishit Patel',
      role: 'Member',
      photo: 'assets/images/assistant_hrisit.jpg',
      github: 'https://github.com/Hri25',
      // LinkedIn not provided yet — the button shows but is disabled.
      linkedin: '#',
      whatsapp:
          'https://wa.me/919428444614?text=Hello%20Sir%21%20I%20want%20to%20talk%20regarding%20the%20Safai%20Setu%20app%2C%20which%20is%20developed%20by%20the%20Diplomax%20team%2C%20and%20you%20are%20a%20member%20of%20the%20team',
      phone: '+91-9428444614',
    ),
    _TeamMember(
      name: 'Nihar Shukla',
      role: 'Member',
      photo: 'assets/images/assistant_nihar.jpg',
      github: 'https://github.com/Nihar-Shukla',
      linkedin: 'https://www.linkedin.com/in/nihar-shukla-296542426',
      whatsapp:
          'https://wa.me/919428400234?text=Hello%20Sir%21%20I%20want%20to%20talk%20regarding%20the%20Safai%20Setu%20app%2C%20which%20is%20developed%20by%20the%20Diplomax%20team%2C%20and%20you%20are%20a%20member%20of%20the%20team',
      phone: '+91-9428400234',
    ),
    _TeamMember(
      name: 'Harsh Trivedi',
      role: 'Member',
      photo: 'assets/images/assistant_harsh.jpg',
      github: 'https://github.com/HarshTrivedi99',
      linkedin: 'https://www.linkedin.com/in/harsh-trivedi-31968838b',
      whatsapp:
          'https://wa.me/919909430299?text=Hello%20Sir%21%20I%20want%20to%20talk%20regarding%20the%20Safai%20Setu%20app%2C%20which%20is%20developed%20by%20the%20Diplomax%20team%2C%20and%20you%20are%20a%20member%20of%20the%20team',
      phone: '+91-9909430299',
    ),
    _TeamMember(
      name: 'Preeyanshi Parekh',
      role: 'Member',
      photo: 'assets/images/assistant_preeyanshi.jpg',
      github: 'https://github.com/peehuparekh',
      linkedin: 'https://www.linkedin.com/in/preeyaanshi-parekh-74a212268',
      whatsapp:
          'https://wa.me/919104642214?text=Hello%20Ma%27am%21%20I%20want%20to%20talk%20regarding%20the%20Safai%20Setu%20app%2C%20which%20is%20developed%20by%20the%20Diplomax%20team%2C%20and%20you%20are%20a%20member%20of%20the%20team',
      phone: '+91-9104642214',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      appBar: AppBar(
        title: Text(
          'Development Team',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _heroHeader(context),
              const SizedBox(height: 20),
              for (var i = 0; i < _members.length; i++) ...[
                _MemberCard(member: _members[i], number: i + 1),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  /// Gradient hero banner with the mascot.
  Widget _heroHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.darkGreen,
            AppColors.primaryGreen,
            AppColors.lightGreen,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.35),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative translucent circles.
          Positioned(
            right: -26,
            top: -34,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            right: 60,
            bottom: -40,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '★ Core Team',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'The Team Behind\nSafai Setu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap any logo to visit the profile\nor start a chat.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Image.asset(
                'assets/images/safai_setu_mascot.png',
                width: 96,
                height: 96,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamMember {
  const _TeamMember({
    required this.name,
    required this.role,
    this.photo,
    this.github,
    this.linkedin,
    this.whatsapp,
    this.phone,
  });

  final String name;
  final String role;
  final String? photo;
  final String? github;
  final String? linkedin;
  final String? whatsapp;
  final String? phone;

  bool get hasLinks =>
      github != null || linkedin != null || whatsapp != null || phone != null;
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member, required this.number});

  final _TeamMember member;
  final int number;

  Color get _accent => AppColors.primaryGreen;

  @override
  Widget build(BuildContext context) {
    final placeholder = !member.hasLinks;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: placeholder
              ? AppColors.borderColor
              : _accent.withOpacity(0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: (_accent).withOpacity(placeholder ? 0.05 : 0.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decorative glow blob in the top-right corner.
            Positioned(
              top: -34,
              right: -28,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.withOpacity(placeholder ? 0.05 : 0.10),
                ),
              ),
            ),
            // Big translucent number badge in the background.
            Positioned(
              right: 14,
              bottom: -18,
              child: Text(
                number.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  color: _accent.withOpacity(placeholder ? 0.04 : 0.07),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _ringAvatar(context),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            _roleChip(placeholder),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (placeholder)
                    _placeholderStrip()
                  else
                    _actionRow(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Photo with a gradient ring (like a badge).
  Widget _ringAvatar(BuildContext context) {
    final photo = member.photo;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            _accent,
            AppColors.lightGreen,
            _accent.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: SizedBox(
          width: 62,
          height: 62,
          child: photo != null
              ? Image.asset(
                  photo,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _initialsCircle(),
                )
              : _initialsCircle(),
        ),
      ),
    );
  }

  Widget _initialsCircle() {
    final initials = member.name
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0])
        .join()
        .toUpperCase();
    return Container(
      color: AppColors.paleGreen,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryGreen,
        ),
      ),
    );
  }

  IconData get _roleIcon {
    if (placeholder) return Icons.schedule;
    final role = member.role.toLowerCase();
    if (role == 'team lead' || role == 'lead') {
      return Icons.workspace_premium_rounded;
    }
    if (role == 'co-lead' || role == 'co lead') {
      return Icons.star_rounded;
    }
    return Icons.person_outline;
  }

  bool get placeholder => !member.hasLinks;

  Widget _roleChip(bool placeholder) {
    final icon = _roleIcon;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: placeholder
              ? [AppColors.textSecondary.withOpacity(0.12), AppColors.textSecondary.withOpacity(0.06)]
              : [AppColors.paleGreen, _accent.withOpacity(0.15)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: placeholder ? AppColors.textSecondary : _accent,
          ),
          const SizedBox(width: 5),
          Text(
            member.role,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: placeholder ? AppColors.textSecondary : _accent,
            ),
          ),
        ],
      ),
    );
  }

  bool get _linkedinEnabled {
    final link = member.linkedin?.trim();
    return link != null && link.isNotEmpty && link != '#';
  }

  /// Glassy circular action buttons — only the links the member has.
  Widget _actionRow(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (member.github != null)
          _GlassyButton(
            icon: FaIcon(FontAwesomeIcons.github,
                color: AppColors.textPrimary, size: 18),
            color: AppColors.textPrimary,
            tooltip: 'GitHub',
            onTap: () => _openLink(context, member.github!, 'GitHub'),
          ),
        if (member.linkedin != null)
          _GlassyButton(
            icon: FaIcon(
              FontAwesomeIcons.linkedinIn,
              color: _linkedinEnabled
                  ? const Color(0xFF0A66C2)
                  : AppColors.textSecondary.withOpacity(0.45),
              size: 18,
            ),
            color: _linkedinEnabled
                ? const Color(0xFF0A66C2)
                : AppColors.textSecondary,
            tooltip: _linkedinEnabled ? 'LinkedIn' : 'LinkedIn not available',
            enabled: _linkedinEnabled,
            onTap: () => _openLink(context, member.linkedin!, 'LinkedIn'),
          ),
        if (member.whatsapp != null)
          _GlassyButton(
            icon: const FaIcon(FontAwesomeIcons.whatsapp,
                color: Color(0xFF25D366), size: 18),
            color: const Color(0xFF25D366),
            tooltip: 'WhatsApp',
            onTap: () => _openLink(context, member.whatsapp!, 'WhatsApp'),
          ),
        if (member.phone != null)
          _GlassyButton(
            icon: Icon(Icons.phone_outlined,
                color: AppColors.primaryGreen, size: 19),
            color: AppColors.primaryGreen,
            tooltip: 'Call',
            onTap: () => callPhoneNumber(context, phone: member.phone!),
          ),
      ],
    );
  }

  Widget _placeholderStrip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.textSecondary.withOpacity(0.08),
            AppColors.textSecondary.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_top_rounded,
              size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 7),
          Text(
            'Details will be added soon.',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openLink(BuildContext context, String url, String label) async {
    final uri = Uri.parse(url);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $label.')),
        );
      }
    } on Object catch (e) {
      debugPrint('open $label error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $label: $e')),
        );
      }
    }
  }
}

/// Circular glassy icon button with a tinted fill and a soft ring.
class _GlassyButton extends StatelessWidget {
  const _GlassyButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
    this.enabled = true,
  });

  final Widget icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  /// When false the button renders dimmed and does nothing on tap.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withOpacity(enabled ? 0.12 : 0.06),
        shape: const CircleBorder(),
        elevation: enabled ? 1 : 0,
        shadowColor: color.withOpacity(0.35),
        child: InkWell(
          onTap: enabled ? onTap : null,
          customBorder: const CircleBorder(),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(enabled ? 0.35 : 0.15),
                width: 1.2,
              ),
            ),
            child: Center(child: icon),
          ),
        ),
      ),
    );
  }
}
