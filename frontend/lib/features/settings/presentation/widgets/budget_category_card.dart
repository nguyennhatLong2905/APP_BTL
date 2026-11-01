import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/category_budget.dart';

class BudgetCategoryCard extends StatelessWidget {
  final CategoryBudget category;
  final VoidCallback? onEditPressed;

  const BudgetCategoryCard({
    super.key,
    required this.category,
    this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###', 'vi_VN');
    final isNearLimit = category.isNearLimit;
    final percentageInt = category.percentageInt;

    final progressColor =
        isNearLimit ? Colors.brown.shade700 : const Color(0xFF0F5B47);
    final percentTextColor =
        isNearLimit ? Colors.brown.shade800 : Colors.black87;

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isNearLimit
                        ? Colors.orange.shade100
                        : category.iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    category.icon,
                    color: isNearLimit
                        ? Colors.brown.shade800
                        : const Color(0xFF0F5B47),
                    size: 20,
                  ),
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
                      const SizedBox(height: 2),
                      Text(
                        'Đã tiêu ${currencyFormatter.format(category.spentAmount)} ₫',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${currencyFormatter.format(category.allocatedAmount)} ₫',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: percentTextColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: onEditPressed,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                    Text(
                      '$percentageInt%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: percentTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (category.percentageSpent).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: const Color(0xFFEAF8F5),
                color: progressColor,
              ),
            ),

            // Warning Box if any
            if (category.warningMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 14, color: Colors.brown.shade800),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        category.warningMessage!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.brown.shade900,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onEditPressed,
                      child: Text(
                        'Điều chỉnh...',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown.shade800,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
