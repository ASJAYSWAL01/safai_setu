import 'package:flutter/material.dart';

import '../models/complaint.dart';
import '../theme/app_theme.dart';
import 'pressable_scale.dart';
import 'status_badge.dart';

class ComplaintCard extends StatelessWidget {
  const ComplaintCard({
    super.key,
    required this.complaint,
    required this.onTap,
  });

  final Complaint complaint;
  final VoidCallback onTap;

  /// Status accent color used for the accent bar, icon tints and glow.
  Color get _accent {
    final isDark = AppColors.isDark;
    switch (complaint.status) {
      case ComplaintStatus.pending:
        return isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100);
      case ComplaintStatus.assigned:
        return isDark ? const Color(0xFF64B5F6) : const Color(0xFF1565C0);
      case ComplaintStatus.inProgress:
        return isDark ? const Color(0xFF9FA8DA) : const Color(0xFF3949AB);
      case ComplaintStatus.resolved:
        return AppColors.darkGreen;
      case ComplaintStatus.rejected:
        return isDark ? const Color(0xFFE57373) : const Color(0xFFC62828);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    final dateText = _formatDate(complaint.dateReported);

    return PressableScale(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.borderColor.withOpacity(0.6),
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(AppColors.isDark ? 0.12 : 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status accent bar on the left edge.
                  Container(
                    width: 4,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [accent, accent.withOpacity(0.30)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                complaint.category,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusBadge(
                              status: complaint.status,
                              compact: true,
                            ),
                          ],
                        ),
                        if (complaint.description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            complaint.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          text: complaint.location,
                          accent: accent,
                        ),
                        const SizedBox(height: 6),
                        _InfoRow(
                          icon: Icons.tag_outlined,
                          text: 'Complaint ID: ${complaint.displayId}',
                        ),
                        const SizedBox(height: 6),
                        _InfoRow(
                          icon: Icons.calendar_today_outlined,
                          text: dateText,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, this.accent});

  final IconData icon;
  final String text;

  /// Optional accent color for the icon (used for the location row).
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final iconColor = accent ?? AppColors.textSecondary;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.10),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: iconColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
