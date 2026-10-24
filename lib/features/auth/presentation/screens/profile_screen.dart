import 'package:flutter/material.dart';

/// TODO: Implement Profile Screen
/// - Display user info (name, email, avatar)
/// - Edit profile
/// - Logout button
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ Sơ')),
      body: const Center(
        child: Text('Profile Screen - TODO'),
      ),
    );
  }
}
