import 'package:flutter/material.dart';

class TransactionScreen extends StatelessWidget {
  const TransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Thu Chi'),
      ),
      body: const Center(
        child: Text('Màn hình Danh sách Thu Chi / Hóa đơn'),
      ),
    );
  }
}
