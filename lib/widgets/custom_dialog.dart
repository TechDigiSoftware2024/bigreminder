import 'package:flutter/material.dart';

class CustomDialog {
  /// Compact confirm / alert dialogs (delete, logout, continue…).
  static const double confirmWidth = 360;

  /// Small form dialogs (create feature, reply…).
  static const double formWidth = 400;

  /// Larger form dialogs (plans, subscriptions…).
  static const double formWideWidth = 440;

  static const double _snackDesktopWidth = 420;

  // ============================================================
  // RESPONSIVE WIDTH
  // ============================================================

  static double dialogWidth(
    BuildContext context, {
    double desktop = confirmWidth,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 900) return desktop;
    return (width - 48).clamp(280.0, desktop);
  }

  static bool _isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 900;
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  static void showSuccessSnack(
    BuildContext context,
    String message,
  ) {
    _showSnack(
      context,
      message,
      Colors.green,
      Icons.check_circle,
    );
  }

  static void showErrorSnack(
    BuildContext context,
    String message,
  ) {
    _showSnack(
      context,
      message,
      Colors.red,
      Icons.error,
    );
  }

  static void showInfoSnack(
    BuildContext context,
    String message,
  ) {
    _showSnack(
      context,
      message,
      Theme.of(context).colorScheme.primary,
      Icons.info,
    );
  }

  static void _showSnack(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final snackWidth = _isDesktop(context)
        ? _snackDesktopWidth
        : (screenWidth * 0.72).clamp(220.0, 320.0);

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          width: snackWidth,
          content: Container(
            width: snackWidth,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  // ============================================================
  // CONFIRM DIALOG
  // ============================================================

  /// Compact confirm dialog. Returns `true` if confirmed.
  static Future<bool> showConfirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
    IconData? icon,
  }) async {
    final primary = Theme.of(context).colorScheme.primary;
    final accent = isDestructive ? Colors.red : primary;
    final width = dialogWidth(context, desktop: confirmWidth);
    final resolvedIcon = icon ??
        (isDestructive ? Icons.delete_outline_rounded : Icons.help_outline_rounded);

    final result = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: SizedBox(
            width: width,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(resolvedIcon, color: accent, size: 26),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(
                              dialogContext,
                              rootNavigator: true,
                            ).pop(false);
                          },
                          child: Text(cancelLabel),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(
                              dialogContext,
                              rootNavigator: true,
                            ).pop(true);
                          },
                          child: Text(
                            confirmLabel,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return result == true;
  }

  /// Legacy API — uses the same compact confirm dialog.
  static Future<void> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
    IconData? icon,
  }) async {
    final ok = await showConfirm(
      context: context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      isDestructive: isDestructive,
      icon: icon,
    );
    if (ok) onConfirm();
  }

  // ============================================================
  // BOTTOM SHEET
  // ============================================================

  static Future<void> showBottomMessage({
    required BuildContext context,
    required String title,
    required String message,
    required Color color,
    IconData icon = Icons.info,
  }) {
    final isDesktop = _isDesktop(context);

    return showModalBottomSheet(
      context: context,
      constraints: isDesktop
          ? const BoxConstraints(maxWidth: confirmWidth)
          : null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(
                  icon,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(message),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
