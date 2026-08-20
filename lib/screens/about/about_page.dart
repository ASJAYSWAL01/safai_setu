import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_branding.dart';
import '../../widgets/app_card.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      appBar: AppBar(        title: Text(
          'About Safai Setu',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppBranding(compact: true),
              const SizedBox(height: 20),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Our Mission 🌱',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Safai Setu connects citizens, pickup-truck workers and the municipal department to keep cities clean. '
                      'Report waste in seconds, get it collected by a tracked worker, and see photo proof when the job is done.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How It Works',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),                    _HowStep(
                      icon: Icons.person_outline,
                      color: AppColors.primaryGreen,
                      title: 'Citizens report',
                      body: 'Upload a photo and location of the waste problem. Your complaint gets a unique ID.',
                    ),
                    _HowStep(
                      icon: Icons.admin_panel_settings_outlined,
                      color: const Color(0xFF6A1B9A),
                      title: 'The Head assigns',
                      body:
                          'The department Head creates a collection task from your complaint and assigns it to a pickup-truck worker.',
                    ),
                    _HowStep(
                      icon: Icons.local_shipping_outlined,
                      color: const Color(0xFF1565C0),
                      title: 'The worker collects',
                      body:
                          'The worker navigates to the spot on the live map, collects the waste and uploads a proof photo.',
                    ),
                    _HowStep(
                      icon: Icons.verified_outlined,
                      color: AppColors.lightGreen,
                      title: 'Proof goes to citizen & Head',
                      body:
                          'The Head verifies the photo and the citizen sees the completed work on their complaint.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Key Features',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const _FeatureRow(
                        icon: Icons.camera_alt_outlined,
                        label: 'Photo-based waste reporting with GPS'),
                    const _FeatureRow(
                        icon: Icons.map_outlined,
                        label: 'Live Google Map for workers and the Head'),
                    const _FeatureRow(
                        icon: Icons.badge_outlined,
                        label: 'Worker IDs generated only by the Head'),
                    const _FeatureRow(
                        icon: Icons.photo_library_outlined,
                        label: 'Proof-of-work photos reviewed by the Head'),
                    const _FeatureRow(
                        icon: Icons.location_searching,
                        label: 'Live GPS sharing from worker to Head'),
                    const _FeatureRow(
                        icon: Icons.dark_mode_outlined,
                        label: 'Dark & light theme for every user'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contact',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const _FeatureRow(
                        icon: Icons.email_outlined,
                        label: 'tech.safaisetu@gmail.com'),
                    const _FeatureRow(
                        icon: Icons.phone_outlined,
                        label: '+91-7283881430'),
                    const _FeatureRow(
                        icon: Icons.phone_outlined,
                        label: '+91-6355413255'),
                    const _FeatureRow(
                        icon: Icons.location_on_outlined,
                        label: 'LDRP Institute of Technology and Research, Sector 15, Gandhinagar, Gujarat 382016'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Safai Setu v1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary.withOpacity(0.8),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _HowStep extends StatelessWidget {
  const _HowStep({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 12.5,
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

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.primaryGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}
