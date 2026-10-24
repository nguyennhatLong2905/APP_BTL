import 'package:flutter/material.dart';

/// TODO: Implement Login Screen
/// - Email/Phone + Password input
/// - Login button
/// - Navigate to Register
/// - Forgot password link
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng Nhập')),
      body: const Center(
        child: Text('Login Screen - TODO'),
      ),
    );
  }
}
