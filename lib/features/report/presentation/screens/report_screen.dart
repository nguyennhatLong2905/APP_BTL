import 'package:flutter/material.dart';

/// TODO (Long): Implement Report Screen (Lịch Sử Giao Dịch)
/// - Time Period Selector: Tuần / Tháng / Năm
/// - Summary Cards: Tổng thu, tổng chi, còn lại
/// - Pie Chart: Phân bổ chi tiêu theo category
/// - Bar Chart: So sánh thu chi theo thời gian
/// - Transaction List: Grouped by date
/// - Filter: By category, date range
class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch Sử Giao Dịch')),
      body: const Center(
        child: Text('Report Screen - TODO (Long)'),
      ),
    );
  }
}
