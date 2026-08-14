import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppBranding extends StatelessWidget {
  const AppBranding({
    super.key,
    this.showTagline = true,
    this.compact = false,
  });

  static const String mascotAsset = 'assets/images/safai_setu_mascot.png';

  final bool showTagline;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final logoHeight = compact ? 110.0 : 140.0;

    return Column(
      children: [
        Container(
          height: logoHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Image.asset(
            mascotAsset,
            height: logoHeight,
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(height: compact ? 12 : 16),
        Text(
          'Safai Setu',
          style: TextStyle(
            fontSize: compact ? 24 : 28,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGreen,
            letterSpacing: 0.5,
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 6),
          Text(
            'Smart Waste Management for Cleaner Cities',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 13 : 14,
              color: AppColors.textSecondary.withOpacity(0.9),
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}
