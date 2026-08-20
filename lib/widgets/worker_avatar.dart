import 'package:flutter/material.dart';

/// Circular avatar for a worker — shows their profile photo
/// (`profiles.avatar_url`) when one is set, otherwise falls back to the
/// first letter of their name. Used across the Head's workers list,
/// worker details, dashboard live locations, and live map.
class WorkerAvatar extends StatelessWidget {
  const WorkerAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.radius = 20,
    this.accent = const Color(0xFF1565C0),
  });

  final String name;
  final String? photoUrl;
  final double radius;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final photo = photoUrl;
    if (photo != null && photo.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: accent.withOpacity(0.1),
        backgroundImage: NetworkImage(photo),
        onBackgroundImageError: (_, __) {},
      );
    }
    final trimmed = name.trim();
    return CircleAvatar(
      radius: radius,
      backgroundColor: accent.withOpacity(0.1),
      child: Text(
        trimmed.isEmpty ? '?' : trimmed[0].toUpperCase(),
        style: TextStyle(
          color: accent,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.85,
        ),
      ),
    );
  }
}
