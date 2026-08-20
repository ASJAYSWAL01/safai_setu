import 'package:flutter/material.dart';

import '../models/collection_task.dart';
import '../models/complaint.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final ComplaintStatus status;
  final bool compact;

  Color get _backgroundColor {
    switch (status) {
      case ComplaintStatus.pending:
        return AppColors.isDark
            ? const Color(0xFFE65100).withOpacity(0.18)
            : const Color(0xFFFFF3E0);
      case ComplaintStatus.assigned:
        return AppColors.isDark
            ? const Color(0xFF1565C0).withOpacity(0.22)
            : const Color(0xFFE3F2FD);
      case ComplaintStatus.inProgress:
        return AppColors.isDark
            ? const Color(0xFF3949AB).withOpacity(0.22)
            : const Color(0xFFE8EAF6);
      case ComplaintStatus.resolved:
        return AppColors.paleGreen;
      case ComplaintStatus.rejected:
        return AppColors.isDark
            ? const Color(0xFFC62828).withOpacity(0.2)
            : const Color(0xFFFFEBEE);
    }
  }

  Color get _textColor {
    switch (status) {
      case ComplaintStatus.pending:
        return AppColors.isDark
            ? const Color(0xFFFFB74D)
            : const Color(0xFFE65100);
      case ComplaintStatus.assigned:
        return AppColors.isDark
            ? const Color(0xFF64B5F6)
            : const Color(0xFF1565C0);
      case ComplaintStatus.inProgress:
        return AppColors.isDark
            ? const Color(0xFF9FA8DA)
            : const Color(0xFF3949AB);
      case ComplaintStatus.resolved:
        return AppColors.darkGreen;
      case ComplaintStatus.rejected:
        return AppColors.isDark
            ? const Color(0xFFE57373)
            : const Color(0xFFC62828);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: _textColor,
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class TaskStatusBadge extends StatelessWidget {
  const TaskStatusBadge({super.key, required this.status});

  final CollectionTaskStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      CollectionTaskStatus.assigned => AppColors.isDark
          ? (const Color(0xFFE65100).withOpacity(0.18),
              const Color(0xFFFFB74D))
          : (const Color(0xFFFFF3E0), const Color(0xFFE65100)),
      CollectionTaskStatus.enRoute => AppColors.isDark
          ? (const Color(0xFF1565C0).withOpacity(0.22),
              const Color(0xFF64B5F6))
          : (const Color(0xFFE3F2FD), const Color(0xFF1565C0)),
      CollectionTaskStatus.collecting => AppColors.isDark
          ? (const Color(0xFF3949AB).withOpacity(0.22),
              const Color(0xFF9FA8DA))
          : (const Color(0xFFE8EAF6), const Color(0xFF3949AB)),
      CollectionTaskStatus.completed => (
          AppColors.paleGreen,
          AppColors.darkGreen
        ),
      CollectionTaskStatus.rejected => AppColors.isDark
          ? (const Color(0xFFC62828).withOpacity(0.2),
              const Color(0xFFE57373))
          : (const Color(0xFFFFEBEE), const Color(0xFFC62828)),
      CollectionTaskStatus.revoked => AppColors.isDark
          ? (const Color(0xFF546E7A).withOpacity(0.22),
              const Color(0xFF90A4AE))
          : (const Color(0xFFECEFF1), const Color(0xFF546E7A)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class RiskBadge extends StatelessWidget {
  const RiskBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
