import 'package:flutter/material.dart';

/// TODO: Implement Settings Screen
/// - Language settings
/// - Theme toggle (dark/light)
/// - Notification preferences
/// - About app
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài Đặt')),
      body: const Center(
        child: Text('Settings Screen - TODO'),
      ),
    );
  }
}
