import 'package:flutter/material.dart';

/// Helper hiển thị Loading Dialog dùng chung khi đang gọi API
class LoadingDialog {
  static bool _isShowing = false;

  /// Hiển thị Loading Dialog
  static void show(BuildContext context, {String message = 'Đang xử lý...'}) {
    if (_isShowing) return;
    _isShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Tắt Loading Dialog
  static void hide(BuildContext context) {
    if (!_isShowing) return;
    _isShowing = false;
    Navigator.of(context, rootNavigator: true).pop();
  }
}
