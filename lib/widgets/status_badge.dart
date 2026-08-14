import 'package:flutter/material.dart';

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
        return const Color(0xFFFFF3E0);
      case ComplaintStatus.assigned:
        return const Color(0xFFE3F2FD);
      case ComplaintStatus.inProgress:
        return const Color(0xFFE8EAF6);
      case ComplaintStatus.resolved:
        return AppColors.paleGreen;
    }
  }

  Color get _textColor {
    switch (status) {
      case ComplaintStatus.pending:
        return const Color(0xFFE65100);
      case ComplaintStatus.assigned:
        return const Color(0xFF1565C0);
      case ComplaintStatus.inProgress:
        return const Color(0xFF3949AB);
      case ComplaintStatus.resolved:
        return AppColors.darkGreen;
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
