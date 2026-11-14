import 'package:flutter/material.dart';

/// Bong bóng xác nhận kiểu "Dynamic Island": viên thuốc nhỏ, bo tròn lớn,
/// nền tối, bật ra từ phía trên màn hình với hiệu ứng nảy nhẹ.
Future<bool> showIslandConfirm(
  BuildContext context, {
  required String title,
  String message = '',
  String cancelLabel = 'Hủy',
  String confirmLabel = 'Đồng ý',
  IconData icon = Icons.help_outline_rounded,
  Color accent = const Color(0xFFE5484D),
}) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: Colors.black.withValues(alpha: 0.25),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (dialogContext, _, _) => IslandBubble(
      title: title,
      message: message,
      cancelLabel: cancelLabel,
      confirmLabel: confirmLabel,
      icon: icon,
      accent: accent,
    ),
    transitionBuilder: (context, animation, _, child) {
      final pop = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: fade,
        child: SafeArea(
          child: Align(
            alignment: const Alignment(0, -0.8),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1).animate(pop),
              alignment: Alignment.topCenter,
              child: child,
            ),
          ),
        ),
      );
    },
  );
  return result ?? false;
}

/// Nội dung bong bóng. Tự đóng dialog và trả kết quả qua Navigator.pop.
class IslandBubble extends StatelessWidget {
  final String title;
  final String message;
  final String cancelLabel;
  final String confirmLabel;
  final IconData icon;
  final Color accent;

  const IslandBubble({
    super.key,
    required this.title,
    this.message = '',
    this.cancelLabel = 'Hủy',
    this.confirmLabel = 'Đồng ý',
    this.icon = Icons.help_outline_rounded,
    this.accent = const Color(0xFFE5484D),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 26,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      if (message.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _IslandPill(
                    label: cancelLabel,
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _IslandPill(
                    label: confirmLabel,
                    filled: true,
                    accent: accent,
                    onTap: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IslandPill extends StatelessWidget {
  final String label;
  final bool filled;
  final Color accent;
  final VoidCallback onTap;

  const _IslandPill({
    required this.label,
    required this.onTap,
    this.filled = false,
    this.accent = const Color(0xFFE5484D),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? accent : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: filled ? Colors.white : Colors.white70,
            fontSize: 12.5,
            fontWeight: filled ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
