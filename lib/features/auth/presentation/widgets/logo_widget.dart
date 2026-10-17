import 'dart:math';
import 'package:flutter/material.dart';

/// Widget hiển thị logo Ví An — icon teal bo góc + tên app
/// Nhận [animation] từ ngoài để điều khiển fade-in + scale
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
            // ── Logo icon: Teal rounded square + mascot ────────────────
            Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                color: const Color(0xFF2C7873),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2C7873).withValues(alpha: 0.45),
                    blurRadius: 32,
                    spreadRadius: 0,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Center(
                child: CustomPaint(
                  size: const Size(64, 64),
                  painter: _MascotPainter(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Tên App ────────────────────────────────────────────────
            const Text(
              'Ví An',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 6),

            // ── Tagline ────────────────────────────────────────────────
            Text(
              'Quản lý tài chính thông minh',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.75),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter vẽ icon mascot Ví An:
/// - Vòng tròn viền trắng bên ngoài
/// - Hai mắt tròn (filled white)
/// - Cung miệng/cằm phía dưới
class _MascotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // ── 1. Vòng tròn viền ngoài ─────────────────────────────────────
    final outerRadius = size.width * 0.44;
    canvas.drawCircle(Offset(cx, cy), outerRadius, strokePaint);

    // ── 2. Mắt trái ─────────────────────────────────────────────────
    final eyeRadius = size.width * 0.07;
    final eyeY = cy - size.height * 0.10;
    canvas.drawCircle(Offset(cx - size.width * 0.16, eyeY), eyeRadius, fillPaint);

    // ── 3. Mắt phải ─────────────────────────────────────────────────
    canvas.drawCircle(Offset(cx + size.width * 0.16, eyeY), eyeRadius, fillPaint);

    // ── 4. Cung miệng / cằm (nụ cười nhẹ) ──────────────────────────
    final mouthRect = Rect.fromCenter(
      center: Offset(cx, cy + size.height * 0.08),
      width: size.width * 0.38,
      height: size.height * 0.22,
    );
    canvas.drawArc(mouthRect, pi * 0.15, pi * 0.70, false, strokePaint);

    // ── 5. Tai/antenna trái (vòng nhỏ phía trên bên trái) ──────────
    canvas.drawCircle(
      Offset(cx - size.width * 0.30, cy - size.height * 0.28),
      size.width * 0.07,
      strokePaint,
    );

    // ── 6. Tai/antenna phải (vòng nhỏ phía trên bên phải) ──────────
    canvas.drawCircle(
      Offset(cx + size.width * 0.30, cy - size.height * 0.28),
      size.width * 0.07,
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
