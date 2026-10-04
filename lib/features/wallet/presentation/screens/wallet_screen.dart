import 'package:flutter/material.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Ví & Tài khoản'),
      ),
      body: const Center(
        child: Text('Màn hình Ví cá nhân & Số dư'),
      ),
    );
  }
}
