import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/budget.dart';

class BudgetProgressChart extends StatelessWidget {
  final Budget budget;

  const BudgetProgressChart({
    super.key,
    required this.budget,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###', 'vi_VN');
    final totalBudget = budget.monthlyBudget;
    final totalAllocated = budget.totalAllocated;
    final totalSpent = budget.totalSpent;

    final allocatedRatio =
        totalBudget > 0 ? (totalAllocated / totalBudget).clamp(0.0, 1.0) : 0.0;
    final spentRatio =
        totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tổng Quan Phân Bổ Ngân Sách',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoCol('Tổng phân bổ', currencyFormatter.format(totalAllocated),
                    budget.isOverAllocated ? Colors.red : Colors.blue.shade800),
                _buildInfoCol('Tổng thực chi', currencyFormatter.format(totalSpent),
                    Colors.orange.shade800),
                _buildInfoCol(
                    'Chưa phân bổ',
                    currencyFormatter.format(budget.remainingUnallocated),
                    budget.remainingUnallocated >= 0
                        ? Colors.green.shade800
                        : Colors.red),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Tỷ lệ đã phân bổ (${(allocatedRatio * 100).toStringAsFixed(0)}%):',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: allocatedRatio,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                color: budget.isOverAllocated ? Colors.red : const Color(0xFF00A86B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tỷ lệ đã thực chi (${(spentRatio * 100).toStringAsFixed(0)}%):',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: spentRatio,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCol(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          '$value ₫',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
