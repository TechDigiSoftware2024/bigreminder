import 'package:flutter/material.dart';
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

   CustomButton({
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
      border = BorderSide(color: primary, width: 0.8);
    }

    final bg = backgroundColor ??
        (variant == ButtonVariant.filled ? primary : Colors.transparent);

    final txtColor = textColor ??
        (variant == ButtonVariant.filled ? Colors.white : primary);

    return Material(
      color: disabled ? theme.disabledColor.withOpacity(0.2) : bg,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: border != null ? Border.fromBorderSide(border) : null,
          ),
          child: isLoading
              ? CircularProgressIndicator(
            strokeWidth: 2,
            color: txtColor,
          )
              : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: txtColor),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: txtColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}