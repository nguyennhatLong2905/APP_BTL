import 'package:flutter/material.dart';

/// Widget hiển thị logo Ví An — dùng trên Splash Screen
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
            // ── Logo icon ────────────────────────────────────────────
            const ViAnLogoIcon(size: 108),

            const SizedBox(height: 20),

            // ── Tên App ──────────────────────────────────────────────
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

            // ── Tagline ──────────────────────────────────────────────
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

/// Icon logo Ví An độc lập — dùng được ở bất kỳ đâu
class ViAnLogoIcon extends StatelessWidget {
  final double size;

  const ViAnLogoIcon({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF146352),
        borderRadius: BorderRadius.circular(size * 0.24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF146352).withValues(alpha: 0.5),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none, // Cho phép smile vẽ ngoài painter bounds
        children: [
          // ── Vòng tròn mờ ngoài ──────────────────────────────────
          Container(
            width: size * 0.64,
            height: size * 0.64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: size * 0.022,
              ),
            ),
          ),

          // ── Icon mascot ──────────────────────────────────────────
          // Painter cao hơn để chứa smile bên dưới arch
          CustomPaint(
            size: Size(size * 0.38, size * 0.46),
            painter: _LogoIconPainter(),
          ),
        ],
      ),
    );
  }
}

/// Vẽ mascot Ví An:
/// 1. Arch vòm đối xứng (∩)
/// 2. Vòng tròn nhỏ ở tâm arch
/// 3. Đường cong đáy (smile)
class _LogoIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = w * 0.155
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // ── 1. Arch/vòm đối xứng ─────────────────────────────────────
    // Control point ở X = w/2 để arch đối xứng trái-phải
    final archPath = Path()
      ..moveTo(0, h * 0.78)
      ..quadraticBezierTo(w * 0.5, -h * 0.18, w, h * 0.78);
    canvas.drawPath(archPath, paint);

    // ── 2. Vòng tròn nhỏ ở trung tâm arch ───────────────────────
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.42),
      w * 0.105,
      paint,
    );

    // ── 3. Đường cong đáy (smile/base) ───────────────────────────
    // Nằm dưới arch, cong nhẹ xuống rồi lên
    final smilePath = Path()
      ..moveTo(w * 0.14, h * 0.96)
      ..quadraticBezierTo(w * 0.5, h * 1.22, w * 0.86, h * 0.96);
    canvas.drawPath(smilePath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
