import 'package:flutter/material.dart';

/// TODO (Dũng): Implement Budget Planning Screen (Kế Hoạch Chi Tiêu)
/// - Monthly Budget Input: Set ngân sách tổng tháng
/// - Category Budgets: Set ngân sách cho từng category
///   - Ăn uống, Di chuyển, Giải trí, Mua sắm...
/// - Progress Bars: Hiển thị % đã chi / budget
/// - Alerts: Warning khi gần hết budget (>80%)
/// - History: Xem budget các tháng trước
/// - Quick Templates: Tiết kiệm / Trung bình / Thoải mái
/// - Drag to Adjust: Kéo thanh để adjust %
class BudgetPlanningScreen extends StatelessWidget {
  const BudgetPlanningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kế Hoạch Chi Tiêu')),
      body: const Center(
        child: Text('Budget Planning - TODO (Dũng)'),
      ),
    );
  }
}
