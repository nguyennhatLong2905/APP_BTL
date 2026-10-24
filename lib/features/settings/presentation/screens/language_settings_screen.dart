import 'package:flutter/material.dart';

/// TODO: Implement Language Settings Screen
/// - List of supported languages
/// - Current language indicator
/// - Tap to switch language
class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ngôn Ngữ')),
      body: const Center(
        child: Text('Language Settings Screen - TODO'),
      ),
    );
  }
}
