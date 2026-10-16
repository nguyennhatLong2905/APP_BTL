import 'package:flutter/material.dart';

/// TODO (Long): Implement Home/Dashboard Screen
/// - Header: Avatar, tên user, notification icon
/// - Balance Card: Hiển thị tổng số dư
/// - Quick Actions: 4 nút (Thu/Chi/Chuyển/Mục tiêu)
/// - Transaction List: List 5 giao dịch gần nhất
/// - Chart: Biểu đồ chi tiêu tuần
/// - Bottom Navigation Bar: 5 tabs
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tổng Quan')),
      body: const Center(
        child: Text('Dashboard - TODO (Long)'),
      ),
    );
  }
}
