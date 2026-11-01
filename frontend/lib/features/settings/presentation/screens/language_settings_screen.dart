import 'package:flutter/material.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài Đặt Ngôn Ngữ')),
      body: const Center(
        child: Text('Language Settings Screen'),
      ),
    );
  }
}
