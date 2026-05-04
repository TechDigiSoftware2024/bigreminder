import 'package:flutter/material.dart';

class CustomDialog {
  /// ================= SNACKBAR =================

  static void showSuccessSnack(BuildContext context, String message) {
    _showSnack(
      context,
      message,
      Colors.green,
      Icons.check_circle,
    );
  }

  static void showErrorSnack(BuildContext context, String message) {
    _showSnack(
      context,
      message,
      Colors.red,
      Icons.error,
    );
  }

  static void showInfoSnack(BuildContext context, String message) {
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
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  /// ================= CONFIRM DIALOG =================

  static Future<void> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    final primary = Theme.of(context).colorScheme.primary;

    return showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  backgroundColor: primary.withOpacity(0.1),
                  child: Icon(Icons.help, color: primary),
                ),
                const SizedBox(height: 16),
                Text(title, style: const TextStyle(fontSize: 18,fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onConfirm();
                        },
                        child: const Text("Confirm"),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  /// ================= BOTTOM SHEET =================

  static Future<void> showBottomMessage({
    required BuildContext context,
    required String title,
    required String message,
    required Color color,
    IconData icon = Icons.info,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(message),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

}