import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ Sơ Cá Nhân')),
      body: const Center(
        child: Text('Profile Screen'),
      ),
    );
  }
}
