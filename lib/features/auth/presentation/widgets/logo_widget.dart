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
                color: const Color(0xFF1A6B5A),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A6B5A).withValues(alpha: 0.45),
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

/// CustomPainter vẽ icon mascot Ví An theo đúng thiết kế Figma:
/// - Vòng tròn mờ phía ngoài (aura)
/// - Thân hình vòm/khiên (shield/dome)
/// - Mắt tròn đồng tâm (outer ring + inner dot)
class _MascotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // ── Paints ───────────────────────────────────────────────────────
    final fillWhite = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final fillDark = Paint()
      ..color = const Color(0xFF1A6B5A)
      ..style = PaintingStyle.fill;

    final strokeWhiteThin = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final strokeWhiteMed = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    // ── 1. Outer aura ring (faint, large) ────────────────────────────
    canvas.drawCircle(Offset(cx, cy), size.width * 0.47, strokeWhiteThin);

    // ── 2. Inner aura ring (slightly less faint) ─────────────────────
    canvas.drawCircle(Offset(cx, cy), size.width * 0.38, strokeWhiteMed);

    // ── 3. Body: shield/dome shape ───────────────────────────────────
    // Top half is a semicircle, bottom tapers to a rounded point
    final bodyPath = Path();
    final bLeft  = cx - size.width  * 0.25;
    final bRight = cx + size.width  * 0.25;
    final bTop   = cy - size.height * 0.32;
    final bMid   = cy + size.height * 0.05;
    final bTip   = cy + size.height * 0.30;

    // Top arc (semicircle)
    bodyPath.moveTo(bLeft, bMid);
    bodyPath.quadraticBezierTo(bLeft, bTop, cx, bTop);
    bodyPath.quadraticBezierTo(bRight, bTop, bRight, bMid);
    // Bottom taper to rounded tip
    bodyPath.quadraticBezierTo(bRight, bTip, cx, bTip);
    bodyPath.quadraticBezierTo(bLeft, bTip, bLeft, bMid);
    bodyPath.close();

    canvas.drawPath(bodyPath, fillWhite);

    // ── 4. Eye: concentric circles ───────────────────────────────────
    final eyeCx  = cx;
    final eyeCy  = cy - size.height * 0.06;
    final outerR = size.width * 0.115;
    final innerR = size.width * 0.058;

    // Outer ring (dark fill = "hole" showing background)
    canvas.drawCircle(Offset(eyeCx, eyeCy), outerR, fillDark);
    // Thin white ring outline
    canvas.drawCircle(
      Offset(eyeCx, eyeCy),
      outerR,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    // Inner white filled circle (pupil)
    canvas.drawCircle(Offset(eyeCx, eyeCy), innerR, fillWhite);
    // Dark center dot (center of pupil)
    canvas.drawCircle(
      Offset(eyeCx, eyeCy),
      innerR * 0.45,
      Paint()..color = const Color(0xFF1A6B5A)..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

