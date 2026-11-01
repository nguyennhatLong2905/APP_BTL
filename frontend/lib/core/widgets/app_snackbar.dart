import 'package:flutter/material.dart';

/// Helper hiển thị Custom SnackBar thông báo lỗi / thành công
class AppSnackBar {
  static void showSuccess(BuildContext context, String message) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.green.shade700,
      icon: Icons.check_circle_outline,
    );
  }

  static void showError(BuildContext context, String message) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: Theme.of(context).colorScheme.error,
      icon: Icons.error_outline,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.orange.shade800,
      icon: Icons.warning_amber_outlined,
    );
  }

  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
