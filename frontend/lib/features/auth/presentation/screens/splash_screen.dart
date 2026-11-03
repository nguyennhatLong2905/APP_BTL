import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/core/constants/app_constants.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/presentation/widgets/logo_widget.dart';
import 'package:go_router/go_router.dart';

/// Màn hình Splash — kiểm tra token → điều hướng login hoặc home
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    // Kiểm tra auth status rồi điều hướng sau khi frame đầu tiên render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAndNavigate();
    });
  }

  Future<void> _initAndNavigate() async {
    debugPrint('Splash: Bắt đầu _initAndNavigate');
    try {
      // Chờ animation + kiểm tra token song song
      await Future.wait([
        Future.delayed(const Duration(seconds: 2)),
        ref.read(authProvider.notifier).checkAuthStatus(),
      ]);
      debugPrint('Splash: Future.wait hoàn thành');
    } catch (e) {
      debugPrint('Splash: Lỗi Future.wait: $e');
    }

    if (!mounted) {
      debugPrint('Splash: Widget unmounted, bỏ qua điều hướng');
      return;
    }

    final isAuthenticated = ref.read(authProvider).isAuthenticated;
    debugPrint('Splash: Điều hướng. isAuthenticated: $isAuthenticated');
    
    if (isAuthenticated) {
      debugPrint('Splash: context.go -> homeRoute');
      context.go(AppConstants.homeRoute);
    } else {
      debugPrint('Splash: context.go -> loginRoute');
      context.go(AppConstants.loginRoute);
    }
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A5C58),
              Color(0xFF2C7873),
              Color(0xFF3D9E98),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
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

            Center(
              child: LogoWidget(animation: _fadeAnimation),
            ),

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
