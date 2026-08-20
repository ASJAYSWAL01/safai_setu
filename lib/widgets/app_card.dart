import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'pressable_scale.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsets padding;

  /// Space around the card (e.g. a bottom gap between stacked cards, so
  /// their drop shadows don't blend into each other).
  final EdgeInsets margin;
  final VoidCallback? onTap;

  /// Optional accent tint used for the card's soft shadow and gradient.
  /// Defaults to the brand green.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.primaryGreen;

    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.isDark
              ? const [Color(0xFF202A23), Color(0xFF1A221D)]
              : const [Colors.white, Color(0xFFF8FCF9)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.55)),
        boxShadow: [
          BoxShadow(
            color: AppColors.isDark
                ? Colors.black.withOpacity(0.35)
                : accent.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );

    Widget content = card;
    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: card,
        ),
      );
      content = PressableScale(child: content);
    }

    if (margin == EdgeInsets.zero) return content;
    return Padding(padding: margin, child: content);
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (actionLabel != null && onActionTap != null)
          TextButton(
            onPressed: onActionTap,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}
