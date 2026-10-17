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
        scale: Tween<double>(begin: 0.85, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Logo icon (Tròn với border trắng) ──────────────────────
            Container(
              width: 100,
              height: 100,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 24,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF00A86B),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Tên App ────────────────────────────────────────────────
            const Text(
              'Ví An',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 6),

            // ── Tagline ────────────────────────────────────────────────
            Text(
              'Quản lý tài chính thông minh',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.8),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
