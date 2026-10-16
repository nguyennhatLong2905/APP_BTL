import 'package:flutter/material.dart';

/// TODO (Long): Implement Splash Screen
/// - Hiển thị logo Ví An ở giữa màn hình
/// - Background gradient (xem docs/design/logo.png)
/// - Animation fade-in logo (300ms)
/// - Auto navigate sau 2 giây → Dashboard
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Splash Screen - TODO (Long)'),
      ),
    );
  }
}
