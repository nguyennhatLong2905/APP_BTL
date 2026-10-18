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
/// - Vòng tròn mờ phía ngoài (aura/glow)
/// - Thân hình vòm/nón (như con bọ/mascot)
/// - 1 mắt tròn ở giữa (có viền + chấm đen)
class _MascotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // ── Paint objects ────────────────────────────────────────────────
    final strokeWhite = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final fillWhite = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final fillDark = Paint()
      ..color = const Color(0xFF1A6B5A)
      ..style = PaintingStyle.fill;

    // ── 1. Vòng tròn mờ phía ngoài (aura) ───────────────────────────
    final auraPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(Offset(cx, cy), size.width * 0.46, auraPaint);

    // ── 2. Thân hình vòm (arch/dome body) ───────────────────────────
    // Phần trên: cung vòm từ trái sang phải
    final bodyPath = Path();
    final bodyLeft  = cx - size.width * 0.28;
    final bodyRight = cx + size.width * 0.28;
    final bodyTop   = cy - size.height * 0.30;
    final bodyBottom = cy + size.height * 0.22;

    bodyPath.moveTo(bodyLeft, bodyBottom);
    // Cung vòm phía trên
    bodyPath.quadraticBezierTo(bodyLeft,  bodyTop, cx, bodyTop);
    bodyPath.quadraticBezierTo(bodyRight, bodyTop, bodyRight, bodyBottom);
    // Đáy cong nhẹ
    bodyPath.quadraticBezierTo(cx, bodyBottom + size.height * 0.08, bodyLeft, bodyBottom);
    bodyPath.close();

    canvas.drawPath(bodyPath, fillWhite);

    // ── 3. Mắt tròn 1 ở giữa (vị trí hơi trên trung tâm thân) ──────
    final eyeCx = cx;
    final eyeCy = cy - size.height * 0.04;
    final eyeOuterR = size.width * 0.115;
    final eyeInnerR = size.width * 0.055;

    // Viền ngoài mắt (teal, cùng màu nền)
    canvas.drawCircle(Offset(eyeCx, eyeCy), eyeOuterR, fillDark);
    // Mống mắt trắng
    canvas.drawCircle(Offset(eyeCx, eyeCy), eyeOuterR, strokeWhite);
    // Chấm đồng tử đen nhỏ ở giữa
    canvas.drawCircle(Offset(eyeCx, eyeCy), eyeInnerR,
        Paint()..color = Colors.white..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(eyeCx, eyeCy), eyeInnerR * 0.5,
        Paint()..color = const Color(0xFF1A6B5A)..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
