import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'pressable_scale.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;
    final foreground = AppColors.isDark ? const Color(0xFF111511) : Colors.white;

    return PressableScale(
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [AppColors.primaryGreen, AppColors.lightGreen],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGreen
                      .withOpacity(disabled ? 0.15 : 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: InkWell(
              onTap: disabled ? null : onPressed,
              borderRadius: BorderRadius.circular(14),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: foreground,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: 20, color: foreground),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                              color: foreground,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OutlinedSocialButton extends StatelessWidget {
  const OutlinedSocialButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.leading,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.cardColor,
            foregroundColor: AppColors.textPrimary,
            side: BorderSide(color: AppColors.borderColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 1,
            shadowColor: Colors.black.withOpacity(0.06),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              leading,
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
