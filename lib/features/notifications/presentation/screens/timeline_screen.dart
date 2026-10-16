import 'package:flutter/material.dart';

/// TODO (Dũng): Implement Timeline Screen (Nhìn Lại Nhật Ký)
/// - Timeline View: Hiển thị giao dịch theo dòng thời gian
/// - Date Headers: Sticky headers cho mỗi ngày
/// - Transaction Cards: Icon, tên, số tiền, thời gian, ảnh HĐ
/// - Calendar View Toggle: Switch list view ↔ calendar view
/// - Search & Filter: By name, category, date range
/// - Statistics Card: Tóm tắt chi tiêu trong khoảng thời gian
/// - Infinite Scroll + Pull-to-refresh
class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nhìn Lại Nhật Ký')),
      body: const Center(
        child: Text('Timeline - TODO (Dũng)'),
      ),
    );
  }
}
