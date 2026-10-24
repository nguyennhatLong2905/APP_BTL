import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import '../../domain/models/category_budget.dart';

class CategoryBudgetItem extends StatelessWidget {
  final CategoryBudget category;
  final double totalMonthlyBudget;
  final ValueChanged<double> onAmountChanged;

  const CategoryBudgetItem({
    super.key,
    required this.category,
    required this.totalMonthlyBudget,
    required this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###', 'vi_VN');
    final percentSpent = category.percentageSpent.clamp(0.0, 1.0);
    final isNearLimit = category.isNearLimit;
    final isOverBudget = category.isOverBudget;

    Color progressColor = category.color;
    if (isOverBudget) {
      progressColor = Colors.red;
    } else if (isNearLimit) {
      progressColor = Colors.orange;
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: category.color.withValues(alpha: 0.15),
                  radius: 18,
                  child: Icon(category.icon, color: category.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Đã chi: ${currencyFormatter.format(category.spentAmount)} ₫',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOverBudget ? Colors.red : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${currencyFormatter.format(category.allocatedAmount)} ₫',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: percentSpent,
                backgroundColor: Colors.grey.shade200,
                color: progressColor,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kéo slider để điều chỉnh ngân sách:',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                Text(
                  '${((category.allocatedAmount / (totalMonthlyBudget > 0 ? totalMonthlyBudget : 1)) * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SfSlider(
              min: 0.0,
              max: totalMonthlyBudget > 0 ? totalMonthlyBudget : 10000000.0,
              value: category.allocatedAmount,
              interval: totalMonthlyBudget > 0 ? totalMonthlyBudget / 4 : 2500000.0,
              stepSize: 100000.0,
              activeColor: category.color,
              onChanged: (dynamic value) {
                onAmountChanged(value as double);
              },
            ),
          ],
        ),
      ),
    );
  }
}
