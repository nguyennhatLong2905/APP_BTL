import 'package:flutter/material.dart';
import 'package:flutter_riverpod_clean_architecture/core/constants/app_constants.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/presentation/widgets/logo_widget.dart';
import 'package:go_router/go_router.dart';

/// Màn hình Splash — màn hình đầu tiên khi mở app
/// Hiển thị logo + animation fade-in, tự động chuyển sang Dashboard sau 2 giây
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // ── Animation Controller: 400ms fade-in ────────────────────────
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    // Bắt đầu animation ngay khi màn hình render
    _controller.forward();

    // ── Auto navigate sau 2 giây ────────────────────────────────────
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // TODO: Tạm thời đi thẳng vào home để test UI
        // Sau này bật lại: context.go(AppConstants.loginRoute);
        context.go(AppConstants.homeRoute);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        // ── Background: Teal gradient khớp màu Figma ────────────────
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A5C58), // Teal đậm trên
              Color(0xFF2C7873), // Teal chính giữa
              Color(0xFF3D9E98), // Teal sáng dưới
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // ── Vòng tròn trang trí (decorative circles) ────────────
            Positioned(
              top: -80,
              right: -80,
              child: _DecorativeCircle(
                size: 280,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            Positioned(
              bottom: -120,
              left: -60,
              child: _DecorativeCircle(
                size: 340,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            Positioned(
              top: size.height * 0.15,
              left: -40,
              child: _DecorativeCircle(
                size: 160,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),

            // ── Logo ở giữa màn hình ─────────────────────────────────
            Center(
              child: LogoWidget(animation: _fadeAnimation),
            ),

            // ── Loading indicator ở dưới cùng ───────────────────────
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Đang khởi động...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget vòng tròn trang trí nền
class _DecorativeCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _DecorativeCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
