import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/call_utils.dart';
import '../../widgets/app_card.dart';

/// "Call Our Assistant" — shows the support team members with one-tap dial.
class CallAssistantPage extends StatelessWidget {
  const CallAssistantPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      appBar: AppBar(
        title: Text(
          'Call Our Assistant',
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
              _header(context),
              const SizedBox(height: 20),
              _AssistantCard(
                name: 'Ashish Jayswal',
                role: 'Support Assistant',
                phone: '+91-7283881430',
                photo: 'assets/images/assistant_ashish.png',
                gradient: const [Color(0xFF2E7D32), Color(0xFF66BB6A)],
              ),
              const SizedBox(height: 16),
              _AssistantCard(
                name: 'Het Suthar',
                role: 'Support Assistant',
                phone: '+91-6355413255',
                photo: 'assets/images/assistant_het.jpg',
                gradient: const [Color(0xFF1565C0), Color(0xFF42A5F5)],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.paleGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.support_agent,
                color: AppColors.primaryGreen, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Need help?',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  'Tap Call on any assistant and we will connect you right away.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
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

class _AssistantCard extends StatelessWidget {
  const _AssistantCard({
    required this.name,
    required this.role,
    required this.phone,
    required this.gradient,
    this.photo,
  });

  final String name;
  final String role;
  final String phone;
  final List<Color> gradient;

  /// Asset path of the assistant's photo, shown in the circular avatar.
  final String? photo;

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    return parts.map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase();
  }

  Widget _initialsAvatar() {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          // Circular photo avatar (falls back to gradient initials if the
          // image ever fails to load).
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(
              child: photo != null
                  ? Image.asset(
                      photo!,
                      width: 62,
                      height: 62,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _initialsAvatar(),
                    )
                  : _initialsAvatar(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: gradient.first.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: gradient.first.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.phone_outlined,
                          size: 13, color: gradient.first),
                      const SizedBox(width: 5),
                      Text(
                        phone,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: gradient.first,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // One-tap call button — soft tinted pill that matches the app.
          Material(
            color: gradient.first.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () => callPhoneNumber(context, phone: phone),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: gradient.first.withOpacity(0.35),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.call, color: gradient.first, size: 20),
                    const SizedBox(height: 2),
                    Text(
                      'Call',
                      style: TextStyle(
                        color: gradient.first,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
