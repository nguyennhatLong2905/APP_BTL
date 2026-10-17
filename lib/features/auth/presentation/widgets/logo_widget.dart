import 'package:flutter/material.dart';

/// Widget hiển thị logo Ví An (icon + tên app)
/// Nhận [animation] từ ngoài để điều khiển fade-in
class LogoWidget extends StatelessWidget {
  final Animation<double> animation;

  const LogoWidget({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Logo icon ──────────────────────────────────────────────
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00A86B).withValues(alpha: 0.35),
                    blurRadius: 32,
                    spreadRadius: 4,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Tên App ────────────────────────────────────────────────
            const Text(
              'Ví An',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 8),

            // ── Tagline ────────────────────────────────────────────────
            Text(
              'Quản lý tài chính thông minh',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.75),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
