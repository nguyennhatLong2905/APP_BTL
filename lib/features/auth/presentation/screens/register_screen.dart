import 'package:flutter/material.dart';

/// TODO: Implement Register Screen
/// - Name, Email, Password, Confirm Password inputs
/// - Register button
/// - Navigate to Login
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng Ký')),
      body: const Center(
        child: Text('Register Screen - TODO'),
      ),
    );
  }
}
