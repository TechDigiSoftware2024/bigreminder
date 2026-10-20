import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../utils/enum_classes.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final ButtonVariant variant;

  final Color? backgroundColor;
  final Color? textColor;

  const CustomButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.variant = ButtonVariant.filled,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final disabled = isDisabled || onTap == null;

    BorderSide? border;
    if (variant == ButtonVariant.outline) {
      border = BorderSide(color: primary.withValues(alpha: 0.55));
    }

    final bg = backgroundColor ??
        (variant == ButtonVariant.filled ? primary : Colors.transparent);

    final txtColor = textColor ??
        (variant == ButtonVariant.filled ? AppColors.textOnPrimary : primary);

    return Material(
      borderRadius: AppRadius.button,
      color: disabled ? AppColors.buttonDisabledBg : bg,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: AppRadius.button,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: AppRadius.button,
            border: border != null ? Border.fromBorderSide(border) : null,
          ),
          child: isLoading
              ? SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: disabled ? AppColors.buttonDisabledText : txtColor,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 16,
                        color: disabled ? AppColors.buttonDisabledText : txtColor,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: disabled ? AppColors.buttonDisabledText : txtColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
