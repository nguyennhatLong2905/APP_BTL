import 'package:flutter/material.dart';
import '../../domain/models/budget.dart';

class BudgetAlertCard extends StatelessWidget {
  final Budget budget;

  const BudgetAlertCard({
    super.key,
    required this.budget,
  });

  @override
  Widget build(BuildContext context) {
    final overBudgetCategories =
        budget.categories.where((c) => c.isOverBudget).toList();
    final nearLimitCategories =
        budget.categories.where((c) => c.isNearLimit).toList();

    if (!budget.isOverAllocated &&
        overBudgetCategories.isEmpty &&
        nearLimitCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: budget.isOverAllocated || overBudgetCategories.isNotEmpty
            ? Colors.red.shade50
            : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: budget.isOverAllocated || overBudgetCategories.isNotEmpty
              ? Colors.red.shade300
              : Colors.orange.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                budget.isOverAllocated || overBudgetCategories.isNotEmpty
                    ? Icons.warning_amber_rounded
                    : Icons.info_outline_rounded,
                color: budget.isOverAllocated || overBudgetCategories.isNotEmpty
                    ? Colors.red.shade800
                    : Colors.orange.shade800,
              ),
              const SizedBox(width: 8),
              Text(
                'Cảnh Báo Ngân Sách',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: budget.isOverAllocated || overBudgetCategories.isNotEmpty
                      ? Colors.red.shade800
                      : Colors.orange.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (budget.isOverAllocated)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                '• Tổng ngân sách phân bổ cho các mục vượt quá ngân sách tháng!',
                style: TextStyle(fontSize: 12, color: Colors.red.shade900),
              ),
            ),
          for (final cat in overBudgetCategories)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                '• Danh mục "${cat.name}" đã vượt chi tiêu cho phép!',
                style: TextStyle(fontSize: 12, color: Colors.red.shade900),
              ),
            ),
          for (final cat in nearLimitCategories)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                '• Danh mục "${cat.name}" đã dùng tới ${(cat.percentageSpent * 100).toStringAsFixed(0)}% ngân sách!',
                style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
              ),
            ),
        ],
      ),
    );
  }
}
