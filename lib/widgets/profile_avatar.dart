import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Circular avatar for the dashboard top corner — shows the signed-in user's
/// profile photo (`profiles.avatar_url`), falling back to their initial.
/// Tapping it opens the profile page.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.radius = 20,
    this.accent,
    this.onTap,
  });

  final double radius;

  /// Ring/initial color; defaults to the app's primary green.
  final Color? accent;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.primaryGreen;
    final user = AuthService.instance.user;
    final photoUrl = user?.photoUrl;

    final Widget avatar;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: color.withOpacity(0.1),
        backgroundImage: NetworkImage(photoUrl),
        onBackgroundImageError: (_, __) {},
      );
    } else {
      final name = user?.name.trim() ?? '';
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: color.withOpacity(0.1),
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: radius * 0.85,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      );
    }

    if (onTap == null) return avatar;
    return GestureDetector(onTap: onTap, child: avatar);
  }
}
